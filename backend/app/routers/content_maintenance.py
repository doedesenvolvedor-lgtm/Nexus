"""
Router de manutenção de conteúdo.

Endpoints:
- GET /admin/content-maintenance/stats — Estatísticas de conteúdo
- POST /admin/content-maintenance/verify-streams — Verificar links de streaming
- POST /admin/content-maintenance/verify-channels — Verificar canais ao vivo
- POST /admin/content-maintenance/update-tmdb — Atualizar catálogo via TMDb
- POST /admin/content-maintenance/playlists/refresh — Atualizar playlists M3U8
- POST /admin/content-maintenance/run-cycle — Ciclo completo de manutenção
"""
import logging
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query, Request
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import User
from app.security_admin import get_admin_user
from app.services.audit_service import log_admin_action
from app.services.content_maintenance_service import ContentMaintenanceService

logger = logging.getLogger(__name__)

router = APIRouter(
    prefix="/admin/content-maintenance",
    tags=["Content Maintenance"],
    dependencies=[Depends(get_admin_user)],
)


def _get_service() -> ContentMaintenanceService:
    return ContentMaintenanceService()


@router.get("/stats")
def content_stats(
    db: Session = Depends(get_db),
    _: User = Depends(get_admin_user),
):
    """Retorna estatísticas de conteúdo para dashboard."""
    try:
        service = _get_service()
        return service.get_content_stats(db)
    except Exception as exc:
        logger.exception("Erro ao obter estatísticas de conteúdo")
        raise HTTPException(status_code=500, detail="Erro ao obter estatísticas de conteúdo") from exc


@router.post("/verify-streams")
def verify_streams(
    request: Request,
    db: Session = Depends(get_db),
    current_admin: User = Depends(get_admin_user),
):
    """Verifica todos os links de streaming e remove inválidos."""
    try:
        service = _get_service()
        results = service.update_streaming_links(db)

        log_admin_action(
            db=db,
            admin_user=current_admin,
            action="verify_streams",
            resource_type="media",
            details=results,
            request=request,
            status="success",
        )

        return {
            "message": "Verificação de streams concluída",
            "results": results,
        }
    except Exception as exc:
        logger.exception("Erro ao verificar streams")
        raise HTTPException(status_code=500, detail="Erro ao verificar streams") from exc


@router.post("/verify-channels")
def verify_channels(
    request: Request,
    db: Session = Depends(get_db),
    channel_id: Optional[str] = Query(None, description="ID do canal específico"),
    current_admin: User = Depends(get_admin_user),
):
    """Verifica disponibilidade dos canais ao vivo."""
    try:
        service = _get_service()
        results = service.check_channel_availability(db, channel_id=channel_id)

        log_admin_action(
            db=db,
            admin_user=current_admin,
            action="verify_channels",
            resource_type="live_channel",
            resource_id=channel_id,
            details=results,
            request=request,
            status="success",
        )

        return {
            "message": "Verificação de canais concluída",
            "results": results,
        }
    except Exception as exc:
        logger.exception("Erro ao verificar canais")
        raise HTTPException(status_code=500, detail="Erro ao verificar canais") from exc


@router.post("/update-tmdb")
async def update_from_tmdb(
    request: Request,
    db: Session = Depends(get_db),
    limit: int = Query(20, ge=1, le=100, description="Quantidade de filmes a buscar"),
    current_admin: User = Depends(get_admin_user),
):
    """Atualiza o catálogo automaticamente a partir do TMDb."""
    try:
        service = _get_service()
        results = await service.auto_update_from_tmdb(db, limit=limit)

        log_admin_action(
            db=db,
            admin_user=current_admin,
            action="update_tmdb",
            resource_type="media",
            details=results,
            request=request,
            status="success",
        )

        return {
            "message": "Atualização via TMDb concluída",
            "results": results,
        }
    except Exception as exc:
        logger.exception("Erro ao atualizar via TMDb")
        raise HTTPException(status_code=500, detail="Erro ao atualizar via TMDb") from exc


@router.post("/playlists/refresh")
def refresh_playlists(
    request: Request,
    db: Session = Depends(get_db),
    current_admin: User = Depends(get_admin_user),
):
    """Atualiza todas as playlists M3U8 cadastradas."""
    try:
        service = _get_service()
        results = service.auto_update_playlists(db)

        log_admin_action(
            db=db,
            admin_user=current_admin,
            action="refresh_playlists",
            resource_type="m3u8_playlist",
            details=results,
            request=request,
            status="success",
        )

        return {
            "message": "Atualização de playlists concluída",
            "results": results,
        }
    except Exception as exc:
        logger.exception("Erro ao atualizar playlists")
        raise HTTPException(status_code=500, detail="Erro ao atualizar playlists") from exc


@router.post("/run-cycle")
async def run_full_cycle(
    request: Request,
    db: Session = Depends(get_db),
    current_admin: User = Depends(get_admin_user),
):
    """Executa ciclo completo de manutenção (streams, canais, playlists, TMDb)."""
    try:
        service = _get_service()
        results = await service.run_maintenance_cycle()

        log_admin_action(
            db=db,
            admin_user=current_admin,
            action="run_maintenance_cycle",
            resource_type="system",
            details={k: (v if isinstance(v, dict) else {"status": str(v)}) for k, v in results.items()},
            request=request,
            status="success",
        )

        return {
            "message": "Ciclo de manutenção concluído",
            "results": results,
        }
    except Exception as exc:
        logger.exception("Erro no ciclo de manutenção")
        raise HTTPException(status_code=500, detail="Erro no ciclo de manutenção") from exc
</｜｜DSML｜｜parameter>
</｜｜DSML｜｜invoke>
