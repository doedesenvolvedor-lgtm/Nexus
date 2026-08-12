"""
Router de gerenciamento de playlists M3U8.

Permite:
- Importar playlists M3U/M3U8 (URL ou texto)
- Listar/gerenciar playlists importadas
- Verificar validade dos canais (links de stream)
- Remover canais inválidos
- Atualizar playlists automaticamente
"""

import logging
import re
from datetime import datetime, timezone
from typing import Optional
from uuid import UUID

import httpx
from fastapi import APIRouter, Depends, File, HTTPException, Query, UploadFile
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import LiveChannel, M3U8Playlist, User
from app.security_admin import get_admin_user
from app.schemas import (
    LiveChannelCreate,
    LiveChannelResponse,
    LiveChannelUpdate,
    M3U8PlaylistCreate,
    M3U8PlaylistResponse,
)

logger = logging.getLogger(__name__)

router = APIRouter(
    prefix="/admin/m3u8",
    tags=["M3U8 Playlist Management"],
    dependencies=[Depends(get_admin_user)],
)

DEFAULT_REQUEST_TIMEOUT = 15.0  # segundos
MAX_PLAYLIST_SIZE = 5 * 1024 * 1024  # 5MB


# ==================== UTILITÁRIOS ====================

def _parse_m3u_content(content: str) -> list[dict]:
    """
    Parse de conteúdo M3U/M3U8.
    Suporta EXTINF, EXTVLCOPT, logo, group-title e URLs.
    
    Retorna lista de canais: {name, url, logo_url, category}
    """
    channels = []
    lines = content.splitlines()

    current_name = None
    current_logo = None
    current_category = None

    for line in lines:
        line = line.strip()

        if not line:
            continue

        # Atributos EXTINF: http-log, group-title, tvg-logo, etc.
        if line.upper().startswith("#EXTINF"):
            parts = line.split(":", 1)
            if len(parts) < 2:
                continue
            attrs_str = parts[1]

            # Extrair tvg-logo="URL"
            logo_match = re.search(r'tvg-logo="([^"]*)"', attrs_str)
            if logo_match:
                current_logo = logo_match.group(1)

            # Extrair group-title="CATEGORIA"
            cat_match = re.search(r'group-title="([^"]*)"', attrs_str)
            if cat_match:
                current_category = cat_match.group(1)

            # Extrair nome do canal (após último vírgula)
            name_match = re.search(r',\s*(.+)$', attrs_str)
            if name_match:
                current_name = name_match.group(1).strip()
            continue

        # Ignorar outros metadados
        if line.startswith("#"):
            continue

        # Linha de URL do stream
        if current_name or line.startswith("http"):
            name = current_name or line.split("/")[-1].split(".m3u8")[0].replace("_", " ").title()
            channels.append({
                "name": name,
                "url": line,
                "logo_url": current_logo,
                "category": current_category,
            })
            current_name = None
            current_logo = None
            current_category = None

    return channels


async def _fetch_url_content(url: str) -> Optional[str]:
    """Busca conteúdo de uma URL (playlist M3U8)."""
    try:
        async with httpx.AsyncClient(timeout=DEFAULT_REQUEST_TIMEOUT, follow_redirects=True) as client:
            response = await client.get(url, headers={"User-Agent": "NexusStreaming/1.0"})
            response.raise_for_status()
            return response.text
    except Exception as exc:
        logger.warning(f"Falha ao buscar URL {url}: {exc}")
        return None


async def _verify_stream_url(url: str) -> bool:
    """Verifica se uma URL de stream é válida (responde com 2xx)."""
    try:
        async with httpx.AsyncClient(timeout=10.0, follow_redirects=True) as client:
            response = await client.head(url, headers={"User-Agent": "NexusStreaming/1.0"})
            if response.status_code < 400:
                return True
            # Fallback para GET (alguns servidores não suportam HEAD)
            response = await client.get(url, headers={"User-Agent": "NexusStreaming/1.0"})
            return response.status_code < 400
    except Exception:
        return False


def _serialize_channel(channel: LiveChannel) -> dict:
    return {
        "id": str(channel.id),
        "name": channel.name,
        "url": channel.url,
        "logo_url": channel.logo_url,
        "category": channel.category,
        "description": channel.description,
        "is_active": channel.is_active,
        "is_verified": channel.is_verified,
        "source": channel.source,
        "last_checked_at": channel.last_checked_at.isoformat() if channel.last_checked_at else None,
        "added_at": channel.added_at.isoformat() if channel.added_at else None,
    }


