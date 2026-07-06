from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import Profile, User
from app.schemas import ProfileCreate, ProfileResponse

router = APIRouter(tags=["Perfis"])


@router.post("/", response_model=ProfileResponse)
def create_profile(profile: ProfileCreate, db: Session = Depends(get_db)):
    new_profile = Profile(
        name=profile.name,
        avatar_url=profile.avatar_url,
        is_kids=profile.is_kids,
        pin_code=profile.pin_code,
        user_id="00000000-0000-0000-0000-000000000000",
    )
    db.add(new_profile)
    db.commit()
    db.refresh(new_profile)
    return new_profile


@router.get("/", response_model=list[ProfileResponse])
def list_profiles(db: Session = Depends(get_db)):
    return db.query(Profile).all()


@router.get("/{profile_id}", response_model=ProfileResponse)
def get_profile(profile_id: str, db: Session = Depends(get_db)):
    profile = db.query(Profile).filter(Profile.id == profile_id).first()
    if not profile:
        raise HTTPException(status_code=404, detail="Perfil não encontrado.")
    return profile
