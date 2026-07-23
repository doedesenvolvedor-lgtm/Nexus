import logging
import os
from datetime import datetime
from pathlib import Path
from fastapi import APIRouter, HTTPException, Response

logger = logging.getLogger(__name__)
router = APIRouter()

RELEASES_DIR = Path("storage/releases")


def _safe_apk_path(filename: str) -> Path:
    # Resolve caminho absoluto e verifica se está dentro do diretório permitido
    candidate = (RELEASES_DIR / filename).resolve()
    releases_root = RELEASES_DIR.resolve(strict=False)
    
    # Verificação adicional contra symlink attacks
    real_candidate = os.path.realpath(candidate)
    real_releases = os.path.realpath(releases_root)
    
    if not real_candidate.startswith(real_releases + "/") and real_candidate != real_releases:
        raise HTTPException(status_code=400, detail="Arquivo inválido")
    if candidate.suffix.lower() != ".apk":
        raise HTTPException(status_code=400, detail="Arquivo inválido")
    return candidate


@router.get("/releases/info")
async def get_releases_info():
    """Retorna informações sobre versões disponíveis de download."""
    try:
        releases_info = []
        releases_dir = RELEASES_DIR
        
        if not releases_dir.exists():
            return {
                "available_releases": [],
                "message": "Nenhuma versão disponível para download"
            }
        
        for file in releases_dir.glob("*.apk"):
            file_size = file.stat().st_size
            file_date = datetime.fromtimestamp(file.stat().st_mtime)
            
            releases_info.append({
                "name": file.name,
                "size_mb": round(file_size / (1024 * 1024), 2),
                "download_url": f"/releases/{file.name}",
                "date": file_date.isoformat(),
                "type": "APK Release"
            })
        
        return {
            "available_releases": sorted(releases_info, key=lambda x: x["date"], reverse=True),
            "total": len(releases_info)
        }
    except Exception:
        logger.exception("Error fetching releases info")
        raise HTTPException(status_code=500, detail="Erro ao buscar releases")


@router.get("/releases/latest")
async def get_latest_release():
    """Retorna informações sobre a versão mais recente."""
    try:
        releases_dir = RELEASES_DIR
        
        if not releases_dir.exists():
            raise HTTPException(status_code=404, detail="Nenhuma versão disponível")
        
        apk_files = list(releases_dir.glob("*.apk"))
        
        if not apk_files:
            raise HTTPException(status_code=404, detail="Nenhuma versão APK disponível")
        
        # Get the most recently modified file
        latest_file = max(apk_files, key=lambda x: x.stat().st_mtime)
        file_size = latest_file.stat().st_size
        file_date = datetime.fromtimestamp(latest_file.stat().st_mtime)
        
        return {
            "name": latest_file.name,
            "size_mb": round(file_size / (1024 * 1024), 2),
            "download_url": f"/releases/{latest_file.name}",
            "date": file_date.isoformat(),
            "type": "APK Release",
            "direct_link": f"/releases/{latest_file.name}"
        }
    except HTTPException:
        raise
    except Exception:
        logger.exception("Error fetching latest release")
        raise HTTPException(status_code=500, detail="Erro ao buscar release mais recente")


@router.head("/releases/{filename}")
async def head_release(filename: str):
    """Retorna headers do arquivo sem fazer download (para verificar se existe)."""
    file_path = _safe_apk_path(filename)
    
    if not file_path.exists():
        raise HTTPException(status_code=404, detail="Arquivo não encontrado")
    
    return Response(
        status_code=200,
        headers={
            "Content-Length": str(file_path.stat().st_size),
            "Content-Type": "application/vnd.android.package-archive",
        },
    )
