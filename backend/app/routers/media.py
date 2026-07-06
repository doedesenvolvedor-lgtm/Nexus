from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import MediaContent
from app.schemas import MediaCreate, MediaResponse
from app.services.media_service import get_catalog, search

router = APIRouter(tags=["Media"])


@router.post("/", response_model=MediaResponse)
def create_movie(movie: MediaCreate, db: Session = Depends(get_db)):
    media = MediaContent(**movie.model_dump())
    db.add(media)
    db.commit()
    db.refresh(media)
    return media


@router.get("/", response_model=list[MediaResponse])
def catalog(db: Session = Depends(get_db)):
    return get_catalog(db)


@router.get("/movies", response_model=list[MediaResponse])
def movies(db: Session = Depends(get_db)):
    return db.query(MediaContent).filter(MediaContent.content_type == "movie").all()


@router.get("/series", response_model=list[MediaResponse])
def series(db: Session = Depends(get_db)):
    return db.query(MediaContent).filter(MediaContent.content_type == "series").all()


@router.get("/search", response_model=list[MediaResponse])
def search_media(q: str, db: Session = Depends(get_db)):
    return search(db, q)


@router.get("/genre/{genre}", response_model=list[MediaResponse])
def genre(genre: str, db: Session = Depends(get_db)):
    return db.query(MediaContent).filter(MediaContent.genre == genre).all()


@router.get("/ai-search", response_model=list[MediaResponse])
def ai(emotion: str, db: Session = Depends(get_db)):
    return db.query(MediaContent).filter(MediaContent.ai_emotions_tags.ilike(f"%{emotion.lower()}%")) .all()


@router.get("/{id}", response_model=MediaResponse)
def details(id: str, db: Session = Depends(get_db)):
    media = db.query(MediaContent).filter(MediaContent.id == id).first()
    if media is None:
        raise HTTPException(status_code=404, detail="Conteúdo não encontrado.")
    return media


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
