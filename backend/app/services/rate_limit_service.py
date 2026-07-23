"""
Servico de Rate Limiting para protecao contra DDoS e abuse.
Implementa 3 niveis:
1. Global (por IP)
2. Por usuario autenticado
3. Por tipo de endpoint (streams, login, APIs)
"""

import logging
from datetime import datetime, timedelta, timezone
from typing import Tuple

import redis

from app.config import REDIS_URL, REDIS_PASSWORD

logger = logging.getLogger(__name__)


class RateLimitService:
    """Gerencia rate limits usando Redis."""

    def __init__(self, redis_url: str = REDIS_URL, redis_password: str = REDIS_PASSWORD):
        self.redis_url = redis_url
        self.redis_password = redis_password
        self._redis: redis.Redis | None = None

    # ==================== LIMITES CONFIGURAVEIS ====================

    LIMITS = {
        "global": {"requests": 1000, "window": 3600},
        "streams": {"requests": 100, "window": 60},
        "segments": {"requests": 500, "window": 60},
        "api": {"requests": 100, "window": 60},
        "login": {"requests": 5, "window": 900},
        "register": {"requests": 3, "window": 3600},
        "payment": {"requests": 5, "window": 3600},
        "admin": {"requests": 500, "window": 60},
    }

    # ==================== METODOS PUBLICOS ====================

    def check_global_limit(self, ip_address: str) -> Tuple[bool, dict]:
        limit_config = self.LIMITS["global"]
        return self._check_limit(key=f"ratelimit:global:{ip_address}", **limit_config)

    def check_user_limit(self, user_id: str, limit_type: str = "api") -> Tuple[bool, dict]:
        limit_config = self.LIMITS.get(limit_type, self.LIMITS["api"])
        return self._check_limit(key=f"ratelimit:user:{user_id}:{limit_type}", **limit_config)

    def check_ip_limit(self, ip_address: str, limit_type: str = "api") -> Tuple[bool, dict]:
        limit_config = self.LIMITS.get(limit_type, self.LIMITS["global"])
        return self._check_limit(key=f"ratelimit:ip:{ip_address}:{limit_type}", **limit_config)

    def check_endpoint_limit(self, ip_address: str, endpoint: str) -> Tuple[bool, dict]:
        limit_config = self.LIMITS["global"]

        if "/auth/login" in endpoint:
            limit_config = self.LIMITS["login"]
        elif "/auth/register" in endpoint:
            limit_config = self.LIMITS["register"]
        elif "/streams" in endpoint:
            limit_config = self.LIMITS["streams"]
        elif "/payment" in endpoint:
            limit_config = self.LIMITS["payment"]
        elif "/admin" in endpoint:
            limit_config = self.LIMITS["admin"]
        elif "/media" in endpoint:
            limit_config = self.LIMITS["api"]

        return self._check_limit(key=f"ratelimit:endpoint:{ip_address}:{endpoint}", **limit_config)

    # ==================== METODOS PRIVADOS ====================

    def _check_limit(self, key: str, requests: int, window: int) -> Tuple[bool, dict]:
        try:
            redis_client = self._get_redis()
            current = int(redis_client.get(key) or 0)
            ttl = redis_client.ttl(key)

            if ttl == -1:
                redis_client.delete(key)
                reset_in = window
            elif ttl == -2:
                current = 0
                reset_in = window
            else:
                reset_in = ttl

            if current < requests:
                redis_client.incr(key)
                if current == 0:
                    redis_client.expire(key, window)
                remaining = requests - (current + 1)
                return True, {"limit": requests, "remaining": remaining, "reset_in": reset_in, "window": window}
            else:
                return False, {"limit": requests, "remaining": 0, "reset_in": reset_in, "window": window, "retry_after": reset_in}

        except Exception as e:
            logger.warning("Rate limit Redis error: %s", e, exc_info=True)
            return True, {"limit": requests, "remaining": requests - 1, "reset_in": window, "window": window, "error": str(e)}

    def reset_limit(self, key: str) -> bool:
        try:
            self._get_redis().delete(key)
            return True
        except Exception as e:
            logger.warning("Erro ao resetar rate limit %s: %s", key, e, exc_info=True)
            return False

    def get_stats(self, key: str) -> dict:
        try:
            redis_client = self._get_redis()
            current = int(redis_client.get(key) or 0)
            ttl = redis_client.ttl(key)
            return {
                "current": current,
                "ttl": ttl,
                "expires_at": datetime.now(timezone.utc) + timedelta(seconds=ttl) if ttl > 0 else None,
            }
        except Exception as e:
            return {"error": str(e)}

    def _get_redis(self) -> redis.Redis:
        if self._redis is None:
            if self.redis_password:
                self._redis = redis.from_url(self.redis_url, decode_responses=True, password=self.redis_password)
            else:
                self._redis = redis.from_url(self.redis_url, decode_responses=True)
        return self._redis


# Instancia global
rate_limit_service = RateLimitService()
