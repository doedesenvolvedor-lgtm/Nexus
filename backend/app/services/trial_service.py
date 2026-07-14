from datetime import datetime, timezone

from sqlalchemy.orm import Session

from app.models import Subscription, User


def get_subscription_status(user: User, db: Session) -> dict:
    """
    Retorna o status da subscription do usuário.
    """
    subscription = (
        db.query(Subscription)
        .filter(Subscription.user_id == user.id)
        .order_by(Subscription.created_at.desc())
        .first()
    )

    if not subscription:
        return {
            "plan_type": "Free",
            "status": "none",
            "is_premium": False,
            "days_remaining": 0,
        }

    is_premium = subscription.plan_type in ["Trial", "Premium"]
    days_remaining = 0

    # Verificar se trial expirou
    if subscription.plan_type == "Trial" and subscription.trial_ends_at:
        now = datetime.now(timezone.utc)
        trial_ends = subscription.trial_ends_at.replace(tzinfo=timezone.utc)

        if now > trial_ends:
            # Trial expirou - atualizar no banco
            subscription.plan = "Free"
            subscription.plan_type = "Free"
            subscription.status = "expired"
            subscription.trial_started_at = None
            subscription.trial_ends_at = None
            subscription.updated_at = datetime.now(timezone.utc)
            db.commit()

            return {
                "plan_type": "Free",
                "status": "expired",
                "is_premium": False,
                "days_remaining": 0,
            }
        else:
            # Trial ainda ativo
            delta = trial_ends - now
            days_remaining = max(0, delta.days + (1 if delta.seconds > 0 else 0))

    return {
        "plan_type": subscription.plan_type,
        "status": subscription.status,
        "is_premium": is_premium,
        "days_remaining": days_remaining,
        "trial_ends_at": subscription.trial_ends_at,
    }


def check_premium_access(user: User, db: Session) -> bool:
    """
    Verifica se o usuário tem acesso a conteúdo premium.
    """
    status = get_subscription_status(user, db)
    return status["is_premium"]
