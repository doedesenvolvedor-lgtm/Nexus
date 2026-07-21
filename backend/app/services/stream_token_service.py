"""
Serviço para gerar e validar tokens JWT para streaming de vídeos.
Tokens com expiração curta (60 minutos) vinculados a um média específico.
"""

from datetime import datetime, timedelta, timezone
from jose import JWTError, jwt

from app.config import ALGORITHM, SECRET_KEY
from app.security import _ensure_security_config


def create_stream_token(media_id: str, user_id: str, expires_in_minutes: int = 60) -> str:
    """
    Cria um JWT token para streaming de vídeo.
    
    Args:
        media_id: ID do média a ser assistido
        user_id: ID do usuário fazendo requisição
        expires_in_minutes: Tempo de expiração em minutos (padrão 60)
    
    Returns:
        JWT token string
    """
    _ensure_security_config()
    payload = {
        "media_id": str(media_id),
        "user_id": str(user_id),
        "type": "stream",
        "exp": datetime.now(timezone.utc) + timedelta(minutes=expires_in_minutes),
    }
    return jwt.encode(payload, SECRET_KEY, algorithm=ALGORITHM)


def validate_stream_token(token: str, media_id: str) -> dict:
    """
    Valida um token de streaming e verifica se é para o média correto.
    
    Args:
        token: JWT token a validar
        media_id: ID do média sendo acessado
    
    Returns:
        Dict com payload do token se válido
    
    Raises:
        JWTError: Se token inválido ou expirado
        ValueError: Se token não for para o média solicitado
    """
    _ensure_security_config()
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
    except JWTError as e:
        raise JWTError("Token inválido ou expirado") from e
    
    if payload.get("type") != "stream":
        raise ValueError("Token não é do tipo stream")
    
    if payload.get("media_id") != str(media_id):
        raise ValueError("Token não autorizado para este conteúdo")
    
    return payload


def create_playlist_token(playlist_path: str, user_id: str, expires_in_minutes: int = 60) -> str:
    """
    Cria um token específico para acesso a playlist M3U8.
    
    Args:
        playlist_path: Caminho da playlist (ex: "uuid/master.m3u8")
        user_id: ID do usuário
        expires_in_minutes: Expiração em minutos
    
    Returns:
        JWT token string
    """
    _ensure_security_config()
    payload = {
        "playlist": playlist_path,
        "user_id": str(user_id),
        "type": "playlist",
        "exp": datetime.now(timezone.utc) + timedelta(minutes=expires_in_minutes),
    }
    return jwt.encode(payload, SECRET_KEY, algorithm=ALGORITHM)


def validate_playlist_token(token: str, playlist_path: str) -> dict:
    """
    Valida acesso a uma playlist específica.
    
    Args:
        token: JWT token
        playlist_path: Caminho da playlist sendo acessada
    
    Returns:
        Payload do token se válido
    
    Raises:
        JWTError/ValueError se inválido
    """
    _ensure_security_config()
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
    except JWTError as e:
        raise JWTError("Token inválido ou expirado") from e
    
    if payload.get("type") != "playlist":
        raise ValueError("Token não é do tipo playlist")
    
    if payload.get("playlist") != playlist_path:
        raise ValueError("Token não autorizado para esta playlist")
    
    return payload
