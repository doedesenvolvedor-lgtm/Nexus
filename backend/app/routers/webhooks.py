"""
Webhooks para processamento de eventos de pagamento e assinatura.
Suporta MercadoPago e outros provedores de pagamento.
"""

import logging
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Request, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.config import MERCADOPAGO_WEBHOOK_SECRET
from app.services.webhook_service import WebhookValidator, MercadoPagoWebhookData
from app.exception_handlers import APIError

logger = logging.getLogger(__name__)
router = APIRouter(tags=["Webhooks"])


@router.post("/mercadopago")
async def mercadopago_webhook(
    request: Request,
    db: Session = Depends(get_db),
):
    """
    Webhook para eventos do MercadoPago.
    
    Valida assinatura e processa pagamentos/assinaturas.
    
    Headers esperados:
    - X-Signature: Assinatura HMAC
    - X-Request-ID: ID único da requisição
    """
    
    try:
        # Extrair headers de validação
        x_signature = request.headers.get("X-Signature")
        x_request_id = request.headers.get("X-Request-ID")
        
        # Ler body
        body = await request.body()
        
        # Validar assinatura
        is_valid = WebhookValidator.validate_mercadopago_signature(
            x_signature=x_signature,
            x_request_id=x_request_id,
            body=body,
            webhook_secret=MERCADOPAGO_WEBHOOK_SECRET,
        )
        
        if not is_valid:
            logger.warning(f"Invalid webhook signature from {request.client.host}")
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Assinatura de webhook inválida",
            )
        
        # Parse JSON
        import json
        payload = json.loads(body)
        
        # Validar estrutura
        webhook_data = MercadoPagoWebhookData(**payload)
        
        # Processar webhook
        success = WebhookValidator.process_payment_webhook(
            payload=webhook_data.dict(),
            db=db,
        )
        
        if success:
            logger.info(f"Webhook processed successfully: {webhook_data.id}")
            return {
                "status": "received",
                "id": webhook_data.id,
                "message": "Webhook processado com sucesso",
            }
        else:
            logger.error(f"Failed to process webhook: {webhook_data.id}")
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Erro ao processar webhook",
            )
            
    except ValueError as e:
        logger.warning(f"Invalid JSON in webhook: {e}")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="JSON inválido",
        )
    except Exception as e:
        logger.error(f"Unexpected error in webhook: {e}", exc_info=True)
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
    
    Estrutura similar ao MercadoPago mas com validações específicas.
    """
    
    try:
        # Headers de validação do Stripe
        stripe_signature = request.headers.get("Stripe-Signature")
        
        if not stripe_signature:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Assinatura do Stripe ausente",
            )
        
        # Ler body
        body = await request.body()
        
        # Nota: Implementar validação de assinatura do Stripe conforme documentação
        # https://stripe.com/docs/webhooks/signatures
        
        logger.info("Stripe webhook received")
        return {
            "status": "received",
            "message": "Webhook do Stripe recebido",
        }
        
    except Exception as e:
        logger.error(f"Error processing Stripe webhook: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erro ao processar webhook",
        )


@router.get("/test")
async def webhook_test():
    """Endpoint de teste para validar webhook."""
    return {
        "status": "ok",
        "message": "Webhook service está funcionando",
    }
