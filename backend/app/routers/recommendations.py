from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import MediaContent
from app.schemas import MediaResponse

router = APIRouter(tags=["Recomendações"])


@router.get("/recommended/{profile_id}", response_model=list[MediaResponse])
def recommendations(profile_id: str, db: Session = Depends(get_db)):
    return db.query(MediaContent).limit(20).all()
