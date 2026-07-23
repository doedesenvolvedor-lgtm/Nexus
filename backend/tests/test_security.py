"""Testes unitários para o módulo de segurança."""

import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

from datetime import datetime, timezone
import uuid

import pytest
from jose import JWTError

# Configurar variáveis de ambiente para teste
os.environ["SECRET_KEY"] = "test-secret-key-for-unit-tests-nexus"
os.environ["ALGORITHM"] = "HS256"
os.environ["ACCESS_TOKEN_EXPIRE_MINUTES"] = "30"
os.environ["REFRESH_TOKEN_EXPIRE_DAYS"] = "7"

from app.security import (
    hash_password,
    verify_password,
    create_access_token,
    create_refresh_token,
    decode_token,
    _ensure_security_config,
)


class TestPasswordHashing:
    def test_hash_password(self):
        """Testa se o hash e gerado corretamente."""
        password = "TestPassword123!@#"
        hashed = hash_password(password)
        assert hashed != password
        assert hashed.startswith("$2b$")  # bcrypt hash prefix

    def test_verify_password_correct(self):
        """Testa se a senha correta e verificada com sucesso."""
        password = "TestPassword123!@#"
        hashed = hash_password(password)
        assert verify_password(password, hashed) is True

    def test_verify_password_incorrect(self):
        """Testa se a senha incorreta e rejeitada."""
        hashed = hash_password("CorrectPassword123!@#")
        assert verify_password("WrongPassword123!@#", hashed) is False

    def test_hash_uniqueness(self):
        """Testa se hashes sao unicos (bcrypt usa salt)."""
        password = "TestPassword123!@#"
        hash1 = hash_password(password)
        hash2 = hash_password(password)
        assert hash1 != hash2


class TestAccessToken:
    def test_create_access_token(self):
        """Testa criacao de access token."""
        data = {"sub": str(uuid.uuid4()), "email": "test@example.com"}
        token = create_access_token(data)
        assert token is not None
        assert isinstance(token, str)
        assert len(token) > 50  # JWT token

    def test_decode_valid_token(self):
        """Testa decodificacao de token valido."""
        user_id = str(uuid.uuid4())
        data = {"sub": user_id, "email": "test@example.com"}
        token = create_access_token(data)
        payload = decode_token(token)
        assert payload["sub"] == user_id
        assert payload["email"] == "test@example.com"
        assert payload["type"] == "access"
        assert "iat" in payload
        assert "jti" in payload
        assert "exp" in payload

    def test_token_expiration(self):
        """Testa se token expira corretamente."""
        import app.security as sec
        data = {"sub": str(uuid.uuid4())}
        original = sec.ACCESS_TOKEN_EXPIRE_MINUTES
        sec.ACCESS_TOKEN_EXPIRE_MINUTES = -1  # Token ja expirado
        try:
            token = sec.create_access_token(data)
            with pytest.raises(JWTError):
                sec.decode_token(token)
        finally:
            sec.ACCESS_TOKEN_EXPIRE_MINUTES = original


class TestRefreshToken:
    def test_create_refresh_token(self):
        """Testa criacao de refresh token."""
        data = {"sub": str(uuid.uuid4()), "email": "test@example.com"}
        token = create_refresh_token(data)
        assert token is not None
        assert isinstance(token, str)

    def test_refresh_token_type(self):
        """Testa se refresh token tem tipo correto."""
        data = {"sub": str(uuid.uuid4())}
        token = create_refresh_token(data)
        payload = decode_token(token)
        assert payload["type"] == "refresh"

    def test_access_vs_refresh_different(self):
        """Testa se access e refresh tokens sao diferentes."""
        data = {"sub": str(uuid.uuid4()), "email": "test@example.com"}
        access = create_access_token(data)
        refresh = create_refresh_token(data)
        assert access != refresh

    def test_refresh_longer_expiry(self):
        """Testa se refresh token expira depois do access token."""
        data = {"sub": str(uuid.uuid4())}
        access = create_access_token(data)
        refresh = create_refresh_token(data)

        access_payload = decode_token(access)
        refresh_payload = decode_token(refresh)

        access_exp = access_payload["exp"]
        refresh_exp = refresh_payload["exp"]

        assert refresh_exp > access_exp


class TestSecurityConfig:
    def test_ensure_config_with_secret(self):
        """Testa se configuracao valida nao levanta erro."""
        _ensure_security_config()

    def test_ensure_config_without_secret(self):
        """Testa se ausencia de SECRET_KEY levanta erro."""
        import app.security as sec
        original_secret = sec.SECRET_KEY
        original_algo = sec.ALGORITHM
        sec.SECRET_KEY = None
        sec.ALGORITHM = None
        try:
            with pytest.raises(RuntimeError, match="SECRET_KEY"):
                sec._ensure_security_config()
        finally:
            sec.SECRET_KEY = original_secret
            sec.ALGORITHM = original_algo


class TestJWTClaims:
    def test_token_has_iat(self):
        """Testa se token tem issued-at timestamp."""
        data = {"sub": str(uuid.uuid4())}
        token = create_access_token(data)
        payload = decode_token(token)
        assert "iat" in payload
        assert isinstance(payload["iat"], int)

    def test_token_has_jti(self):
        """Testa se token tem unique ID."""
        data = {"sub": str(uuid.uuid4())}
        token = create_access_token(data)
        payload = decode_token(token)
        assert "jti" in payload
        assert isinstance(payload["jti"], str)

    def test_unique_jti_per_token(self):
        """Testa se cada token tem JTI unico."""
        data = {"sub": str(uuid.uuid4())}
        token1 = create_access_token(data)
        token2 = create_access_token(data)

        payload1 = decode_token(token1)
        payload2 = decode_token(token2)

        assert payload1["jti"] != payload2["jti"]

    def test_token_custom_data(self):
        """Testa se dados customizados sao preservados."""
        data = {
            "sub": str(uuid.uuid4()),
            "email": "user@test.com",
            "role": "admin",
            "custom_key": "custom_value",
        }
        token = create_access_token(data)
        payload = decode_token(token)
        assert payload["email"] == "user@test.com"
        assert payload["role"] == "admin"
        assert payload["custom_key"] == "custom_value"
