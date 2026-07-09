from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import Payment
from app.schemas import PaymentCreate, PaymentResponse

router = APIRouter(tags=["Pagamentos"])


@router.post("/payments", response_model=PaymentResponse)
def register(payment: PaymentCreate, db: Session = Depends(get_db)):
    obj = Payment(**payment.model_dump())
    db.add(obj)
    db.commit()
    db.refresh(obj)
    return obj


@router.get("/payments", response_model=list[PaymentResponse])
def payments(db: Session = Depends(get_db)):
    return db.query(Payment).all()


@router.get("/payments/history/{user_id}", response_model=list[PaymentResponse])
def history(user_id: str, db: Session = Depends(get_db)):
    return db.query(Payment).filter(Payment.user_id == user_id).all()
