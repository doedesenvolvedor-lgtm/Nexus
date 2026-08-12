"""
Router de integração com TMDb (The Movie Database).

Endpoints administrativos para:
- Buscar filmes e séries
- Obter detalhes completos
- Importar conteúdo para o catálogo
- Verificar status da integração
"""

import logging

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import MediaContent, User
from app.schemas import MediaResponse
from app.security_admin import get_admin_user
from app.services.cache_service import delete_by_prefix
from app.services import tmdb_service

logger = logging.getLogger(__name__)
router = APIRouter(
    prefix="/admin/tmdb",
    tags=["TMDb Integration"],
    dependencies=[Depends(get_admin_user)],
)


@router.get("/status")
def tmdb_status():
    """Retorna status da integração TMDb."""
    return tmdb_service.get_health_status()


@router.get("/search")
async def search(
    q: str = Query(..., min_length=2, description="Termo de busca"),
    type: str = Query(default="all", pattern=r"^(all|movie|series)$"),
    page: int = Query(default=1, ge=1),
):
    """Busca filmes e/ou séries no TMDb."""
    if type == "movie":
        results = await tmdb_service.search_movies(q, page)
        return {"query": q, "type": "movie", "page": page, "results": results}

    if type == "series":
        results = await tmdb_service.search_series(q, page)
        return {"query": q, "type": "series", "page": page, "results": results}

    return await tmdb_service.search_all(q, page)


@router.get("/movie/{tmdb_id}")
async def movie_details(tmdb_id: int):
    """Obtém detalhes completos de um filme do TMDb."""
    details = await tmdb_service.get_movie_details(tmdb_id)
    if details is None:
        raise HTTPException(status_code=404, detail="Filme não encontrado no TMDb.")
    return details


@router.get("/series/{tmdb_id}")
async def series_details(tmdb_id: int):
    """Obtém detalhes completos de uma série do TMDb."""
    details = await tmdb_service.get_series_details(tmdb_id)
    if details is None:
        raise HTTPException(status_code=404, detail="Série não encontrada no TMDb.")
    return details


@router.post("/movie/{tmdb_id}/import", response_model=MediaResponse)
async def import_movie(
    tmdb_id: int,
    db: Session = Depends(get_db),
    _: User = Depends(get_admin_user),
):
    """Importa um filme do TMDb para o catálogo."""
    payload = await tmdb_service.fetch_movie_media_payload(tmdb_id)
    if payload is None:
        raise HTTPException(
            status_code=404,
            detail="Não foi possível buscar o filme no TMDb. Verifique se a TMDB_API_KEY está configurada.",
        )

    # Verificar duplicidade por título + ano
    title = payload.get("title", "")
    year = payload.get("release_year")
    duplicate = (
        db.query(MediaContent)
        .filter(
            MediaContent.title == title,
            MediaContent.content_type == "movie",
        )
        .first()
    )
    if duplicate:
        raise HTTPException(
            status_code=409,
            detail=f"Filme '{title}' já existe no catálogo.",
        )

    # Preencher campos obrigatórios faltantes
    payload.setdefault("video_url", "")
    payload.setdefault("rating", "L")
    payload.setdefault("duration", 0)
    payload.setdefault("genre", "Diversos")

    media = MediaContent(**payload)
    db.add(media)
    db.commit()
    db.refresh(media)

    # Invalidar cache
    delete_by_prefix("media:")
    delete_by_prefix("recommendations:")

    return media


@router.post("/series/{tmdb_id}/import", response_model=MediaResponse)
async def import_series(
    tmdb_id: int,
    db: Session = Depends(get_db),
    _: User = Depends(get_admin_user),
):
    """Importa uma série do TMDb para o catálogo."""
    payload = await tmdb_service.fetch_series_media_payload(tmdb_id)
    if payload is None:
        raise HTTPException(
            status_code=404,
            detail="Não foi possível buscar a série no TMDb. Verifique se a TMDB_API_KEY está configurada.",
        )

    title = payload.get("title", "")
    duplicate = (
        db.query(MediaContent)
        .filter(
            MediaContent.title == title,
            MediaContent.content_type == "series",
        )
        .first()
    )
    if duplicate:
        raise HTTPException(
            status_code=409,
            detail=f"Série '{title}' já existe no catálogo.",
        )

    payload.setdefault("video_url", "")
    payload.setdefault("rating", "L")
    payload.setdefault("duration", 0)
    payload.setdefault("genre", "Diversos")

    media = MediaContent(**payload)
    db.add(media)
    db.commit()
    db.refresh(media)

    delete_by_prefix("media:")
    delete_by_prefix("recommendations:")

    return media


@router.get("/popular")
async def popular(
    type: str = Query(default="all", pattern=r"^(all|movie|series)$"),
    page: int = Query(default=1, ge=1),
):
    """Retorna conteúdo popular do TMDb."""
    if type == "movie":
        return await tmdb_service.get_popular_movies(page)
    if type == "series":
        return await tmdb_service.get_popular_series(page)
    movies = await tmdb_service.get_popular_movies(page)
    series = await tmdb_service.get_popular_series(page)
    return {"movies": movies, "series": series}
