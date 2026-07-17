"""
Middleware de Rate Limiting.
Aplica proteção contra DDoS e abuse em múltiplos níveis.
"""

from fastapi import Request, status
from fastapi.responses import JSONResponse
from app.services.rate_limit_service import rate_limit_service


class RateLimitMiddleware:
    """
    Middleware que aplica rate limiting baseado em:
    1. IP global
    2. Tipo de endpoint (login, streams, APIs, etc)
    3. Usuário autenticado (se logado)
    """
    
    def __init__(self, app):
        self.app = app
    
    async def __call__(self, request: Request, call_next):
        # Extrair IP do cliente
        client_ip = self._get_client_ip(request)
        endpoint = request.url.path
        
        # Rotas que não aplicam rate limit
        if self._should_skip_rate_limit(endpoint):
            return await call_next(request)
        
        # ==================== VERIFICAÇÃO 1: LIMITE GLOBAL ====================
        allowed, info = rate_limit_service.check_global_limit(client_ip)
        if not allowed:
            return self._rate_limit_response(
                info,
                "Limite global de requisições atingido (1000/hora por IP)",
            )
        
        # ==================== VERIFICAÇÃO 2: LIMITE POR ENDPOINT ====================
        allowed, info = rate_limit_service.check_endpoint_limit(client_ip, endpoint)
        if not allowed:
            limit_type = self._get_limit_type(endpoint)
            messages = {
                "login": "Muitas tentativas de login. Tente novamente em 15 minutos.",
                "streams": "Muitos requests de streaming. Limite: 100 req/min",
                "payment": "Limite de requisições de pagamento atingido.",
                "admin": "Limite de admin atingido.",
                "api": "Limite de API atingido.",
            }
            return self._rate_limit_response(
                info,
                messages.get(limit_type, "Limite de requisições atingido"),
            )
        
        # ==================== VERIFICAÇÃO 3: LIMITE POR USUÁRIO ====================
        # Se usuário autenticado, verificar limite específico do usuário
        user_id = self._extract_user_id(request)
        if user_id:
            limit_type = self._get_limit_type(endpoint)
            allowed, info = rate_limit_service.check_user_limit(user_id, limit_type)
            if not allowed:
                return self._rate_limit_response(
                    info,
                    f"Limite de {limit_type} por usuário atingido",
                )
        
        # Processar requisição normalmente
        response = await call_next(request)
        
        # Adicionar headers de rate limit na resposta
        if user_id:
            _, info = rate_limit_service.check_user_limit(user_id, "api")
        else:
            _, info = rate_limit_service.check_global_limit(client_ip)
        
        response.headers["X-RateLimit-Limit"] = str(info.get("limit", ""))
        response.headers["X-RateLimit-Remaining"] = str(info.get("remaining", ""))
        response.headers["X-RateLimit-Reset"] = str(info.get("reset_in", ""))
        
        return response
    
    # ==================== MÉTODOS AUXILIARES ====================
    
    @staticmethod
    def _get_client_ip(request: Request) -> str:
        """Extrai IP real do cliente."""
        # Verificar headers de proxy
        if x_forwarded_for := request.headers.get("X-Forwarded-For"):
            # Pega o primeiro IP (cliente real)
            return x_forwarded_for.split(",")[0].strip()
        
        if x_real_ip := request.headers.get("X-Real-IP"):
            return x_real_ip
        
        # Fallback para conexão direta
        return request.client.host if request.client else "unknown"
    
    @staticmethod
    def _extract_user_id(request: Request) -> str | None:
        """Extrai user_id do JWT token."""
        try:
            auth_header = request.headers.get("authorization", "")
            if not auth_header.startswith("Bearer "):
                return None
            
            token = auth_header.replace("Bearer ", "")
            
            # Decode JWT (simplificado - use library completa em produção)
            from app.security import decode_token
            payload = decode_token(token)
            return payload.get("sub")
        except Exception:
            return None
    
    @staticmethod
    def _should_skip_rate_limit(endpoint: str) -> bool:
        """Retorna True se endpoint não deve aplicar rate limit."""
        skip_paths = [
            "/health",
            "/metrics",
            "/.well-known",
            "/static",
            "/docs",
            "/redoc",
            "/openapi.json",
        ]
        
        for path in skip_paths:
            if endpoint.startswith(path):
                return True
        
        return False
    
    @staticmethod
    def _get_limit_type(endpoint: str) -> str:
        """Determina tipo de limite baseado no endpoint."""
        if "/auth/login" in endpoint:
            return "login"
        elif "/streams" in endpoint:
            return "streams"
        elif "/payment" in endpoint:
            return "payment"
        elif "/admin" in endpoint:
            return "admin"
        else:
            return "api"
    
    @staticmethod
    def _rate_limit_response(info: dict, message: str) -> JSONResponse:
        """Retorna resposta 429 com rate limit headers."""
        return JSONResponse(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            content={
                "detail": message,
                "limit": info.get("limit"),
                "remaining": info.get("remaining"),
                "reset_in": info.get("reset_in"),
                "retry_after": info.get("retry_after"),
            },
            headers={
                "X-RateLimit-Limit": str(info.get("limit", "")),
                "X-RateLimit-Remaining": str(info.get("remaining", "")),
                "X-RateLimit-Reset": str(info.get("reset_in", "")),
                "Retry-After": str(info.get("retry_after", "")),
            },
        )
