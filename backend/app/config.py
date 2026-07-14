from dotenv import load_dotenv
import os

load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL")
REDIS_URL = os.getenv("REDIS_URL", "redis://127.0.0.1:6379/0")
SECRET_KEY = os.getenv("SECRET_KEY")
ALGORITHM = os.getenv("ALGORITHM")
ACCESS_TOKEN_EXPIRE_MINUTES = int(
    os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", 1440)
)

APP_NAME = os.getenv("APP_NAME", "Nexus Streaming")
FRONTEND_URL = os.getenv("FRONTEND_URL", "http://localhost:3000")
FRONTEND_RESET_PASSWORD_URL = os.getenv(
    "FRONTEND_RESET_PASSWORD_URL", f"{FRONTEND_URL}/reset-password"
)

SMTP_SERVER = os.getenv("SMTP_SERVER")
SMTP_PORT = int(os.getenv("SMTP_PORT", 465))
SMTP_USER = os.getenv("SMTP_USER")
SMTP_PASSWORD = os.getenv("SMTP_PASSWORD")
SMTP_SECURITY = os.getenv("SMTP_SECURITY", "ssl").strip().lower()
SMTP_FROM_EMAIL = os.getenv("SMTP_FROM_EMAIL", SMTP_USER or "noreply@localhost")
SMTP_FROM_NAME = os.getenv("SMTP_FROM_NAME", APP_NAME)

# ===== Email Configuration =====
SMTP_RETRY_ATTEMPTS = int(os.getenv("SMTP_RETRY_ATTEMPTS", 3))
SMTP_RETRY_DELAY = int(os.getenv("SMTP_RETRY_DELAY", 5))  # segundos
