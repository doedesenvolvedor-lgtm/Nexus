from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import WatchList
from app.schemas import WatchListCreate, WatchListResponse

router = APIRouter(tags=["Watchlist"])


@router.post("/", response_model=WatchListResponse)
def add_to_watchlist(item: WatchListCreate, db: Session = Depends(get_db)):
    obj = WatchList(**item.model_dump())
    db.add(obj)
    db.commit()
    db.refresh(obj)
    return obj


@router.get("/", response_model=list[WatchListResponse])
def list_watchlist(db: Session = Depends(get_db)):
    return db.query(WatchList).all()


@router.delete("/{item_id}")
def remove_from_watchlist(item_id: str, db: Session = Depends(get_db)):
    obj = db.query(WatchList).filter(WatchList.id == item_id).first()
    if not obj:
        raise HTTPException(status_code=404, detail="Item não encontrado.")
    db.delete(obj)
    db.commit()
    return {"detail": "Removido da watchlist"}
