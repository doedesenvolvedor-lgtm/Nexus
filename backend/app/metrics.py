from prometheus_client import Counter, Histogram, Gauge
from fastapi import Request
from time import time
import logging

logger = logging.getLogger(__name__)

# Métricas para requisições HTTP
http_requests_total = Counter(
    'http_requests_total',
    'Total de requisições HTTP',
    ['method', 'endpoint', 'status_code'],
)

http_request_duration_seconds = Histogram(
    'http_request_duration_seconds',
    'Duração das requisições HTTP em segundos',
    ['method', 'endpoint'],
    buckets=(0.1, 0.5, 1.0, 2.5, 5.0, 10.0)
)

# Métricas para usuários
active_users = Gauge(
    'active_users_total',
    'Número total de usuários ativos',
)

authenticated_requests = Counter(
    'authenticated_requests_total',
    'Total de requisições autenticadas',
    ['endpoint'],
)

# Métricas para banco de dados
db_query_duration_seconds = Histogram(
    'db_query_duration_seconds',
    'Duração das queries do banco de dados em segundos',
    ['query_type'],
    buckets=(0.01, 0.05, 0.1, 0.5, 1.0)
)

db_connection_errors = Counter(
    'db_connection_errors_total',
    'Total de erros de conexão com o banco de dados',
)

# Métricas para cache (Redis)
redis_operations = Counter(
    'redis_operations_total',
    'Total de operações no Redis',
    ['operation', 'status'],
)

redis_operation_duration_seconds = Histogram(
    'redis_operation_duration_seconds',
    'Duração das operações do Redis em segundos',
    ['operation'],
    buckets=(0.001, 0.01, 0.05, 0.1, 0.5)
)

# Métricas para pagamentos
payment_attempts = Counter(
    'payment_attempts_total',
    'Total de tentativas de pagamento',
    ['status', 'method'],
)

payment_amount = Counter(
    'payment_amount_total',
    'Quantidade total de pagamentos processados',
    ['currency', 'status'],
)

# Métricas para autenticação
login_attempts = Counter(
    'login_attempts_total',
    'Total de tentativas de login',
    ['status'],
)

# Métricas para erros
api_errors = Counter(
    'api_errors_total',
    'Total de erros da API',
    ['error_type', 'endpoint'],
)

# Métricas de negócio
media_imports = Counter(
    'media_imports_total',
    'Total de importações de mídia',
    ['status'],
)

tmdb_sync_operations = Counter(
    'tmdb_sync_operations_total',
    'Total de sincronizações com TMDb',
    ['status'],
)


class PrometheusMiddleware:
    """Middleware para coletar métricas do Prometheus."""

    def __init__(self, app):
        self.app = app

    async def __call__(self, scope, receive, send):
        if scope["type"] != "http":
            await self.app(scope, receive, send)
            return

        # Skip para endpoints de métricas
        if scope["path"] == "/metrics":
            await self.app(scope, receive, send)
            return

        request = Request(scope)
        start_time = time()
        status_code = 500

        async def send_wrapper(message):
            nonlocal status_code
            if message["type"] == "http.response.start":
                status_code = message["status"]
            await send(message)

        try:
            await self.app(scope, receive, send_wrapper)
        finally:
            # Registra a métrica
            duration = time() - start_time
            method = scope["method"]
            endpoint = scope["path"]
            
            http_requests_total.labels(
                method=method,
                endpoint=endpoint,
                status_code=status_code,
            ).inc()

            http_request_duration_seconds.labels(
                method=method,
                endpoint=endpoint,
            ).observe(duration)

            # Log de requisição
            logger.info(
                f"{method} {endpoint} - {status_code} - {duration:.3f}s"
            )
