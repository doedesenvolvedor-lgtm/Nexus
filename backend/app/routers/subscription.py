from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import Subscription
from app.schemas import SubscriptionCreate, SubscriptionResponse

router = APIRouter(tags=["Assinaturas"])


@router.post("/", response_model=SubscriptionResponse)
def create_subscription(sub: SubscriptionCreate, db: Session = Depends(get_db)):
    obj = Subscription(**sub.model_dump())
    db.add(obj)
    db.commit()
    db.refresh(obj)
    return obj


@router.get("/", response_model=list[SubscriptionResponse])
def list_subscriptions(db: Session = Depends(get_db)):
    return db.query(Subscription).all()


@router.delete("/{subscription_id}")
def cancel_subscription(subscription_id: str, db: Session = Depends(get_db)):
    obj = db.query(Subscription).filter(Subscription.id == subscription_id).first()
    if not obj:
        raise HTTPException(status_code=404, detail="Assinatura não encontrada.")
    db.delete(obj)
    db.commit()
    return {"detail": "Assinatura cancelada"}
