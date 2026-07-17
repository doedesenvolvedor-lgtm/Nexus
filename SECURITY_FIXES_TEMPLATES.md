# Código de Correção - Templates Prontos

## 1. CORS Seguro (main.py)

```python
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import os

app = FastAPI(
    title="Nexus Streaming",
    version="1.0",
    docs_url=None if os.getenv("ENVIRONMENT") == "production" else "/docs",
    redoc_url=None if os.getenv("ENVIRONMENT") == "production" else "/redoc",
)

# CORS Configuration
ALLOWED_ORIGINS = os.getenv(
    "ALLOWED_ORIGINS",
    "https://nexusstream.com,https://app.nexusstream.com"
).split(",")

app.add_middleware(
    CORSMiddleware,
    allow_origins=ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE", "PATCH"],
    allow_headers=["Authorization", "Content-Type", "X-CSRF-Token"],
    expose_headers=["X-Total-Count", "X-Page-Count"],
    max_age=3600,  # 1 hora
)

# Security Headers Middleware
@app.middleware("http")
async def add_security_headers(request, call_next):
    response = await call_next(request)
    response.headers["X-Content-Type-Options"] = "nosniff"
    response.headers["X-Frame-Options"] = "DENY"
    response.headers["X-XSS-Protection"] = "1; mode=block"
    response.headers["Strict-Transport-Security"] = "max-age=31536000; includeSubDomains; preload"
    response.headers["Content-Security-Policy"] = "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'"
    return response
```

---

## 2. Rate Limiting com SlowAPI

```bash
# requirements.txt adicionar:
slowapi==0.1.9
```

```python
# routers/auth.py
from slowapi import Limiter
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded

limiter = Limiter(key_func=get_remote_address, default_limits=["100/minute"])

@router.post("/login", response_model=Token)
@limiter.limit("5/minute")  # 5 tentativas por minuto
def login(request: Request, credentials: Login, db: Session = Depends(get_db)):
    # ... resto do código
    pass

@router.post("/forgot-password")
@limiter.limit("3/hour")  # 3 por hora
def forgot_password(request: Request, req: ForgotPasswordRequest, db: Session = Depends(get_db)):
    # ... resto do código
    pass

# Em main.py, adicionar:
from slowapi.errors import RateLimitExceeded
from slowapi.middleware import SlowAPIMiddleware

app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_error_handler)
app.add_middleware(SlowAPIMiddleware)
```

---

## 3. Validações em Schemas

```python
# schemas.py
from pydantic import BaseModel, EmailStr, Field, field_validator
from typing import Optional
import re

class UserCreate(BaseModel):
    email: EmailStr
    username: Optional[str] = Field(
        None, 
        min_length=3, 
        max_length=50,
        pattern=r'^[a-zA-Z0-9_-]+$',
        description="Apenas letras, números, -, _"
    )
    password: str = Field(
        ...,
        min_length=12,
        max_length=128,
        description="Mín 12 chars: 1 maiúscula, 1 minúscula, 1 dígito, 1 especial"
    )
    
    @field_validator('password')
    @classmethod
    def validate_password_strength(cls, v):
        """Validar força da senha"""
        patterns = {
            "maiúscula": r'[A-Z]',
            "minúscula": r'[a-z]',
            "dígito": r'\d',
            "especial": r'[@$!%*?&_\-#^]'
        }
        
        for name, pattern in patterns.items():
            if not re.search(pattern, v):
                raise ValueError(f"Deve conter pelo menos 1 {name}")
        
        # Rejeitar padrões comuns
        common_patterns = ["123456", "password", "qwerty", "admin", "nexus"]
        if any(pattern in v.lower() for pattern in common_patterns):
            raise ValueError("Senha muito simples ou comum")
        
        return v

class Login(BaseModel):
    email: EmailStr = Field(..., description="Email válido")
    password: str = Field(..., min_length=1)

class ResetPasswordRequest(BaseModel):
    token: str = Field(..., min_length=20, max_length=100)
    new_password: str = Field(
        ...,
        min_length=12,
        max_length=128,
    )

class ProfileCreate(BaseModel):
    name: str = Field(
        ...,
        min_length=1,
        max_length=100,
        description="Nome do perfil"
    )
    avatar_url: Optional[str] = Field(
        None,
        max_length=2000,
        description="URL da imagem"
    )
    is_kids: bool = False
    pin_code: Optional[str] = Field(
        None,
        min_length=4,
        max_length=4,
        regex=r'^\d{4}$',
        description="PIN de 4 dígitos"
    )

class MediaCreate(BaseModel):
    title: str = Field(..., min_length=1, max_length=255)
    description: str = Field(
        ...,
        min_length=10,
        max_length=5000,
        description="Descrição entre 10-5000 caracteres"
    )
    content_type: str = Field(
        ...,
        regex=r'^(movie|series|episode)$',
        description="Apenas: movie, series ou episode"
    )
    genre: str = Field(..., min_length=1, max_length=100)
    release_year: int = Field(..., ge=1900, le=2100)
    duration: int = Field(..., ge=1, le=300)  # minutos
    rating: str = Field(..., regex=r'^(G|PG|PG-13|R|NC-17)$')
    thumbnail_url: str = Field(..., max_length=2000)
    video_url: str = Field(..., max_length=2000)
```

