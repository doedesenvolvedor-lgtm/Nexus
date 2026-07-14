from pathlib import Path

from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles

from app.database import Base, engine
from app.routers import admin, auth, episodes, history, media, notifications, payments, profiles, queue_jobs, ratings, recommendations, subscriptions, subscriptions_trial, watchlist, webhooks

app = FastAPI(
    title="Nexus Streaming",
    version="1.0",
)

try:
    Base.metadata.create_all(bind=engine)
except Exception as exc:  # pragma: no cover - defensive for local/dev environments
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
    return {
        "platform": "Nexus Streaming",
        "status": "online",
        "version": "1.0",
    }


@app.get("/health")
def health():
    return {"status": "healthy"}