# ==================== ENDPOINTS DE PLAYLISTS ====================

@router.post("/playlists", response_model=M3U8PlaylistResponse)
def create_playlist(
    payload: M3U8PlaylistCreate,
    db: Session = Depends(get_db),
):
    """Cria um registro de playlist M3U8 (importação posterior)."""
    playlist = M3U8Playlist(
        name=payload.name,
        source_url=payload.source_url,
        source_type=payload.source_type,
    )
    db.add(playlist)
    db.commit()
    db.refresh(playlist)
    return playlist


@router.get("/playlists", response_model=list[M3U8PlaylistResponse])
def list_playlists(db: Session = Depends(get_db)):
    """Lista todas as playlists importadas."""
    return db.query(M3U8Playlist).order_by(M3U8Playlist.created_at.desc()).all()


@router.get("/playlists/{playlist_id}", response_model=M3U8PlaylistResponse)
def get_playlist(playlist_id: UUID, db: Session = Depends(get_db)):
    """Obtém detalhes de uma playlist."""
    playlist = db.query(M3U8Playlist).filter(M3U8Playlist.id == playlist_id).first()
    if not playlist:
        raise HTTPException(status_code=404, detail="Playlist não encontrada.")
    return playlist


@router.post("/playlists/{playlist_id}/import")
async def import_playlist(
    playlist_id: UUID,
    db: Session = Depends(get_db),
):
    """
    Importa canais de uma playlist M3U8 existente (por URL armazenada).
    Endpoint: /admin/m3u8/playlists/{id}/import
    """
    playlist = db.query(M3U8Playlist).filter(M3U8Playlist.id == playlist_id).first()
    if not playlist:
        raise HTTPException(status_code=404, detail="Playlist não encontrada.")

    if not playlist.source_url:
        raise HTTPException(status_code=400, detail="Playlist não possui source_url para importação.")

    content = await _fetch_url_content(playlist.source_url)
    if content is None:
        raise HTTPException(status_code=502, detail="Falha ao buscar conteúdo da playlist URL.")

    channels_data = _parse_m3u_content(content)
    if not channels_data:
        raise HTTPException(status_code=400, detail="Nenhum canal encontrado na playlist.")

    # Importar canais
    total = 0
    for data in channels_data:
        # Evitar duplicatas (mesma URL já existente e pertencente a esta playlist)
        existing = (
            db.query(LiveChannel)
            .filter(
                LiveChannel.url == data["url"],
                LiveChannel.m3u8_playlist_id == playlist_id,
            )
            .first()
        )
        if existing:
            continue

        channel = LiveChannel(
            name=data["name"],
            url=data["url"],
            logo_url=data.get("logo_url"),
            category=data.get("category"),
            source="m3u8_import",
            m3u8_playlist_id=playlist_id,
        )
        db.add(channel)
        total += 1

    # Atualizar estatísticas da playlist
    playlist.total_channels = db.query(LiveChannel).filter(
        LiveChannel.m3u8_playlist_id == playlist_id
    ).count()
    playlist.last_import_at = datetime.now(timezone.utc)

    db.commit()

    return {
        "message": f"Playlist importada com sucesso.",
        "imported": total,
        "total_channels": playlist.total_channels,
        "playlist_id": str(playlist_id),
    }


@router.post("/import-url")
async def import_from_url(
    name: str = Query(..., min_length=1, max_length=255),
    url: str = Query(..., min_length=5, max_length=2000),
    db: Session = Depends(get_db),
):
    """Importa canais diretamente de uma URL de playlist M3U8."""
    content = await _fetch_url_content(url)
    if content is None:
        raise HTTPException(status_code=502, detail="Falha ao buscar conteúdo da URL.")

    channels_data = _parse_m3u_content(content)
    if not channels_data:
        raise HTTPException(status_code=400, detail="Nenhum canal encontrado na URL.")

    # Criar playlist
    playlist = M3U8Playlist(
        name=name,
        source_url=url,
        source_type="url",
        total_channels=0,
        last_import_at=datetime.now(timezone.utc),
    )
    db.add(playlist)
    db.flush()  # obter ID

    # Importar canais
    imported = 0
    for data in channels_data:
        channel = LiveChannel(
            name=data["name"],
            url=data["url"],
            logo_url=data.get("logo_url"),
            category=data.get("category"),
            source="m3u8_import",
            m3u8_playlist_id=playlist.id,
        )
        db.add(channel)
        imported += 1

    playlist.total_channels = imported
    db.commit()

    return {
        "message": f"Playlist '{name}' importada com {imported} canais.",
        "playlist_id": str(playlist.id),
        "imported": imported,
    }


