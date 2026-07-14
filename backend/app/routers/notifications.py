from typing import Optional
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.database import get_db
from app.dependencies import get_current_user
from app.models import DeviceToken, User
from app.services.firebase_service import FirebaseService

router = APIRouter(prefix="/notifications", tags=["Notifications"])


class RegisterDeviceTokenRequest(BaseModel):
    device_token: str
    device_type: str  # ios, android
    device_name: Optional[str] = None


class DeviceTokenResponse(BaseModel):
    id: UUID
    device_token: str
    device_type: str
    device_name: Optional[str]
    is_active: bool

    class Config:
        from_attributes = True


@router.post("/device-token")
def register_device_token(
    request: RegisterDeviceTokenRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> dict:
    """Registra um novo token de dispositivo para notificações push"""

    if request.device_type not in ["ios", "android"]:
        raise HTTPException(status_code=400, detail="device_type deve ser 'ios' ou 'android'")

    try:
        # Verificar se token já existe
        existing = db.query(DeviceToken).filter(
            DeviceToken.device_token == request.device_token
        ).first()

        if existing:
            # Atualizar token existente
            existing.is_active = True
            existing.device_type = request.device_type
            existing.device_name = request.device_name
            db.commit()
            return {"message": "Device token atualizado", "id": str(existing.id)}

        # Criar novo token
        device_token = DeviceToken(
            user_id=current_user.id,
            device_token=request.device_token,
            device_type=request.device_type,
            device_name=request.device_name,
        )
        db.add(device_token)
        db.commit()
        db.refresh(device_token)

        return {"message": "Device token registrado com sucesso", "id": str(device_token.id)}
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Erro ao registrar device token: {str(e)}")


@router.get("/device-tokens")
def list_device_tokens(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> list[DeviceTokenResponse]:
    """Lista todos os device tokens do usuário"""

    tokens = db.query(DeviceToken).filter(
        DeviceToken.user_id == current_user.id,
        DeviceToken.is_active == True,
    ).all()

    return tokens


@router.delete("/device-token/{token_id}")
def revoke_device_token(
    token_id: UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> dict:
    """Remove um device token"""

    token = db.query(DeviceToken).filter(
        DeviceToken.id == token_id,
        DeviceToken.user_id == current_user.id,
    ).first()

    if not token:
        raise HTTPException(status_code=404, detail="Device token não encontrado")

    try:
        token.is_active = False
        db.commit()
        return {"message": "Device token removido"}
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Erro ao remover device token: {str(e)}")


@router.delete("/device-token")
def revoke_all_device_tokens(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> dict:
    """Remove todos os device tokens do usuário"""

    try:
        db.query(DeviceToken).filter(
            DeviceToken.user_id == current_user.id,
        ).update({"is_active": False})
        db.commit()
        return {"message": "Todos os device tokens foram removidos"}
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Erro ao remover device tokens: {str(e)}")
