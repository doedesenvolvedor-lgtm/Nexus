from fastapi import Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.database import get_db
from app.dependencies import get_current_user
from app.models import User

# Lista de emails de admin (você pode expandir isso com um campo no banco)
ADMIN_EMAILS = [
    "admin@nexus.com",
    "admin@example.com",
]


def get_admin_user(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    """
    Verifica se o usuário atual é um administrador.
    Retorna o usuário se for admin, lança exceção caso contrário.
    """
    if current_user is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Usuário não autenticado",
        )

    if current_user.email not in ADMIN_EMAILS:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Acesso negado. Apenas administradores podem acessar.",
        )

    return current_user


# Versão alternativa usando um campo no banco de dados (recomendado para produção)
def get_admin_user_from_db(current_user: User = Depends(get_current_user)):
    """
    Verifica permissão de admin consultando campo no banco.
    Para isso, adicionar campo `is_admin: bool` ao modelo User.
    """
    if current_user is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Usuário não autenticado",
        )

    # Quando implementar campo is_admin:
    # if not current_user.is_admin:
    #     raise HTTPException(...)

    return current_user