@router.post("/import-file")
async def import_from_file(
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
):
    """Importa canais de um arquivo M3U/M3U8 enviado."""
    content_bytes = await file.read(MAX_PLAYLIST_SIZE + 1)
    if len(content_bytes) > MAX_PLAYLIST_SIZE:
        raise HTTPException(status_code=413, detail="Arquivo muito grande (máx 5MB).")

    content = content_bytes.decode("utf-8", errors="replace")
    channels_data = _parse_m3u_content(content)
    if not channels_data:
        raise HTTPException(status_code=400, detail="Nenhum canal encontrado no arquivo.")

    playlist_name = file.filename or "playlist_importada"
    playlist = M3U8Playlist(
        name=playlist_name,
        source_type="file",
        total_channels=0,
        last_import_at=datetime.now(timezone.utc),
    )
    db.add(playlist)
    db.flush()

    imported = 0
    for data in channels_data:
        channel = LiveChannel(
            name=data["name"],
            url=data["url"],
            logo_url=data.get("logo_url"),
            category=data.get("category"),
            source="m3u8_import",
            m3u8_playlist_id=playlist.id,
        )
        db.add(channel)
        imported += 1

    playlist.total_channels = imported
    db.commit()

    return {
        "message": f"Arquivo '{playlist_name}' importado com {imported} canais.",
        "playlist_id": str(playlist.id),
        "imported": imported,
    }


@router.delete("/playlists/{playlist_id}")
def delete_playlist(playlist_id: UUID, db: Session = Depends(get_db)):
    """Remove uma playlist e todos os seus canais."""
    playlist = db.query(M3U8Playlist).filter(M3U8Playlist.id == playlist_id).first()
    if not playlist:
        raise HTTPException(status_code=404, detail="Playlist não encontrada.")

    deleted_channels = db.query(LiveChannel).filter(
        LiveChannel.m3u8_playlist_id == playlist_id
    ).count()

    db.delete(playlist)
    db.commit()

    return {
        "message": f"Playlist removida. {deleted_channels} canais deletados.",
        "deleted_channels": deleted_channels,
    }


# ==================== ENDPOINTS DE CANAIS ====================

@router.get("/channels", response_model=list[LiveChannelResponse])
def list_channels(
    search: Optional[str] = Query(default=None, min_length=1),
    category: Optional[str] = Query(default=None),
    active_only: bool = Query(default=False),
    db: Session = Depends(get_db),
):
    """Lista canais com filtros opcionais."""
    query = db.query(LiveChannel).order_by(LiveChannel.name)

    if search:
        query = query.filter(LiveChannel.name.ilike(f"%{search}%"))
    if category:
        query = query.filter(LiveChannel.category == category)
    if active_only:
        query = query.filter(LiveChannel.is_active.is_(True))

    return query.all()


@router.get("/channels/categories")
def list_categories(db: Session = Depends(get_db)):
    """Retorna todas as categorias de canais disponíveis."""
    rows = db.query(LiveChannel.category).distinct().filter(
        LiveChannel.category.isnot(None)
    ).all()
    categories = [row[0] for row in rows if row[0]]
    return {"categories": sorted(categories)}


@router.get("/channels/{channel_id}", response_model=LiveChannelResponse)
def get_channel(channel_id: UUID, db: Session = Depends(get_db)):
    """Obtém detalhes de um canal."""
    channel = db.query(LiveChannel).filter(LiveChannel.id == channel_id).first()
    if not channel:
        raise HTTPException(status_code=404, detail="Canal não encontrado.")
    return channel


@router.post("/channels", response_model=LiveChannelResponse)
def create_channel(
    payload: LiveChannelCreate,
    db: Session = Depends(get_db),
):
    """Cria um canal manualmente."""
    # Verificar duplicidade por URL
    existing = db.query(LiveChannel).filter(LiveChannel.url == payload.url).first()
    if existing:
        raise HTTPException(status_code=409, detail="Já existe um canal com esta URL.")

    channel = LiveChannel(**payload.model_dump())
    db.add(channel)
    db.commit()
    db.refresh(channel)
    return channel


