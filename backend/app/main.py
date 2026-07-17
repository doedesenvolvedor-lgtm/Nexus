from pathlib import Path
import logging

from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles
from prometheus_client import generate_latest

from app.database import Base, engine
from app.logging_config import setup_logging
from app.metrics import PrometheusMiddleware
from app.middleware.stream_auth import StreamAuthMiddleware
from app.middleware.rate_limit import RateLimitMiddleware
from app.routers import admin, auth, episodes, history, media, notifications, payments, profiles, queue_jobs, ratings, recommendations, subscriptions, subscriptions_trial, watchlist, webhooks

# Configura logging
setup_logging()
logger = logging.getLogger(__name__)

app = FastAPI(
    title="Nexus Twos",
    version="1.0",
)

# Adiciona middlewares (última adição = primeira execução)
app.add_middleware(StreamAuthMiddleware)        # 3º: Valida tokens de stream
app.add_middleware(RateLimitMiddleware)         # 2º: Verifica rate limits
app.add_middleware(PrometheusMiddleware)        # 1º: Coleta métricas

try:
    Base.metadata.create_all(bind=engine)
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
app.include_router(admin.router, prefix="/admin")
app.include_router(queue_jobs.router)

streams_dir = Path("storage/streams")
streams_dir.mkdir(parents=True, exist_ok=True)
app.mount("/streams", StaticFiles(directory=str(streams_dir)), name="streams")


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
    return generate_latest()
