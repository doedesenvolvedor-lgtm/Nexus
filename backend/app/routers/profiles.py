from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.database import get_db
from app.dependencies import get_current_user
from app.models import Profile, User
from app.schemas import ProfileCreate, ProfileResponse

router = APIRouter(tags=["Perfis"])


def _get_owned_profile(db: Session, profile_id: str, user: User) -> Profile:
    """Retorna um perfil somente se pertence ao usuário autenticado."""
    profile = (
        db.query(Profile)
        .filter(Profile.id == profile_id, Profile.user_id == user.id)
        .first()
    )
    if not profile:
        raise HTTPException(status_code=404, detail="Perfil não encontrado.")
    return profile


@router.post("/", response_model=ProfileResponse)
def create_profile(
    profile: ProfileCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    new_profile = Profile(
        name=profile.name,
        avatar_url=profile.avatar_url,
        is_kids=profile.is_kids,
        pin_code=profile.pin_code,
        user_id=current_user.id,
    )
    db.add(new_profile)
    db.commit()
    db.refresh(new_profile)
    return new_profile


@router.get("/", response_model=list[ProfileResponse])
def list_profiles(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return (
        db.query(Profile)
        .filter(Profile.user_id == current_user.id)
        .all()
    )


@router.get("/{profile_id}", response_model=ProfileResponse)
def get_profile(
    profile_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return _get_owned_profile(db, profile_id, current_user)


@router.put("/{profile_id}", response_model=ProfileResponse)
def update_profile(
    profile_id: str,
    profile_update: ProfileCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    profile = _get_owned_profile(db, profile_id, current_user)
    profile.name = profile_update.name
    profile.avatar_url = profile_update.avatar_url
    profile.is_kids = profile_update.is_kids
    profile.pin_code = profile_update.pin_code
    db.commit()
    db.refresh(profile)
    return profile


@router.delete("/{profile_id}")
def delete_profile(
    profile_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    profile = _get_owned_profile(db, profile_id, current_user)
    db.delete(profile)
    db.commit()
    return {"message": "Perfil removido."}
