from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import Rating
from app.schemas import RatingCreate, RatingResponse

router = APIRouter(tags=["Avaliações"])


@router.post("/", response_model=RatingResponse)
def rate(rating: RatingCreate, db: Session = Depends(get_db)):
    obj = Rating(**rating.model_dump())
    db.add(obj)
    db.commit()
    db.refresh(obj)
    return obj


@router.get("/{media_id}", response_model=list[RatingResponse])
def ratings(media_id: str, db: Session = Depends(get_db)):
    return db.query(Rating).filter(Rating.media_id == media_id).all()
