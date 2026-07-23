from datetime import datetime, timezone, timedelta
from pathlib import Path
from uuid import uuid4

import magic
from fastapi import APIRouter, Body, Depends, File, HTTPException, Query, UploadFile
from sqlalchemy.orm import Session
from sqlalchemy import and_, func

from app.database import get_db
from app.models import MediaContent, Payment, PlaybackHistory, Profile, User, Subscription
from app.schemas import AdminEmailAnnouncementRequest, AdminUserResponse, PaginatedAdminUsersResponse
from app.security_admin import get_admin_user
from app.services.email_service import get_email_service
from workers.transcoder import process_video

router = APIRouter(tags=["Admin"], dependencies=[Depends(get_admin_user)])

UPLOAD_DIR = Path("uploads")
UPLOAD_DIR.mkdir(exist_ok=True)
MAX_UPLOAD_BYTES = 2 * 1024 * 1024 * 1024  # 2GB
ALLOWED_UPLOAD_EXTENSIONS = {".mp4", ".mkv", ".mov", ".webm", ".avi"}
ALLOWED_MIME_TYPES = {
    "video/mp4",
    "video/x-matroska",
    "video/quicktime",
    "video/webm",
    "video/x-msvideo",
    "application/octet-stream",  # alguns MKV podem vir como octet-stream
}


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
    approved_payments = db.query(Payment).filter(Payment.status == "approved").all()
    total = sum(payment.amount for payment in approved_payments)

    return {
        "total_revenue": total,
        "payments": len(approved_payments),
    }


@router.get("/dashboard/stats")
def dashboard_stats(db: Session = Depends(get_db)):
    return dashboard(db)


@router.get("/users", response_model=PaginatedAdminUsersResponse)
def users(
    page: int = Query(default=1, ge=1),
    limit: int = Query(default=20, ge=1, le=100),
    search: str | None = Query(default=None, min_length=1),
    plan: str | None = Query(default=None),
    status: str | None = Query(default=None),
    db: Session = Depends(get_db),
):
    from sqlalchemy.orm import joinedload
    
    query = db.query(User).options(
        joinedload(User.subscriptions)
    ).order_by(User.created_at.desc())

    if search:
        normalized_search = f"%{search.strip().lower()}%"
        query = query.filter(
            func.lower(User.email).ilike(normalized_search)
            | func.lower(func.coalesce(User.username, "")).ilike(normalized_search)
        )

    user_rows = query.all()
    data: list[AdminUserResponse] = []

    for user in user_rows:
        # Subscription já carregada via joinedload
        latest_subscription = None
        if user.subscriptions:
            # subscriptions já ordenado, pegar o mais recente
            sorted_subs = sorted(user.subscriptions, key=lambda s: s.created_at, reverse=True)
            latest_subscription = sorted_subs[0] if sorted_subs else None

        plan_value = (latest_subscription.plan or "free") if latest_subscription else "free"
        status_value = (
            latest_subscription.status
            if latest_subscription and latest_subscription.status
            else ("active" if user.is_premium else "inactive")
        )

        if plan and plan_value.lower() != plan.lower():
            continue
        if status and status_value.lower() != status.lower():
            continue

        data.append(
            AdminUserResponse(
                id=user.id,
                email=user.email,
                username=user.username,
                is_premium=user.is_premium,
                role=user.role,
                created_at=user.created_at,
                plan=plan_value.lower(),
                status=status_value.lower(),
            )
        )

    start = (page - 1) * limit
    end = start + limit
    return {
        "data": data[start:end],
        "total": len(data),
        "page": page,
        "limit": limit,
    }


@router.get("/payments")
def list_payments(
    page: int = Query(default=1, ge=1),
    limit: int = Query(default=20, ge=1, le=100),
    status: str | None = Query(default=None),
    method: str | None = Query(default=None),
    db: Session = Depends(get_db),
):
    query = db.query(Payment, User).join(User, Payment.user_id == User.id).order_by(Payment.created_at.desc())

    if status:
        query = query.filter(Payment.status == status)
    if method:
        query = query.filter(Payment.provider == method)

    rows = query.all()
    start = (page - 1) * limit
    end = start + limit
    paginated_rows = rows[start:end]

    return {
        "data": [
            {
                "id": str(payment.id),
                "user_email": user.email,
                "amount": payment.amount,
                "method": payment.provider,
                "status": payment.status,
                "created_at": payment.created_at,
            }
            for payment, user in paginated_rows
        ],
        "total": len(rows),
        "page": page,
        "limit": limit,
    }


