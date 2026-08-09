"""Testes unitários para o módulo de segurança."""

import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

from datetime import datetime, timezone
import uuid

import pytest
from fastapi import HTTPException
from jose import JWTError
from unittest.mock import MagicMock, patch

# Configurar variáveis de ambiente para teste
os.environ["SECRET_KEY"] = "test-secret-key-for-unit-tests-nexus"
os.environ["ALGORITHM"] = "HS256"
os.environ["ACCESS_TOKEN_EXPIRE_MINUTES"] = "30"
os.environ["REFRESH_TOKEN_EXPIRE_DAYS"] = "7"

from app.dependencies import get_current_user
from app.models import User
from app.routers.auth import refresh_token
from app.schemas import RefreshTokenRequest
from app.security import (
    hash_password,
    verify_password,
    create_access_token,
    create_refresh_token,
    decode_token,
    _ensure_security_config,
)


class DummyUser:
    def __init__(self, user_id):
        self.id = user_id


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

    def test_get_current_user_rejects_refresh_token(self):
        """Testa que refresh tokens nao validam endpoints protegidos."""
        user_id = str(uuid.uuid4())
        access_token = create_access_token({"sub": user_id, "email": "test@example.com"})
        refresh_token = create_refresh_token({"sub": user_id, "email": "test@example.com"})

        mock_db = MagicMock()
        mock_db.query.return_value.filter.return_value.first.return_value = DummyUser(user_id)

        # Access token deve funcionar
        user = get_current_user(token=access_token, db=mock_db)
        assert user.id == user_id

        # Refresh token nao deve ser aceito para endpoints protegidos
        with pytest.raises(Exception):
            get_current_user(token=refresh_token, db=mock_db)


class TestSessionValidation:
    def test_get_current_user_rejects_inactive_session(self):
        """Testa que um access token com sessao revogada e rejeitado."""
        user_id = str(uuid.uuid4())
        token = create_access_token({"sub": user_id, "email": "test@example.com"})

        mock_db = MagicMock()
        mock_db.query.return_value.filter.return_value.first.return_value = DummyUser(user_id)

        with patch("app.services.auth_session_service.is_session_active", return_value=False):
            with pytest.raises(HTTPException) as exc_info:
                get_current_user(token=token, db=mock_db)

        assert exc_info.value.status_code == 401
        assert "Sessao expirada ou revogada" in str(exc_info.value.detail)

    def test_refresh_token_rotates_jti_and_registers_new_session(self):
        """Testa que refresh token valida sessao e cria nova sessao com JTI trocado."""
        user_id = str(uuid.uuid4())
        old_jti = str(uuid.uuid4())
        refresh_token_value = create_refresh_token({"sub": user_id, "email": "test@example.com"}, jti=old_jti)

        mock_db = MagicMock()
        mock_db.query.return_value.filter.return_value.first.return_value = DummyUser(user_id)

        with patch("app.services.auth_session_service.is_session_active", return_value=True) as mock_active, \
             patch("app.services.auth_session_service.revoke_session") as mock_revoke, \
             patch("app.services.auth_session_service.register_session") as mock_register:
            response = refresh_token(
                request=RefreshTokenRequest(refresh_token=refresh_token_value),
                db=mock_db,
            )

        assert response["token_type"] == "bearer"
        assert response["access_token"] != refresh_token_value
        assert response["refresh_token"] != refresh_token_value
        assert mock_revoke.called
        assert mock_register.called
        mock_active.assert_called_once_with(user_id, old_jti)
