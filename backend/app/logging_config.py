import logging
import logging.config
from pathlib import Path
import pythonjsonlogger.jsonlogger
import os

# Cria o diretório de logs se não existir
log_dir = Path("/var/log/nexus")
log_dir.mkdir(parents=True, exist_ok=True)

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
            "filename": "/var/log/nexus/app.log",
            "maxBytes": 104857600,  # 100MB
            "backupCount": 10,
            "encoding": "utf-8",
        },
        "file_auth": {
            "class": "logging.handlers.RotatingFileHandler",
            "level": "INFO",
            "formatter": "json",
            "filename": "/var/log/nexus/auth.log",
            "maxBytes": 52428800,  # 50MB
            "backupCount": 10,
            "encoding": "utf-8",
        },
        "file_api": {
            "class": "logging.handlers.RotatingFileHandler",
            "level": "INFO",
            "formatter": "json",
            "filename": "/var/log/nexus/api.log",
            "maxBytes": 52428800,  # 50MB
            "backupCount": 10,
            "encoding": "utf-8",
        },
        "file_payments": {
            "class": "logging.handlers.RotatingFileHandler",
            "level": "INFO",
            "formatter": "json",
            "filename": "/var/log/nexus/payments.log",
            "maxBytes": 52428800,  # 50MB
            "backupCount": 10,
            "encoding": "utf-8",
        },
        "file_database": {
            "class": "logging.handlers.RotatingFileHandler",
            "level": "DEBUG",
            "formatter": "json",
            "filename": "/var/log/nexus/database.log",
            "maxBytes": 52428800,  # 50MB
            "backupCount": 10,
            "encoding": "utf-8",
        },
        "file_errors": {
            "class": "logging.handlers.RotatingFileHandler",
            "level": "ERROR",
            "formatter": "json",
            "filename": "/var/log/nexus/errors.log",
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
