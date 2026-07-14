from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.database import get_db
from app.dependencies import get_current_user
from app.models import Subscription, User
from app.schemas import SubscriptionResponse, TrialStatusResponse

router = APIRouter(prefix="/subscriptions", tags=["Subscriptions"])


@router.get("/me", response_model=SubscriptionResponse)
def get_my_subscription(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Retorna a subscription atual do usuário."""
    subscription = (
        db.query(Subscription)
        .filter(Subscription.user_id == current_user.id)
        .order_by(Subscription.created_at.desc())
        .first()
    )

    if not subscription:
        raise HTTPException(status_code=404, detail="Nenhuma subscription encontrada.")

    return subscription


@router.get("/me/trial-status", response_model=TrialStatusResponse)
def get_trial_status(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Retorna o status do trial do usuário."""
    subscription = (
        db.query(Subscription)
        .filter(Subscription.user_id == current_user.id)
        .order_by(Subscription.created_at.desc())
        .first()
    )

    if not subscription:
        raise HTTPException(status_code=404, detail="Nenhuma subscription encontrada.")

    is_trial = subscription.plan_type == "Trial"
    days_remaining = 0

    if is_trial and subscription.trial_ends_at:
        now = datetime.now(timezone.utc)
        trial_ends = subscription.trial_ends_at.replace(tzinfo=timezone.utc)
        delta = trial_ends - now
        days_remaining = max(0, delta.days + (1 if delta.seconds > 0 else 0))

    return TrialStatusResponse(
        is_trial=is_trial,
        days_remaining=days_remaining,
        trial_ends_at=subscription.trial_ends_at,
        plan_type=subscription.plan_type,
    )


@router.post("/upgrade-trial")
def upgrade_trial_to_paid(
    plan: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Faz upgrade do trial para um plano pago.
    
    Planos disponíveis: Basic (R$ 15), Standard (R$ 25), Premium (R$ 40)
    """
    if plan not in ["Basic", "Standard", "Premium"]:
        raise HTTPException(
            status_code=400,
            detail="Plano inválido. Opções: Basic, Standard, Premium",
        )

    subscription = (
        db.query(Subscription)
        .filter(Subscription.user_id == current_user.id)
        .order_by(Subscription.created_at.desc())
        .first()
    )

    if not subscription:
        raise HTTPException(status_code=404, detail="Nenhuma subscription encontrada.")

    subscription.plan = plan
    subscription.plan_type = "Premium"
    subscription.status = "active"
    subscription.trial_started_at = None
    subscription.trial_ends_at = None
    subscription.updated_at = datetime.now(timezone.utc)

    db.commit()
    db.refresh(subscription)

    return {
        "message": f"Upgrade para plano {plan} realizado com sucesso!",
        "subscription": SubscriptionResponse.from_orm(subscription),
    }


@router.post("/check-trial-expiration")
def check_and_update_expired_trials(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Verifica se o trial do usuário expirou e atualiza o status para Free.
    """
    subscription = (
        db.query(Subscription)
        .filter(Subscription.user_id == current_user.id)
        .order_by(Subscription.created_at.desc())
        .first()
    )

    if not subscription:
        raise HTTPException(status_code=404, detail="Nenhuma subscription encontrada.")

    if subscription.plan_type == "Trial" and subscription.trial_ends_at:
        now = datetime.now(timezone.utc)
        trial_ends = subscription.trial_ends_at.replace(tzinfo=timezone.utc)

        if now > trial_ends:
            subscription.plan = "Free"
            subscription.plan_type = "Free"
            subscription.status = "expired"
            subscription.trial_started_at = None
            subscription.trial_ends_at = None
            subscription.updated_at = datetime.now(timezone.utc)

            db.commit()
            db.refresh(subscription)

            return {
                "message": "Seu trial expirou. Escolha um plano para continuar.",
                "status": "expired",
                "subscription": SubscriptionResponse.from_orm(subscription),
            }

    return {
        "message": "Trial ainda ativo.",
        "status": "active",
        "subscription": SubscriptionResponse.from_orm(subscription),
    }
