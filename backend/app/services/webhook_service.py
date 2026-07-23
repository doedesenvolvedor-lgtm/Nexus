"""
Servico unificado para validacao e processamento de webhooks de pagamento.
Suporta MercadoPago e Stripe.
WARNING: Esta e a unica fonte de verdade para processamento de webhooks.
A logica duplicada em app/routers/webhooks.py foi removida e delegada para ca.
"""

import hashlib
import hmac
import logging
from datetime import datetime, timezone
from typing import Optional
from uuid import UUID

from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.models import Payment, Subscription, User
from app.services.cache_service import acquire_lock, release_lock
from app.services.mercadopago_service import get_mercadopago_service
from app.services.email_service import get_email_service

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
        webhook_secret: str,
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

            message = f"{x_request_id}|{webhook_secret}|{ts}|{body.decode()}"
            expected_hmac = hmac.new(
                webhook_secret.encode(), message.encode(), hashlib.sha256
            ).hexdigest()

            is_valid = hmac.compare_digest(expected_hmac, v1)

            if not is_valid:
                logger.warning("HMAC mismatch - possible webhook tampering")

            return is_valid

        except Exception as e:
            logger.error(f"Error validating webhook signature: {e}")
            return False

    @staticmethod
    def validate_stripe_signature(
        stripe_signature: Optional[str],
        body: bytes,
        webhook_secret: str,
    ) -> bool:
        """Valida assinatura do webhook Stripe."""
        if not stripe_signature:
            logger.warning("Missing Stripe-Signature header")
            return False

        try:
            expected_sig = hmac.new(
                webhook_secret.encode(), body, hashlib.sha256
            ).hexdigest()

            sig_parts = {}
            for part in stripe_signature.split(","):
                kv = part.strip().split("=", 1)
                if len(kv) == 2:
                    sig_parts[kv[0]] = kv[1]

            received_sig = sig_parts.get("v1", "")
            return hmac.compare_digest(expected_sig, received_sig)

        except Exception as e:
            logger.error(f"Error validating Stripe signature: {e}")
            return False

    @staticmethod
    def process_payment_webhook(payload: dict, db: Session) -> bool:
        """
        Processa webhook de pagamento (MercadoPago ou Stripe).
        UNICO ponto de processamento de pagamentos.
        """
        try:
            webhook_type = payload.get("type")
            action = payload.get("action")
            data = payload.get("data", {})

            logger.info(f"Processing webhook: type={webhook_type}, action={action}")

            if webhook_type == "payment":
                return _process_payment_notification(payload, db)
            elif webhook_type in ("subscription", "subscription_updated"):
                return _process_subscription_notification(data, db)
            else:
                logger.warning(f"Unknown webhook type: {webhook_type}, ignoring")
                return True  # Tipos desconhecidos sao ignorados

        except Exception as e:
            logger.error(f"Error processing webhook: {e}", exc_info=True)
            return False


def _process_payment_notification(payload: dict, db: Session) -> bool:
    """
    Processa notificacao de pagamento.
    Obtem status real do provedor, atualiza payment e subscription.
    """
    try:
        payment_id = payload.get("data", {}).get("id")
        if not payment_id:
            logger.warning("Payment ID nao encontrado no webhook")
            return False

        mp_service = get_mercadopago_service()
        payment_info = mp_service.get_payment_status(str(payment_id))

        external_ref = payment_info.get("external_reference", "")
        if not external_ref or "_plan_" not in external_ref:
            logger.warning(f"external_reference invalida: {external_ref}")
            return False

        user_id_str = external_ref.split("_plan_")[0].replace("user_", "")
        plan = external_ref.split("_plan_")[1]

        try:
            user_id = UUID(user_id_str)
        except ValueError:
            logger.error(f"Invalid user_id in external_reference: {user_id_str}")
            return False

        # Lock distribuido para evitar race condition
        lock_key = f"payment:processing:{user_id}"
        if not acquire_lock(lock_key, ttl_seconds=10):
            logger.warning(f"Payment already being processed for user {user_id}")
            return True  # Ja esta sendo processado

        try:
            payment = (
                db.query(Payment)
                .filter(Payment.user_id == user_id)
                .order_by(Payment.created_at.desc())
                .first()
            )

            if not payment:
                logger.warning(f"No payment found for user {user_id}")
                return False

            previous_status = payment.status
            new_status = payment_info.get("status", "pending")

            if new_status != previous_status:
                payment.status = new_status
                payment.payment_id = str(payment_id)
                payment.updated_at = datetime.now(timezone.utc)

                if new_status == "approved":
                    subscription = (
                        db.query(Subscription)
                        .filter(Subscription.user_id == user_id)
                        .first()
                    )

                    if subscription:
                        subscription.plan_type = plan
                        subscription.status = "active"
                        subscription.updated_at = datetime.now(timezone.utc)

                    user = db.query(User).filter(User.id == user_id).first()
                    if user and previous_status != "approved":
                        get_email_service().send_payment_receipt_email(
                            to_email=user.email,
                            plan=payment.plan or plan,
                            amount=payment.amount,
                            payment_id=str(payment_id),
                            status="approved",
                        )

                db.commit()
                logger.info(f"Payment {payment_id} updated to {new_status}")

        finally:
            release_lock(lock_key)

        return True

    except Exception as e:
        logger.error(f"Error processing payment notification: {e}", exc_info=True)
        db.rollback()
        return False


def _process_subscription_notification(data: dict, db: Session) -> bool:
    """Processa webhook de assinatura."""
    try:
        subscription_id = data.get("id")
        status = data.get("status")
        external_reference = data.get("external_reference")

        logger.info(
            f"Subscription webhook: subscription_id={subscription_id}, status={status}"
        )

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
            logger.warning(f"Subscription not found for external_ref: {external_reference}")
            return False

    except Exception as e:
        logger.error(f"Error processing subscription webhook: {e}", exc_info=True)
        db.rollback()
        return False
