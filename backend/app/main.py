from pathlib import Path
import logging
import uuid

from fastapi import FastAPI
from fastapi.responses import Response
from fastapi.staticfiles import StaticFiles
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.trustedhost import TrustedHostMiddleware
from prometheus_client import CONTENT_TYPE_LATEST, generate_latest
from sqlalchemy import text

from app.database import Base, engine
from app.database import SessionLocal
from app.logging_config import setup_logging
from app.config import FRONTEND_URL, ADMIN_FRONTEND_URL, SECRET_KEY
from app.exception_handlers import register_exception_handlers
from app.metrics import PrometheusMiddleware
from app.middleware.stream_auth import StreamAuthMiddleware
from app.middleware.rate_limit import RateLimitMiddleware
from app.services.admin_bootstrap_service import enforce_non_billing_premium_accounts
from app.routers import admin, auth, downloads, episodes, history, media, notifications, payments, profiles, queue_jobs, ratings, recommendations, subscriptions, subscriptions_trial, watchlist, webhooks

# Configura logging
setup_logging()
logger = logging.getLogger(__name__)

# Validar SECRET_KEY na inicialização
if not SECRET_KEY:
    raise RuntimeError("SECRET_KEY não configurada. Defina a variável de ambiente SECRET_KEY antes de iniciar o servidor.")

app = FastAPI(
    title="Nexus Twos",
    version="2.0",
)

# ===== CORS Configuration =====
allowed_origins = [
    FRONTEND_URL,
    ADMIN_FRONTEND_URL,
    "http://localhost:3000",
    "http://localhost:5000",
    "http://localhost:8000",
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=[origin for origin in allowed_origins if origin],
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"],  # Métodos específicos, não wildcard
    allow_headers=["Authorization", "Content-Type", "X-Request-ID", "X-Idempotency-Key", "X-Stream-Token", "Accept"],  # Headers específicos
    max_age=3600,  # Cache preflight por 1 hora
)

# Registra exception handlers
register_exception_handlers(app)

# Adiciona middlewares
# NOTA: BaseHTTPMiddleware executa na ordem de adicao (FIFO)
# PrometheusMiddleware deve ser o PRIMEIRO a capturar metrics
# RateLimitMiddleware deve vir antes de StreamAuthMiddleware para proteger tambem streams
app.add_middleware(PrometheusMiddleware)
app.add_middleware(RateLimitMiddleware)
app.add_middleware(StreamAuthMiddleware)

try:
    Base.metadata.create_all(bind=engine)
    with engine.begin() as connection:
        connection.execute(
            text(
                "ALTER TABLE users "
                "ADD COLUMN IF NOT EXISTS role VARCHAR(20) DEFAULT 'user' NOT NULL"
            )
        )
        connection.execute(
            text("CREATE INDEX IF NOT EXISTS idx_users_role ON users(role)")
        )
    logger.info("Database tables initialized successfully")
except Exception as exc:  # pragma: no cover - defensive for local/dev environments
    logger.error(f"Warning: could not initialize database tables: {exc}")
    print(f"Warning: could not initialize database tables: {exc}")

app.include_router(auth.router, prefix="/auth")
app.include_router(media.router, prefix="/media")
app.include_router(profiles.router, prefix="/profiles")
app.include_router(history.router, prefix="/history")
app.include_router(episodes.router)
app.include_router(ratings.router, prefix="/ratings")
app.include_router(watchlist.router, prefix="/watchlist")
app.include_router(recommendations.router, prefix="/recommendations")
app.include_router(subscriptions.router, prefix="/subscription")
app.include_router(subscriptions_trial.router)
app.include_router(payments.router)
app.include_router(webhooks.router, prefix="/webhook")
app.include_router(notifications.router)
app.include_router(downloads.router)
app.include_router(admin.router, prefix="/admin")
app.include_router(queue_jobs.router)

streams_dir = Path("storage/streams")
streams_dir.mkdir(parents=True, exist_ok=True)
app.mount("/streams", StaticFiles(directory=str(streams_dir)), name="streams")

# Serve releases (APKs, etc)
releases_dir = Path("storage/releases")
releases_dir.mkdir(parents=True, exist_ok=True)
app.mount("/releases", StaticFiles(directory=str(releases_dir)), name="releases")


@app.on_event("startup")
def apply_admin_bootstrap():
    db = SessionLocal()
    try:
        updated_accounts = enforce_non_billing_premium_accounts(db)
        if updated_accounts:
            logger.info(
                "Applied non-billing premium admin bootstrap to %d account(s): %s",
                len(updated_accounts),
                ", ".join(updated_accounts),
            )
    finally:
        db.close()


@app.get("/")
def root():
    logger.info("Root endpoint accessed")
    return {
        "platform": "Nexus Twos",
        "status": "online",
        "version": "1.0",
    }


@app.get("/health")
def health():
    logger.debug("Health check performed")
    return {"status": "healthy"}


@app.get("/metrics")
def metrics():
    """Endpoint para Prometheus coletar métricas."""
    logger.debug("Metrics endpoint accessed")
    return Response(content=generate_latest(), media_type=CONTENT_TYPE_LATEST)
