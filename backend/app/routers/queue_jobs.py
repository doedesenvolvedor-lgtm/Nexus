from datetime import datetime, timezone

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field

from app.services.queue_audit_service import create_queue_job, list_recent_jobs, mark_job_failed
from app.services.queue_service import (
    IMPORT_QUEUE,
    PUSH_QUEUE,
    enqueue,
    get_counter,
    get_queue_length,
)

router = APIRouter(prefix="/queue", tags=["Queue"])

CHUNK_SIZE = 100


class ImportMediaItem(BaseModel):
    title: str
    description: str | None = None
    content_type: str = "movie"
    genre: str | None = None
    release_year: int | None = None
    duration: int | None = None
    rating: str | None = None
    thumbnail_url: str | None = None
    banner_url: str | None = None
    trailer_url: str | None = None
    video_url: str | None = None
    ai_emotions_tags: str | None = None


class BulkImportRequest(BaseModel):
    items: list[ImportMediaItem] = Field(default_factory=list)


class PushNotificationItem(BaseModel):
    user_id: str
    title: str
    body: str
    channel: str = "push"


class BulkPushRequest(BaseModel):
    notifications: list[PushNotificationItem] = Field(default_factory=list)


def _chunk(items: list, chunk_size: int) -> list[list]:
    return [items[i : i + chunk_size] for i in range(0, len(items), chunk_size)]


@router.post("/import-media")
def enqueue_import_media(data: BulkImportRequest):
    if not data.items:
        raise HTTPException(status_code=400, detail="Envie ao menos 1 item para importacao.")

    chunks = _chunk(data.items, CHUNK_SIZE)
    created_jobs = 0

    for batch in chunks:
        payload = {
            "type": "import_media_batch",
            "created_at": datetime.now(timezone.utc).isoformat(),
            "size": len(batch),
            "items": [item.model_dump() for item in batch],
        }
        job_id = create_queue_job(
            queue_name=IMPORT_QUEUE,
            job_type="import_media_batch",
            items_count=len(batch),
            payload=payload,
        )
        payload["job_id"] = job_id
        if enqueue(IMPORT_QUEUE, payload):
            created_jobs += 1
        else:
            mark_job_failed(job_id, "Redis indisponivel para enfileirar job")

    if created_jobs == 0:
        raise HTTPException(status_code=503, detail="Redis indisponivel para enfileirar jobs.")

    return {
        "message": "Importacao enfileirada com sucesso.",
        "jobs_created": created_jobs,
        "items_received": len(data.items),
        "batch_size": CHUNK_SIZE,
    }


@router.post("/push-notifications")
def enqueue_push_notifications(data: BulkPushRequest):
    if not data.notifications:
        raise HTTPException(status_code=400, detail="Envie ao menos 1 notificacao.")

    chunks = _chunk(data.notifications, CHUNK_SIZE)
    created_jobs = 0

    for batch in chunks:
        payload = {
            "type": "push_notifications_batch",
            "created_at": datetime.now(timezone.utc).isoformat(),
            "size": len(batch),
            "notifications": [n.model_dump() for n in batch],
        }
        job_id = create_queue_job(
            queue_name=PUSH_QUEUE,
            job_type="push_notifications_batch",
            items_count=len(batch),
            payload=payload,
        )
        payload["job_id"] = job_id
        if enqueue(PUSH_QUEUE, payload):
            created_jobs += 1
        else:
            mark_job_failed(job_id, "Redis indisponivel para enfileirar job")

    if created_jobs == 0:
        raise HTTPException(status_code=503, detail="Redis indisponivel para enfileirar jobs.")

    return {
        "message": "Notificacoes enfileiradas com sucesso.",
        "jobs_created": created_jobs,
        "notifications_received": len(data.notifications),
        "batch_size": CHUNK_SIZE,
    }


@router.get("/stats")
def queue_stats():
    return {
        "import_queue_length": get_queue_length(IMPORT_QUEUE),
        "push_queue_length": get_queue_length(PUSH_QUEUE),
        "processed_import_items": get_counter("jobs:processed:import_items"),
        "processed_push_notifications": get_counter("jobs:processed:push_notifications"),
        "failed_jobs": get_counter("jobs:processed:failed"),
    }


@router.get("/jobs")
def queue_jobs(limit: int = 50):
    return {
        "jobs": list_recent_jobs(limit=min(max(limit, 1), 200)),
    }