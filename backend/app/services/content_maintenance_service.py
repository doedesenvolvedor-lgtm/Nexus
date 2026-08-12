"""
Serviço de manutenção de conteúdo.

Responsável por:
- Atualização automática dos conteúdos via TMDb
- Remoção de links inválidos (M3U8/streams)
- Verificação de disponibilidade de playlists
- Estatísticas de conteúdo
"""
import asyncio
import logging
from datetime import datetime, timezone
from pathlib import Path
from typing import Optional

import httpx
import redis
from sqlalchemy.orm import Session

from app.config import CONTENT_MAINTENANCE_INTERVAL, LIVE_CHANNEL_REFRESH_INTERVAL, LIVE_CHANNELS_CACHE_TTL, REDIS_URL
from app.database import SessionLocal
from app.models import Episode, LiveChannel, M3U8Playlist, MediaContent
from app.services.tmdb_service import get_popular_movies, map_movie_to_media

logger = logging.getLogger(__name__)


class ContentMaintenanceService:
    """Serviço de manutenção automática de conteúdo."""

    def __init__(self):
        self._redis = None

    @property
    def redis_client(self) -> Optional[redis.Redis]:
        if self._redis is None:
            try:
                self._redis = redis.Redis.from_url(REDIS_URL, decode_responses=True, socket_connect_timeout=2, socket_timeout=2)
                self._redis.ping()
            except Exception:
                self._redis = None
                logger.warning("Redis não disponível para manutenção de conteúdo")
        return self._redis

    # ===== Atualização Automática de Conteúdo =====

    def update_streaming_links(self, db: Session) -> dict:
        """
        Verifica a disponibilidade dos links de streaming (M3U8/TS).
        Remove ou marca como inválidos links que não respondem.
        """
        stats = {
            "checked": 0,
            "valid": 0,
            "invalid": 0,
            "removed": 0,
        }

        # Verificar MediaContent
        media_items = db.query(MediaContent).filter(MediaContent.video_url.isnot(None)).all()
        for media in media_items:
            stats["checked"] += 1
            if self._check_stream_url(media.video_url):
                stats["valid"] += 1
            else:
                stats["invalid"] += 1
                # Marcar conteúdo sem stream válido
                media.video_url = None
                stats["removed"] += 1

        # Verificar Episódios
        episodes = db.query(Episode).filter(Episode.video_url.isnot(None)).all()
        for episode in episodes:
            stats["checked"] += 1
            if self._check_stream_url(episode.video_url):
                stats["valid"] += 1
            else:
                stats["invalid"] += 1
                episode.video_url = None
                stats["removed"] += 1

        db.commit()
        return stats

    def _check_stream_url(self, url: str, timeout: float = 5.0) -> bool:
        """
        Verifica se uma URL de stream responde corretamente.
        Suporta URLs http/https e caminhos locais.
        """
        if not url:
            return False

        # Caminho local (arquivo)
        if not url.startswith(("http://", "https://")):
            path = Path(url.replace("/streams/", "storage/streams/"))
            return path.exists()

        try:
            with httpx.Client(timeout=timeout, follow_redirects=True) as client:
                # HEAD request primeiro (mais leve)
                try:
                    response = client.head(url)
                except httpx.HTTPStatusError:
                    return False
                except Exception:
                    # Fallback para GET se HEAD não suportado
                    response = client.get(url, headers={"Range": "bytes=0-1024"})

                if response.status_code >= 400:
                    return False

                # Verificar se é conteúdo de vídeo
                content_type = response.headers.get("content-type", "")
                if content_type:
                    return any(t in content_type for t in ["video", "mpegurl", "mp2t", "octet-stream", "m4v"])
                return True
        except Exception as exc:
            logger.debug(f"Falha ao verificar URL {url}: {exc}")
            return False

    def check_channel_availability(self, db: Session, channel_id: Optional[str] = None) -> dict:
        """
        Verifica a disponibilidade dos canais ao vivo.
        """
        stats = {"checked": 0, "valid": 0, "invalid": 0, "disabled": 0}

        query = db.query(LiveChannel).filter(LiveChannel.is_active.is_(True))
        if channel_id:
            query = query.filter(LiveChannel.id == channel_id)

        channels = query.all()
        for channel in channels:
            stats["checked"] += 1
            valid = self._check_stream_url(channel.url)
            channel.is_verified = valid
            channel.last_checked_at = datetime.now(timezone.utc)

            if valid:
                stats["valid"] += 1
            else:
                stats["invalid"] += 1
                channel.is_active = False
                stats["disabled"] += 1

        db.commit()
        return stats

    # ===== Atualização Automática via TMDb =====

    async def auto_update_from_tmdb(self, db: Session, limit: int = 20) -> dict:
        """
        Busca conteúdos populares do TMDb e atualiza o catálogo.
        """
        stats = {"fetched": 0, "updated": 0, "created": 0, "errors": 0}

        try:
            # Filmes populares (API async do tmdb_service)
            raw_movies = await get_popular_movies(page=1)
            movies = raw_movies[:limit]

            for raw in movies:
                try:
                    # Converter dados TMDb para payload MediaContent
                    movie = await map_movie_to_media(raw)

                    title = movie.get("title", "Título desconhecido")
                    existing = db.query(MediaContent).filter(
                        MediaContent.title == title,
                        MediaContent.content_type == "movie",
                    ).first()

                    if existing:
                        existing.description = movie.get("description") or existing.description
                        existing.release_year = movie.get("release_year") or existing.release_year
                        existing.thumbnail_url = movie.get("thumbnail_url") or existing.thumbnail_url
                        existing.banner_url = movie.get("banner_url") or existing.banner_url
                        stats["updated"] += 1
                    else:
                        db.add(MediaContent(
                            title=title,
                            description=movie.get("description"),
                            content_type="movie",
                            genre=movie.get("genre"),
                            release_year=movie.get("release_year"),
                            thumbnail_url=movie.get("thumbnail_url"),
                            banner_url=movie.get("banner_url"),
                            trailer_url=movie.get("trailer_url"),
                            video_url=None,
                        ))
                        stats["created"] += 1
                    stats["fetched"] += 1
                except Exception as exc:
                    logger.error(f"Erro ao processar filme TMDb: {exc}")
                    stats["errors"] += 1

            db.commit()
        except Exception as exc:
            logger.error(f"Erro na atualização automática TMDb: {exc}")
            db.rollback()

        return stats

    def auto_update_playlists(self, db: Session) -> dict:
        """
        Atualiza playlists M3U8 cadastradas e refaz o import.
        """
        stats = {"checked": 0, "updated": 0, "failed": 0}

        playlists = db.query(M3U8Playlist).filter(M3U8Playlist.status == "active").all()
        for playlist in playlists:
            stats["checked"] += 1
            try:
                self._refresh_playlist(db, playlist)
                stats["updated"] += 1
            except Exception as exc:
                logger.error(f"Falha ao atualizar playlist {playlist.name}: {exc}")
                playlist.status = "error"
                stats["failed"] += 1

        db.commit()
        return stats

    def _refresh_playlist(self, db: Session, playlist: M3U8Playlist) -> None:
        """Atualiza os canais de uma playlist."""
        if not playlist.source_url:
            return

        try:
            response = httpx.get(playlist.source_url, timeout=10)
            response.raise_for_status()
            content = response.text
        except Exception as exc:
            raise RuntimeError(f"Não foi possível baixar playlist: {exc}")

        # Parse básico M3U8 (EXTINF + URL)
        lines = content.strip().splitlines()
        channels = []
        current_name = None

        for line in lines:
            line = line.strip()
            if line.startswith("#EXTINF"):
                # Tentar extrair nome
                if "," in line:
                    current_name = line.rsplit(",", 1)[1].strip()
                else:
                    current_name = None
            elif line and not line.startswith("#"):
                # URL do canal
                channels.append({
                    "name": current_name or f"Canal {len(channels) + 1}",
                    "url": line,
                })
                current_name = None

        # Atualizar canais existentes / criar novos
        existing_urls = {c.url for c in playlist.channels}
        new_urls = {c["url"] for c in channels}

        # Remover canais que não existem mais
        for channel in list(playlist.channels):
            if channel.url not in new_urls:
                channel.is_active = False

        # Criar novos canais
        for channel_data in channels:
            if channel_data["url"] not in existing_urls:
                db.add(LiveChannel(
                    name=channel_data["name"],
                    url=channel_data["url"],
                    source="m3u8_import",
                    m3u8_playlist_id=playlist.id,
                    is_active=True,
                    is_verified=False,
                ))

        playlist.total_channels = len(channels)
        playlist.valid_channels = len(channels)
        playlist.invalid_channels = 0
        playlist.last_import_at = datetime.now(timezone.utc)

    # ===== Estatísticas de Conteúdo =====

    def get_content_stats(self, db: Session) -> dict:
        """Retorna estatísticas de conteúdo para o dashboard."""
        total_media = db.query(MediaContent).count()
        total_movies = db.query(MediaContent).filter(MediaContent.content_type == "movie").count()
        total_series = db.query(MediaContent).filter(MediaContent.content_type == "series").count()
        total_channels = db.query(LiveChannel).count()
        active_channels = db.query(LiveChannel).filter(LiveChannel.is_active.is_(True)).count()
        total_playlists = db.query(M3U8Playlist).count()
        invalid_links = db.query(MediaContent).filter(MediaContent.video_url.is_(None)).count()

        return {
            "media": {
                "total": total_media,
                "movies": total_movies,
                "series": total_series,
                "invalid_links": invalid_links,
            },
            "live_tv": {
                "total_channels": total_channels,
                "active_channels": active_channels,
                "inactive_channels": total_channels - active_channels,
                "playlists": total_playlists,
            },
            "maintenance": {
                "interval_seconds": CONTENT_MAINTENANCE_INTERVAL,
                "channel_refresh_seconds": LIVE_CHANNEL_REFRESH_INTERVAL,
                "last_run": None,
            },
        }

    async def run_maintenance_cycle(self) -> dict:
        """
        Executa ciclo completo de manutenção.
        Chamado pelo worker periódico.
        """
        db = SessionLocal()
        results = {}
        try:
            results["stream_links"] = self.update_streaming_links(db)
            results["channel_availability"] = self.check_channel_availability(db)
            results["playlists"] = self.auto_update_playlists(db)
            results["tmdb_update"] = await self.auto_update_from_tmdb(db, limit=10)
            return results
        finally:
            db.close()


# ===== Funções utilitárias (compatibilidade) =====


def cleanup_invalid_streams():
    """Função de compatibilidade para o worker."""
    service = ContentMaintenanceService()
    db = SessionLocal()
    try:
        return service.update_streaming_links(db)
    finally:
        db.close()


def validate_and_cleanup_channels():
    """Função de compatibilidade para o worker."""
    service = ContentMaintenanceService()
    db = SessionLocal()
    try:
        return service.check_channel_availability(db)
    finally:
        db.close()


def update_content_from_tmdb():
    """Função síncrona de compatibilidade para o worker."""
    service = ContentMaintenanceService()
    db = SessionLocal()
    try:
        return asyncio.run(service.auto_update_from_tmdb(db))
    finally:
        db.close()
