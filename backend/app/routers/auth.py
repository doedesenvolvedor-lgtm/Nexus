from datetime import datetime, timedelta, timezone
import secrets
from uuid import uuid4

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.config import ACCESS_TOKEN_EXPIRE_MINUTES
from app.database import get_db
from app.dependencies import get_current_token_payload, get_current_user
from app.models import User, Subscription
from app.schemas import (
    ForgotPasswordRequest,
    Login,
    RefreshTokenRequest,
    ResetPasswordRequest,
    SubscriptionResponse,
    Token,
    UserCreate,
    UserResponse,
)
from app.security import create_access_token, create_refresh_token, decode_token, hash_password, verify_password
from app.services.auth_session_service import (
    clear_login_failures,
    is_login_locked,
    register_failed_login,
    register_session,
    revoke_session,
)
from app.services.cache_service import delete_key, get_json, set_json
from app.services.email_service import get_email_service

router = APIRouter(tags=["Autenticação"])

PASSWORD_RESET_TTL_SECONDS = 30 * 60


def _reset_token_key(token: str) -> str:
    return f"auth:password_reset:{token}"


@router.post("/register", response_model=UserResponse)
def register(user: UserCreate, db: Session = Depends(get_db)):
    exists = db.query(User).filter(User.email == user.email).first()
    if exists:
        raise HTTPException(status_code=400, detail="Email já cadastrado.")

    new_user = User(
        email=user.email,
        username=user.username,
        hashed_password=hash_password(user.password),
    )

    db.add(new_user)
    db.flush()

    # Criar subscription com 3 dias de trial
    trial_started_at = datetime.now(timezone.utc)
    trial_ends_at = trial_started_at + timedelta(days=3)
    
    subscription = Subscription(
        user_id=new_user.id,
        plan="Trial",
        plan_type="Trial",
        status="active",
        trial_started_at=trial_started_at,
        trial_ends_at=trial_ends_at,
    )
    
    db.add(subscription)
    db.commit()
    db.refresh(new_user)

    email_service = get_email_service()
    email_service.send_welcome_email(
        to_email=new_user.email,
        username=new_user.username,
    )

    return new_user


@router.post("/login", response_model=Token)
def login(credentials: Login, db: Session = Depends(get_db)):
    is_locked, lock_ttl = is_login_locked(credentials.email)
    if is_locked:
        raise HTTPException(
            status_code=429,
            detail=f"Muitas tentativas inválidas. Tente novamente em {lock_ttl}s.",
        )

    user = db.query(User).filter(User.email == credentials.email).first()

    if not user or not verify_password(credentials.password, user.hashed_password):
        locked_now, lock_ttl = register_failed_login(credentials.email)
        if locked_now:
            raise HTTPException(
                status_code=429,
                detail=f"Muitas tentativas inválidas. Tente novamente em {lock_ttl}s.",
            )
        raise HTTPException(status_code=401, detail="Credenciais inválidas.")

    clear_login_failures(credentials.email)
    jti = str(uuid4())
    token = create_access_token({"sub": str(user.id), "email": user.email})
    refresh_token = create_refresh_token({"sub": str(user.id), "email": user.email})
    register_session(
        user_id=str(user.id),
        jti=jti,
        ttl_seconds=ACCESS_TOKEN_EXPIRE_MINUTES * 60,
    )

    return {
        "access_token": token,
        "refresh_token": refresh_token,
        "token_type": "bearer",
    }


@router.post("/refresh", response_model=Token)
def refresh_token(request: RefreshTokenRequest, db: Session = Depends(get_db)):
    """Gera um novo access token usando refresh token."""
    try:
        payload = decode_token(request.refresh_token)
        if payload.get("type") != "refresh":
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Token de refresh inválido.",
            )
        
        user_id = payload.get("sub")
        user = db.query(User).filter(User.id == user_id).first()
        if not user:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Usuário não encontrado.",
            )

        # Revogar sessão antiga
        old_jti = payload.get("jti")
        if old_jti:
            revoke_session(str(user.id), str(old_jti))

        # Criar novos tokens
        jti = str(uuid4())
        new_access_token = create_access_token({"sub": str(user.id), "email": user.email})
        new_refresh_token = create_refresh_token({"sub": str(user.id), "email": user.email})
        register_session(
            user_id=str(user.id),
            jti=jti,
            ttl_seconds=ACCESS_TOKEN_EXPIRE_MINUTES * 60,
        )

        return {
            "access_token": new_access_token,
            "refresh_token": new_refresh_token,
            "token_type": "bearer",
        }
    except HTTPException:
        raise
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token de refresh inválido ou expirado.",
        )


@router.post("/logout")
def logout(payload=Depends(get_current_token_payload)):
    if payload is None:
        raise HTTPException(status_code=401, detail="Token inválido.")

    user_id = payload.get("sub")
    jti = payload.get("jti")
    if user_id and jti:
        revoke_session(str(user_id), str(jti))

    return {"message": "Sessão encerrada com sucesso."}


@router.post("/forgot-password")
def forgot_password(request: ForgotPasswordRequest, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.email == request.email).first()

    if user:
        token = secrets.token_urlsafe(32)
        set_json(
            _reset_token_key(token),
            {"user_id": str(user.id), "email": user.email},
            ttl_seconds=PASSWORD_RESET_TTL_SECONDS,
        )
        get_email_service().send_password_reset_email(
            to_email=user.email,
            reset_token=token,
        )

    return {
        "message": "Se o e-mail existir, você receberá as instruções para redefinição de senha."
    }


@router.post("/reset-password")
def reset_password(request: ResetPasswordRequest, db: Session = Depends(get_db)):
    token_key = _reset_token_key(request.token)
    payload = get_json(token_key)

    if not payload:
        raise HTTPException(status_code=400, detail="Token inválido ou expirado.")

    user = db.query(User).filter(User.id == payload.get("user_id")).first()
    if not user:
        raise HTTPException(status_code=404, detail="Usuário não encontrado.")

    user.hashed_password = hash_password(request.new_password)
    db.commit()
    delete_key(token_key)

    return {"message": "Senha redefinida com sucesso."}


@router.get("/me", response_model=UserResponse)
def me(current_user=Depends(get_current_user)):
    if current_user is None:
        raise HTTPException(status_code=401, detail="Token inválido.")

    return current_user


@router.get("/me/profile")
def me_profile(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Retorna usuário com informações de subscription e trial."""
    if current_user is None:
        raise HTTPException(status_code=401, detail="Token inválido.")

    subscription = (
        db.query(Subscription)
        .filter(Subscription.user_id == current_user.id)
        .order_by(Subscription.created_at.desc())
        .first()
    )

    return {
        "id": current_user.id,
        "email": current_user.email,
        "username": current_user.username,
        "is_premium": current_user.is_premium,
        "subscription": SubscriptionResponse.from_orm(subscription)
        if subscription
        else None,
    }
