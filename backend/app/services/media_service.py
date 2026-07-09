from sqlalchemy.orm import Session

from app.models import MediaContent


def get_catalog(db: Session):
    return db.query(MediaContent).all()


def search(db: Session, text: str):
    return db.query(MediaContent).filter(MediaContent.title.ilike(f"%{text}%")).all()
