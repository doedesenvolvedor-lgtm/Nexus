import shutil
from datetime import datetime, timezone, timedelta
from pathlib import Path
from uuid import uuid4

from fastapi import APIRouter, Depends, File, HTTPException, UploadFile
from sqlalchemy.orm import Session
from sqlalchemy import and_, func

from app.database import get_db
from app.models import MediaContent, Payment, PlaybackHistory, Profile, User, Subscription
from app.schemas import AdminEmailAnnouncementRequest
from app.security_admin import get_admin_user
from app.services.email_service import get_email_service
from workers.transcoder import process_video

router = APIRouter(tags=["Admin"], dependencies=[Depends(get_admin_user)])

UPLOAD_DIR = Path("uploads")
UPLOAD_DIR.mkdir(exist_ok=True)


@router.get("/dashboard")
def dashboard(db: Session = Depends(get_db)):
    users = db.query(User).count()
    premium = db.query(User).filter(User.is_premium.is_(True)).count()
    profiles = db.query(Profile).count()
    media = db.query(MediaContent).count()
    watched = db.query(PlaybackHistory).count()

    return {
        "users": users,
        "premium_users": premium,
        "profiles": profiles,
        "catalog": media,
        "playbacks": watched,
    }


@router.get("/analytics")
def analytics(db: Session = Depends(get_db)):
    total = db.query(User).count()
    premium = db.query(User).filter(User.is_premium.is_(True)).count()
    movies = db.query(MediaContent).filter(MediaContent.content_type == "movie").count()
    series = db.query(MediaContent).filter(MediaContent.content_type == "series").count()

    return {
        "subscribers": total,
        "premium": premium,
        "movies": movies,
        "series": series,
        "premium_rate": round(premium / total * 100, 2) if total else 0,
    }


@router.get("/revenue")
def revenue(db: Session = Depends(get_db)):
    payments = db.query(Payment).all()
    total = sum(payment.amount for payment in payments if payment.status == "approved")

    return {
        "total_revenue": total,
        "payments": len(payments),
    }


@router.get("/users")
def users(db: Session = Depends(get_db)):
    return db.query(User).all()


@router.put("/users/{user_id}/premium")
def premium(user_id: str, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="Usuário não encontrado.")

    user.is_premium = True
    db.commit()
    return {"message": "Usuário Premium."}


@router.delete("/users/{user_id}")
def delete_user(user_id: str, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="Usuário não encontrado.")

    db.delete(user)
    db.commit()
    return {"message": "Usuário removido."}


@router.post("/announcements/email")
def send_announcement_email(
    payload: AdminEmailAnnouncementRequest,
    db: Session = Depends(get_db),
):
    recipients = [
        email
        for (email,) in db.query(User.email)
        .filter(User.email.isnot(None))
        .all()
    ]

    if not recipients:
        return {"message": "Nenhum usuário com e-mail cadastrado.", "sent": 0}

    email_service = get_email_service()
    sent = 0
    for recipient in recipients:
        if email_service.send_admin_announcement_email(
            to_email=recipient,
            title=payload.title,
            message=payload.message,
        ):
            sent += 1

    return {
        "message": "Comunicado processado.",
        "sent": sent,
        "total": len(recipients),
    }


@router.get("/catalog")
def catalog(db: Session = Depends(get_db)):
    return db.query(MediaContent).all()


@router.delete("/catalog/{media_id}")
def delete_media(media_id: str, db: Session = Depends(get_db)):
    media = db.query(MediaContent).filter(MediaContent.id == media_id).first()
    if not media:
        raise HTTPException(status_code=404, detail="Conteúdo não encontrado.")

    db.delete(media)
    db.commit()
    return {"message": "Conteúdo removido."}


@router.post("/upload")
async def upload_video(file: UploadFile = File(...), db: Session = Depends(get_db)):
    path = UPLOAD_DIR / f"{uuid4()}_{file.filename}"
    with path.open("wb") as buffer:
        shutil.copyfileobj(file.file, buffer)

    output_folder = Path("storage/streams") / str(uuid4())
    master = process_video(str(path), str(output_folder))

    media = MediaContent(
        title=file.filename,
        description="Upload via admin",
        content_type="movie",
        thumbnail_url="",
        video_url=master.replace("\\", "/"),
    )
    db.add(media)
    db.commit()
    db.refresh(media)

    return {
        "filename": file.filename,
        "path": str(path),
        "stream": master.replace("\\", "/"),
        "media_id": str(media.id),
        "status": "uploaded_and_transcoded",
    }


# ==================== ENDPOINTS DE TRIAL ====================


@router.get("/trials")
def get_trials(
    skip: int = 0,
    limit: int = 100,
    status: str = None,
    db: Session = Depends(get_db),
):
    """
    Listar usuários em trial.
    
    Query params:
    - skip: Pular N registros
    - limit: Limitar a N registros
    - status: Filtrar por status (active, expired, converted)
    """
    query = db.query(User, Subscription).join(
        Subscription, User.id == Subscription.user_id
    ).filter(Subscription.plan_type == "Trial")

    if status == "active":
        query = query.filter(
            and_(
                Subscription.trial_ends_at > datetime.now(timezone.utc),
                Subscription.status == "active",
            )
        )
    elif status == "expired":
        query = query.filter(
            and_(
                Subscription.trial_ends_at <= datetime.now(timezone.utc),
                Subscription.status == "expired",
            )
        )

    total = query.count()
    trials = query.order_by(Subscription.trial_started_at.desc()).offset(skip).limit(limit).all()

    result = []
    for user, subscription in trials:
        days_remaining = 0
        if subscription.trial_ends_at:
            now = datetime.now(timezone.utc)
            trial_ends = subscription.trial_ends_at.replace(tzinfo=timezone.utc)
            delta = trial_ends - now
            days_remaining = max(0, delta.days + (1 if delta.seconds > 0 else 0))

        result.append({
            "user_id": str(user.id),
            "email": user.email,
            "username": user.username,
            "created_at": user.created_at,
            "trial_started_at": subscription.trial_started_at,
            "trial_ends_at": subscription.trial_ends_at,
            "days_remaining": days_remaining,
            "status": subscription.status,
            "plan": subscription.plan,
        })

    return {
        "total": total,
        "skip": skip,
        "limit": limit,
        "data": result,
    }


