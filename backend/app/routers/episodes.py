from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import Episode, Season
from app.schemas import EpisodeCreate, EpisodeResponse, SeasonCreate, SeasonResponse

router = APIRouter(tags=["Episódios"])


@router.post("/seasons", response_model=SeasonResponse)
def create_season(season: SeasonCreate, db: Session = Depends(get_db)):
    obj = Season(**season.model_dump())
    db.add(obj)
    db.commit()
    db.refresh(obj)
    return obj


@router.get("/seasons/{media_id}", response_model=list[SeasonResponse])
def seasons(media_id: str, db: Session = Depends(get_db)):
    return db.query(Season).filter(Season.media_id == media_id).all()


@router.post("/episodes", response_model=EpisodeResponse)
def create_episode(episode: EpisodeCreate, db: Session = Depends(get_db)):
    obj = Episode(**episode.model_dump())
    db.add(obj)
    db.commit()
    db.refresh(obj)
    return obj


@router.get("/episodes/{season_id}", response_model=list[EpisodeResponse])
def episodes(season_id: str, db: Session = Depends(get_db)):
    return db.query(Episode).filter(Episode.season_id == season_id).all()
