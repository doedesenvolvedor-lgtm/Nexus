"""
Serviço de integração com TMDb (The Movie Database).

Fornece funcionalidades para:
- Buscar filmes e séries por título
- Obter detalhes completos (sinopse, capas, banners, trailers, elenco)
- Importar metadados automaticamente para o catálogo
- Preencher informações faltantes em conteúdos existentes
"""

import logging
from typing import Any, Optional

import httpx

from app.config import TMDB_API_KEY, TMDB_BASE_URL, TMDB_IMAGE_BASE_URL, TMDB_LANGUAGE

logger = logging.getLogger(__name__)

DEFAULT_TIMEOUT = 10.0  # segundos


def _is_configured() -> bool:
    return bool(TMDB_API_KEY)


def _image_url(path: Optional[str], size: str = "original") -> Optional[str]:
    """Converte um path de imagem do TMDb em URL completa."""
    if not path:
        return None
    return f"{TMDB_IMAGE_BASE_URL}/{size}{path}"


def _safe_get(media: dict, *keys: str, default: Any = None) -> Any:
    """Acessa dict aninhado com segurança."""
    current = media
    for key in keys:
        if not isinstance(current, dict) or key not in current:
            return default
        current = current[key]
    return current


async def search_movies(query: str, page: int = 1) -> list[dict]:
    """Busca filmes por título no TMDb."""
    if not _is_configured():
        logger.warning("TMDB_API_KEY não configurada. Busca de filmes desabilitada.")
        return []

    try:
        async with httpx.AsyncClient(timeout=DEFAULT_TIMEOUT) as client:
            response = await client.get(
                f"{TMDB_BASE_URL}/search/movie",
                params={
                    "api_key": TMDB_API_KEY,
                    "query": query,
                    "language": TMDB_LANGUAGE,
                    "page": page,
                    "include_adult": "false",
                },
            )
            response.raise_for_status()
            data = response.json()
            return data.get("results", [])
    except Exception as exc:
        logger.error(f"Erro ao buscar filmes no TMDb: {exc}")
        return []


async def search_series(query: str, page: int = 1) -> list[dict]:
    """Busca séries por título no TMDb."""
    if not _is_configured():
        logger.warning("TMDB_API_KEY não configurada. Busca de séries desabilitada.")
        return []

    try:
        async with httpx.AsyncClient(timeout=DEFAULT_TIMEOUT) as client:
            response = await client.get(
                f"{TMDB_BASE_URL}/search/tv",
                params={
                    "api_key": TMDB_API_KEY,
                    "query": query,
                    "language": TMDB_LANGUAGE,
                    "page": page,
                    "include_adult": "false",
                },
            )
            response.raise_for_status()
            data = response.json()
            return data.get("results", [])
    except Exception as exc:
        logger.error(f"Erro ao buscar séries no TMDb: {exc}")
        return []


async def search_all(query: str, page: int = 1) -> dict:
    """Busca filmes e séries simultaneamente."""
    movies = await search_movies(query, page)
    series = await search_series(query, page)
    return {
        "movies": movies,
        "series": series,
        "total": len(movies) + len(series),
    }


async def get_movie_details(tmdb_id: int) -> Optional[dict]:
    """Obtém detalhes completos de um filme."""
    if not _is_configured():
        return None

    try:
        async with httpx.AsyncClient(timeout=DEFAULT_TIMEOUT) as client:
            response = await client.get(
                f"{TMDB_BASE_URL}/movie/{tmdb_id}",
                params={
                    "api_key": TMDB_API_KEY,
                    "language": TMDB_LANGUAGE,
                    "append_to_response": "videos,credits,images",
                },
            )
            response.raise_for_status()
            return response.json()
    except Exception as exc:
        logger.error(f"Erro ao obter detalhes do filme {tmdb_id}: {exc}")
        return None


async def get_series_details(tmdb_id: int) -> Optional[dict]:
    """Obtém detalhes completos de uma série."""
    if not _is_configured():
        return None

    try:
        async with httpx.AsyncClient(timeout=DEFAULT_TIMEOUT) as client:
            response = await client.get(
                f"{TMDB_BASE_URL}/tv/{tmdb_id}",
                params={
                    "api_key": TMDB_API_KEY,
                    "language": TMDB_LANGUAGE,
                    "append_to_response": "videos,credits,images",
                },
            )
            response.raise_for_status()
            return response.json()
    except Exception as exc:
        logger.error(f"Erro ao obter detalhes da série {tmdb_id}: {exc}")
        return None


def _get_trailer_url(videos: Any) -> Optional[str]:
    """Extrai URL do trailer (YouTube) dos dados de vídeos."""
    if not isinstance(videos, dict):
        return None
    results = videos.get("results", [])
    for video in results:
        if video.get("type") == "Trailer" and video.get("site") == "YouTube":
            key = video.get("key")
            if key:
                return f"https://www.youtube.com/watch?v={key}"
    # Fallback: primeiro vídeo disponível
    for video in results:
        key = video.get("key")
        if key and video.get("site") == "YouTube":
            return f"https://www.youtube.com/watch?v={key}"
    return None


