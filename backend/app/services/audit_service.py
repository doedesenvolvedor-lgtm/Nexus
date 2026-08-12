"""
Serviço de auditoria administrativa.

Responsável por registrar e consultar logs de ações administrativas.
"""

import logging
from typing import Optional
from uuid import UUID

from fastapi import Request
from sqlalchemy import func
from sqlalchemy.orm import Session

from app.models import AdminAuditLog, User

logger = logging.getLogger(__name__)


def log_admin_action(
    db: Session,
    admin_user: User,
    action: str,
    resource_type: str,
    resource_id: Optional[str] = None,
    details: Optional[dict] = None,
    request: Optional[Request] = None,
    status: str = "success",
    error_message: Optional[str] = None,
) -> AdminAuditLog:
    """
    Registra uma ação administrativa no log de auditoria.

    Args:
        db: Sessão do banco de dados
        admin_user: Usuário admin que executou a ação
        action: Nome da ação (ex: create_media, delete_user)
        resource_type: Tipo do recurso afetado (ex: media, user, payment)
        resource_id: ID do recurso (string, pode ser UUID ou str)
        details: Detalhes adicionais em JSON serializável
        request: Objeto Request para extrair IP e User-Agent
        status: Status da ação (success, failure, denied)
        error_message: Mensagem de erro se status == failure
    """
    ip_address = None
    user_agent = None

    if request is not None:
        ip_address = request.client.host if request.client else None
        user_agent = request.headers.get("user-agent")

    resource_uuid = None
    if resource_id is not None:
        try:
            resource_uuid = UUID(str(resource_id))
        except (ValueError, AttributeError):
            resource_uuid = None

    resource_details = dict(details or {})
    if error_message:
        resource_details["error"] = error_message

    log_entry = AdminAuditLog(
        admin_user_id=admin_user.id,
        admin_email=getattr(admin_user, "email", None),
        action=action,
        resource_type=resource_type,
        resource_id=resource_uuid,
        details=resource_details,
        ip_address=ip_address,
        user_agent=user_agent,
        status=status,
    )

    db.add(log_entry)
    db.commit()
    db.refresh(log_entry)

    logger.info(
        "Admin action: %s on %s by %s (status=%s)",
        action,
        resource_type,
        admin_user.email if admin_user else "unknown",
        status,
    )

    return log_entry


def log_admin_action_sync(
    db: Session,
    admin_user: User,
    action: str,
    resource_type: str,
    resource_id: Optional[str] = None,
    details: Optional[dict] = None,
    request: Optional[Request] = None,
    status: str = "success",
    error_message: Optional[str] = None,
) -> AdminAuditLog:
    """Alias síncrono para log_admin_action (por compatibilidade)."""
    return log_admin_action(
        db=db,
        admin_user=admin_user,
        action=action,
        resource_type=resource_type,
        resource_id=resource_id,
        details=details,
        request=request,
        status=status,
        error_message=error_message,
    )


def get_audit_logs(
    db: Session,
    page: int = 1,
    limit: int = 50,
    action: Optional[str] = None,
    resource_type: Optional[str] = None,
    admin_email: Optional[str] = None,
    status: Optional[str] = None,
) -> dict:
    """
    Consulta logs de auditoria com filtros e paginação.

    Returns:
        {"data": [...], "total": int, "page": int, "limit": int}
    """
    query = db.query(AdminAuditLog).order_by(AdminAuditLog.created_at.desc())

    if action:
        query = query.filter(AdminAuditLog.action == action)
    if resource_type:
        query = query.filter(AdminAuditLog.resource_type == resource_type)
    if admin_email:
        query = query.filter(AdminAuditLog.admin_email.ilike(f"%{admin_email}%"))
    if status:
        query = query.filter(AdminAuditLog.status == status)

    total = query.count()
    rows = query.offset((page - 1) * limit).limit(limit).all()

    data = [
        {
            "id": str(row.id),
            "admin_email": row.admin_email,
            "action": row.action,
            "resource_type": row.resource_type,
            "resource_id": str(row.resource_id) if row.resource_id else None,
            "details": row.details,
            "ip_address": row.ip_address,
            "user_agent": row.user_agent,
            "status": row.status,
            "created_at": row.created_at,
        }
        for row in rows
    ]

    return {
        "data": data,
        "total": total,
        "page": page,
        "limit": limit,
    }


def get_audit_log_actions(db: Session) -> list[str]:
    """Lista todas as ações distintas registradas."""
    rows = db.query(AdminAuditLog.action).distinct().all()
    return [row[0] for row in rows]


def get_audit_stats(db: Session) -> dict:
    """Retorna estatísticas gerais de auditoria."""
    total = db.query(AdminAuditLog).count()
    success = db.query(AdminAuditLog).filter(AdminAuditLog.status == "success").count()
    failure = db.query(AdminAuditLog).filter(AdminAuditLog.status == "failure").count()
    denied = db.query(AdminAuditLog).filter(AdminAuditLog.status == "denied").count()

    unique_admins = db.query(func.count(func.distinct(AdminAuditLog.admin_email))).scalar() or 0

    # Ações mais comuns
    top_actions_rows = (
        db.query(AdminAuditLog.action, func.count(AdminAuditLog.id).label("count"))
        .group_by(AdminAuditLog.action)
        .order_by(func.count(AdminAuditLog.id).desc())
        .limit(10)
        .all()
    )

    return {
        "total_logs": total,
        "success": success,
        "failure": failure,
        "denied": denied,
        "unique_admins": unique_admins,
        "top_actions": [{"action": action, "count": count} for action, count in top_actions_rows],
    }
