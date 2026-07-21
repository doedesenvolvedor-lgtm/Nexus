import logging
import logging.config
from pathlib import Path
import pythonjsonlogger.jsonlogger
import os


def _resolve_log_dir() -> Path:
    preferred_dir = Path(os.getenv("NEXUS_LOG_DIR", "/var/log/nexus"))
    fallback_dir = Path("logs")

    for candidate in (preferred_dir, fallback_dir):
        try:
            candidate.mkdir(parents=True, exist_ok=True)
            test_file = candidate / ".write_test"
            test_file.write_text("ok", encoding="utf-8")
            test_file.unlink()
            return candidate
        except (PermissionError, OSError):
            continue

    raise RuntimeError("Nenhum diretório de log gravável disponível")


log_dir = _resolve_log_dir()

# Configuração de logging em formato JSON
LOGGING_CONFIG = {
    "version": 1,
    "disable_existing_loggers": False,
    "formatters": {
        "json": {
            "()": "pythonjsonlogger.jsonlogger.JsonFormatter",
            "fmt": "%(timestamp)s %(level)s %(name)s %(message)s",
        },
        "standard": {
            "format": "%(asctime)s [%(levelname)s] %(name)s: %(message)s",
        },
    },
    "handlers": {
        "console": {
            "class": "logging.StreamHandler",
            "level": "INFO",
            "formatter": "standard",
            "stream": "ext://sys.stdout",
        },
        "file_json": {
            "class": "logging.handlers.RotatingFileHandler",
            "level": "DEBUG",
            "formatter": "json",
            "filename": str(log_dir / "app.log"),
            "maxBytes": 104857600,  # 100MB
            "backupCount": 10,
            "encoding": "utf-8",
        },
        "file_auth": {
            "class": "logging.handlers.RotatingFileHandler",
            "level": "INFO",
            "formatter": "json",
            "filename": str(log_dir / "auth.log"),
            "maxBytes": 52428800,  # 50MB
            "backupCount": 10,
            "encoding": "utf-8",
        },
        "file_api": {
            "class": "logging.handlers.RotatingFileHandler",
            "level": "INFO",
            "formatter": "json",
            "filename": str(log_dir / "api.log"),
            "maxBytes": 52428800,  # 50MB
            "backupCount": 10,
            "encoding": "utf-8",
        },
        "file_payments": {
            "class": "logging.handlers.RotatingFileHandler",
            "level": "INFO",
            "formatter": "json",
            "filename": str(log_dir / "payments.log"),
            "maxBytes": 52428800,  # 50MB
            "backupCount": 10,
            "encoding": "utf-8",
        },
        "file_database": {
            "class": "logging.handlers.RotatingFileHandler",
            "level": "DEBUG",
            "formatter": "json",
            "filename": str(log_dir / "database.log"),
            "maxBytes": 52428800,  # 50MB
            "backupCount": 10,
            "encoding": "utf-8",
        },
        "file_errors": {
            "class": "logging.handlers.RotatingFileHandler",
            "level": "ERROR",
            "formatter": "json",
            "filename": str(log_dir / "errors.log"),
            "maxBytes": 52428800,  # 50MB
            "backupCount": 20,
            "encoding": "utf-8",
        },
    },
    "loggers": {
        "app.routers.auth": {
            "level": "INFO",
            "handlers": ["console", "file_auth"],
            "propagate": False,
        },
        "app.routers.payments": {
            "level": "INFO",
            "handlers": ["console", "file_payments"],
            "propagate": False,
        },
        "app.database": {
            "level": "DEBUG",
            "handlers": ["console", "file_database"],
            "propagate": False,
        },
        "app": {
            "level": "DEBUG",
            "handlers": ["console", "file_json"],
            "propagate": False,
        },
    },
    "root": {
        "level": "INFO",
        "handlers": ["console", "file_json", "file_errors"],
    },
}


def setup_logging():
    """Configura o logging para a aplicação."""
    logging.config.dictConfig(LOGGING_CONFIG)


# Loggers específicos para uso nos routers
def get_logger(name: str) -> logging.Logger:
    """Retorna um logger configurado."""
    return logging.getLogger(name)


# Logger para eventos importantes
def log_event(logger: logging.Logger, event_type: str, details: dict):
    """Log estruturado de eventos importantes."""
    log_data = {
        "event_type": event_type,
        **details,
    }
    logger.info(str(log_data))
