"""
Endpoints de Pagamento com MercadoPago
Web Checkout Integration
"""

import logging
from fastapi import APIRouter, Depends, HTTPException, Request, status
from sqlalchemy.orm import Session
from app.database import get_db
from app.dependencies import get_current_user
from app.models import User, Payment, Subscription
from app.services.email_service import get_email_service
from app.services.mercadopago_service import get_mercadopago_service
from pydantic import BaseModel, Field
from datetime import datetime
from typing import Literal, Optional
from uuid import UUID
from app.config import MERCADOPAGO_WEBHOOK_SECRET
from app.services.webhook_service import WebhookValidator

router = APIRouter(prefix="/payments", tags=["payments"])
logger = logging.getLogger(__name__)
PLAN_PRICES = {
    "Basic": 15.0,
    "Standard": 25.0,
    "Premium": 40.0,
}


class CheckoutRequest(BaseModel):
    plan: Literal["Basic", "Standard", "Premium"]
    price: Optional[float] = Field(default=None, gt=0, le=10000)


class CheckoutResponse(BaseModel):
    preference_id: str
    payment_url: str
    plan: str


def _resolve_plan_price(plan: str) -> float:
    return PLAN_PRICES[plan]


@router.post("/checkout", response_model=CheckoutResponse)
async def create_checkout(
    request: CheckoutRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Criar sessão de checkout com MercadoPago
    
    ### Exemplo:
    ```json
    {
        "plan": "Premium",
        "price": 39.99
    }
    ```
    """
    
    if current_user is None:
        raise HTTPException(status_code=401, detail="Token inválido.")

    try:
        resolved_price = _resolve_plan_price(request.plan)
        if request.price is not None and abs(request.price - resolved_price) > 0.009:
            logger.warning(
                "Ignoring client supplied checkout price",
                extra={
                    "user_id": str(current_user.id),
                    "plan": request.plan,
                    "client_price": request.price,
                    "resolved_price": resolved_price,
                },
            )

        mp_service = get_mercadopago_service()
        
        # Criar preferência no MercadoPago
        preference = mp_service.create_preference(
            user_id=str(current_user.id),
            username=current_user.username,
            email=current_user.email,
            plan=request.plan,
            price=resolved_price,
        )
        
        # Registrar pagamento como "pending" no banco
        payment = Payment(
            user_id=current_user.id,
            provider="mercadopago",
            payment_id=preference.get("preference_id"),
            amount=resolved_price,
            currency="BRL",
            status="pending",
            plan=request.plan,
        )
        db.add(payment)
        db.commit()
        
        return CheckoutResponse(
            preference_id=preference.get("preference_id"),
            payment_url=preference.get("payment_url"),
            plan=request.plan,
        )
        
    except ValueError as exc:
        raise HTTPException(status_code=400, detail="Configuração de pagamento inválida.") from exc
    except Exception as exc:
        logger.error("Erro ao criar checkout MercadoPago", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail="Não foi possível iniciar o checkout no provedor de pagamento.",
        ) from exc


@router.get("/success")
async def payment_success(
    preference_id: Optional[str] = None,
    status: Optional[str] = None,
    db: Session = Depends(get_db),
):
    """
    Callback de retorno do checkout.
    A aprovação definitiva deve ocorrer via webhook assinado do provedor.
    """
    
    try:
        # MercadoPago pode enviar payment_id ou collection_id
        payment = db.query(Payment).filter(
            Payment.payment_id == preference_id
        ).first()
        
        if not payment:
            return {
                "status": "error",
                "message": "Pagamento não encontrado",
                "redirect_url": "https://nexus.app/subscription/error"
            }
        
        # Apenas marca como retorno recebido; aprovação final vem no webhook.
        payment.status = "pending"
        payment.updated_at = datetime.utcnow()
        
        db.commit()
        
        return {
            "status": "success",
            "message": "Pagamento recebido. Aguardando confirmação final.",
            "plan": payment.plan,
            "redirect_url": f"https://nexus.app/subscription/pending?plan={payment.plan}"
        }
        
    except Exception:
        logger.error(
            "Erro ao processar callback de pagamento",
            extra={"preference_id": preference_id, "status": status},
            exc_info=True,
        )
        return {
            "status": "error",
            "message": "Não foi possível confirmar o retorno do pagamento.",
            "redirect_url": "https://nexus.app/subscription/error"
        }


@router.get("/failure")
async def payment_failure():
    """Callback de falha do MercadoPago"""
    
    return {
        "status": "failure",
        "message": "Pagamento recusado",
        "redirect_url": "https://nexus.app/subscription/error"
    }


@router.get("/pending")
async def payment_pending():
    """Callback de pagamento pendente"""
    
    return {
        "status": "pending",
        "message": "Pagamento pendente de confirmação",
        "redirect_url": "https://nexus.app/subscription/pending"
    }


@router.post("/webhook")
async def webhook_mercadopago(
    request: Request,
    db: Session = Depends(get_db),
):
    """
    Webhook do MercadoPago para notificações de pagamento.
    Este endpoint é mantido para compatibilidade reversa.
    O processamento principal ocorre via /webhook/mercadopago.
    
    Redireciona para o processador unificado.
    """
    from app.routers.webhooks import mercadopago_webhook as unified_webhook
    return await unified_webhook(request, db)


@router.get("/me/history")
async def get_payment_history(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
    limit: int = 10,
    offset: int = 0,
):
    """
    Obter histórico de pagamentos do usuário
    """
    
    if current_user is None:
        raise HTTPException(status_code=401, detail="Token inválido.")

    payments = db.query(Payment).filter(
        Payment.user_id == current_user.id
    ).order_by(Payment.created_at.desc()).offset(offset).limit(limit).all()
    
    total = db.query(Payment).filter(
        Payment.user_id == current_user.id
    ).count()
    
    return {
        "total": total,
        "limit": limit,
        "offset": offset,
        "payments": [
            {
                "id": str(p.id),
                "provider": p.provider,
                "amount": p.amount,
                "plan": p.plan,
                "status": p.status,
                "created_at": p.created_at.isoformat(),
            }
            for p in payments
        ]
    }