@router.put("/channels/{channel_id}", response_model=LiveChannelResponse)
def update_channel(
    channel_id: UUID,
    payload: LiveChannelUpdate,
    db: Session = Depends(get_db),
):
    """Atualiza um canal existente."""
    channel = db.query(LiveChannel).filter(LiveChannel.id == channel_id).first()
    if not channel:
        raise HTTPException(status_code=404, detail="Canal não encontrado.")

    for field, value in payload.model_dump(exclude_unset=True).items():
        setattr(channel, field, value)

    channel.updated_at = datetime.now(timezone.utc)
    db.commit()
    db.refresh(channel)
    return channel


@router.delete("/channels/{channel_id}")
def delete_channel(channel_id: UUID, db: Session = Depends(get_db)):
    """Remove um canal."""
    channel = db.query(LiveChannel).filter(LiveChannel.id == channel_id).first()
    if not channel:
        raise HTTPException(status_code=404, detail="Canal não encontrado.")
    db.delete(channel)
    db.commit()
    return {"message": "Canal removido."}


@router.post("/channels/{channel_id}/verify")
async def verify_channel(channel_id: UUID, db: Session = Depends(get_db)):
    """Verifica se a URL do canal é válida (responde com 2xx)."""
    channel = db.query(LiveChannel).filter(LiveChannel.id == channel_id).first()
    if not channel:
        raise HTTPException(status_code=404, detail="Canal não encontrado.")

    is_valid = await _verify_stream_url(channel.url)
    channel.is_verified = is_valid
    channel.is_active = is_valid
    channel.last_checked_at = datetime.now(timezone.utc)
    db.commit()

    return {
        "channel_id": str(channel_id),
        "is_valid": is_valid,
        "status": "active" if is_valid else "inactive",
    }


@router.post("/verify-all")
async def verify_all_channels(db: Session = Depends(get_db)):
    """Verifica a validade de todos os canais ativos."""
    channels = db.query(LiveChannel).filter(LiveChannel.is_active.is_(True)).all()
    valid = 0
    invalid = 0

    for channel in channels:
        is_valid = await _verify_stream_url(channel.url)
        channel.is_verified = is_valid
        channel.is_active = is_valid
        channel.last_checked_at = datetime.now(timezone.utc)
        if is_valid:
            valid += 1
        else:
            invalid += 1

    db.commit()

    return {
        "message": f"Verificação concluída. {valid} válidos, {invalid} inválidos.",
        "total": len(channels),
        "valid": valid,
        "invalid": invalid,
    }


@router.post("/channels/{channel_id}/refresh")
async def refresh_channel(channel_id: UUID, db: Session = Depends(get_db)):
    """Atualiza a URL de um canal a partir da playlist original."""
    channel = db.query(LiveChannel).filter(LiveChannel.id == channel_id).first()
    if not channel:
        raise HTTPException(status_code=404, detail="Canal não encontrado.")

    if channel.source != "m3u8_import" or not channel.m3u8_playlist_id:
        raise HTTPException(status_code=400, detail="Canal não é proveniente de uma playlist M3U8.")

    playlist = db.query(M3U8Playlist).filter(M3U8Playlist.id == channel.m3u8_playlist_id).first()
    if not playlist or not playlist.source_url:
        raise HTTPException(status_code=400, detail="Playlist de origem não encontrada.")

    content = await _fetch_url_content(playlist.source_url)
    if content is None:
        raise HTTPException(status_code=502, detail="Falha ao buscar playlist de origem.")

    channels_data = _parse_m3u_content(content)
    current_url = channel.url

    # Procurar canal pelo nome
    updated = False
    for data in channels_data:
        if data["name"].strip().lower() == channel.name.strip().lower():
            if data["url"] != current_url:
                channel.url = data["url"]
                channel.last_checked_at = datetime.now(timezone.utc)
                updated = True
            break

    db.commit()

    return {
        "message": "Canal atualizado." if updated else "Canal já está atualizado.",
        "channel_id": str(channel_id),
        "updated": updated,
        "url": channel.url,
    }


@router.post("/remove-invalid")
async def remove_invalid_channels(db: Session = Depends(get_db)):
    """Remove todos os canais inválidos (URLs não verificadas)."""
    invalid_channels = db.query(LiveChannel).filter(LiveChannel.is_active.is_(False)).all()
    count = len(invalid_channels)

    for channel in invalid_channels:
        db.delete(channel)

    db.commit()

    return {
        "message": f"{count} canais inválidos removidos.",
        "removed": count,
    }