---

## 4. Webhook MercadoPago com Validação HMAC

```python
# routers/webhooks.py
import hmac
import hashlib
from fastapi import APIRouter, HTTPException, Request, Depends
from sqlalchemy.orm import Session
import logging
from app.database import get_db
from app.models import Payment, Subscription
from app.config import MERCADOPAGO_ACCESS_TOKEN

logger = logging.getLogger(__name__)
router = APIRouter(tags=["Webhooks"])

# Chave secreta MercadoPago (adicionar ao .env)
MERCADOPAGO_WEBHOOK_SECRET = os.getenv("MERCADOPAGO_WEBHOOK_SECRET", "")

def verify_webhook_signature(body: bytes, signature: str) -> bool:
    """Verificar assinatura HMAC do webhook MercadoPago"""
    if not MERCADOPAGO_WEBHOOK_SECRET:
        logger.error("MERCADOPAGO_WEBHOOK_SECRET não configurado!")
        return False
    
    expected_signature = hmac.new(
        MERCADOPAGO_WEBHOOK_SECRET.encode(),
        body,
        hashlib.sha256
    ).hexdigest()
    
    # Comparação em tempo constante
    return hmac.compare_digest(signature, expected_signature)

@router.post("/mercadopago")
async def webhook_mercadopago(
    request: Request,
    db: Session = Depends(get_db)
):
    """
    Receber webhooks autenticados do MercadoPago
    """
    try:
        # Obter corpo bruto
        body = await request.body()
        
        # Verificar assinatura
        signature = request.headers.get("X-Signature")
        if not signature or not verify_webhook_signature(body, signature):
            logger.warning(f"Webhook inválido recebido de {request.client.host}")
            raise HTTPException(status_code=401, detail="Assinatura inválida")
        
        # Parse JSON
        payload = await request.json()
        
        # Validar payload
        action = payload.get("action")
        data = payload.get("data", {})
        
        if action != "payment.created":
            logger.debug(f"Ação ignorada: {action}")
            return {"status": "ok"}
        
        # Buscar pagamento
        payment_id = data.get("id")
        payment = db.query(Payment).filter(
            Payment.payment_id == str(payment_id)
        ).first()
        
        if not payment:
            logger.warning(f"Pagamento não encontrado: {payment_id}")
            raise HTTPException(status_code=404, detail="Pagamento não encontrado")
        
        # Verificar status
        status = data.get("status")
        if status == "approved":
            payment.status = "approved"
            
            # Atualizar subscription do usuário
            subscription = db.query(Subscription).filter(
                Subscription.user_id == payment.user_id
            ).first()
            
            if subscription:
                subscription.status = "active"
                subscription.plan_type = payment.plan
            
            logger.info(f"Pagamento aprovado: {payment_id} - Usuário: {payment.user_id}")
        
        elif status == "rejected":
            payment.status = "rejected"
            logger.warning(f"Pagamento rejeitado: {payment_id}")
        
        elif status == "pending":
            payment.status = "pending"
        
        db.commit()
        
        # Logar webhook recebido
        logger.info(f"Webhook processado: {action} - Payment: {payment_id} - Status: {status}")
        
        return {"status": "ok", "payment_id": payment_id}
        
    except Exception as e:
        logger.error(f"Erro ao processar webhook: {str(e)}", exc_info=True)
        # Não expor detalhes de erro
        raise HTTPException(status_code=400, detail="Erro ao processar webhook")
```

