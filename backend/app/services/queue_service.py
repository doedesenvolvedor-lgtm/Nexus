import json
import logging
from typing import Any

import redis

from app.config import REDIS_URL

logger = logging.getLogger(__name__)

IMPORT_QUEUE = "jobs:import_media"
PUSH_QUEUE = "jobs:push_notifications"


def _redis_client() -> redis.Redis | None:
    try:
        client = redis.Redis.from_url(
            REDIS_URL,
            decode_responses=True,
            socket_connect_timeout=1,
            socket_timeout=1,
        )
        client.ping()
        return client
    except Exception:
        return None


def enqueue(queue_name: str, payload: dict[str, Any]) -> bool:
    client = _redis_client()
    if client is None:
        return False

    try:
        client.rpush(queue_name, json.dumps(payload, default=str))
        return True
    except Exception:
        logger.exception("Erro ao enfileirar job em %s", queue_name)
        return False


def get_queue_length(queue_name: str) -> int:
    client = _redis_client()
    if client is None:
        return 0

    try:
        return int(client.llen(queue_name))
    except Exception:
        logger.exception("Erro ao consultar tamanho da fila %s", queue_name)
        return 0


def increment_counter(counter_key: str, amount: int = 1) -> None:
    client = _redis_client()
    if client is None:
        return

    try:
        client.incrby(counter_key, amount)
    except Exception:
        logger.exception("Erro ao incrementar contador %s", counter_key)


def get_counter(counter_key: str) -> int:
    client = _redis_client()
    if client is None:
        return 0

    try:
        value = client.get(counter_key)
        return int(value) if value else 0
    except Exception:
        logger.exception("Erro ao ler contador %s", counter_key)
        return 0