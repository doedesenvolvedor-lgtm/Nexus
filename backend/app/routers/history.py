from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.database import get_db
from app.dependencies import get_current_user
from app.models import PlaybackHistory, Profile, User
from app.schemas import PlaybackHistoryCreate, PlaybackHistoryResponse

router = APIRouter(tags=["Histórico"])


def _get_owned_history(db: Session, history_id: str, user: User) -> PlaybackHistory:
    """Retorna um registro de histórico somente se pertence a um perfil do usuário."""
    entry = (
        db.query(PlaybackHistory)
        .join(Profile, PlaybackHistory.profile_id == Profile.id)
        .filter(PlaybackHistory.id == history_id, Profile.user_id == user.id)
        .first()
    )
    if not entry:
        raise HTTPException(status_code=404, detail="Registro não encontrado.")
    return entry


@router.post("/", response_model=PlaybackHistoryResponse, status_code=201)
def create_history_entry(
    item: PlaybackHistoryCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    # Garantir que o perfil pertence ao usuário autenticado
    profile = (
        db.query(Profile)
        .filter(Profile.id == item.profile_id, Profile.user_id == current_user.id)
        .first()
    )
    if not profile:
        raise HTTPException(status_code=404, detail="Perfil não encontrado.")

    history_entry = PlaybackHistory(**item.model_dump())
    db.add(history_entry)
    db.commit()
    db.refresh(history_entry)
    return history_entry


@router.get("/", response_model=list[PlaybackHistoryResponse])
def list_history(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return (
        db.query(PlaybackHistory)
        .join(Profile, PlaybackHistory.profile_id == Profile.id)
        .filter(Profile.user_id == current_user.id)
        .all()
    )


@router.get("/{history_id}", response_model=PlaybackHistoryResponse)
def get_history_entry(
    history_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return _get_owned_history(db, history_id, current_user)
