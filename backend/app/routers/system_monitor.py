"""
Router de monitoramento de sistema (VPS/Storage).

Endpoints administrativos:
- GET /admin/system/stats — Métricas gerais (CPU, RAM, Disco, Rede)
- GET /admin/system/storage — Controle de armazenamento
- GET /admin/system/processes — Processos mais pesados
- GET /admin/system/health — Saúde do sistema
"""

import logging
import shutil
import time
from datetime import datetime
from pathlib import Path
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import User
from app.security_admin import get_admin_user

logger = logging.getLogger(__name__)

router = APIRouter(
    prefix="/admin/system",
    tags=["System Monitoring"],
    dependencies=[Depends(get_admin_user)],
)

try:
    import psutil
    PSUTIL_AVAILABLE = True
except ImportError:
    PSUTIL_AVAILABLE = False

PATHS_TO_MONITOR = [
    ("Backend", "backend"),
    ("Storage", "storage"),
    ("Uploads", "uploads"),
    ("Logs", "/var/log/nexus"),
]


def _bytes_to_mb(bytes_value: float) -> float:
    return round(bytes_value / (1024 * 1024), 2)


def _bytes_to_gb(bytes_value: float) -> float:
    return round(bytes_value / (1024 * 1024 * 1024), 2)


@router.get("/stats")
def get_system_stats():
    """
    Retorna métricas gerais do sistema (CPU, RAM, Disco, Rede, Uptime).
    """
    if not PSUTIL_AVAILABLE:
        raise HTTPException(status_code=503, detail="psutil não instalado.")

    # CPU
    cpu_percent = psutil.cpu_percent(interval=0.5)
    cpu_count = psutil.cpu_count()
    cpu_freq = psutil.cpu_freq()

    # Memória
    vm = psutil.virtual_memory()

    # Disco
    disk = shutil.disk_usage("/")

    # Swap
    swap = psutil.swap_memory()

    # Rede
    net = psutil.net_io_counters()

    # Uptime
    boot_time = datetime.fromtimestamp(psutil.boot_time())
    uptime_seconds = int(time.time() - psutil.boot_time())
    uptime_days = uptime_seconds // 86400
    uptime_hours = (uptime_seconds % 86400) // 3600
    uptime_minutes = (uptime_seconds % 3600) // 60

    # Load average
    load_avg = psutil.getloadavg()

    return {
        "timestamp": datetime.now().isoformat(),
        "cpu": {
            "percent": cpu_percent,
            "cores": cpu_count,
            "freq_mhz": cpu_freq.current if cpu_freq else None,
            "load_avg_1m": round(load_avg[0], 2),
            "load_avg_5m": round(load_avg[1], 2),
            "load_avg_15m": round(load_avg[2], 2),
        },
        "memory": {
            "total_gb": _bytes_to_gb(vm.total),
            "used_gb": _bytes_to_gb(vm.used),
            "available_gb": _bytes_to_gb(vm.available),
            "percent": vm.percent,
        },
        "disk": {
            "total_gb": _bytes_to_gb(disk.total),
            "used_gb": _bytes_to_gb(disk.used),
            "free_gb": _bytes_to_gb(disk.free),
            "percent": disk.percent,
        },
        "swap": {
            "total_gb": _bytes_to_gb(swap.total),
            "used_gb": _bytes_to_gb(swap.used),
            "percent": swap.percent,
        },
        "network": {
            "bytes_sent_mb": _bytes_to_mb(net.bytes_sent),
            "bytes_recv_mb": _bytes_to_mb(net.bytes_recv),
            "packets_sent": net.packets_sent,
            "packets_recv": net.packets_recv,
        },
        "uptime": {
            "seconds": uptime_seconds,
            "days": uptime_days,
            "hours": uptime_hours,
            "minutes": uptime_minutes,
            "boot_time": boot_time.isoformat(),
        },
    }


@router.get("/storage")
def get_storage_info():
    """
    Retorna informações detalhadas de armazenamento dos diretórios do projeto.
    """
    results = []

    for label, path_str in PATHS_TO_MONITOR:
        path = Path(path_str)
        if not path.exists():
            results.append({
                "label": label,
                "path": str(path),
                "exists": False,
                "size_mb": 0,
                "files": 0,
                "directories": 0,
            })
            continue

        size_bytes = 0
        files_count = 0
        dirs_count = 0

        for root, dirs, files in path.rglob("*"):
            dirs_count += 1
            for file in files:
                files_count += 1
                try:
                    size_bytes += (root / file).stat().st_size
                except OSError:
                    pass

        results.append({
            "label": label,
            "path": str(path),
            "exists": True,
            "size_mb": _bytes_to_mb(size_bytes),
            "size_gb": _bytes_to_gb(size_bytes),
            "files": files_count,
            "directories": dirs_count,
        })

    # Disco total
    disk = shutil.disk_usage("/")
    total_used = sum(item.get("size_gb", 0) for item in results if item.get("exists"))

    return {
        "directories": results,
        "disk_total_gb": _bytes_to_gb(disk.total),
        "disk_used_gb": _bytes_to_gb(disk.used),
        "disk_free_gb": _bytes_to_gb(disk.free),
        "project_used_gb": round(total_used, 2),
    }


@router.get("/processes")
def get_top_processes(
    limit: int = Query(default=10, ge=1, le=50),
):
    """
    Retorna os processos mais pesados do sistema.
    """
    if not PSUTIL_AVAILABLE:
        raise HTTPException(status_code=503, detail="psutil não instalado.")

    processes = []
    for proc in psutil.process_iter(["pid", "name", "username", "cpu_percent", "memory_percent", "memory_info", "status"]):
        try:
            info = proc.info
            processes.append({
                "pid": info["pid"],
                "name": info["name"],
                "user": info["username"],
                "cpu_percent": round(info["cpu_percent"] or 0, 2),
                "memory_percent": round(info["memory_percent"] or 0, 2),
                "memory_mb": _bytes_to_mb(info["memory_info"].rss) if info["memory_info"] else 0,
                "status": info["status"],
            })
        except (psutil.NoSuchProcess, psutil.AccessDenied, psutil.ZombieProcess):
            continue

    processes.sort(key=lambda p: (p["cpu_percent"], p["memory_percent"]), reverse=True)
    return {"processes": processes[:limit]}


@router.get("/health")
def system_health():
    """
    Retorna um resumo de saúde do sistema.
    """
    if not PSUTIL_AVAILABLE:
        return {
            "status": "degraded",
            "message": "psutil não instalado — métricas parciais disponíveis",
        }

    cpu_percent = psutil.cpu_percent(interval=0.5)
    vm = psutil.virtual_memory()
    disk = shutil.disk_usage("/")

    # Avaliar estado
    issues = []
    if cpu_percent > 90:
        issues.append("Uso de CPU crítico")
    if vm.percent > 90:
        issues.append("Uso de memória crítico")
    if disk.percent > 90:
        issues.append("Espaço em disco crítico")

    status = "healthy"
    if len(issues) >= 2:
        status = "critical"
    elif issues:
        status = "degraded"

    return {
        "status": status,
        "message": "; ".join(issues) if issues else "Todos os sistemas operacionais normais",
        "checks": {
            "cpu_percent": cpu_percent,
            "memory_percent": vm.percent,
            "disk_percent": disk.percent,
        },
    }
