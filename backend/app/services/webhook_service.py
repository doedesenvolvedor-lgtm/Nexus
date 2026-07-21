"""
Serviço para validação e processamento de webhooks de pagamento.
Suporta MercadoPago e outros provedores de pagamento.
"""

import hmac
import hashlib
import logging
from typing import Optional
from datetime import datetime, timezone

from pydantic import BaseModel
from sqlalchemy.orm import Session

logger = logging.getLogger(__name__)


class MercadoPagoWebhookData(BaseModel):
    """Dados do webhook do MercadoPago."""
    
    id: str
    type: str  # payment, subscription, etc
    action: str  # payment.created, payment.updated, etc
    data: dict
    
    class Config:
        from_attributes = True


class WebhookValidator:
    """Valida webhooks de pagamento."""
    
    @staticmethod
    def validate_mercadopago_signature(
        x_signature: Optional[str],
        x_request_id: Optional[str],
        body: bytes,
        webhook_secret: str
    ) -> bool:
        """
        Valida assinatura do webhook MercadoPago.
        
        MercadoPago usa: X-Signature = ts=timestamp;v1=hmac_value
        HMAC = SHA256(request_id|access_token|timestamp|body)
        """
        if not x_signature or not x_request_id:
            logger.warning("Missing X-Signature or X-Request-ID headers")
            return False
        
        try:
            # Parse signature header
            parts = x_signature.split(";")
            ts = None
            v1 = None
            
            for part in parts:
                if part.startswith("ts="):
                    ts = part.replace("ts=", "")
                elif part.startswith("v1="):
                    v1 = part.replace("v1=", "")
            
            if not ts or not v1:
                logger.warning("Invalid signature format")
                return False
            
            # Gerar HMAC esperado
            # Nota: Adaptar conforme documentação real do MercadoPago
            message = f"{x_request_id}|{webhook_secret}|{ts}|{body.decode()}"
            expected_hmac = hmac.new(
                webhook_secret.encode(),
                message.encode(),
                hashlib.sha256
            ).hexdigest()
            
            # Comparar com timing-safe comparison
            is_valid = hmac.compare_digest(expected_hmac, v1)
            
            if not is_valid:
                logger.warning("HMAC mismatch - possible webhook tampering")
            
            return is_valid
            
        except Exception as e:
            logger.error(f"Error validating webhook signature: {e}")
            return False
    
    @staticmethod
    def process_payment_webhook(
        payload: dict,
        db: Session
    ) -> bool:
        """
        Processa webhook de pagamento.
        Atualiza status de assinatura/pagamento no banco de dados.
        """
        try:
            webhook_type = payload.get("type")
            action = payload.get("action")
            data = payload.get("data", {})
            
            logger.info(f"Processing webhook: type={webhook_type}, action={action}")
            
            if webhook_type == "payment":
                return _process_payment(data, db)
            elif webhook_type == "subscription":
                return _process_subscription(data, db)
            else:
                logger.warning(f"Unknown webhook type: {webhook_type}")
                return False
                
        except Exception as e:
            logger.error(f"Error processing webhook: {e}", exc_info=True)
            return False


def _process_payment(data: dict, db: Session) -> bool:
    """Processa webhook de pagamento individual."""
    try:
        from app.models import Payment, Subscription
        
        payment_id = data.get("id")
        status = data.get("status")  # approved, pending, rejected, cancelled
        logger.info(f"Payment webhook: payment_id={payment_id}, status={status}")
        
        if not payment_id:
            logger.warning("Missing payment_id in webhook")
            return False
        
        # Procurar pagamento existente
        payment = db.query(Payment).filter(Payment.payment_id == str(payment_id)).first()
        
        if payment:
            # Atualizar status
            payment.status = status
            payment.updated_at = datetime.now(timezone.utc)
            
            # Se aprovado, ativar subscription
            if status == "approved":
                subscription = (
                    db.query(Subscription)
                    .filter(Subscription.user_id == payment.user_id)
                    .order_by(Subscription.created_at.desc())
                    .first()
                )
                
                if subscription:
                    subscription.status = "active"
                    subscription.updated_at = datetime.now(timezone.utc)
                    logger.info(f"Subscription activated: {subscription.id}")
            
            db.commit()
            logger.info(f"Payment updated: {payment_id}")
            return True
        else:
            logger.warning(f"Payment not found: {payment_id}")
            return False
            
    except Exception as e:
        logger.error(f"Error processing payment webhook: {e}", exc_info=True)
        db.rollback()
        return False


def _process_subscription(data: dict, db: Session) -> bool:
    """Processa webhook de assinatura."""
    try:
        from app.models import Subscription
        
        subscription_id = data.get("id")
        status = data.get("status")
        external_reference = data.get("external_reference")
        
        logger.info(f"Subscription webhook: subscription_id={subscription_id}, status={status}")
        
        if not subscription_id:
            logger.warning("Missing subscription_id in webhook")
            return False
        
        subscription = None
        if external_reference and "_plan_" in external_reference:
            user_id_str = external_reference.split("_plan_")[0].replace("user_", "")
            subscription = (
                db.query(Subscription)
                .filter(Subscription.user_id == user_id_str)
                .order_by(Subscription.created_at.desc())
                .first()
            )
        
        if subscription:
            subscription.status = status
            subscription.updated_at = datetime.now(timezone.utc)
            db.commit()
            logger.info(f"Subscription updated: {subscription_id}")
            return True
        else:
            logger.warning(f"Subscription not found: {subscription_id}")
            return False
            
    except Exception as e:
        logger.error(f"Error processing subscription webhook: {e}", exc_info=True)
        db.rollback()
        return False
