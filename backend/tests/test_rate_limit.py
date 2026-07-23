"""Testes unitários para o serviço de rate limiting."""

import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

os.environ["REDIS_URL"] = "redis://localhost:6379/9"
os.environ["REDIS_PASSWORD"] = ""

import pytest
from unittest.mock import patch, MagicMock

from app.services.rate_limit_service import RateLimitService


class TestRateLimitService:
    def setup_method(self):
        """Setup antes de cada teste."""
        self.service = RateLimitService()
        # Mock Redis para evitar conexão real
        self.mock_redis = MagicMock()
        self.service._redis = self.mock_redis

    def test_global_limit_within(self):
        """Testa se requisição dentro do limite é permitida."""
        self.mock_redis.get.return_value = b"50"  # 50 de 1000
        self.mock_redis.ttl.return_value = 1800  # 30 minutos restantes
        
        allowed, info = self.service.check_global_limit("192.168.1.1")
        
        assert allowed is True
        assert info["limit"] == 1000
        assert info["remaining"] < 1000
        assert info["reset_in"] == 1800

    def test_global_limit_exceeded(self):
        """Testa se requisição acima do limite é bloqueada."""
        self.mock_redis.get.return_value = b"1000"  # Limite atingido
        self.mock_redis.ttl.return_value = 1800
        
        allowed, info = self.service.check_global_limit("192.168.1.1")
        
        assert allowed is False
        assert info["remaining"] == 0

    def test_login_limit_blocked(self):
        """Testa bloqueio de login após muitas tentativas."""
        self.mock_redis.get.return_value = b"5"
        self.mock_redis.ttl.return_value = 800
        
        allowed, info = self.service.check_ip_limit("192.168.1.1", "login")
        
        assert allowed is False
        assert info["remaining"] == 0

    def test_register_limit(self):
        """Testa limite de registro."""
        self.mock_redis.get.return_value = b"0"
        self.mock_redis.ttl.return_value = -2  # Key não existe
        
        allowed, info = self.service.check_ip_limit("192.168.1.1", "register")
        
        assert allowed is True
        assert info["limit"] == 3

    def test_redis_unavailable(self):
        """Testa comportamento quando Redis está indisponível (fail open)."""
        self.service._redis = None
        
        allowed, info = self.service.check_global_limit("192.168.1.1")
        
        assert allowed is True  # fail open
        assert "error" in info

    def test_endpoint_login_limit(self):
        """Testa rate limit específico para login endpoint."""
        self.mock_redis.get.return_value = b"0"
        self.mock_redis.ttl.return_value = -2
        
        allowed, info = self.service.check_endpoint_limit("192.168.1.1", "/auth/login")
        
        assert allowed is True
        assert info["limit"] == 5  # Login limit

    def test_endpoint_register_limit(self):
        """Testa rate limit específico para register endpoint."""
        self.mock_redis.get.return_value = b"0"
        self.mock_redis.ttl.return_value = -2
        
        allowed, info = self.service.check_endpoint_limit("192.168.1.1", "/auth/register")
        
        assert allowed is True
        assert info["limit"] == 3  # Register limit

    def test_endpoint_payment_limit(self):
        """Testa rate limit específico para payment endpoint."""
        self.mock_redis.get.return_value = b"0"
        self.mock_redis.ttl.return_value = -2
        
        allowed, info = self.service.check_endpoint_limit("192.168.1.1", "/payments")
        
        assert allowed is True
        assert info["limit"] == 5  # Payment limit

    def test_user_limit(self):
        """Testa rate limit por usuário."""
        self.mock_redis.get.return_value = b"0"
        self.mock_redis.ttl.return_value = -2
        
        allowed, info = self.service.check_user_limit("user-123", "api")
        
        assert allowed is True
        assert info["limit"] == 100  # API limit

    def test_user_limit_exceeded(self):
        """Testa bloqueio por usuário após exceder limite."""
        self.mock_redis.get.return_value = b"100"
        self.mock_redis.ttl.return_value = 30
        
        allowed, info = self.service.check_user_limit("user-123", "api")
        
        assert allowed is False
        assert info["remaining"] == 0

    def test_reset_limit(self):
        """Testa reset de rate limit."""
        self.mock_redis.delete.return_value = True
        
        result = self.service.reset_limit("ratelimit:global:192.168.1.1")
        assert result is True

    def test_get_stats(self):
        """Testa obtenção de estatísticas."""
        self.mock_redis.get.return_value = b"42"
        self.mock_redis.ttl.return_value = 300
        
        stats = self.service.get_stats("ratelimit:global:192.168.1.1")
        assert stats["current"] == 42
        assert stats["ttl"] == 300
