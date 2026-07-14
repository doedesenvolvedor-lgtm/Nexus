from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import MediaContent
from app.schemas import MediaResponse
from app.services.cache_service import build_cache_key, get_json, set_json

router = APIRouter(tags=["Recomendações"])


@router.get("/recommended/{profile_id}", response_model=list[MediaResponse])
def recommendations(profile_id: str, db: Session = Depends(get_db)):
    cache_key = build_cache_key("recommendations:profile", profile_id=profile_id)
    cached = get_json(cache_key)
    if cached is not None:
        return cached

    data = db.query(MediaContent).limit(20).all()
    payload = [MediaResponse.model_validate(item).model_dump(mode="json") for item in data]
    set_json(cache_key, payload, ttl_seconds=90)
    return payload
