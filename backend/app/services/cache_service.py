import json
import logging
from typing import Any

import redis

from app.config import REDIS_URL

logger = logging.getLogger(__name__)


# Connection pool global - evita memory leak do @lru_cache
_connection_pool = redis.ConnectionPool.from_url(
    REDIS_URL,
    decode_responses=True,
    socket_connect_timeout=2,
    socket_timeout=2,
    max_connections=20,
)


def _get_client() -> redis.Redis | None:
    try:
        client = redis.Redis(connection_pool=_connection_pool)
        client.ping()
        return client
    except Exception:
        logger.warning("Redis indisponível, operação de cache ignorada.")
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


def acquire_lock(lock_key: str, ttl_seconds: int = 30) -> bool:
    """Tenta adquirir um lock distribuído via Redis (NX + EX)."""
    client = _get_client()
    if client is None:
        return True  # fail open
    try:
        return bool(client.set(lock_key, "1", nx=True, ex=ttl_seconds))
    except Exception:
        return True


def release_lock(lock_key: str) -> None:
    """Libera um lock distribuído."""
    client = _get_client()
    if client is None:
        return
    try:
        client.delete(lock_key)
    except Exception:
        pass
