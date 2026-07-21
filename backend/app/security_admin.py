from fastapi import Depends, HTTPException, status
from app.config import ADMIN_EMAILS
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

    user_role = getattr(current_user, "role", None)
    user_email = (current_user.email or "").strip().lower()
    is_allowed_email = user_email in ADMIN_EMAILS
    is_admin_role = user_role == "admin"

    if not (is_admin_role or is_allowed_email):
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

    user_role = getattr(current_user, "role", None)
    user_email = (current_user.email or "").strip().lower()
    is_allowed_email = user_email in ADMIN_EMAILS

    if user_role not in ("admin", "moderator") and not is_allowed_email:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Acesso negado. Apenas moderadores podem acessar este recurso.",
        )

    return current_user
