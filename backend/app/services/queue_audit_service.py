from datetime import datetime, timezone
from uuid import UUID

from app.database import SessionLocal
from app.models import QueueJob


def create_queue_job(
    queue_name: str,
    job_type: str,
    items_count: int,
    payload: dict,
) -> str:
    db = SessionLocal()
    try:
        job = QueueJob(
            queue_name=queue_name,
            job_type=job_type,
            status="queued",
            items_count=items_count,
            payload=payload,
        )
        db.add(job)
        db.commit()
        db.refresh(job)
        return str(job.id)
    finally:
        db.close()


def mark_job_processing(job_id: str) -> None:
    db = SessionLocal()
    try:
        job = db.query(QueueJob).filter(QueueJob.id == UUID(job_id)).first()
        if job is None:
            return
        job.status = "processing"
        job.started_at = datetime.now(timezone.utc)
        db.commit()
    finally:
        db.close()


def mark_job_completed(job_id: str, processed_count: int) -> None:
    db = SessionLocal()
    try:
        job = db.query(QueueJob).filter(QueueJob.id == UUID(job_id)).first()
        if job is None:
            return
        job.status = "completed"
        job.processed_count = processed_count
        job.finished_at = datetime.now(timezone.utc)
        db.commit()
    finally:
        db.close()


def mark_job_failed(job_id: str, error_message: str) -> None:
    db = SessionLocal()
    try:
        job = db.query(QueueJob).filter(QueueJob.id == UUID(job_id)).first()
        if job is None:
            return
        job.status = "failed"
        job.error_message = error_message[:1000]
        job.finished_at = datetime.now(timezone.utc)
        db.commit()
    finally:
        db.close()


def list_recent_jobs(limit: int = 50) -> list[dict]:
    db = SessionLocal()
    try:
        jobs = (
            db.query(QueueJob)
            .order_by(QueueJob.created_at.desc())
            .limit(limit)
            .all()
        )
        return [
            {
                "id": str(job.id),
                "queue_name": job.queue_name,
                "job_type": job.job_type,
                "status": job.status,
                "items_count": job.items_count,
                "processed_count": job.processed_count,
                "error_message": job.error_message,
                "created_at": job.created_at.isoformat() if job.created_at else None,
                "started_at": job.started_at.isoformat() if job.started_at else None,
                "finished_at": job.finished_at.isoformat() if job.finished_at else None,
            }
            for job in jobs
        ]
    finally:
        db.close()