"""
Configuração de logging estruturado em JSON para o backend.
Compatível com CloudWatch, ELK Stack e outros serviços de logging.
"""

import json
import logging
import logging.config
from datetime import datetime
from typing import Any, Dict
from pythonjsonlogger import jsonlogger
from app.config import LOG_LEVEL, ENVIRONMENT


class StructuredJsonFormatter(jsonlogger.JsonFormatter):
    """
    Formatter customizado para logs estruturados em JSON.
    Adiciona campos contextuais e rastreabilidade.
    """

    def __init__(self):
        super().__init__()
        self.custom_fields = {}

    def add_context(self, key: str, value: Any):
        """Adiciona campo customizado ao contexto de logging"""
        self.custom_fields[key] = value

    def format(self, record: logging.LogRecord) -> str:
        """Formata log como JSON estruturado"""
        # Campos básicos
        log_data = {
            "timestamp": datetime.utcnow().isoformat() + "Z",
            "level": record.levelname,
            "logger": record.name,
            "message": record.getMessage(),
            "environment": ENVIRONMENT,
        }

        # Adiciona campos adicionais do record
        if hasattr(record, "request_id"):
            log_data["request_id"] = record.request_id
        if hasattr(record, "user_id"):
            log_data["user_id"] = record.user_id
        if hasattr(record, "endpoint"):
            log_data["endpoint"] = record.endpoint
        if hasattr(record, "method"):
            log_data["method"] = record.method
        if hasattr(record, "status_code"):
            log_data["status_code"] = record.status_code
        if hasattr(record, "duration_ms"):
            log_data["duration_ms"] = record.duration_ms

        # Adiciona exceção se houver
        if record.exc_info:
            log_data["exception"] = {
                "type": record.exc_info[0].__name__,
                "message": str(record.exc_info[1]),
                "traceback": self.formatException(record.exc_info),
            }

        # Adiciona campos customizados
        if self.custom_fields:
            log_data["context"] = self.custom_fields

        # Extra fields do LogRecord
        if hasattr(record, "__dict__"):
            extra_keys = set(record.__dict__.keys()) - {
                "name", "msg", "args", "created", "filename",
                "funcName", "levelname", "levelno", "lineno",
                "module", "msecs", "message", "pathname", "process",
                "processName", "relativeCreated", "thread", "threadName",
                "exc_info", "exc_text", "stack_info", "getMessage"
            }
            for key in extra_keys:
                if not key.startswith("_"):
                    log_data[key] = getattr(record, key)

        return json.dumps(log_data, ensure_ascii=False, default=str)


def setup_logging():
    """
    Configura logging estruturado para a aplicação.
    
    Outputs:
    - Console: Logs em JSON para stdout
    - File: Logs estruturados em /var/log/nexus/app.log
    """
    
    # Cria diretório de logs se não existir
    import os
    from pathlib import Path
    
    log_dir = Path("/var/log/nexus")
    log_dir.mkdir(parents=True, exist_ok=True)
    
    config = {
        "version": 1,
        "disable_existing_loggers": False,
        "formatters": {
            "json": {
                "()": StructuredJsonFormatter,
            },
            "standard": {
                "format": "%(asctime)s [%(levelname)s] %(name)s: %(message)s"
            },
        },
        "handlers": {
            "console": {
                "class": "logging.StreamHandler",
                "level": LOG_LEVEL,
                "formatter": "json",
                "stream": "ext://sys.stdout",
            },
            "file": {
                "class": "logging.handlers.RotatingFileHandler",
                "level": LOG_LEVEL,
                "formatter": "json",
                "filename": "/var/log/nexus/app.log",
                "maxBytes": 10485760,  # 10MB
                "backupCount": 10,
                "encoding": "utf-8",
            },
            "error_file": {
                "class": "logging.handlers.RotatingFileHandler",
                "level": "ERROR",
                "formatter": "json",
                "filename": "/var/log/nexus/error.log",
                "maxBytes": 10485760,  # 10MB
                "backupCount": 10,
                "encoding": "utf-8",
            },
        },
        "loggers": {
            "app": {
                "level": LOG_LEVEL,
                "handlers": ["console", "file", "error_file"],
                "propagate": False,
            },
            "uvicorn": {
                "level": "INFO",
                "handlers": ["console", "file"],
                "propagate": False,
            },
            "uvicorn.access": {
                "level": "INFO",
                "handlers": ["console", "file"],
                "propagate": False,
            },
            "sqlalchemy": {
                "level": "WARNING",
                "handlers": ["console", "file"],
                "propagate": False,
            },
        },
        "root": {
            "level": LOG_LEVEL,
            "handlers": ["console", "file", "error_file"],
        },
    }

    logging.config.dictConfig(config)
    logger = logging.getLogger("app")
    logger.info("Logging estruturado inicializado", extra={
        "environment": ENVIRONMENT,
        "log_level": LOG_LEVEL,
    })
    
    return logger


class RequestContextFilter(logging.Filter):
    """
    Filter que adiciona informações do contexto de requisição ao log.
    Use com middleware para rastrear requisições.
    """

    def filter(self, record: logging.LogRecord) -> bool:
        # Aqui você pode adicionar informações do contexto da requisição
        # Por exemplo, request_id, user_id, etc.
        # Isso é geralmente feito através de um contexto thread-local
        return True


def get_logger(name: str) -> logging.LoggerAdapter:
    """
    Retorna um logger customizado com suporte a contexto estruturado.
    """
    logger = logging.getLogger(name)
    
    class StructuredAdapter(logging.LoggerAdapter):
        def process(self, msg, kwargs):
            # Adiciona extra fields automaticamente
            extra = kwargs.get("extra", {})
            
            # Converte extra para a mensagem se necessário
            if extra:
                kwargs["extra"] = extra
            
            return msg, kwargs
    
    return StructuredAdapter(logger, {})


# Exemplo de uso em middleware
def configure_request_logging(logger: logging.Logger, 
                            request_id: str,
                            user_id: str = None):
    """
    Configura logger com informações de contexto de requisição.
    """
    return logging.LoggerAdapter(logger, {
        "request_id": request_id,
        "user_id": user_id,
    })
