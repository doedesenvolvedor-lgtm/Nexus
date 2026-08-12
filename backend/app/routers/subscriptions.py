from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.database import get_db
from app.dependencies import get_current_user
from app.models import Subscription, User
from app.schemas import SubscriptionCreate, SubscriptionResponse

router = APIRouter(tags=["Assinaturas"])


@router.post("/subscription", response_model=SubscriptionResponse)
def create_subscription(
    sub: SubscriptionCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    # Garantir que a assinatura é criada para o usuário autenticado
    obj = Subscription(**sub.model_dump(exclude={"user_id"}), user_id=current_user.id)
    db.add(obj)
    db.commit()
    db.refresh(obj)
    return obj


@router.get("/subscription", response_model=list[SubscriptionResponse])
def list_subscriptions(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return (
        db.query(Subscription)
        .filter(Subscription.user_id == current_user.id)
        .all()
    )


@router.delete("/subscription/{subscription_id}")
def cancel_subscription(
    subscription_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    obj = (
        db.query(Subscription)
        .filter(
            Subscription.id == subscription_id,
            Subscription.user_id == current_user.id,
        )
        .first()
    )
    if not obj:
        raise HTTPException(status_code=404, detail="Assinatura não encontrada.")
    db.delete(obj)
    db.commit()
    return {"detail": "Assinatura cancelada"}
