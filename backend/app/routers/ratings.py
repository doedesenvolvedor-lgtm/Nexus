from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.database import get_db
from app.dependencies import get_current_user
from app.models import Profile, Rating, User
from app.schemas import RatingCreate, RatingResponse

router = APIRouter(tags=["Avaliações"])


@router.post("/", response_model=RatingResponse)
def rate(
    rating: RatingCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    # Garantir que o perfil pertence ao usuário autenticado
    profile = (
        db.query(Profile)
        .filter(Profile.id == rating.profile_id, Profile.user_id == current_user.id)
        .first()
    )
    if not profile:
        raise HTTPException(status_code=404, detail="Perfil não encontrado.")

    obj = Rating(**rating.model_dump())
    db.add(obj)
    db.commit()
    db.refresh(obj)
    return obj


@router.get("/{media_id}", response_model=list[RatingResponse])
def ratings(media_id: str, db: Session = Depends(get_db)):
    return db.query(Rating).filter(Rating.media_id == media_id).all()
