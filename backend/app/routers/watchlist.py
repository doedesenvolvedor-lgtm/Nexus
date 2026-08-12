from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.database import get_db
from app.dependencies import get_current_user
from app.models import Profile, User, WatchList
from app.schemas import WatchListCreate, WatchListResponse

router = APIRouter(tags=["Watchlist"])


def _get_owned_watchlist_item(db: Session, item_id: str, user: User) -> WatchList:
    """Retorna um item da watchlist somente se pertence a um perfil do usuário."""
    obj = (
        db.query(WatchList)
        .join(Profile, WatchList.profile_id == Profile.id)
        .filter(WatchList.id == item_id, Profile.user_id == user.id)
        .first()
    )
    if not obj:
        raise HTTPException(status_code=404, detail="Item não encontrado.")
    return obj


@router.post("/", response_model=WatchListResponse)
def add_to_watchlist(
    item: WatchListCreate,
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

    obj = WatchList(**item.model_dump())
    db.add(obj)
    db.commit()
    db.refresh(obj)
    return obj


@router.get("/", response_model=list[WatchListResponse])
def list_watchlist(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return (
        db.query(WatchList)
        .join(Profile, WatchList.profile_id == Profile.id)
        .filter(Profile.user_id == current_user.id)
        .all()
    )


@router.delete("/{item_id}")
def remove_from_watchlist(
    item_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    obj = _get_owned_watchlist_item(db, item_id, current_user)
    db.delete(obj)
    db.commit()
    return {"detail": "Removido da watchlist"}