@router.get("/payments/stats")
def payment_stats(db: Session = Depends(get_db)):
    approved_amount = sum(
        payment.amount
        for payment in db.query(Payment).filter(Payment.status == "approved").all()
    )
    refunded_amount = sum(
        payment.amount
        for payment in db.query(Payment).filter(Payment.status == "refunded").all()
    )
    pending_count = db.query(Payment).filter(Payment.status == "pending").count()

    return {
        "total_revenue": approved_amount,
        "pending_count": pending_count,
        "refunded_amount": refunded_amount,
    }


@router.post("/payments/{payment_id}/refund")
def refund_payment(payment_id: str, db: Session = Depends(get_db)):
    payment = db.query(Payment).filter(Payment.id == payment_id).first()
    if not payment:
        raise HTTPException(status_code=404, detail="Pagamento não encontrado.")
    if payment.status != "approved":
        raise HTTPException(status_code=400, detail="Somente pagamentos aprovados podem ser reembolsados.")

    payment.status = "refunded"
    payment.updated_at = datetime.now(timezone.utc)
    db.commit()
    db.refresh(payment)

    return {
        "message": "Pagamento marcado como reembolsado.",
        "payment_id": str(payment.id),
        "status": payment.status,
    }

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



@router.post("/users/{user_id}/block")
def block_user(user_id: str, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="Usuário não encontrado.")

    subscription = (
        db.query(Subscription)
        .filter(Subscription.user_id == user_id)
        .order_by(Subscription.created_at.desc())
        .first()
    )
    if subscription:
        subscription.status = "blocked"
        subscription.updated_at = datetime.now(timezone.utc)
    db.commit()
    return {"message": "Usuário bloqueado."}


@router.post("/users/{user_id}/unblock")
def unblock_user(user_id: str, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="Usuário não encontrado.")

    subscription = (
        db.query(Subscription)
        .filter(Subscription.user_id == user_id)
        .order_by(Subscription.created_at.desc())
        .first()
    )
    if subscription:
        subscription.status = "active"
        subscription.updated_at = datetime.now(timezone.utc)
    db.commit()
    return {"message": "Usuário desbloqueado."}


@router.post("/users/{user_id}/plan")
def change_user_plan(
    user_id: str,
    payload: dict = Body(...),
    db: Session = Depends(get_db),
):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="Usuário não encontrado.")

    plan = str(payload.get("plan", "")).strip()
    if not plan:
        raise HTTPException(status_code=400, detail="Plano inválido.")

    subscription = (
        db.query(Subscription)
        .filter(Subscription.user_id == user_id)
        .order_by(Subscription.created_at.desc())
        .first()
    )
    if subscription:
        subscription.plan = plan
        subscription.updated_at = datetime.now(timezone.utc)
    db.commit()
    return {"message": f"Plano do usuário atualizado para {plan}."}


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
def catalog(
    page: int = Query(default=1, ge=1),
    limit: int = Query(default=50, ge=1, le=200),
    content_type: str | None = Query(default=None),
    db: Session = Depends(get_db),
):
    query = db.query(MediaContent).order_by(MediaContent.title)
    
    if content_type:
        query = query.filter(MediaContent.content_type == content_type)
    
    total = query.count()
    items = query.offset((page - 1) * limit).limit(limit).all()
    
    return {
        "data": items,
        "total": total,
        "page": page,
        "limit": limit,
    }


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
    original_name = Path(file.filename or "").name
    extension = Path(original_name).suffix.lower()
    if extension not in ALLOWED_UPLOAD_EXTENSIONS:
        raise HTTPException(status_code=400, detail="Formato de vídeo não permitido.")

    # Validar MIME type real do arquivo
    header_bytes = await file.read(2048)
    await file.seek(0)
    mime_type = magic.from_buffer(header_bytes, mime=True)
    if mime_type not in ALLOWED_MIME_TYPES:
        raise HTTPException(
            status_code=400,
            detail=f"Tipo de arquivo não permitido: {mime_type}",
        )

    path = UPLOAD_DIR / f"{uuid4()}_{original_name}"
    total_written = 0
    with path.open("wb") as buffer:
        while True:
            chunk = await file.read(1024 * 1024)
            if not chunk:
                break
            total_written += len(chunk)
            if total_written > MAX_UPLOAD_BYTES:
                path.unlink(missing_ok=True)
                raise HTTPException(status_code=413, detail="Arquivo excede limite máximo de 2GB.")
            buffer.write(chunk)
    await file.close()

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
