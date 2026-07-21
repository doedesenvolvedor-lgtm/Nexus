from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.database import get_db
from app.dependencies import get_current_user
from app.models import MediaContent, User
from app.security_admin import get_admin_user
from app.schemas import MediaCreate, MediaResponse
from app.services.cache_service import build_cache_key, delete_by_prefix, get_json, set_json
from app.services.media_service import get_catalog, search
from app.services.stream_token_service import create_stream_token, create_playlist_token

router = APIRouter(tags=["Media"])


def _serialize_media(media: MediaContent) -> dict:
    return MediaResponse.model_validate(media).model_dump(mode="json")


@router.post("/", response_model=MediaResponse)
def create_movie(
    movie: MediaCreate,
    db: Session = Depends(get_db),
    _: User = Depends(get_admin_user),
):
    payload = movie.model_dump()
    payload["ai_emotions_tags"] = ",".join(payload.get("ai_emotions_tags", [])) or None
    media = MediaContent(**payload)
    db.add(media)
    db.commit()
    db.refresh(media)
    delete_by_prefix("media:")
    delete_by_prefix("recommendations:")
    return media


@router.get("/", response_model=list[MediaResponse])
def catalog(db: Session = Depends(get_db)):
    cache_key = "media:catalog"
    cached = get_json(cache_key)
    if cached is not None:
        return cached

    data = get_catalog(db)
    payload = [_serialize_media(item) for item in data]
    set_json(cache_key, payload, ttl_seconds=120)
    return payload


@router.get("/movies", response_model=list[MediaResponse])
def movies(db: Session = Depends(get_db)):
    cache_key = "media:movies"
    cached = get_json(cache_key)
    if cached is not None:
        return cached

    data = db.query(MediaContent).filter(MediaContent.content_type == "movie").all()
    payload = [_serialize_media(item) for item in data]
    set_json(cache_key, payload, ttl_seconds=120)
    return payload


@router.get("/series", response_model=list[MediaResponse])
def series(db: Session = Depends(get_db)):
    cache_key = "media:series"
    cached = get_json(cache_key)
    if cached is not None:
        return cached

    data = db.query(MediaContent).filter(MediaContent.content_type == "series").all()
    payload = [_serialize_media(item) for item in data]
    set_json(cache_key, payload, ttl_seconds=120)
    return payload


@router.get("/search", response_model=list[MediaResponse])
def search_media(q: str, db: Session = Depends(get_db)):
    normalized = q.strip().lower()
    cache_key = build_cache_key("media:search", q=normalized)
    cached = get_json(cache_key)
    if cached is not None:
        return cached

    data = search(db, normalized)
    payload = [_serialize_media(item) for item in data]
    set_json(cache_key, payload, ttl_seconds=60)
    return payload


@router.get("/genre/{genre}", response_model=list[MediaResponse])
def genre(genre: str, db: Session = Depends(get_db)):
    normalized = genre.strip().lower()
    cache_key = build_cache_key("media:genre", genre=normalized)
    cached = get_json(cache_key)
    if cached is not None:
        return cached

    data = db.query(MediaContent).filter(MediaContent.genre.ilike(f"%{normalized}%")).all()
    payload = [_serialize_media(item) for item in data]
    set_json(cache_key, payload, ttl_seconds=120)
    return payload


@router.get("/ai-search", response_model=list[MediaResponse])
def ai(emotion: str, db: Session = Depends(get_db)):
    normalized = emotion.strip().lower()
    cache_key = build_cache_key("media:ai-search", emotion=normalized)
    cached = get_json(cache_key)
    if cached is not None:
        return cached

    data = db.query(MediaContent).filter(MediaContent.ai_emotions_tags.ilike(f"%{normalized}%")).all()
    payload = [_serialize_media(item) for item in data]
    set_json(cache_key, payload, ttl_seconds=60)
    return payload


@router.get("/{id}", response_model=MediaResponse)
def details(id: str, db: Session = Depends(get_db)):
    cache_key = build_cache_key("media:details", id=id)
    cached = get_json(cache_key)
    if cached is not None:
        return cached

    media = db.query(MediaContent).filter(MediaContent.id == id).first()
    if media is None:
        raise HTTPException(status_code=404, detail="Conteúdo não encontrado.")
    payload = _serialize_media(media)
    set_json(cache_key, payload, ttl_seconds=300)
    return payload


@router.get("/{id}/stream-token")
def get_stream_token(
    id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Gera um token JWT para streaming de vídeo.
    Token com expiração de 60 minutos, vinculado ao usuário e mídia específica.
    
    O token deve ser passado na URL: /streams/uuid/master.m3u8?token=<token>
    """
    media = db.query(MediaContent).filter(MediaContent.id == id).first()
    if media is None:
        raise HTTPException(status_code=404, detail="Vídeo não encontrado.")
    
    # Gerar token com expiração de 60 minutos
    token = create_stream_token(
        media_id=id,
        user_id=current_user.id,
        expires_in_minutes=60,
    )
    
    return {
        "token": token,
        "media_id": id,
        "expires_in": 3600,  # segundos
        "token_type": "Bearer",
    }


@router.get("/{id}/play")
def play(
    id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Retorna informações de streaming com token JWT.
    
    Resposta inclui:
    - stream: URL master.m3u8 com token
    - token: JWT para usar em requisições de playlist
    - expires_in: Tempo de expiração em segundos
    """
    media = db.query(MediaContent).filter(MediaContent.id == id).first()
    if media is None:
        raise HTTPException(status_code=404, detail="Vídeo não encontrado.")
    
    # Gerar token de streaming
    stream_token = create_stream_token(
        media_id=id,
        user_id=current_user.id,
        expires_in_minutes=60,
    )
    
    # Extrair caminho da playlist do video_url
    # Ex: /streams/uuid/master.m3u8 → uuid/master.m3u8
    playlist_path = media.video_url.replace("/streams/", "") if media.video_url else ""
    
    # Criar token específico para playlist
    playlist_token = create_playlist_token(
        playlist_path=playlist_path,
        user_id=current_user.id,
        expires_in_minutes=60,
    ) if playlist_path else stream_token
    
    return {
        "title": media.title,
        "stream": f"{media.video_url}?token={playlist_token}",
        "token": playlist_token,
        "thumbnail": media.thumbnail_url,
        "banner": media.banner_url,
        "expires_in": 3600,  # segundos
    }
