from fastapi import Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.database import get_db
from app.dependencies import get_current_user
from app.models import User


def get_admin_user(current_user: User = Depends(get_current_user)):
    """
    Verifica se o usuário atual é um administrador.
    Valida o campo `role` na tabela users.
    
    Roles disponíveis:
    - 'admin': Acesso total ao sistema
    - 'moderator': Acesso limitado para moderar conteúdo
    - 'user': Usuário comum (sem privilégios administrativos)
    """
    if current_user is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Usuário não autenticado",
        )

    if current_user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Acesso negado. Apenas administradores podem acessar este recurso.",
        )

    return current_user


def get_moderator_user(current_user: User = Depends(get_current_user)):
    """
    Verifica se o usuário é moderador ou admin.
    """
    if current_user is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Usuário não autenticado",
        )

    if current_user.role not in ("admin", "moderator"):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Acesso negado. Apenas moderadores podem acessar este recurso.",
        )

    return current_user

