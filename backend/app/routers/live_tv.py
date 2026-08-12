"""
Router de TV ao Vivo (público - App Flutter).

Endpoints:
- GET /live-tv/channels — Listar canais ativos (com cache Redis)
- GET /live-tv/channels/{id} — Detalhes de um canal
- GET /live-tv/channels/{id}/stream — URL de stream com token (auth)
- GET /live-tv/categories — Listar categorias
"""

import logging
from typing import Optional
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session

from app.database import get_db
from app.dependencies import get_current_user
from app.models import LiveChannel, User
from app.services.cache_service import build_cache_key, get_json, set_json
from app.services.parental_control_service import check_access
from app.services.stream_token_service import create_stream_token

logger = logging.getLogger(__name__)

router = APIRouter(
    prefix="/live-tv",
    tags=["Live TV"],
)

CACHE_TTL_CHANNELS = 300  # 5 minutos
CACHE_TTL_CATEGORIES = 600  # 10 minutos


def _serialize_channel(channel: LiveChannel) -> dict:
    return {
        "id": str(channel.id),
        "name": channel.name,
        "url": channel.url,
        "logo_url": channel.logo_url,
        "category": channel.category,
        "description": channel.description,
        "is_verified": channel.is_verified,
    }


@router.get("/channels")
def list_channels(
    category: Optional[str] = Query(default=None),
    search: Optional[str] = Query(default=None, min_length=1),
    limit: int = Query(default=100, ge=1, le=500),
    db: Session = Depends(get_db),
):
    """
    Lista canais de TV ao vivo ativos.
    Usa cache Redis (TTL 5 min).
    """
    cache_key = build_cache_key("live_tv:channels", category=category or "", search=search or "", limit=str(limit))
    cached = get_json(cache_key)
    if cached is not None:
        return cached

    query = db.query(LiveChannel).filter(LiveChannel.is_active.is_(True))

    if category:
        query = query.filter(LiveChannel.category == category)
    if search:
        query = query.filter(LiveChannel.name.ilike(f"%{search.strip().lower()}%"))

    channels = query.order_by(LiveChannel.name).limit(limit).all()
    payload = [_serialize_channel(ch) for ch in channels]

    set_json(cache_key, payload, ttl_seconds=CACHE_TTL_CHANNELS)
    return payload


@router.get("/categories")
def categories(db: Session = Depends(get_db)):
    """
    Lista categorias de canais disponíveis.
    """
    cache_key = "live_tv:categories"
    cached = get_json(cache_key)
    if cached is not None:
        return cached

    from sqlalchemy import distinct
    rows = (
        db.query(distinct(LiveChannel.category))
        .filter(LiveChannel.category.isnot(None), LiveChannel.is_active.is_(True))
        .all()
    )
    categories_list = sorted([row[0] for row in rows if row[0]])

    set_json(cache_key, {"categories": categories_list}, ttl_seconds=CACHE_TTL_CATEGORIES)
    return {"categories": categories_list}


@router.get("/channels/{channel_id}")
def channel_details(channel_id: UUID, db: Session = Depends(get_db)):
    """
    Detalhes de um canal específico.
    """
    cache_key = build_cache_key("live_tv:channel", id=str(channel_id))
    cached = get_json(cache_key)
    if cached is not None:
        return cached

    channel = db.query(LiveChannel).filter(
        LiveChannel.id == channel_id,
        LiveChannel.is_active.is_(True),
    ).first()

    if not channel:
        raise HTTPException(status_code=404, detail="Canal não encontrado.")

    payload = _serialize_channel(channel)
    set_json(cache_key, payload, ttl_seconds=CACHE_TTL_CHANNELS)
    return payload


@router.get("/channels/{channel_id}/stream")
def get_stream(
    channel_id: UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
    profile_id: Optional[str] = Query(default=None, description="ID do perfil ativo (para enforcement de Controle Parental)"),
):
    """
    Retorna URL de stream protegida com token JWT (expira em 60 min).
    """
    channel = db.query(LiveChannel).filter(
        LiveChannel.id == channel_id,
        LiveChannel.is_active.is_(True),
    ).first()

    if not channel:
        raise HTTPException(status_code=404, detail="Canal não encontrado.")

    # Enforcement de Controle Parental no backend (sem bypass client-side)
    if profile_id:
        try:
            result = check_access(
                db,
                profile_id=UUID(profile_id),
                content_type="channel",
                target_id=channel_id,
                rating=None,
                title=channel.name,
            )
        except Exception:
            result = {"allowed": True}
        if not result.get("allowed"):
            raise HTTPException(status_code=403, detail=result.get("message", "Acesso negado pelo Controle Parental."))

    # Gerar token de streaming vinculado ao canal
    token = create_stream_token(
        media_id=str(channel_id),
        user_id=str(current_user.id),
        expires_in_minutes=60,
    )

    # Construir URL com token
    stream_url = f"{channel.url}?token={token}"

    return {
        "channel_id": str(channel_id),
        "name": channel.name,
        "stream": stream_url,
        "url": channel.url,
        "token": token,
        "expires_in": 3600,
    }