---

## 5. Pagination Helper

```python
# schemas.py - adicionar
from pydantic import BaseModel, Field
from typing import Generic, TypeVar, List

T = TypeVar('T')

class PaginationParams(BaseModel):
    skip: int = Field(0, ge=0, description="Índice inicial")
    limit: int = Field(10, ge=1, le=100, description="Máximo 100 items")

class PagedResponse(BaseModel, Generic[T]):
    items: List[T]
    total: int
    skip: int
    limit: int
    
    @property
    def has_more(self) -> bool:
        return self.skip + self.limit < self.total

# routers/admin.py - atualizar
from app.schemas import PaginationParams, PagedResponse

@router.get("/users", response_model=PagedResponse[UserResponse])
def users(
    params: PaginationParams = Depends(),
    db: Session = Depends(get_db)
):
    total = db.query(User).count()
    items = db.query(User).offset(params.skip).limit(params.limit).all()
    
    return PagedResponse(
        items=items,
        total=total,
        skip=params.skip,
        limit=params.limit
    )

@router.get("/subscriptions", response_model=PagedResponse[SubscriptionResponse])
def list_subscriptions(
    params: PaginationParams = Depends(),
    db: Session = Depends(get_db)
):
    total = db.query(Subscription).count()
    items = db.query(Subscription).offset(params.skip).limit(params.limit).all()
    
    return PagedResponse(
        items=items,
        total=total,
        skip=params.skip,
        limit=params.limit
    )
```

---

## 6. Admin Role no Database

```python
# models.py - adicionar coluna
class User(Base):
    __tablename__ = "users"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    email = Column(String(255), unique=True, nullable=False, index=True)
    username = Column(String(100), unique=True, nullable=True, index=True)
    hashed_password = Column(Text, nullable=False)
    is_premium = Column(Boolean, default=False)
    is_admin = Column(Boolean, default=False)  # ← NOVO
    created_at = Column(DateTime(timezone=True), server_default=func.now())

# security_admin.py - atualizar
def get_admin_user_from_db(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Verificar se usuário é admin via DB"""
    if current_user is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Usuário não autenticado",
        )
    
    # Buscar usuário fresco do DB
    user = db.query(User).filter(User.id == current_user.id).first()
    
    if not user or not user.is_admin:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Acesso negado. Apenas administradores podem acessar.",
        )
    
    # Log de acesso admin
    logger.info(f"Admin access by {user.email} to {request.url}")
    
    return user

# routers/admin.py - usar nova função
router = APIRouter(
    tags=["Admin"],
    dependencies=[Depends(get_admin_user_from_db)]
)
```

---

## 7. Connection Pooling PostgreSQL

```python
# database.py
from sqlalchemy import create_engine, event
from sqlalchemy.orm import declarative_base, sessionmaker
from app.config import DATABASE_URL
import logging

logger = logging.getLogger(__name__)

# Connection pooling
engine = create_engine(
    DATABASE_URL,
    pool_size=20,  # Conexões permanentes
    max_overflow=10,  # Conexões extras quando necessário
    pool_recycle=3600,  # Reciclar conexões a cada 1h
    pool_pre_ping=True,  # Testar conexão antes de usar
    echo=False,  # Set True para debug SQL
    connect_args={
        "connect_timeout": 10,
        "options": "-c statement_timeout=30000",  # 30s timeout
    }
)

# Listener para pool events
@event.listens_for(engine, "connect")
def receive_connect(dbapi_conn, connection_record):
    logger.debug("PostgreSQL connection established")

@event.listens_for(engine, "close")
def receive_close(dbapi_conn, connection_record):
    logger.debug("PostgreSQL connection closed")

@event.listens_for(engine, "checkin")
def receive_checkin(dbapi_conn, connection_record):
    logger.debug("Connection checked back into pool")

SessionLocal = sessionmaker(
    autocommit=False,
    autoflush=False,
    bind=engine,
)

Base = declarative_base()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
```

---

## 8. Multi-Stage Dockerfile

