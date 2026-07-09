import shutil
from pathlib import Path
from uuid import uuid4

from fastapi import APIRouter, Depends, File, HTTPException, UploadFile
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import MediaContent, Payment, PlaybackHistory, Profile, User
from workers.transcoder import process_video

router = APIRouter(tags=["Admin"])

UPLOAD_DIR = Path("uploads")
UPLOAD_DIR.mkdir(exist_ok=True)


@router.get("/dashboard")
def dashboard(db: Session = Depends(get_db)):
    users = db.query(User).count()
    premium = db.query(User).filter(User.is_premium.is_(True)).count()
    profiles = db.query(Profile).count()
    media = db.query(MediaContent).count()
    watched = db.query(PlaybackHistory).count()

    return {
        "users": users,
        "premium_users": premium,
        "profiles": profiles,
        "catalog": media,
        "playbacks": watched,
    }


@router.get("/analytics")
def analytics(db: Session = Depends(get_db)):
    total = db.query(User).count()
    premium = db.query(User).filter(User.is_premium.is_(True)).count()
    movies = db.query(MediaContent).filter(MediaContent.content_type == "movie").count()
    series = db.query(MediaContent).filter(MediaContent.content_type == "series").count()

    return {
        "subscribers": total,
        "premium": premium,
        "movies": movies,
        "series": series,
        "premium_rate": round(premium / total * 100, 2) if total else 0,
    }


@router.get("/revenue")
def revenue(db: Session = Depends(get_db)):
    payments = db.query(Payment).all()
    total = sum(payment.amount for payment in payments if payment.status == "approved")

    return {
        "total_revenue": total,
        "payments": len(payments),
    }


@router.get("/users")
def users(db: Session = Depends(get_db)):
    return db.query(User).all()


@router.put("/users/{user_id}/premium")
def premium(user_id: str, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="Usuário não encontrado.")

    user.is_premium = True
    db.commit()
    return {"message": "Usuário Premium."}


@router.delete("/users/{user_id}")
def delete_user(user_id: str, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="Usuário não encontrado.")

    db.delete(user)
    db.commit()
    return {"message": "Usuário removido."}


@router.get("/catalog")
def catalog(db: Session = Depends(get_db)):
    return db.query(MediaContent).all()


@router.delete("/catalog/{media_id}")
def delete_media(media_id: str, db: Session = Depends(get_db)):
    media = db.query(MediaContent).filter(MediaContent.id == media_id).first()
    if not media:
        raise HTTPException(status_code=404, detail="Conteúdo não encontrado.")

    db.delete(media)
    db.commit()
    return {"message": "Conteúdo removido."}


@router.post("/upload")
async def upload_video(file: UploadFile = File(...), db: Session = Depends(get_db)):
    path = UPLOAD_DIR / f"{uuid4()}_{file.filename}"
    with path.open("wb") as buffer:
        shutil.copyfileobj(file.file, buffer)

    output_folder = Path("storage/streams") / str(uuid4())
    master = process_video(str(path), str(output_folder))

    media = MediaContent(
        title=file.filename,
        description="Upload via admin",
        content_type="movie",
        thumbnail_url="",
        video_url=master.replace("\\", "/"),
    )
    db.add(media)
    db.commit()
    db.refresh(media)

    return {
        "filename": file.filename,
        "path": str(path),
        "stream": master.replace("\\", "/"),
        "media_id": str(media.id),
        "status": "uploaded_and_transcoded",
    }
