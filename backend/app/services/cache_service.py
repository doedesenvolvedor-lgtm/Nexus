import json
import logging
from functools import lru_cache
from typing import Any

import redis

from app.config import REDIS_URL

logger = logging.getLogger(__name__)


@lru_cache(maxsize=1)
def _redis_client() -> redis.Redis:
    return redis.Redis.from_url(
        REDIS_URL,
        decode_responses=True,
        socket_connect_timeout=1,
        socket_timeout=1,
    )


def _get_client() -> redis.Redis | None:
    try:
        client = _redis_client()
        client.ping()
        return client
    except Exception:
        return None


def build_cache_key(prefix: str, **params: Any) -> str:
    if not params:
        return prefix
    serialized = ":".join(f"{k}={params[k]}" for k in sorted(params))
    return f"{prefix}:{serialized}"


def get_json(key: str) -> Any | None:
    client = _get_client()
    if client is None:
        return None

    try:
        raw = client.get(key)
        if raw is None:
            return None
        return json.loads(raw)
    except Exception:
        logger.exception("Erro ao ler cache Redis na chave %s", key)
        return None


def set_json(key: str, value: Any, ttl_seconds: int) -> None:
    client = _get_client()
    if client is None:
        return

    try:
        payload = json.dumps(value, default=str)
        client.setex(key, ttl_seconds, payload)
    except Exception:
        logger.exception("Erro ao gravar cache Redis na chave %s", key)


def delete_key(key: str) -> None:
    client = _get_client()
    if client is None:
        return

    try:
        client.delete(key)
    except Exception:
        logger.exception("Erro ao remover chave Redis %s", key)


def delete_by_prefix(prefix: str) -> None:
    client = _get_client()
    if client is None:
        return

    try:
        pattern = f"{prefix}*"
        keys = list(client.scan_iter(match=pattern))
        if keys:
            client.delete(*keys)
    except Exception:
        logger.exception("Erro ao invalidar cache Redis com prefixo %s", prefix)