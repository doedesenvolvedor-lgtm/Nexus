from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import PlaybackHistory

router = APIRouter(tags=["Histórico"])


@router.post("/")
def create_history_entry(profile_id: str, media_id: str, db: Session = Depends(get_db)):
    history_entry = PlaybackHistory(
        profile_id=profile_id,
        media_id=media_id,
    )
    db.add(history_entry)
    db.commit()
    db.refresh(history_entry)
    return history_entry


@router.get("/", response_model=list[dict])
def list_history(db: Session = Depends(get_db)):
    return db.query(PlaybackHistory).all()


@router.get("/{history_id}")
def get_history_entry(history_id: str, db: Session = Depends(get_db)):
    entry = db.query(PlaybackHistory).filter(PlaybackHistory.id == history_id).first()
    if not entry:
        raise HTTPException(status_code=404, detail="Registro não encontrado.")
    return entry