```dockerfile
# Dockerfile.prod

# Stage 1: Builder
FROM python:3.12-slim as builder

WORKDIR /build

# Instalar dependências do sistema
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

# Copiar requirements
COPY requirements.txt .

# Instalar pacotes Python em diretório do usuário
RUN pip install --user --no-cache-dir -r requirements.txt

# Stage 2: Runtime
FROM python:3.12-slim

# Criar usuário não-root
RUN useradd -m -u 1000 nexus

WORKDIR /app

# Copiar dependências do builder
COPY --from=builder /root/.local /home/nexus/.local

# Copiar código da aplicação
COPY --chown=nexus:nexus app ./app
COPY --chown=nexus:nexus workers ./workers

# Criar diretório de logs
RUN mkdir -p /var/log/nexus && chown nexus:nexus /var/log/nexus

# Mudar para usuário não-root
USER nexus

# Adicionar local pip ao PATH
ENV PATH=/home/nexus/.local/bin:$PATH
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1
ENV ENVIRONMENT=production

# Health check
HEALTHCHECK --interval=10s --timeout=5s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

# Comando de inicialização com múltiplos workers
CMD ["uvicorn", "app.main:app", \
     "--host", "0.0.0.0", \
     "--port", "8000", \
     "--workers", "4", \
     "--loop", "uvloop", \
     "--access-log", \
     "--log-level", "info"]
```

---

## 9. Docker Compose com Healthchecks

```yaml
version: '3.8'

services:
  postgres:
    image: postgres:16
    restart: always
    environment:
      POSTGRES_DB: nexus
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres -d nexus"]
      interval: 10s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7-alpine
    restart: always
    command: redis-server --requirepass ${REDIS_PASSWORD}
    ports:
      - "6379:6379"
    healthcheck:
      test: ["CMD", "redis-cli", "-a", "${REDIS_PASSWORD}", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5

  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile.prod
    restart: always
    ports:
      - "8000:8000"
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
    environment:
      DATABASE_URL: postgresql://postgres:${POSTGRES_PASSWORD}@postgres:5432/nexus
      REDIS_URL: redis://:${REDIS_PASSWORD}@redis:6379/0
      ENVIRONMENT: production
      LOG_LEVEL: info
    volumes:
      - /var/log/nexus:/var/log/nexus
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
      interval: 10s
      timeout: 5s
      retries: 3
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 1G
        reservations:
          cpus: '1'
          memory: 512M

  worker:
    build:
      context: ./backend
      dockerfile: Dockerfile.prod
    restart: always
    command: python -m workers.queue_worker
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
    environment:
      DATABASE_URL: postgresql://postgres:${POSTGRES_PASSWORD}@postgres:5432/nexus
      REDIS_URL: redis://:${REDIS_PASSWORD}@redis:6379/0
      ENVIRONMENT: production
    volumes:
      - /var/log/nexus:/var/log/nexus
    deploy:
      resources:
        limits:
          cpus: '1'
          memory: 512M

volumes:
  postgres_data:
  redis_data:

networks:
  default:
    driver: bridge
```

---

## 10. Requirements.txt com Versões

```
# requirements-prod.txt

# Core
fastapi==0.104.1
uvicorn[standard]==0.24.0
uvloop==0.19.0

# Database
sqlalchemy==2.0.23
alembic==1.12.1
psycopg2-binary==2.9.9

# Authentication & Security
python-jose[cryptography]==3.3.0
passlib[bcrypt]==1.7.4
bcrypt==4.1.1
pydantic==2.4.2
pydantic-settings==2.0.3
python-multipart==0.0.6
email-validator==2.1.0

# Cache
redis==5.0.1

# External APIs
mercadopago==2.1.0
firebase-admin==6.2.0
requests==2.31.0
httpx==0.25.1

# Rate Limiting
slowapi==0.1.9

# Monitoring & Logging
prometheus-client==0.18.0
python-json-logger==2.0.7

# Utils
aiofiles==23.2.1
python-dotenv==1.0.0
```

---

## 11. Nginx com Gzip + Timeouts + HSTS

