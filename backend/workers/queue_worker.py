import json
import logging
import time

import redis

from app.config import REDIS_URL
from app.database import SessionLocal
from app.models import DeviceToken, MediaContent
from app.services.firebase_service import FirebaseService
from app.services.queue_audit_service import mark_job_completed, mark_job_failed, mark_job_processing

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
)
logger = logging.getLogger("queue-worker")

IMPORT_QUEUE = "jobs:import_media"
PUSH_QUEUE = "jobs:push_notifications"


def redis_client() -> redis.Redis:
    return redis.Redis.from_url(REDIS_URL, decode_responses=True)


def incr(client: redis.Redis, key: str, amount: int = 1) -> None:
    client.incrby(key, amount)


def process_import_batch(payload: dict) -> int:
    items = payload.get("items", [])
    if not items:
        return 0

    db = SessionLocal()
    try:
        for item in items:
            media = MediaContent(**item)
            db.add(media)
        db.commit()
        return len(items)
    except Exception:
        db.rollback()
        raise
    finally:
        db.close()


def process_push_batch(payload: dict) -> int:
    notifications = payload.get("notifications", [])
    if not notifications:
        return 0

    firebase = FirebaseService()
    
    # Se Firebase não está inicializado, apenas log
    if not firebase.is_initialized():
        logger.warning("Firebase não está inicializado. Notificações serão registradas mas não enviadas.")
        return len(notifications)
    
    db = SessionLocal()
    sent_count = 0
    
    try:
        for notification in notifications:
            user_id = notification.get("user_id")
            title = notification.get("title", "Nexus")
            body = notification.get("body", "Nova notificação")
            channel = notification.get("channel", "push")
            
            # Buscar device tokens ativos do usuário
            device_tokens = db.query(DeviceToken).filter(
                DeviceToken.user_id == user_id,
                DeviceToken.is_active == True,
            ).all()
            
            if not device_tokens:
                logger.debug(f"Nenhum device token ativo para usuário {user_id}")
                continue
            
            # Extrair apenas os tokens
            tokens = [dt.device_token for dt in device_tokens]
            
            # Dados adicionais para a notificação
            data = {
                "channel": channel,
                "timestamp": payload.get("created_at", ""),
            }
            
            # Enviar em lote
            result = firebase.send_multicast(
                device_tokens=tokens,
                title=title,
                body=body,
                data=data,
            )
            
            sent_count += result.get("success", 0)
            
            # Log de falhas
            if result.get("failure", 0) > 0:
                logger.warning(
                    f"Falha ao enviar para {result['failure']} dispositivos do usuário {user_id}"
                )
        
        return sent_count
    except Exception as e:
        logger.error(f"Erro ao processar batch de push: {e}")
        raise
    finally:
        db.close()


def handle_job(client: redis.Redis, queue_name: str, raw_payload: str) -> None:
    job_id = None
    try:
        payload = json.loads(raw_payload)
        job_type = payload.get("type")
        job_id = payload.get("job_id")

        if job_id:
            mark_job_processing(job_id)

        if queue_name == IMPORT_QUEUE and job_type == "import_media_batch":
            processed = process_import_batch(payload)
            incr(client, "jobs:processed:import_items", processed)
            if job_id:
                mark_job_completed(job_id, processed)
            logger.info("Import batch processado com %s itens", processed)
            return

        if queue_name == PUSH_QUEUE and job_type == "push_notifications_batch":
            processed = process_push_batch(payload)
            incr(client, "jobs:processed:push_notifications", processed)
            if job_id:
                mark_job_completed(job_id, processed)
            logger.info("Push batch processado com %s notificacoes", processed)
            return

        incr(client, "jobs:processed:failed", 1)
        if job_id:
            mark_job_failed(job_id, "Tipo/fila de job desconhecido")
        logger.warning("Job ignorado: tipo/fila desconhecido")
    except Exception as exc:
        incr(client, "jobs:processed:failed", 1)
        if job_id:
            mark_job_failed(job_id, str(exc))
        logger.exception("Falha ao processar job: %s", exc)


def run() -> None:
    client = redis_client()
    logger.info("Queue worker iniciado")

    while True:
        try:
            response = client.blpop([IMPORT_QUEUE, PUSH_QUEUE], timeout=5)
            if not response:
                continue

            queue_name, raw_payload = response
            handle_job(client, queue_name, raw_payload)
        except redis.RedisError as exc:
            logger.warning("Erro Redis no worker: %s", exc)
            time.sleep(2)
        except Exception as exc:
            logger.exception("Erro inesperado no worker: %s", exc)
            time.sleep(1)


if __name__ == "__main__":
    run()