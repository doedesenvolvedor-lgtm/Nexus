"""
Endpoints de Pagamento com MercadoPago
Web Checkout Integration
"""

from fastapi import APIRouter, Depends, HTTPException, Request
from sqlalchemy.orm import Session
from app.database import get_db
from app.dependencies import get_current_user
from app.models import User, Payment, Subscription
from app.services.email_service import get_email_service
from app.services.mercadopago_service import get_mercadopago_service
from pydantic import BaseModel
from datetime import datetime
from typing import Optional
from uuid import UUID

router = APIRouter(prefix="/payments", tags=["payments"])


class CheckoutRequest(BaseModel):
    plan: str  # Basic, Standard, Premium
    price: float


class CheckoutResponse(BaseModel):
    preference_id: str
    payment_url: str
    plan: str


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
    
    try:
        mp_service = get_mercadopago_service()
        
        # Criar preferência no MercadoPago
        preference = mp_service.create_preference(
            user_id=str(current_user.id),
            username=current_user.username,
            email=current_user.email,
            plan=request.plan,
            price=request.price,
        )
        
        # Registrar pagamento como "pending" no banco
        payment = Payment(
            user_id=current_user.id,
            provider="mercadopago",
            payment_id=preference.get("preference_id"),
            amount=request.price,
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
        
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.get("/success")
async def payment_success(
    preference_id: Optional[str] = None,
    payment_id: Optional[str] = None,
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
        
    except Exception as e:
        return {
            "status": "error",
            "message": str(e),
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
    Webhook do MercadoPago para notificações de pagamento
    """
    
    try:
        body = await request.json()
        
        # Se for notificação de pagamento
        if body.get("type") == "payment":
            payment_id = body.get("data", {}).get("id")
            
            if not payment_id:
                return {"status": "error"}
            
            mp_service = get_mercadopago_service()
            payment_info = mp_service.get_payment_status(str(payment_id))
            
            # Encontrar pagamento pelo external_reference
            external_ref = payment_info.get("external_reference")
            if external_ref and "_plan_" in external_ref:
                # Parse: user_{user_id}_plan_{plan}
                user_id_str = external_ref.split("_plan_")[0].replace("user_", "")
                plan = external_ref.split("_plan_")[1]
                user_id = UUID(user_id_str)
                
                # Atualizar pagamento no BD
                payment = db.query(Payment).filter(
                    Payment.user_id == user_id
                ).order_by(Payment.created_at.desc()).first()
                
                if payment:
                    previous_status = payment.status
                    if payment_info["status"] == "approved":
                        payment.status = "approved"
                        payment.payment_id = str(payment_id)
                        
                        # Atualizar subscription
                        subscription = db.query(Subscription).filter(
                            Subscription.user_id == user_id
                        ).first()
                        
                        if subscription:
                            subscription.plan_type = plan
                            subscription.status = "active"
                            subscription.updated_at = datetime.utcnow()

                        if previous_status != "approved":
                            user = db.query(User).filter(User.id == user_id).first()
                            if user:
                                get_email_service().send_payment_receipt_email(
                                    to_email=user.email,
                                    plan=payment.plan or plan,
                                    amount=payment.amount,
                                    payment_id=str(payment_id),
                                    status="approved",
                                )
                        
                    elif payment_info["status"] == "rejected":
                        payment.status = "rejected"
                    
                    elif payment_info["status"] == "pending":
                        payment.status = "pending"
                    
                    payment.updated_at = datetime.utcnow()
                    db.commit()
        
        return {"status": "ok"}
        
    except Exception as e:
        return {"status": "error", "message": str(e)}


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
