import logging
from typing import Tuple

import redis

from app.config import REDIS_URL

logger = logging.getLogger(__name__)

FAILED_LOGIN_WINDOW_SECONDS = 15 * 60
LOCK_SECONDS = 15 * 60
MAX_FAILED_ATTEMPTS = 5


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


def _normalize_email(email: str) -> str:
    return email.strip().lower()


def _failed_key(email: str) -> str:
    return f"auth:failed:{_normalize_email(email)}"


def _lock_key(email: str) -> str:
    return f"auth:lock:{_normalize_email(email)}"


def _session_key(user_id: str, jti: str) -> str:
    return f"auth:session:{user_id}:{jti}"


def is_login_locked(email: str) -> Tuple[bool, int]:
    client = _redis_client()
    if client is None:
        return False, 0

    try:
        key = _lock_key(email)
        if client.exists(key):
            ttl = max(client.ttl(key), 0)
            return True, ttl
    except Exception:
        logger.exception("Erro ao validar lock de login")

    return False, 0


def register_failed_login(email: str) -> Tuple[bool, int]:
    client = _redis_client()
    if client is None:
        return False, 0

    try:
        lock_key = _lock_key(email)
        if client.exists(lock_key):
            ttl = max(client.ttl(lock_key), 0)
            return True, ttl

        failed_key = _failed_key(email)
        attempts = client.incr(failed_key)
        if attempts == 1:
            client.expire(failed_key, FAILED_LOGIN_WINDOW_SECONDS)

        if attempts >= MAX_FAILED_ATTEMPTS:
            client.setex(lock_key, LOCK_SECONDS, "1")
            client.delete(failed_key)
            return True, LOCK_SECONDS
    except Exception:
        logger.exception("Erro ao registrar tentativa de login")

    return False, 0


def clear_login_failures(email: str) -> None:
    client = _redis_client()
    if client is None:
        return

    try:
        client.delete(_failed_key(email), _lock_key(email))
    except Exception:
        logger.exception("Erro ao limpar tentativas de login")


def register_session(user_id: str, jti: str, ttl_seconds: int) -> None:
    client = _redis_client()
    if client is None:
        return

    try:
        client.setex(_session_key(user_id, jti), ttl_seconds, "1")
    except Exception:
        logger.exception("Erro ao registrar sessão")


def is_session_active(user_id: str, jti: str) -> bool:
    client = _redis_client()
    if client is None:
        return True

    try:
        return bool(client.exists(_session_key(user_id, jti)))
    except Exception:
        logger.exception("Erro ao validar sessão ativa")
        return True


def revoke_session(user_id: str, jti: str) -> None:
    client = _redis_client()
    if client is None:
        return

    try:
        client.delete(_session_key(user_id, jti))
    except Exception:
        logger.exception("Erro ao revogar sessão")