```nginx
# nginx.conf - adicionar ao bloco http

http {
    # Gzip Compression
    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types 
        text/plain 
        text/css 
        text/xml 
        text/javascript 
        application/json 
        application/javascript 
        application/xml+rss 
        application/rss+xml;
    gzip_min_length 1000;
    gzip_disable "msie6";
    
    # Timeouts
    proxy_connect_timeout 10s;
    proxy_send_timeout 30s;
    proxy_read_timeout 30s;
    
    # Buffer Sizes
    proxy_buffer_size 128k;
    proxy_buffers 4 256k;
    proxy_busy_buffers_size 256k;
    
    # Client Max Body Size
    client_max_body_size 100M;
    
    # Keepalive
    upstream nexus_backend {
        server backend:8000;
        keepalive 32;
    }
    
    # ... resto do nginx.conf
    
    server {
        listen 443 ssl http2;
        server_name api.nexusstream.com;
        
        ssl_certificate /etc/letsencrypt/live/api.nexusstream.com/fullchain.pem;
        ssl_certificate_key /etc/letsencrypt/live/api.nexusstream.com/privkey.pem;
        
        # SSL Config
        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_ciphers HIGH:!aNULL:!MD5;
        ssl_prefer_server_ciphers on;
        ssl_session_cache shared:SSL:10m;
        ssl_session_timeout 10m;
        
        # Security Headers
        add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
        add_header X-Frame-Options "DENY" always;
        add_header X-Content-Type-Options "nosniff" always;
        add_header X-XSS-Protection "1; mode=block" always;
        add_header Referrer-Policy "strict-origin-when-cross-origin" always;
        add_header Permissions-Policy "geolocation=(), microphone=(), camera=()" always;
        add_header Content-Security-Policy "default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline'" always;
        
        location / {
            proxy_pass http://nexus_backend;
            proxy_http_version 1.1;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_set_header Connection "";
            
            # Timeouts
            proxy_connect_timeout 10s;
            proxy_send_timeout 30s;
            proxy_read_timeout 30s;
        }
    }
}
```

---

## 12. Environment File Template Seguro

```bash
# .env.production (NUNCA commitar!)

# ===== BANCO DE DADOS =====
DATABASE_URL=postgresql://postgres:<SENHA_SEGURA>@db.prod.internal:5432/nexus

# ===== REDIS =====
REDIS_URL=redis://:< SENHA_SEGURA>@redis.prod.internal:6379/0
REDIS_PASSWORD=<SENHA_SEGURA>

# ===== AUTENTICAÇÃO =====
SECRET_KEY=<GERAR_COM: python3 -c "import secrets; print(secrets.token_urlsafe(32))">
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=1440

# ===== MERCADOPAGO =====
MERCADOPAGO_ACCESS_TOKEN=<PRODUCTION_TOKEN>
MERCADOPAGO_CLIENT_ID=<PRODUCTION_CLIENT_ID>
MERCADOPAGO_WEBHOOK_SECRET=<GERAR_NOVA_CHAVE>

# ===== SEGURANÇA =====
ALLOWED_ORIGINS=https://nexusstream.com,https://app.nexusstream.com
ENVIRONMENT=production
LOG_LEVEL=info

# ===== EMAIL =====
SMTP_SERVER=smtp.hostinger.com
SMTP_PORT=465
SMTP_USER=noreply@nexusstream.com
SMTP_PASSWORD=<SENHA_SEGURA>
SMTP_SECURITY=ssl

# ===== FIREBASE =====
FIREBASE_CREDENTIALS_PATH=/app/firebase-credentials.json
FIREBASE_PROJECT_ID=nexus-prod

# Comando para validar:
# grep -E "(password|secret|key|token)" .env.production | wc -l
```

---

## 13. Audit Logging Middleware

```python
# middlewares/audit.py
import logging
from datetime import datetime
from fastapi import Request
import json

logger = logging.getLogger("audit")

async def audit_middleware(request: Request, call_next):
    """Log todas as requisições para audit"""
    
    start_time = datetime.utcnow()
    
    # Não logar GET /health e /metrics
    if request.url.path not in ["/health", "/metrics"]:
        logger.info(
            json.dumps({
                "timestamp": start_time.isoformat(),
                "method": request.method,
                "path": request.url.path,
                "client": request.client.host if request.client else "unknown",
                "user_agent": request.headers.get("user-agent", "unknown"),
            })
        )
    
    response = await call_next(request)
    
    duration = (datetime.utcnow() - start_time).total_seconds()
    
    if request.url.path not in ["/health", "/metrics"]:
        logger.info(
            json.dumps({
                "timestamp": datetime.utcnow().isoformat(),
                "status": response.status_code,
                "duration_seconds": duration,
                "path": request.url.path,
            })
        )
    
    return response

# Em main.py:
app.add_middleware(audit_middleware)
```

---

**Nota:** Todos esses templates precisam ser adaptados para sua estrutura específica. Use-os como referência e teste em desenvolvimento antes de produção.
