"""
Exception handlers para a aplicação FastAPI.
Centraliza o tratamento de erros e retorna respostas consistentes.
"""

import logging
from fastapi import FastAPI, Request, status
from fastapi.responses import JSONResponse
from pydantic import ValidationError
from sqlalchemy.exc import SQLAlchemyError
from jose import JWTError

logger = logging.getLogger(__name__)


class APIError(Exception):
    """Base exception para erros da API."""
    
    def __init__(
        self, 
        message: str, 
        status_code: int = status.HTTP_400_BAD_REQUEST,
        error_code: str = "INVALID_REQUEST"
    ):
        self.message = message
        self.status_code = status_code
        self.error_code = error_code
        super().__init__(self.message)


class AuthenticationError(APIError):
    """Erro de autenticação."""
    def __init__(self, message: str = "Não autenticado"):
        super().__init__(
            message=message,
            status_code=status.HTTP_401_UNAUTHORIZED,
            error_code="AUTHENTICATION_ERROR"
        )


class AuthorizationError(APIError):
    """Erro de autorização."""
    def __init__(self, message: str = "Acesso negado"):
        super().__init__(
            message=message,
            status_code=status.HTTP_403_FORBIDDEN,
            error_code="AUTHORIZATION_ERROR"
        )


class NotFoundError(APIError):
    """Erro de recurso não encontrado."""
    def __init__(self, resource: str = "Recurso"):
        super().__init__(
            message=f"{resource} não encontrado",
            status_code=status.HTTP_404_NOT_FOUND,
            error_code="NOT_FOUND"
        )


class ConflictError(APIError):
    """Erro de conflito (ex: email já existe)."""
    def __init__(self, message: str = "Recurso já existe"):
        super().__init__(
            message=message,
            status_code=status.HTTP_409_CONFLICT,
            error_code="CONFLICT"
        )


def register_exception_handlers(app: FastAPI):
    """Registra todos os exception handlers na aplicação."""
    
    @app.exception_handler(APIError)
    async def api_error_handler(request: Request, exc: APIError):
        """Handler para erros customizados da API."""
        logger.warning(
            f"API Error: {exc.error_code} - {exc.message}",
            extra={"path": request.url.path, "status_code": exc.status_code}
        )
        return JSONResponse(
            status_code=exc.status_code,
            content={
                "error": exc.error_code,
                "message": exc.message,
                "status_code": exc.status_code,
            },
        )
    
    @app.exception_handler(ValidationError)
    async def validation_error_handler(request: Request, exc: ValidationError):
        """Handler para erros de validação Pydantic."""
        logger.warning(
            f"Validation Error: {exc}",
            extra={"path": request.url.path}
        )
        return JSONResponse(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            content={
                "error": "VALIDATION_ERROR",
                "message": "Dados inválidos",
                "details": exc.errors(),
                "status_code": status.HTTP_422_UNPROCESSABLE_ENTITY,
            },
        )
    
    @app.exception_handler(JWTError)
    async def jwt_error_handler(request: Request, exc: JWTError):
        """Handler para erros de JWT."""
        logger.warning(
            f"JWT Error: {str(exc)}",
            extra={"path": request.url.path}
        )
        return JSONResponse(
            status_code=status.HTTP_401_UNAUTHORIZED,
            content={
                "error": "INVALID_TOKEN",
                "message": "Token inválido ou expirado",
                "status_code": status.HTTP_401_UNAUTHORIZED,
            },
        )
    
    @app.exception_handler(SQLAlchemyError)
    async def database_error_handler(request: Request, exc: SQLAlchemyError):
        """Handler para erros de banco de dados."""
        logger.error(
            f"Database Error: {str(exc)}",
            extra={"path": request.url.path},
            exc_info=True
        )
        return JSONResponse(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            content={
                "error": "DATABASE_ERROR",
                "message": "Erro ao processar requisição",
                "status_code": status.HTTP_500_INTERNAL_SERVER_ERROR,
            },
        )
    
    @app.exception_handler(Exception)
    async def general_error_handler(request: Request, exc: Exception):
        """Handler genérico para erros não tratados."""
        logger.error(
            f"Unhandled Exception: {str(exc)}",
            extra={"path": request.url.path},
            exc_info=True
        )
        return JSONResponse(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            content={
                "error": "INTERNAL_SERVER_ERROR",
                "message": "Erro interno do servidor",
                "status_code": status.HTTP_500_INTERNAL_SERVER_ERROR,
            },
        )
