import logging
from datetime import datetime, timezone
from uuid import uuid4

from sqlalchemy.orm import Session

from app.config import NON_BILLING_PREMIUM_EMAILS
from app.models import Subscription, User

logger = logging.getLogger(__name__)


def enforce_non_billing_premium_accounts(db: Session) -> list[str]:
    if not NON_BILLING_PREMIUM_EMAILS:
        return []

    updated_accounts: list[str] = []
    now = datetime.now(timezone.utc)

    for email in NON_BILLING_PREMIUM_EMAILS:
        user = db.query(User).filter(User.email == email).first()
        if not user:
            logger.warning(
                "Non-billing premium account email not found in users table: %s",
                email,
            )
            continue

        user.is_premium = True
        if hasattr(user, "role"):
            user.role = "admin"

        subscription = (
            db.query(Subscription)
            .filter(Subscription.user_id == user.id)
            .order_by(Subscription.created_at.desc())
            .first()
        )

        if subscription is None:
            subscription = Subscription(
                id=uuid4(),
                user_id=user.id,
                plan="Premium",
                plan_type="Premium",
                status="active",
                trial_started_at=None,
                trial_ends_at=None,
                renewal_date=None,
                created_at=now,
                updated_at=now,
            )
            db.add(subscription)
        else:
            subscription.plan = "Premium"
            subscription.plan_type = "Premium"
            subscription.status = "active"
            subscription.trial_started_at = None
            subscription.trial_ends_at = None
            subscription.renewal_date = None
            subscription.updated_at = now

        updated_accounts.append(email)

    db.commit()
    return updated_accounts
