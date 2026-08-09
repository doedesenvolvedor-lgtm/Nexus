"""
Worker de manutenção de conteúdo.

Executa ciclos periódicos de manutenção:
- Verificação de streams inválidos
- Atualização de playlists M3U8
- Importação automática via TMDb
- Verificação de canais ao vivo

Uso:
    python -m workers.content_maintenance_worker
"""

import asyncio
import logging
import time
from datetime import datetime, timezone

from app.config import CONTENT_MAINTENANCE_INTERVAL, ENVIRONMENT
from app.services.content_maintenance_service import ContentMaintenanceService

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
)
logger = logging.getLogger("content-maintenance-worker")


def run_cycle() -> dict:
    """Executa um ciclo completo de manutenção (bloqueante)."""
    service = ContentMaintenanceService()
    try:
        results = asyncio.run(service.run_maintenance_cycle())
        return results
    except Exception as exc:
        logger.exception("Erro no ciclo de manutenção: %s", exc)
        return {"error": str(exc)}


def run_once() -> dict:
    """Executa um único ciclo de manutenção e retorna os resultados."""
    started_at = datetime.now(timezone.utc).isoformat()
    logger.info("Iniciando ciclo de manutenção de conteúdo...")

    results = run_cycle()

    results["started_at"] = started_at
    results["finished_at"] = datetime.now(timezone.utc).isoformat()

    logger.info("Ciclo de manutenção concluído: %s", results)
    return results


def run_forever(interval_seconds: int = None) -> None:
    """Executa ciclos periódicos de manutenção."""
    interval = interval_seconds or CONTENT_MAINTENANCE_INTERVAL

    logger.info("Content maintenance worker iniciado (intervalo: %s segundos)", interval)

    # Executar primeiro ciclo imediatamente
    run_once()

    while True:
        time.sleep(interval)
        try:
            run_once()
        except Exception as exc:
            logger.exception("Erro no ciclo agendado: %s", exc)


if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(description="Content Maintenance Worker")
    parser.add_argument(
        "--interval",
        type=int,
        default=CONTENT_MAINTENANCE_INTERVAL,
        help="Intervalo entre ciclos em segundos (default: %(default)s)",
    )
    parser.add_argument(
        "--once",
        action="store_true",
        help="Executar apenas um ciclo e sair",
    )
    args = parser.parse_args()

    if args.once:
        run_once()
    else:
        run_forever(args.interval)
