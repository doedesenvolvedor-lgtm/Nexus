"""
Webhooks para processamento de eventos de pagamento e assinatura.
Suporta MercadoPago e Stripe.
Processamento delegado para WebhookValidator em services/webhook_service.py
"""

import logging

from fastapi import APIRouter, Depends, HTTPException, Request, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.config import MERCADOPAGO_WEBHOOK_SECRET, STRIPE_WEBHOOK_SECRET
from app.services.cache_service import acquire_lock, release_lock
from app.services.webhook_service import WebhookValidator

logger = logging.getLogger(__name__)
router = APIRouter(tags=["Webhooks"])


@router.post("/mercadopago")
async def mercadopago_webhook(
    request: Request,
    db: Session = Depends(get_db),
):
    """
    Webhook para eventos do MercadoPago.
    Valida assinatura via WebhookValidator e processa pagamentos/assinaturas.
    Suporta idempotencia via X-Idempotency-Key.
    """
    if not MERCADOPAGO_WEBHOOK_SECRET:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Webhook MercadoPago nao configurado.",
        )

    idempotency_key = request.headers.get("X-Idempotency-Key") or request.headers.get("X-Request-ID")

    if idempotency_key:
        lock_key = f"webhook:idempotency:{idempotency_key}"
        if not acquire_lock(lock_key, ttl_seconds=300):
            logger.info(f"Webhook duplicado ignorado: {idempotency_key}")
            return {"status": "already_processed", "message": "Webhook ja processado."}

    try:
        x_signature = request.headers.get("X-Signature")
        x_request_id = request.headers.get("X-Request-ID")
        body = await request.body()

        is_valid = WebhookValidator.validate_mercadopago_signature(
            x_signature=x_signature,
            x_request_id=x_request_id,
            body=body,
            webhook_secret=MERCADOPAGO_WEBHOOK_SECRET,
        )

        if not is_valid:
            logger.warning(f"Invalid webhook signature from {request.client.host}")
            if idempotency_key:
                release_lock(f"webhook:idempotency:{idempotency_key}")
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Assinatura de webhook invalida",
            )

        payload = await request.json()
        success = WebhookValidator.process_payment_webhook(payload, db)

        if success:
            return {"status": "received", "message": "Webhook processado com sucesso"}
        else:
            if idempotency_key:
                release_lock(f"webhook:idempotency:{idempotency_key}")
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Erro ao processar webhook",
            )

    except ValueError as e:
        logger.warning(f"Invalid JSON in webhook: {e}")
        if idempotency_key:
            release_lock(f"webhook:idempotency:{idempotency_key}")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="JSON invalido",
        )
    except HTTPException:
        if idempotency_key:
            release_lock(f"webhook:idempotency:{idempotency_key}")
        raise
    except Exception as e:
        logger.error(f"Unexpected error in webhook: {e}", exc_info=True)
        if idempotency_key:
            release_lock(f"webhook:idempotency:{idempotency_key}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erro interno ao processar webhook",
        )


@router.post("/stripe")
async def stripe_webhook(
    request: Request,
    db: Session = Depends(get_db),
):
    """
    Webhook para eventos do Stripe.
    Valida assinatura usando Stripe-Signature e processa via WebhookValidator.
    """
    try:
        stripe_signature = request.headers.get("Stripe-Signature")
        body = await request.body()

        if STRIPE_WEBHOOK_SECRET and stripe_signature:
            is_valid = WebhookValidator.validate_stripe_signature(
                stripe_signature=stripe_signature,
                body=body,
                webhook_secret=STRIPE_WEBHOOK_SECRET,
            )
            if not is_valid:
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="Assinatura do Stripe invalida",
                )

        payload = await request.json()
        success = WebhookValidator.process_payment_webhook(payload, db)

        if success:
            return {"status": "received", "message": "Webhook do Stripe processado"}
        else:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Erro ao processar webhook do Stripe",
            )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error processing Stripe webhook: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erro ao processar webhook",
        )


@router.get("/test")
async def webhook_test():
    """Endpoint de teste para validar webhook."""
    return {"status": "ok", "message": "Webhook service esta funcionando"}