@router.get("/trials/{user_id}")
def get_trial_details(user_id: str, db: Session = Depends(get_db)):
    """Obter detalhes do trial de um usuário específico."""
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="Usuário não encontrado.")

    subscription = (
        db.query(Subscription)
        .filter(Subscription.user_id == user_id)
        .order_by(Subscription.created_at.desc())
        .first()
    )

    if not subscription:
        raise HTTPException(status_code=404, detail="Subscription não encontrada.")

    days_remaining = 0
    if subscription.trial_ends_at:
        now = datetime.now(timezone.utc)
        trial_ends = subscription.trial_ends_at.replace(tzinfo=timezone.utc)
        delta = trial_ends - now
        days_remaining = max(0, delta.days + (1 if delta.seconds > 0 else 0))

    profiles_count = db.query(Profile).filter(Profile.user_id == user_id).count()
    playback_count = db.query(PlaybackHistory).join(
        Profile, PlaybackHistory.profile_id == Profile.id
    ).filter(Profile.user_id == user_id).count()

    return {
        "user": {
            "id": str(user.id),
            "email": user.email,
            "username": user.username,
            "created_at": user.created_at,
        },
        "subscription": {
            "id": str(subscription.id),
            "plan": subscription.plan,
            "plan_type": subscription.plan_type,
            "status": subscription.status,
            "trial_started_at": subscription.trial_started_at,
            "trial_ends_at": subscription.trial_ends_at,
            "days_remaining": days_remaining,
            "created_at": subscription.created_at,
            "updated_at": subscription.updated_at,
        },
        "activity": {
            "profiles_count": profiles_count,
            "playback_count": playback_count,
        },
    }


@router.get("/trials/analytics/summary")
def get_trials_analytics(db: Session = Depends(get_db)):
    """Estatísticas gerais de trials."""
    now = datetime.now(timezone.utc)

    # Total de usuários
    total_users = db.query(User).count()

    # Usuários em trial ativo
    active_trials = db.query(Subscription).filter(
        and_(
            Subscription.plan_type == "Trial",
            Subscription.trial_ends_at > now,
            Subscription.status == "active",
        )
    ).count()

    # Trials expirados
    expired_trials = db.query(Subscription).filter(
        and_(
            Subscription.plan_type == "Trial",
            Subscription.trial_ends_at <= now,
        )
    ).count()

    # Conversão de trial para pago
    converted_trials = db.query(Subscription).filter(
        Subscription.plan_type == "Premium",
    ).count()

    # Taxa de conversão
    total_trials = active_trials + expired_trials + converted_trials
    conversion_rate = (
        round(converted_trials / total_trials * 100, 2) if total_trials > 0 else 0
    )

    # Distribuição de planos
    plan_distribution = db.query(
        Subscription.plan_type,
        func.count(Subscription.id).label("count")
    ).group_by(Subscription.plan_type).all()

    return {
        "total_users": total_users,
        "active_trials": active_trials,
        "expired_trials": expired_trials,
        "converted_to_premium": converted_trials,
        "total_trials": total_trials,
        "conversion_rate": conversion_rate,
        "plan_distribution": {
            plan_type: count for plan_type, count in plan_distribution
        },
    }


@router.post("/trials/{user_id}/extend")
def extend_trial(user_id: str, days: int = 3, db: Session = Depends(get_db)):
    """Estender o trial de um usuário."""
    subscription = (
        db.query(Subscription)
        .filter(Subscription.user_id == user_id)
        .order_by(Subscription.created_at.desc())
        .first()
    )

    if not subscription:
        raise HTTPException(status_code=404, detail="Subscription não encontrada.")

    if subscription.plan_type != "Trial":
        raise HTTPException(status_code=400, detail="Usuário não está em trial.")

    # Estender a partir do current trial_ends_at ou de agora
    base_date = subscription.trial_ends_at or datetime.now(timezone.utc)
    subscription.trial_ends_at = base_date + timedelta(days=days)
    subscription.updated_at = datetime.now(timezone.utc)

    db.commit()
    db.refresh(subscription)

    return {
        "message": f"Trial estendido por {days} dias.",
        "trial_ends_at": subscription.trial_ends_at,
    }


@router.post("/trials/{user_id}/cancel")
def cancel_trial(user_id: str, db: Session = Depends(get_db)):
    """Cancelar trial de um usuário."""
    subscription = (
        db.query(Subscription)
        .filter(Subscription.user_id == user_id)
        .order_by(Subscription.created_at.desc())
        .first()
    )

    if not subscription:
        raise HTTPException(status_code=404, detail="Subscription não encontrada.")

    subscription.plan = "Free"
    subscription.plan_type = "Free"
    subscription.status = "cancelled"
    subscription.trial_started_at = None
    subscription.trial_ends_at = None
    subscription.updated_at = datetime.now(timezone.utc)

    db.commit()
    db.refresh(subscription)

    return {
        "message": "Trial cancelado.",
        "new_plan": "Free",
    }
