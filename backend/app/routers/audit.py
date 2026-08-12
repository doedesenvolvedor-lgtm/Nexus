"""
Router de auditoria administrativa.

Endpoints para consulta de logs de ações administrativas.
"""

import logging
from typing import Optional

from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import User
from app.security_admin import get_admin_user
from app.services import audit_service

logger = logging.getLogger(__name__)

router = APIRouter(
    prefix="/admin/audit",
    tags=["Admin Audit Logs"],
    dependencies=[Depends(get_admin_user)],
)


@router.get("/logs")
def list_audit_logs(
    page: int = Query(default=1, ge=1),
    limit: int = Query(default=50, ge=1, le=100),
    action: Optional[str] = Query(default=None),
    resource_type: Optional[str] = Query(default=None),
    admin_email: Optional[str] = Query(default=None),
    status: Optional[str] = Query(default=None, pattern=r"^(success|failure|denied)$"),
    db: Session = Depends(get_db),
):
    """
    Lista logs de auditoria com filtros.
    
    - page: Página (1-indexed)
    - limit: Itens por página (máx 100)
    - action: Filtrar por ação (ex: create_media)
    - resource_type: Filtrar por tipo (ex: media, user, payment)
    - admin_email: Filtrar por admin
    - status: Filtrar por status
    """
    return audit_service.get_audit_logs(
        db,
        page=page,
        limit=limit,
        action=action,
        resource_type=resource_type,
        admin_email=admin_email,
        status=status,
    )


@router.get("/actions")
def list_actions(db: Session = Depends(get_db)):
    """Lista ações distintas registradas na auditoria."""
    actions = audit_service.get_audit_log_actions(db)
    return {"actions": actions}


@router.get("/stats")
def audit_stats(db: Session = Depends(get_db)):
    """Retorna estatísticas de auditoria."""
    return audit_service.get_audit_stats(db)


@router.get("/export")
def export_audit_logs(
    format: str = Query(default="json", pattern=r"^(json)$"),
    db: Session = Depends(get_db),
):
    """Exporta todos os logs de auditoria (JSON)."""
    from datetime import datetime

    result = audit_service.get_audit_logs(db, page=1, limit=10000)
    return {
        "exported_at": str(datetime.now()),
        "count": result["total"],
        "data": result["data"],
    }
