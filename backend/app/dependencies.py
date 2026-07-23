"""
Dependencias para autenticacao e autorizacao.
Inclui get_optional_user para endpoints que aceitam usuarios nao logados.
"""

from typing import Optional

from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from jose import JWTError
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import User
from app.security import decode_token
from app.services.auth_session_service import is_session_active

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/login", auto_error=False)


def get_current_token_payload(token: str = Depends(oauth2_scheme)):
    try:
        return decode_token(token)
    except JWTError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token invalido ou expirado.",
        )


def get_current_user(token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)):
    if token is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token de autenticacao necessario.",
        )
    try:
        payload = decode_token(token)
        user_id = payload.get("sub")
        if not user_id:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Token invalido.",
            )

        jti = payload.get("jti")
        if jti and not is_session_active(str(user_id), str(jti)):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Sessao expirada ou revogada.",
            )

        user = db.query(User).filter(User.id == user_id).first()
        if user is None:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Usuario nao encontrado para o token informado.",
            )
        return user
    except JWTError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token invalido ou expirado.",
        )


def get_optional_user(
    token: Optional[str] = Depends(oauth2_scheme),
    db: Session = Depends(get_db),
) -> Optional[User]:
    """
    Dependencia que tenta extrair usuario do token, mas nao falha se nao houver token.
    Usado para endpoints que podem ser acessados publicamente mas com recursos extras
    para usuarios autenticados (ex: catalogo com recomendacoes personalizadas).
    """
    if token is None:
        return None
    try:
        payload = decode_token(token)
        user_id = payload.get("sub")
        if not user_id:
            return None

        jti = payload.get("jti")
        if jti and not is_session_active(str(user_id), str(jti)):
            return None

        user = db.query(User).filter(User.id == user_id).first()
        return user
    except JWTError:
        return None
