from dotenv import load_dotenv
import os

load_dotenv()


def _parse_csv_env(key: str) -> list[str]:
    raw_value = os.getenv(key, "")
    if not raw_value:
        return []
    return [item.strip().lower() for item in raw_value.split(",") if item.strip()]


def _get_env_int(key: str, default: int) -> int:
    try:
        return int(os.getenv(key, str(default)))
    except (ValueError, TypeError):
        return default


DATABASE_URL = os.getenv("DATABASE_URL")
REDIS_URL = os.getenv("REDIS_URL", "redis://127.0.0.1:6379/0")
REDIS_PASSWORD = os.getenv("REDIS_PASSWORD", "")
SECRET_KEY = os.getenv("SECRET_KEY")
ALGORITHM = os.getenv("ALGORITHM", "HS256")
ACCESS_TOKEN_EXPIRE_MINUTES = _get_env_int("ACCESS_TOKEN_EXPIRE_MINUTES", 30)
REFRESH_TOKEN_EXPIRE_DAYS = _get_env_int("REFRESH_TOKEN_EXPIRE_DAYS", 7)

APP_NAME = os.getenv("APP_NAME", "Nexus Twos")
FRONTEND_URL = os.getenv("FRONTEND_URL", "http://localhost:3000")
ADMIN_FRONTEND_URL = os.getenv("ADMIN_FRONTEND_URL", "http://localhost:5000")
FRONTEND_RESET_PASSWORD_URL = os.getenv(
    "FRONTEND_RESET_PASSWORD_URL", f"{FRONTEND_URL}/reset-password"
)

SMTP_SERVER = os.getenv("SMTP_SERVER")
SMTP_PORT = _get_env_int("SMTP_PORT", 465)
SMTP_USER = os.getenv("SMTP_USER")
SMTP_PASSWORD = os.getenv("SMTP_PASSWORD")
SMTP_SECURITY = os.getenv("SMTP_SECURITY", "ssl").strip().lower()
SMTP_FROM_EMAIL = os.getenv("SMTP_FROM_EMAIL", SMTP_USER or "noreply@localhost")
SMTP_FROM_NAME = os.getenv("SMTP_FROM_NAME", APP_NAME)

# ===== Email Configuration =====
SMTP_RETRY_ATTEMPTS = _get_env_int("SMTP_RETRY_ATTEMPTS", 3)
SMTP_RETRY_DELAY = _get_env_int("SMTP_RETRY_DELAY", 5)  # segundos

# ===== Webhook Configuration =====
MERCADOPAGO_WEBHOOK_SECRET = os.getenv("MERCADOPAGO_WEBHOOK_SECRET", "").strip()
STRIPE_WEBHOOK_SECRET = os.getenv("STRIPE_WEBHOOK_SECRET", "").strip()

# ===== Admin & Billing Exceptions =====
ADMIN_EMAILS = _parse_csv_env("ADMIN_EMAILS")
NON_BILLING_PREMIUM_EMAILS = _parse_csv_env("NON_BILLING_PREMIUM_EMAILS")

# ===== Environment =====
LOG_LEVEL = os.getenv("LOG_LEVEL", "INFO").upper()
ENVIRONMENT = os.getenv("ENVIRONMENT", "development").lower()
