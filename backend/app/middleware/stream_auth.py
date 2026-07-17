"""
Middleware para autenticação de streams.
Valida tokens JWT antes de servir conteúdo de streaming.
"""

from fastapi import Request, HTTPException, status
from fastapi.responses import JSONResponse
from jose import JWTError

from app.services.stream_token_service import validate_playlist_token, validate_stream_token


class StreamAuthMiddleware:
    """
    Middleware que valida tokens de streaming.
    
    Procura por token em:
    1. Query parameter: ?token=<jwt>
    2. Header Authorization: Bearer <jwt>
    3. Header X-Stream-Token: <jwt>
    """
    
    def __init__(self, app):
        self.app = app
    
    async def __call__(self, request: Request, call_next):
        # Apenas validar rotas de stream
        if not request.url.path.startswith("/streams"):
            return await call_next(request)
        
        # Skip para diretórios, apenas validar arquivos
        if not request.url.path.split("/")[-1]:  # Termina em /
            return await call_next(request)
        
        # Extrair token
        token = self._extract_token(request)
        
        if not token:
            return JSONResponse(
                status_code=status.HTTP_401_UNAUTHORIZED,
                content={"detail": "Token de streaming ausente"},
            )
        
        # Validar token
        try:
            playlist_path = request.url.path.replace("/streams/", "")
            validate_playlist_token(token, playlist_path)
        except (JWTError, ValueError) as e:
            return JSONResponse(
                status_code=status.HTTP_403_FORBIDDEN,
                content={"detail": f"Token inválido: {str(e)}"},
            )
        
        return await call_next(request)
    
    @staticmethod
    def _extract_token(request: Request) -> str | None:
        """Extrai token do request em ordem de precedência."""
        
        # 1. Query parameter
        if token := request.query_params.get("token"):
            return token
        
        # 2. Authorization header (Bearer scheme)
        if auth_header := request.headers.get("authorization"):
            parts = auth_header.split()
            if len(parts) == 2 and parts[0].lower() == "bearer":
                return parts[1]
        
        # 3. Custom X-Stream-Token header
        if token := request.headers.get("x-stream-token"):
            return token
        
        return None
