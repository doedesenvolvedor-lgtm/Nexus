"""
Serviço para validação e processamento de webhooks de pagamento.
Suporta MercadoPago e outros provedores de pagamento.
"""

import logging
import hmac
import hashlib
from typing import Optional
from datetime import datetime, timezone
from uuid import UUID

from sqlalchemy.orm import Session
from pydantic import BaseModel

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
        from app.models import Payment, Subscription, User
        
        payment_id = data.get("id")
        status = data.get("status")  # approved, pending, rejected, cancelled
        amount = data.get("amount")
        user_id = data.get("payer", {}).get("id")  # ID do payer no MercadoPago
        
        logger.info(f"Payment webhook: payment_id={payment_id}, status={status}")
        
        if not payment_id:
            logger.warning("Missing payment_id in webhook")
            return False
        
        # Procurar pagamento existente
        payment = db.query(Payment).filter(
            Payment.external_id == payment_id
        ).first()
        
        if payment:
            # Atualizar status
            payment.status = status
            payment.updated_at = datetime.now(timezone.utc)
            
            # Se aprovado, ativar subscription
            if status == "approved":
                subscription = db.query(Subscription).filter(
                    Subscription.id == payment.subscription_id
                ).first()
                
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
        
        logger.info(f"Subscription webhook: subscription_id={subscription_id}, status={status}")
        
        if not subscription_id:
            logger.warning("Missing subscription_id in webhook")
            return False
        
        # Procurar assinatura
        subscription = db.query(Subscription).filter(
            Subscription.external_id == subscription_id
        ).first()
        
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
