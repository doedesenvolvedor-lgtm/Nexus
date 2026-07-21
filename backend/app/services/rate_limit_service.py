"""
Serviço de Rate Limiting para proteção contra DDoS e abuse.
Implementa 3 níveis:
1. Global (por IP)
2. Por usuário autenticado
3. Por tipo de endpoint (streams, login, APIs)
"""

import logging
from datetime import datetime, timedelta
from typing import Tuple

import redis

from app.config import REDIS_URL

logger = logging.getLogger(__name__)


class RateLimitService:
    """Gerencia rate limits usando Redis."""
    
    def __init__(self, redis_url: str = REDIS_URL):
        self.redis_url = redis_url
        self._redis: redis.Redis | None = None
    
    # ==================== LIMITES CONFIGURÁVEIS ====================
    
    LIMITS = {
        # Global por IP
        "global": {
            "requests": 1000,
            "window": 3600,  # 1 hora
        },
        
        # Streams (proteção contra bandwidth abuse)
        "streams": {
            "requests": 100,
            "window": 60,    # 1 minuto
        },
        
        # Download de segmentos (muito permissivo)
        "segments": {
            "requests": 500,
            "window": 60,    # 1 minuto
        },
        
        # APIs gerais (por usuário)
        "api": {
            "requests": 100,
            "window": 60,    # 1 minuto
        },
        
        # Login (proteção brute force)
        "login": {
            "requests": 5,
            "window": 900,   # 15 minutos
        },
        
        # Pagamentos (muito restritivo)
        "payment": {
            "requests": 5,
            "window": 3600,  # 1 hora
        },
        
        # Admin (mais permissivo)
        "admin": {
            "requests": 500,
            "window": 60,    # 1 minuto
        },
    }
    
    # ==================== MÉTODOS PÚBLICOS ====================
    
    def check_global_limit(self, ip_address: str) -> Tuple[bool, dict]:
        """
        Verifica limite global por IP.
        
        Returns:
            (allowed: bool, info: dict)
            info contém: limit, remaining, reset_in
        """
        limit_config = self.LIMITS["global"]
        return self._check_limit(
            key=f"ratelimit:global:{ip_address}",
            **limit_config,
        )
    
    def check_user_limit(self, user_id: str, limit_type: str = "api") -> Tuple[bool, dict]:
        """
        Verifica limite por usuário autenticado.
        
        Args:
            user_id: ID do usuário
            limit_type: Tipo de limite (api, streams, payment, admin)
        
        Returns:
            (allowed: bool, info: dict)
        """
        limit_config = self.LIMITS.get(limit_type, self.LIMITS["api"])
        return self._check_limit(
            key=f"ratelimit:user:{user_id}:{limit_type}",
            **limit_config,
        )
    
    def check_ip_limit(
        self,
        ip_address: str,
        limit_type: str = "api"
    ) -> Tuple[bool, dict]:
        """
        Verifica limite por IP para um tipo específico.
        
        Args:
            ip_address: IP do cliente
            limit_type: Tipo de limite (api, streams, login, etc)
        
        Returns:
            (allowed: bool, info: dict)
        """
        limit_config = self.LIMITS.get(limit_type, self.LIMITS["global"])
        return self._check_limit(
            key=f"ratelimit:ip:{ip_address}:{limit_type}",
            **limit_config,
        )
    
    def check_endpoint_limit(
        self,
        ip_address: str,
        endpoint: str,
    ) -> Tuple[bool, dict]:
        """
        Verifica limite específico por endpoint e IP.
        
        Args:
            ip_address: IP do cliente
            endpoint: Path do endpoint (ex: /auth/login, /media/upload)
        
        Returns:
            (allowed: bool, info: dict)
        """
        limit_config = self.LIMITS["global"]
        
        # Determine o tipo de limite baseado no endpoint
        if "/auth/login" in endpoint:
            limit_config = self.LIMITS["login"]
        elif "/streams" in endpoint:
            limit_config = self.LIMITS["streams"]
        elif "/payment" in endpoint:
            limit_config = self.LIMITS["payment"]
        elif "/admin" in endpoint:
            limit_config = self.LIMITS["admin"]
        elif "/media" in endpoint:
            limit_config = self.LIMITS["api"]
        
        return self._check_limit(
            key=f"ratelimit:endpoint:{ip_address}:{endpoint}",
            **limit_config,
        )
    
    # ==================== MÉTODOS PRIVADOS ====================
    
    def _check_limit(
        self,
        key: str,
        requests: int,
        window: int,
    ) -> Tuple[bool, dict]:
        """
        Valida se cliente está dentro do limite.
        
        Algoritmo: Token Bucket
        - Cada requisição consome 1 token
        - Tokens se regeneram a cada `window` segundos
        - Se tokens esgotados, rejeita até regeneração
        
        Args:
            key: Chave Redis (inclui identificador)
            requests: Número máximo de requisições
            window: Janela de tempo em segundos
        
        Returns:
            (allowed: bool, info: dict)
        """
        try:
            redis_client = self._get_redis()
            current = int(redis_client.get(key) or 0)
            ttl = redis_client.ttl(key)
            
            # Calcular tempo de reset
            if ttl == -1:
                # Key existe mas sem TTL (erro, resetar)
                redis_client.delete(key)
                reset_in = window
            elif ttl == -2:
                # Key não existe
                current = 0
                reset_in = window
            else:
                reset_in = ttl
            
            # Verificar se dentro do limite
            if current < requests:
                # Incrementar contador
                redis_client.incr(key)
                
                # Configurar TTL (apenas na 1ª requisição)
                if current == 0:
                    redis_client.expire(key, window)
                
                remaining = requests - (current + 1)
                
                return True, {
                    "limit": requests,
                    "remaining": remaining,
                    "reset_in": reset_in,
                    "window": window,
                }
            else:
                # Limite atingido
                return False, {
                    "limit": requests,
                    "remaining": 0,
                    "reset_in": reset_in,
                    "window": window,
                    "retry_after": reset_in,
                }
        
        except Exception as e:
            # Erro no Redis - permitir requisição (fail open)
            logger.warning("Rate limit Redis error: %s", e, exc_info=True)
            return True, {
                "limit": requests,
                "remaining": requests - 1,
                "reset_in": window,
                "window": window,
                "error": str(e),
            }
    
    def reset_limit(self, key: str) -> bool:
        """Reseta um rate limit específico."""
        try:
            self._get_redis().delete(key)
            return True
        except Exception as e:
            logger.warning("Erro ao resetar rate limit %s: %s", key, e, exc_info=True)
            return False
    
    def get_stats(self, key: str) -> dict:
        """Obtém estatísticas de um rate limit."""
        try:
            redis_client = self._get_redis()
            current = int(redis_client.get(key) or 0)
            ttl = redis_client.ttl(key)
            
            return {
                "current": current,
                "ttl": ttl,
                "expires_at": datetime.utcnow() + timedelta(seconds=ttl) if ttl > 0 else None,
            }
        except Exception as e:
            return {"error": str(e)}

    def _get_redis(self) -> redis.Redis:
        if self._redis is None:
            self._redis = redis.from_url(self.redis_url, decode_responses=True)
        return self._redis


# Instância global
rate_limit_service = RateLimitService()
