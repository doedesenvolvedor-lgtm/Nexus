from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import MediaContent
from app.schemas import MediaCreate, MediaResponse
from app.services.cache_service import build_cache_key, delete_by_prefix, get_json, set_json
from app.services.media_service import get_catalog, search

router = APIRouter(tags=["Media"])


@router.post("/", response_model=MediaResponse)
def create_movie(movie: MediaCreate, db: Session = Depends(get_db)):
    media = MediaContent(**movie.model_dump())
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
    payload = [MediaResponse.model_validate(item).model_dump(mode="json") for item in data]
    set_json(cache_key, payload, ttl_seconds=120)
    return payload


@router.get("/movies", response_model=list[MediaResponse])
def movies(db: Session = Depends(get_db)):
    cache_key = "media:movies"
    cached = get_json(cache_key)
    if cached is not None:
        return cached

    data = db.query(MediaContent).filter(MediaContent.content_type == "movie").all()
    payload = [MediaResponse.model_validate(item).model_dump(mode="json") for item in data]
    set_json(cache_key, payload, ttl_seconds=120)
    return payload


@router.get("/series", response_model=list[MediaResponse])
def series(db: Session = Depends(get_db)):
    cache_key = "media:series"
    cached = get_json(cache_key)
    if cached is not None:
        return cached

    data = db.query(MediaContent).filter(MediaContent.content_type == "series").all()
    payload = [MediaResponse.model_validate(item).model_dump(mode="json") for item in data]
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
    payload = [MediaResponse.model_validate(item).model_dump(mode="json") for item in data]
    set_json(cache_key, payload, ttl_seconds=60)
    return payload


@router.get("/genre/{genre}", response_model=list[MediaResponse])
def genre(genre: str, db: Session = Depends(get_db)):
    normalized = genre.strip().lower()
    cache_key = build_cache_key("media:genre", genre=normalized)
    cached = get_json(cache_key)
    if cached is not None:
        return cached

    data = db.query(MediaContent).filter(MediaContent.genre.ilike(normalized)).all()
    payload = [MediaResponse.model_validate(item).model_dump(mode="json") for item in data]
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
    payload = [MediaResponse.model_validate(item).model_dump(mode="json") for item in data]
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
    payload = MediaResponse.model_validate(media).model_dump(mode="json")
    set_json(cache_key, payload, ttl_seconds=300)
    return payload


@router.get("/{id}/play")
def play(id: str, db: Session = Depends(get_db)):
    movie = db.query(MediaContent).filter(MediaContent.id == id).first()
    if movie is None:
        raise HTTPException(status_code=404, detail="Vídeo não encontrado.")

    return {
        "title": movie.title,
        "stream": movie.video_url,
        "thumbnail": movie.thumbnail_url,
        "banner": movie.banner_url,
    }