def _map_genre(genres: list) -> Optional[str]:
    """Converte lista de gêneros do TMDb em string única."""
    if not genres:
        return None
    names = [g.get("name", "") for g in genres if isinstance(g, dict)]
    return ", ".join(names) if names else None


def _extract_common_fields(data: dict, content_type: str) -> dict:
    """Extrai campos comuns entre filme e série."""
    overview = data.get("overview") or ""
    if len(overview) < 10:
        overview = overview or "Sinopse não disponível no momento."

    videos = data.get("videos") or {}
    trailer_url = _get_trailer_url(videos)

    return {
        "title": data.get("name") or data.get("title") or "Título desconhecido",
        "description": overview,
        "content_type": content_type,
        "genre": _map_genre(data.get("genres")) or "Diversos",
        "release_year": (
            data.get("release_date") or data.get("first_air_date") or ""
        )[:4] or None,
        "rating": None,  # rating é classificação indicativa, não nota TMDb
        "thumbnail_url": _image_url(data.get("poster_path"), "w500"),
        "banner_url": _image_url(data.get("backdrop_path"), "w1280"),
        "trailer_url": trailer_url,
        "tlmb_rating": data.get("vote_average"),
        "tmdb_id": data.get("id"),
        "imdb_id": data.get("imdb_id"),
    }


async def map_movie_to_media(tmdb_data: dict) -> dict:
    """Converte dados do TMDb em payload compatível com MediaContent."""
    fields = _extract_common_fields(tmdb_data, "movie")

    # Duração (minutos → segundos)
    runtime = tmdb_data.get("runtime") or 0
    fields["duration"] = runtime * 60 if runtime else None

    # Classificação indicativa (adult → R, senão L)
    fields["rating"] = "R" if tmdb_data.get("adult") else "L"

    return fields


async def map_series_to_media(tmdb_data: dict) -> dict:
    """Converte dados do TMDb em payload compatível com MediaContent."""
    fields = _extract_common_fields(tmdb_data, "series")

    # Duração média de episódio (minutos → segundos)
    episode_runtime = tmdb_data.get("episode_run_time") or []
    avg_runtime = sum(episode_runtime) / len(episode_runtime) if episode_runtime else 0
    fields["duration"] = int(avg_runtime * 60) if avg_runtime else None

    fields["rating"] = "L"
    return fields


async def fetch_movie_media_payload(tmdb_id: int) -> Optional[dict]:
    """Busca filme do TMDb e retorna payload para MediaContent."""
    data = await get_movie_details(tmdb_id)
    if data is None:
        return None
    return await map_movie_to_media(data)


async def fetch_series_media_payload(tmdb_id: int) -> Optional[dict]:
    """Busca série do TMDb e retorna payload para MediaContent."""
    data = await get_series_details(tmdb_id)
    if data is None:
        return None
    return await map_series_to_media(data)


async def get_movie_watch_providers(tmdb_id: int) -> list[dict]:
    """Obtém provedores de streaming disponíveis para o filme (para o Brasil)."""
    if not _is_configured():
        return []

    try:
        async with httpx.AsyncClient(timeout=DEFAULT_TIMEOUT) as client:
            response = await client.get(
                f"{TMDB_BASE_URL}/movie/{tmdb_id}/watch/providers",
                params={"api_key": TMDB_API_KEY},
            )
            response.raise_for_status()
            data = response.json()
            results = data.get("results", {})
            br_data = results.get("BR") or results.get("US") or {}
            return br_data.get("flatrate", [])
    except Exception as exc:
        logger.error(f"Erro ao obter provedores do filme {tmdb_id}: {exc}")
        return []


async def get_popular_movies(page: int = 1) -> list[dict]:
    """Retorna filmes populares do momento."""
    if not _is_configured():
        return []

    try:
        async with httpx.AsyncClient(timeout=DEFAULT_TIMEOUT) as client:
            response = await client.get(
                f"{TMDB_BASE_URL}/movie/popular",
                params={
                    "api_key": TMDB_API_KEY,
                    "language": TMDB_LANGUAGE,
                    "page": page,
                },
            )
            response.raise_for_status()
            return response.json().get("results", [])
    except Exception as exc:
        logger.error(f"Erro ao buscar filmes populares: {exc}")
        return []


async def get_popular_series(page: int = 1) -> list[dict]:
    """Retorna séries populares do momento."""
    if not _is_configured():
        return []

    try:
        async with httpx.AsyncClient(timeout=DEFAULT_TIMEOUT) as client:
            response = await client.get(
                f"{TMDB_BASE_URL}/tv/popular",
                params={
                    "api_key": TMDB_API_KEY,
                    "language": TMDB_LANGUAGE,
                    "page": page,
                },
            )
            response.raise_for_status()
            return response.json().get("results", [])
    except Exception as exc:
        logger.error(f"Erro ao buscar séries populares: {exc}")
        return []


def get_health_status() -> dict:
    """Retorna status da integração TMDb."""
    return {
        "configured": _is_configured(),
        "base_url": TMDB_BASE_URL,
        "image_base_url": TMDB_IMAGE_BASE_URL,
        "language": TMDB_LANGUAGE,
        "message": "TMDb API key configurada" if _is_configured() else "TMDB_API_KEY não configurada",
    }
