"""Testes unitários para o serviço de tokens de streaming."""

import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

import uuid

import pytest
from jose import JWTError

os.environ["SECRET_KEY"] = "test-secret-key-for-stream-tokens"
os.environ["ALGORITHM"] = "HS256"

from app.services.stream_token_service import (
    create_stream_token,
    validate_stream_token,
    create_playlist_token,
    validate_playlist_token,
)


class TestStreamToken:
    def test_create_stream_token(self):
        """Testa criação de token de stream."""
        media_id = str(uuid.uuid4())
        user_id = str(uuid.uuid4())
        
        token = create_stream_token(media_id=media_id, user_id=user_id)
        assert token is not None
        assert isinstance(token, str)

    def test_validate_valid_token(self):
        """Testa validação de token válido."""
        media_id = str(uuid.uuid4())
        user_id = str(uuid.uuid4())
        
        token = create_stream_token(media_id=media_id, user_id=user_id)
        payload = validate_stream_token(token, media_id)
        
        assert payload["media_id"] == media_id
        assert payload["user_id"] == user_id
        assert payload["type"] == "stream"

    def test_validate_wrong_media(self):
        """Testa rejeição de token para mídia errada."""
        media_id = str(uuid.uuid4())
        wrong_media_id = str(uuid.uuid4())
        
        token = create_stream_token(media_id=media_id, user_id=str(uuid.uuid4()))
        
        with pytest.raises(ValueError, match="não autorizado"):
            validate_stream_token(token, wrong_media_id)

    def test_validate_expired_token(self):
        """Testa rejeição de token expirado."""
        import app.services.stream_token_service as sts
        from datetime import timedelta
        
        media_id = str(uuid.uuid4())
        token = create_stream_token(
            media_id=media_id,
            user_id=str(uuid.uuid4()),
            expires_in_minutes=-1,  # Expirado
        )
        
        with pytest.raises(JWTError, match="expirado"):
            validate_stream_token(token, media_id)

    def test_token_with_custom_expiry(self):
        """Testa token com expiração customizada."""
        media_id = str(uuid.uuid4())
        
        token = create_stream_token(
            media_id=media_id,
            user_id=str(uuid.uuid4()),
            expires_in_minutes=120,  # 2 horas
        )
        
        payload = validate_stream_token(token, media_id)
        assert payload["media_id"] == media_id


class TestPlaylistToken:
    def test_create_playlist_token(self):
        """Testa criação de token de playlist."""
        playlist_path = "uuid/master.m3u8"
        user_id = str(uuid.uuid4())
        
        token = create_playlist_token(
            playlist_path=playlist_path,
            user_id=user_id,
        )
        
        assert token is not None

    def test_validate_valid_playlist(self):
        """Testa validação de token de playlist válido."""
        playlist_path = "uuid/master.m3u8"
        user_id = str(uuid.uuid4())
        
        token = create_playlist_token(
            playlist_path=playlist_path,
            user_id=user_id,
        )
        
        payload = validate_playlist_token(token, playlist_path)
        assert payload["playlist"] == playlist_path
        assert payload["type"] == "playlist"

    def test_validate_wrong_playlist(self):
        """Testa rejeição de token para playlist errada."""
        token = create_playlist_token(
            playlist_path="correct/playlist.m3u8",
            user_id=str(uuid.uuid4()),
        )
        
        with pytest.raises(ValueError, match="não autorizado"):
            validate_playlist_token(token, "wrong/playlist.m3u8")

    def test_token_type_mismatch(self):
        """Testa rejeição de tipo de token incorreto."""
        media_id = str(uuid.uuid4())
        stream_token = create_stream_token(
            media_id=media_id,
            user_id=str(uuid.uuid4()),
        )
        
        with pytest.raises(ValueError, match="não é do tipo playlist"):
            validate_playlist_token(stream_token, "any/playlist.m3u8")
