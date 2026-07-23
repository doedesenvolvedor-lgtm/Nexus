# 🚀 Guia Completo de Preparação de VPS em Produção - NexusTwos

**Versão:** 2.0  
**Última Atualização:** 2026  
**Sistema:** Ubuntu 22.04 LTS (recomendado)  
**Stack:** FastAPI + PostgreSQL + Redis + Docker + Nginx + Flutter (Mobile)

---

## 📑 Índice

1. [Pré-requisitos da VPS](#1-pré-requisitos-da-vps)
2. [Estrutura Completa de Diretórios](#2-estrutura-completa-de-diretórios)
3. [Arquivos que Devem Ser Enviados](#3-arquivos-que-devem-ser-enviados)
4. [Arquivos que NÃO Devem Ser Enviados](#4-arquivos-que-não-devem-ser-enviados)
5. [Instalação do Ambiente Base](#5-instalação-do-ambiente-base)
6. [Docker e Docker Compose](#6-docker-e-docker-compose)
7. [Nginx como Proxy Reverso](#7-nginx-como-proxy-reverso)
8. [SSL com Certbot (Let's Encrypt)](#8-ssl-com-certbot-lets-encrypt)
9. [PostgreSQL](#9-postgresql)
10. [Redis](#10-redis)
11. [Variáveis de Ambiente (.env)](#11-variáveis-de-ambiente-env)
12. [Backend FastAPI](#12-backend-fastapi)
13. [Painel Administrativo](#13-painel-administrativo)
14. [Workers e Filas](#14-workers-e-filas)
15. [Serviços Docker (docker-compose.yml)](#15-serviços-docker-docker-composeyml)
16. [Configuração de Logs](#16-configuração-de-logs)
17. [Backup Automático](#17-backup-automático)
18. [Firewall (UFW)](#18-firewall-ufw)
19. [Segurança da VPS](#19-segurança-da-vps)
20. [Domínio e Subdomínios](#20-domínio-e-subdomínios)
21. [Bunny CDN](#21-bunny-cdn)
22. [Serviço de E-mail (Hostinger Mail)](#22-serviço-de-e-mail-hostinger-mail)
23. [Firebase Cloud Messaging (FCM)](#23-firebase-cloud-messaging-fcm)
24. [Mercado Pago](#24-mercado-pago)
25. [FFmpeg](#25-ffmpeg)
26. [Monitoramento (Prometheus + Grafana)](#26-monitoramento-prometheus--grafana)
27. [Comandos de Gerenciamento](#27-comandos-de-gerenciamento)
28. [Comandos para Verificar Logs e Diagnosticar](#28-comandos-para-verificar-logs-e-diagnosticar)
29. [Atualização sem Perda de Dados](#29-atualização-sem-perda-de-dados)
30. [Checklist Final de Produção](#30-checklist-final-de-produção)

---

## 1. Pré-requisitos da VPS

### Especificações Mínimas

| Recurso | Mínimo | Recomendado |
|---------|--------|-------------|
| **CPU** | 2 vCPUs | 4 vCPUs |
| **RAM** | 4 GB | 8 GB |
| **Disco** | 50 GB SSD | 100 GB NVMe |
| **Largura de Banda** | 1 Gbps | 1 Gbps |
| **Sistema Operacional** | Ubuntu 22.04 LTS | Ubuntu 24.04 LTS |

### Contas e Serviços Necessários

- ✅ Provedor de VPS (Hostinger, DigitalOcean, AWS, etc.)
- ✅ Domínio registrado (ex: nexus.com)
- ✅ Conta de e-mail transacional (Hostinger Mail / SendGrid / SES)
- ✅ Conta Firebase (para FCM)
- ✅ Conta Mercado Pago (para pagamentos)
- ✅ Conta Bunny CDN (opcional, para streaming)
- ✅ Acesso SSH com chave pública

---

## 2. Estrutura Completa de Diretórios

```
/opt/nexus/                          # → Diretório raiz da aplicação
├── .env                             # Variáveis de ambiente (NUNCA versionar)
├── docker-compose.yml               # Orquestração Docker
├── Dockerfile.flutter               # Build do APK
├── deploy_vps.sh                    # Script de deploy automatizado
├── backup_nexus.sh                  # Script de backup
├── health_check.sh                  # Health check dos serviços
├── verify_vps_deployment.sh         # Verificação pós-deploy
├── guia/                            # Documentação
│   └── VPS_GUIDE_COMPLETO.md
│
├── backend/                         # API FastAPI
│   ├── Dockerfile                   # Dockerfile do backend
│   ├── requirements.txt             # Dependências Python
│   ├── alembic.ini                  # Migrations
│   ├── alembic/                     # Scripts de migração
│   ├── app/                         # Código principal
│   │   ├── main.py                  # Entrypoint FastAPI
│   │   ├── config.py                # Configurações (.env)
│   │   ├── database.py              # Conexão PostgreSQL
│   │   ├── models.py                # Modelos SQLAlchemy
│   │   ├── schemas.py               # Schemas Pydantic
│   │   ├── security.py              # Autenticação JWT
│   │   ├── metrics.py               # Métricas Prometheus
│   │   ├── logging_config.py        # Configuração de logs JSON
│   │   ├── logging_config_improved.py
│   │   ├── exception_handlers.py    # Tratamento de erros
│   │   ├── dependencies.py          # Dependências FastAPI
│   │   ├── middleware/              # Middlewares
│   │   │   ├── rate_limit.py        # Rate limiting
│   │   │   └── stream_auth.py       # Autenticação de streams
│   │   ├── routers/                 # Rotas da API
│   │   │   ├── auth.py              # Autenticação
│   │   │   ├── media.py             # Mídia/catálogo
│   │   │   ├── profiles.py          # Perfis de usuário
│   │   │   ├── history.py           # Histórico de reprodução
│   │   │   ├── episodes.py          # Episódios
│   │   │   ├── ratings.py           # Avaliações
│   │   │   ├── watchlist.py         # Lista de assistir
│   │   │   ├── subscriptions.py     # Assinaturas
│   │   │   ├── subscriptions_trial.py
│   │   │   ├── payments.py          # Pagamentos
│   │   │   ├── webhooks.py          # Webhooks MP/Stripe
│   │   │   ├── admin.py             # Admin
│   │   │   ├── notifications.py     # Notificações
│   │   │   ├── downloads.py         # Downloads
│   │   │   ├── queue_jobs.py        # Jobs em fila
│   │   │   └── recommendations.py   # Recomendações
│   │   └── services/                # Serviços
│   │       ├── email_service.py     # E-mail (Hostinger)
│   │       ├── firebase_service.py  # Firebase FCM
│   │       ├── mercadopago_service.py    # Mercado Pago
│   │       ├── cache_service.py     # Cache Redis
│   │       ├── queue_service.py     # Filas Redis
│   │       ├── queue_audit_service.py    # Auditoria de filas
│   │       ├── media_service.py     # Serviço de mídia
│   │       ├── stream_token_service.py   # Tokens de stream
│   │       ├── auth_session_service.py   # Sessões
│   │       ├── subscription_limits.py    # Limites por plano
│   │       ├── trial_service.py     # Trial grátis
│   │       ├── rate_limit_service.py    # Rate limiting
│   │       ├── pix_service.py       # Pagamentos PIX
│   │       ├── stripe_service.py    # Stripe
│   │       ├── webhook_service.py   # Webhooks
│   │       └── admin_bootstrap_service.py
│   ├── workers/                     # Workers de fila
│   │   ├── queue_worker.py          # Worker principal
│   │   └── transcoder.py            # Transcoder FFmpeg
│   ├── database/                    # Scripts SQL
│   │   ├── init.sql                 # Inicialização
│   │   ├── 002_add_trial_support.sql
│   │   ├── 003_add_device_tokens.sql
│   │   ├── 004_add_user_roles.sql
│   │   └── 005_add_indexes.sql
│   ├── storage/                     # Armazenamento
│   │   ├── streams/                 # Vídeos HLS
│   │   └── releases/                # APKs/AABs
│   ├── logs/                        # Logs locais (fallback)
│   ├── uploads/                     # Uploads temporários
│   └── tests/                       # Testes
│
├── admin/                           # Site estático (privacy/terms)
│   ├── index.html
│   ├── login.html
│   ├── dashboard.html
│   ├── privacy.html
│   ├── terms.html
│   ├── robots.txt
│   ├── sitemap.xml
│   └── src/
│       └── config.js
│
├── admin-panel-nexus/               # Painel Admin React
│   ├── package.json
│   ├── vite.config.js
│   ├── index.html
│   ├── src/
│   │   └── App.jsx
│   └── public/
│
├── nginx/                           # Configuração Nginx
│   ├── nginx.conf                   # Config principal
│   └── serve_releases.conf          # Servir APKs
│
├── monitoring/                      # Stack Prometheus/Grafana
│   ├── prometheus.yml               # Config Prometheus
│   ├── alert_rules.yml              # Regras de alerta
│   ├── alertmanager.yml             # Config Alertmanager
│   ├── alertmanager_templates.tmpl  # Templates de notificação
│   └── grafana/                     # Provisionamento Grafana
│       └── provisioning/
│           ├── datasources/
│           │   └── prometheus.yml
│           └── dashboards/
│               ├── dashboards.yml
│               └── nexus-system.json
│
├── kubernetes/                      # (Opcional) Config K8s
│
├── nexus_mobile/                    # App Flutter
│   ├── pubspec.yaml
│   └── lib/                         # Código Dart
│
├── certbot/                         # Certificados SSL (gerado pelo Let's Encrypt)
│   ├── conf/                        # Certificados
│   └── www/                         # Webroot
│
└── data/                            # Dados persistentes
    ├── postgres/                    # (via volume Docker)
    ├── prometheus/                  # (via volume Docker)
    ├── grafana/                     # (via volume Docker)
    └── alertmanager/                # (via volume Docker)

# Diretórios do Sistema
/var/log/nexus/                      # Logs centralizados
├── app.log                          # Log principal (JSON)
├── auth.log                         # Logs de autenticação
├── api.log                          # Logs de API
├── payments.log                     # Logs de pagamentos
├── database.log                     # Logs de banco
├── errors.log                       # Apenas erros
└── monitor.log                      # Logs de monitoramento

/backups/nexus/                      # Backups automáticos
├── postgres_YYYYMMDD_HHMMSS.sql
├── prometheus_YYYYMMDD_HHMMSS.tar.gz
├── grafana_dashboards_YYYYMMDD_HHMMSS.json
├── alertmanager_YYYYMMDD_HHMMSS.tar.gz
└── logs_YYYYMMDD_HHMMSS.tar.gz
```

---

## 3. Arquivos que Devem Ser Enviados para a VPS

### Essenciais (obrigatórios)

| Arquivo/Pasta | Descrição |
|---------------|-----------|
| `docker-compose.yml` | Orquestração de todos os containers |
| `backend/` | API FastAPI + Workers |
| `nginx/nginx.conf` | Configuração do proxy reverso |
| `admin/` | Páginas estáticas (privacy, terms) |
| `monitoring/` | Prometheus, Grafana, Alertmanager |
| `deploy_vps.sh` | Script de setup inicial |
| `backup_nexus.sh` | Script de backup |
| `health_check.sh` | Script de health check |
| `verify_vps_deployment.sh` | Verificação pós-deploy |

### Condicionais

| Arquivo/Pasta | Quando enviar |
|---------------|---------------|
| `admin-panel-nexus/` | Se for fazer deploy do painel admin React na VPS |
| `nexus_mobile/` | Se for compilar o app Flutter na VPS |
| `kubernetes/` | Se usar Kubernetes em vez de Docker Compose |
| `Dockerfile.flutter` | Se for buildar o APK via Docker |

---

## 4. Arquivos que NÃO Devem Ser Enviados

### ❌ Excluir Totalmente

| Arquivo/Pasta | Motivo |
|---------------|--------|
| `node_modules/` | Gerado pelo `npm install` (pesado, desnecessário) |
| `build/` | Artefatos de build do Flutter |
| `.dart_tool/` | Cache do Dart |
| `__pycache__/` | Cache do Python |
| `*.pyc` | Bytecode compilado |
| `.pytest_cache/` | Cache de testes |
| `.venv/` | Virtualenv local (usa Docker) |
| `.env` | Contém senhas em texto claro (criar na VPS) |
| `**/.env` | Qualquer arquivo .env |
| `*.jks`, `*.keystore` | Chaves de assinatura Android |
| `google-services.json` | Credenciais Firebase Android |
| `*.ipynb` | Notebooks Jupyter |
| `.git/` | Histórico Git (opcional manter para updates) |
| `nexus_mobile/build/` | Build do Flutter (pode ser > 1GB) |
| `nexus_mobile/ios/` | Código iOS (se não for compilar iOS) |
| `nexus_mobile/android/` | Código Android (se não for compilar Android) |
| `backend/logs/` | Logs locais de desenvolvimento |
| `backend/uploads/` | Uploads temporários locais |
| `backend/tests/` | Testes (não necessários em produção) |

### ⚠️ Arquivos para Ignorar via .gitignore

```gitignore
# Python
__pycache__/
*.py[cod]
.pytest_cache/
.venv/

# Node
node_modules/

# Flutter/Dart
.dart_tool/
build/
*.apk
*.aab
*.hprof

# Android
*.jks
*.keystore
google-services.json
local.properties

# IDE
.idea/
*.iml
.vscode/
*.swp
*.swo

# Environment
.env
**/.env

# Logs
*.log

# OS
.DS_Store
Thumbs.db

# Jupyter
.ipynb_checkpoints/
*.ipynb
```

---

## 5. Instalação do Ambiente Base

### Conectar à VPS

```bash
# Via SSH com chave pública (recomendado)
ssh -i ~/.ssh/sua_chave.pem root@SEU_IP_VPS

# Via SSH com senha
ssh root@SEU_IP_VPS
```

### Atualizar Sistema

```bash
# Atualizar lista de pacotes
apt-get update -y

# Atualizar todos os pacotes
apt-get upgrade -y

# Instalar pacotes base essenciais
apt-get install -y \
    curl \
    wget \
    git \
    htop \
    nload \
    net-tools \
    jq \
    unzip \
    zip \
    gzip \
    tar \
    tree \
    vim \
    nano \
    ufw \
    fail2ban \
    unattended-upgrades \
    apt-listchanges \
    needrestart \
    chrony \
    rsync \
    logrotate \
    certbot \
    python3-certbot-nginx \
    python3-pip \
    python3-venv \
    ffmpeg \
    build-essential \
    libpq-dev \
    libmagic1 \
    libssl-dev

# Limpar cache
apt-get autoremove -y
apt-get autoclean -y
```

### Configurar Fuso Horário

```bash
# Listar fusos
timedatectl list-timezones

# Configurar (exemplo: São Paulo)
timedatectl set-timezone America/Sao_Paulo

# Verificar
timedatectl
```

---

## 6. Docker e Docker Compose

### Instalação do Docker

```bash
# Instalar Docker via script oficial
curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
bash /tmp/get-docker.sh
rm /tmp/get-docker.sh

# Adicionar usuário ao grupo docker (evitar sudo)
usermod -aG docker $USER

# Ativar e iniciar Docker
systemctl enable docker
systemctl start docker

# Verificar instalação
docker --version
docker run hello-world
```

### Instalação do Docker Compose v2

```bash
# Docker Compose moderno (plugin)
apt-get install -y docker-compose-plugin

# Verificar
docker compose version
```

### Configuração de Performance do Docker

```bash
# Limitar logs dos containers (evitar disco cheio)
cat > /etc/docker/daemon.json << 'EOF'
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "storage-driver": "overlay2",
  "experimental": true,
  "metrics-addr": "0.0.0.0:9323"
}
EOF

# Aplicar configuração
systemctl restart docker
```

---

## 7. Nginx como Proxy Reverso

### Instalação do Nginx

```bash
# Instalar Nginx
apt-get install -y nginx

# Ativar e iniciar
systemctl enable nginx
systemctl start nginx
```

### Configuração do Nginx

O arquivo principal de configuração está em `/opt/nexus/nginx/nginx.conf`.

**Configuração de produção com proxy reverso para:**

- `nexus.com` → Site institucional + Páginas legais
- `api.nexus.com` → Backend FastAPI
- `admin.nexus.com` → Painel Administrativo
- `privacypolicy.nexus.com` → Política de Privacidade
- `termosdeuso.nexus.com` → Termos de Uso
- `cdn.nexus.com` → Conteúdo estático (Bunny CDN)

**Testar configuração:**

```bash
# Testar sintaxe
nginx -t

# Recarregar configuração
nginx -s reload

# Verificar logs de acesso/erro
tail -f /var/log/nginx/access.log
tail -f /var/log/nginx/error.log
```

---

## 8. SSL com Certbot (Let's Encrypt)

### Instalação

```bash
# Certbot já instalado na etapa 5
# Se não, instalar:
apt-get install -y certbot python3-certbot-nginx
```

### Obter Certificados

```bash
# Para cada domínio/subdomínio
certbot certonly --nginx -d nexus.com -d www.nexus.com
certbot certonly --nginx -d api.nexus.com
certbot certonly --nginx -d admin.nexus.com
certbot certonly --nginx -d privacypolicy.nexus.com
certbot certonly --nginx -d termosdeuso.nexus.com
```

### Renovação Automática

```bash
# Testar renovação
certbot renew --dry-run

# Verificar status
systemctl list-timers | grep certbot

# Script de renovação automática (já incluso no security_hardening.sh)
cat > /usr/local/bin/certbot_renew.sh << 'SCRIPT'
#!/bin/bash
certbot renew --quiet --agree-tos
docker exec nexus-nginx-1 nginx -s reload 2>/dev/null || systemctl reload nginx
SCRIPT
chmod +x /usr/local/bin/certbot_renew.sh

# Cron job: toda segunda às 3AM
echo "0 3 * * 1 root /usr/local/bin/certbot_renew.sh >> /var/log/nexus/certbot_renew.log 2>&1" >> /etc/crontab
```

---

## 9. PostgreSQL

O PostgreSQL é executado via Docker. Não instalar diretamente no host.

### Configuração via Docker

```yaml
# No docker-compose.yml
postgres:
  image: postgres:16
  restart: always
  environment:
    POSTGRES_DB: nexus
    POSTGRES_USER: postgres
    POSTGRES_PASSWORD: ${DB_PASSWORD}
  ports:
    - "5432:5432"  # Não expor em produção (remover ou restringir)
  volumes:
    - postgres_data:/var/lib/postgresql/data
    - ./backend/database/init.sql:/docker-entrypoint-initdb.d/01-init.sql:ro
  healthcheck:
    test: ["CMD-SHELL", "pg_isready -U postgres"]
    interval: 10s
    timeout: 5s
    retries: 5
```

### Comandos Úteis

```bash
# Conectar ao PostgreSQL
docker compose exec postgres psql -U postgres -d nexus

# Executar SQL
docker compose exec postgres psql -U postgres -d nexus -c "SELECT * FROM users;"

# Executar script SQL
docker compose exec -T postgres psql -U postgres -d nexus < backend/database/init.sql

# Backup manual
docker compose exec -T postgres pg_dump -U postgres nexus > backup_$(date +%Y%m%d).sql

# Restore
cat backup.sql | docker compose exec -T postgres psql -U postgres nexus

# Verificar conexões ativas
docker compose exec postgres psql -U postgres -d nexus -c "SELECT * FROM pg_stat_activity;"

# Verificar tamanho do banco
docker compose exec postgres psql -U postgres -d nexus -c "SELECT pg_database_size('nexus')/1024/1024 as size_mb;"
```

---

## 10. Redis

### Configuração via Docker

```yaml
# No docker-compose.yml
redis:
  image: redis:7
  restart: always
  ports:
    - "6379:6379"  # Não expor em produção
  command: ["redis-server", "--requirepass", "${REDIS_PASSWORD}", "--appendonly", "yes"]
  healthcheck:
    test: ["CMD", "redis-cli", "ping"]
    interval: 10s
    timeout: 5s
    retries: 5
  volumes:
    - redis_data:/data
```

### Comandos Úteis

```bash
# Testar conexão
docker compose exec redis redis-cli -a "${REDIS_PASSWORD}" ping

# Verificar uso de memória
docker compose exec redis redis-cli -a "${REDIS_PASSWORD}" INFO memory

# Listar chaves
docker compose exec redis redis-cli -a "${REDIS_PASSWORD}" KEYS "*"

# Monitorar em tempo real
docker compose exec redis redis-cli -a "${REDIS_PASSWORD}" MONITOR

# Verificar tamanho das filas
docker compose exec redis redis-cli -a "${REDIS_PASSWORD}" LLEN "jobs:import_media"
docker compose exec redis redis-cli -a "${REDIS_PASSWORD}" LLEN "jobs:push_notifications"
```

---

## 11. Variáveis de Ambiente (.env)

O arquivo `.env` é a alma da configuração. Deve ser criado manualmente na VPS.

### Template Completo

```bash
# =============================================
# NEXUSTWOS - PRODUCTION ENVIRONMENT VARIABLES
# =============================================

# === Database ===
DATABASE_URL=postgresql://postgres:SUA_SENHA_AQUI@postgres:5432/nexus
DB_NAME=nexus
DB_USER=postgres
DB_PASSWORD=SUA_SENHA_AQUI

# === Redis ===
REDIS_URL=redis://:SUA_SENHA_REDIS@redis:6379/0
REDIS_PASSWORD=SUA_SENHA_REDIS

# === Security ===
SECRET_KEY=gerar-uma-chave-aleatoria-muito-longa-aqui-com-python
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30
REFRESH_TOKEN_EXPIRE_DAYS=7

# === Application ===
APP_NAME=NexusTwos
ENVIRONMENT=production
LOG_LEVEL=INFO
FRONTEND_URL=https://nexus.com
ADMIN_FRONTEND_URL=https://admin.nexus.com
FRONTEND_RESET_PASSWORD_URL=https://nexus.com/reset-password

# === SMTP (Hostinger Mail) ===
SMTP_SERVER=smtp.hostinger.com
SMTP_PORT=465
SMTP_USER=noreply@nexus.com
SMTP_PASSWORD=SUA_SENHA_SMTP
SMTP_SECURITY=ssl
SMTP_FROM_EMAIL=noreply@nexus.com
SMTP_FROM_NAME=NexusTwos

# === Firebase Cloud Messaging ===
FIREBASE_CREDENTIALS_PATH=/app/firebase-credentials.json

# === Mercado Pago ===
MERCADOPAGO_ACCESS_TOKEN=TEST-123456789-abcdef
MERCADOPAGO_CLIENT_ID=SEU_CLIENT_ID
MERCADOPAGO_WEBHOOK_SECRET=SEU_WEBHOOK_SECRET
WEBHOOK_URL=https://api.nexus.com/webhook

# === Stripe (opcional) ===
STRIPE_SECRET_KEY=sk_live_xxx
STRIPE_WEBHOOK_SECRET=whsec_xxx
STRIPE_PUBLISHABLE_KEY=pk_live_xxx

# === Admin & Billing ===
ADMIN_EMAILS=admin@nexus.com
NON_BILLING_PREMIUM_EMAILS=admin@nexus.com,admin2@nexus.com

# === Monitoring (Grafana) ===
GF_ADMIN_USER=admin
GF_ADMIN_PASSWORD=SUA_SENHA_GRAFANA

# === Monitoring (Alertmanager) ===
SMTP_USER=noreply@nexus.com
SMTP_PASSWORD=SUA_SENHA_SMTP
SMTP_FROM_EMAIL=noreply@nexus.com
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/SEU/WEBHOOK/AQUI
TELEGRAM_CHAT_ID=SEU_CHAT_ID
ADMIN_EMAILS=admin@nexus.com
```

### Gerar SECRET_KEY segura

```bash
# Gerar chave aleatória de 50 caracteres
python3 -c "import secrets; print(secrets.token_urlsafe(50))"
# Exemplo: x7K2p9mQ4rZ8vF1nJ3wL5yB6cE0gH2iA4dS6uT8oP0kM2nR4tV6xY8zA

# Copiar o resultado e colar no .env como SECRET_KEY
```

### Regras de Segurança do .env

```bash
# 1. Criar o arquivo na VPS manualmente
nano /opt/nexus/.env

# 2. Proteger permissões
chmod 600 /opt/nexus/.env
chown root:root /opt/nexus/.env

# 3. NUNCA versionar no Git
echo ".env" >> .gitignore

# 4. Fazer backup seguro (criptografado)
gpg -c /opt/nexus/.env  # Será solicitada uma senha
```

---

## 12. Backend FastAPI

### Estrutura do Container

```dockerfile
# backend/Dockerfile
FROM python:3.12-slim AS builder
WORKDIR /build
RUN apt-get update && apt-get install -y --no-install-recommends gcc libpq-dev
COPY requirements.txt .
RUN pip install --no-cache-dir --user -r requirements.txt

FROM python:3.12-slim AS runtime
RUN groupadd -r nexus && useradd -r -g nexus nexus
WORKDIR /app
RUN apt-get update && apt-get install -y --no-install-recommends libmagic1 libpq5 ffmpeg
COPY --from=builder /root/.local /usr/local/
COPY . .
RUN mkdir -p /var/log/nexus storage/streams storage/releases uploads && \
    chown -R nexus:nexus /var/log/nexus storage uploads
USER nexus
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python -c "import http.client; conn=http.client.HTTPConnection('localhost:8000'); conn.request('GET','/health'); resp=conn.getresponse(); exit(0) if resp.status==200 else exit(1)"
EXPOSE 8000
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

### Rodar Migrations

```bash
# Após iniciar os containers
docker compose exec backend alembic upgrade head

# Verificar status
docker compose exec backend alembic current

# Criar nova migration
docker compose exec backend alembic revision --autogenerate -m "descricao"
```

### Primeiro Acesso Admin

```bash
# Conectar ao PostgreSQL
docker compose exec postgres psql -U postgres -d nexus

# Tornar um usuário admin
UPDATE users SET role = 'admin' WHERE email = 'seu-email@nexus.com';

# Verificar
SELECT id, email, role FROM users;
```

---

## 13. Painel Administrativo

### Opção 1: Servir via Backend (Recomendado)

O painel admin é servido como parte do backend FastAPI na rota `/admin/`.

```bash
# Acessar via navegador
https://admin.nexus.com  # Configurado no nginx.conf
```

### Opção 2: Buildar e Servir Separadamente

Se o painel React estiver em `/opt/nexus/admin-panel-nexus/`:

```bash
# Buildar
cd /opt/nexus/admin-panel-nexus
npm install
npm run build

# Servir via Docker
cat > Dockerfile.admin << 'EOF'
FROM nginx:alpine
COPY ./dist /usr/share/nginx/html
COPY ./nginx.admin.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
EOF

docker build -t nexus-admin -f Dockerfile.admin .
docker run -d --name nexus-admin -p 3000:80 nexus-admin
```

### Credenciais Padrão

- **URL:** https://admin.nexus.com
- **Email:** admin@nexus.com (definido em ADMIN_EMAILS)
- **Senha:** Definida via fluxo de recuperação de senha

---

## 14. Workers e Filas

### Worker de Processamento

Processa dois tipos de jobs via Redis:

1. **Importação de Mídia** (`jobs:import_media`) → Importa itens do catálogo
2. **Notificações Push** (`jobs:push_notifications`) → Envia notificações FCM

### Iniciar/Parar Worker

```bash
# Worker roda como container separado no docker-compose
docker compose up -d worker

# Ver logs do worker
docker compose logs -f worker

# Verificar status das filas
docker compose exec redis redis-cli -a "${REDIS_PASSWORD}" LLEN "jobs:import_media"
docker compose exec redis redis-cli -a "${REDIS_PASSWORD}" LLEN "jobs:push_notifications"

# Forçar processamento manual
docker compose exec worker python -c "
from workers.queue_worker import redis_client, IMPORT_QUEUE
import json
client = redis_client()
client.rpush(IMPORT_QUEUE, json.dumps({'type': 'import_media_batch', 'items': []}))
print('Job de teste enfileirado')
"
```

### Transcoder (FFmpeg)

```bash
# Processar um vídeo para HLS manualmente
docker compose exec backend python -c "
from workers.transcoder import process_video
master = process_video('uploads/video.mp4', 'storage/streams/meu_video')
print(f'Master playlist: {master}')
"

# Verificar resultado
ls -la /opt/nexus/backend/storage/streams/meu_video/
```

---

## 15. Serviços Docker (docker-compose.yml)

### Stack Completa

| Serviço | Porta | Descrição |
|---------|-------|-----------|
| `postgres` | 5432 | Banco de dados relacional |
| `redis` | 6379 | Cache e filas |
| `backend` | 8000 | API FastAPI |
| `worker` | - | Processamento de filas |
| `nginx` | 80/443 | Proxy reverso |
| `prometheus` | 9090 | Coleta de métricas |
| `grafana` | 3000 | Dashboards |
| `alertmanager` | 9093 | Alertas |
| `postgres_exporter` | 9187 | Métricas PostgreSQL |
| `redis_exporter` | 9121 | Métricas Redis |
| `node_exporter` | 9100 | Métricas do sistema |
| `cadvisor` | 8080 | Métricas Docker |

### Comandos de Gerenciamento

```bash
# Iniciar todos os serviços
cd /opt/nexus && docker compose up -d

# Iniciar serviços específicos
docker compose up -d postgres redis backend worker nginx

# Iniciar apenas monitoramento
docker compose up -d prometheus grafana alertmanager

# Parar tudo
docker compose down

# Parar e remover volumes (⚠️ PERDE DADOS)
docker compose down -v

# Ver status
docker compose ps

# Ver logs em tempo real
docker compose logs -f

# Ver logs de um serviço específico
docker compose logs -f backend
docker compose logs -f worker
```

---

## 16. Configuração de Logs

### Estrutura de Logs

Todos os logs são centralizados em `/var/log/nexus/` em formato JSON.

```bash
/var/log/nexus/
├── app.log          # Log principal (rotação: 10x100MB)
├── auth.log         # Autenticação (rotação: 10x50MB)
├── api.log          # Requisições API (rotação: 10x50MB)
├── payments.log     # Pagamentos (rotação: 10x50MB)
├── database.log     # Banco de dados (rotação: 10x50MB)
├── errors.log       # Apenas erros (rotação: 20x50MB)
├── monitor.log      # Monitoramento do sistema
├── backup.log       # Log de backups
├── health.log       # Health checks
└── certbot_renew.log # Renovação SSL
```

### Formato JSON Estruturado

```json
{
  "timestamp": "2026-07-17T15:30:00Z",
  "level": "INFO",
  "logger": "app.routers.auth",
  "message": "Login bem-sucedido",
  "environment": "production",
  "request_id": "abc-123",
  "user_id": "uuid-do-usuario",
  "endpoint": "/auth/login",
  "method": "POST",
  "status_code": 200,
  "duration_ms": 45.2
}
```

### Logrotate

```bash
# Configuração de rotação automática (já criada no setup)
cat > /etc/logrotate.d/nexus << 'EOF'
/var/log/nexus/*.log {
    daily
    rotate 30
    compress
    delaycompress
    missingok
    notifempty
    create 0640 www-data adm
    sharedscripts
    postrotate
        systemctl reload nginx 2>/dev/null || true
    endscript
}
EOF

# Testar rotação
logrotate -d /etc/logrotate.d/nexus

# Forçar rotação manual
logrotate -f /etc/logrotate.d/nexus
```

### Consultar Logs

```bash
# Últimas 100 linhas em tempo real
tail -f /var/log/nexus/app.log | jq .

# Filtrar por nível
tail -f /var/log/nexus/app.log | jq 'select(.level == "ERROR")'

# Filtrar por endpoint
tail -f /var/log/nexus/api.log | jq 'select(.endpoint == "/auth/login")'

# Contar erros nas últimas 24h
grep -c '"level":"ERROR"' /var/log/nexus/app.log

# Buscar por usuário específico
grep '"user_id":"SEU_UUID"' /var/log/nexus/auth.log

# Ver logs do Docker container
docker compose logs --tail=100 backend

# Exportar logs para análise
cat /var/log/nexus/app.log | jq -c 'select(.level == "ERROR")' > /tmp/errors.json
```

---

## 17. Backup Automático

### Script de Backup Completo

Localizado em `/opt/nexus/backup_nexus.sh`, realiza backup de:

1. **PostgreSQL** - Dump completo do banco
2. **Prometheus** - Dados de métricas
3. **Grafana** - Dashboards exportados
4. **Alertmanager** - Dados de alertas
5. **Logs** - Compactação dos logs
6. **Arquivos de Configuração** - docker-compose, nginx.conf, etc.

### Configuração Cron

```bash
# Editar crontab do root
sudo crontab -e

# Adicionar:
# Backup diário às 2:00 AM
0 2 * * * /opt/nexus/backup_nexus.sh >> /var/log/nexus/backup.log 2>&1

# Health check a cada 5 minutos
*/5 * * * * /opt/nexus/health_check.sh >> /var/log/nexus/health.log 2>&1

# Limpeza de logs antigos toda segunda
0 3 * * 1 find /var/log/nexus -name "*.log.*" -mtime +30 -delete

# Renovação SSL toda segunda às 3:00 AM
0 3 * * 1 /usr/local/bin/certbot_renew.sh >> /var/log/nexus/certbot_renew.log 2>&1
```

### Restaurar Backup

```bash
# Listar backups disponíveis
ls -lh /backups/nexus/

# Restaurar PostgreSQL
cat /backups/nexus/postgres_20260717_020000.sql | docker compose exec -T postgres psql -U postgres nexus

# Extrair backup completo
tar -xzf /backups/nexus/nexus_backup_20260717_020000.tar.gz -C /tmp/restore/
```

---

## 18. Firewall (UFW)

### Configuração Base

```bash
# Ativar UFW
ufw --force enable

# Política padrão: negar tudo
ufw default deny incoming
ufw default allow outgoing

# Liberar SSH
ufw allow 22/tcp

# Liberar HTTP/HTTPS
ufw allow 80/tcp
ufw allow 443/tcp

# Liberar portas internas (se necessário para debug)
# ufw allow from 192.168.0.0/16 to any port 9090 proto tcp  # Prometheus (restrito)
# ufw allow from 192.168.0.0/16 to any port 3000 proto tcp  # Grafana (restrito)

# Verificar regras
ufw status verbose

# Ver portas em escuta
ss -tlnp
netstat -tulpn
```

### Regras para Ambientes de Produção

```bash
# APENAS portas necessárias expostas
ufw allow 22/tcp    # SSH
ufw allow 80/tcp    # HTTP
ufw allow 443/tcp   # HTTPS

# NÃO expor portas internas (5432, 6379, 8000, 9090, 3000)
# Se precisar acessar, use SSH tunnel:

# Acessar Grafana via tunnel SSH
ssh -L 3000:localhost:3000 root@SEU_IP_VPS

# Acessar banco via tunnel SSH
ssh -L 5432:localhost:5432 root@SEU_IP_VPS
```

---

## 19. Segurança da VPS

### SSH Hardening

```bash
# Backup da configuração original
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak

# Configurações seguras
cat >> /etc/ssh/sshd_config << 'EOF'
Port 22
PermitRootLogin no
PubkeyAuthentication yes
PasswordAuthentication no
PermitEmptyPasswords no
X11Forwarding no
MaxAuthTries 3
MaxSessions 10
ClientAliveInterval 300
ClientAliveCountMax 2
TCPKeepAlive yes
EOF

# Restart SSH
systemctl restart sshd
```

### Fail2Ban

```bash
# Configuração para proteger SSH, Nginx e serviços
cat > /etc/fail2ban/jail.local << 'EOF'
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5
destemail = admin@nexus.com

[sshd]
enabled = true
port = ssh
filter = sshd
maxretry = 3

[nginx-http-auth]
enabled = true
port = http,https
filter = nginx-http-auth
logpath = /var/log/nginx/error.log

[nginx-badbots]
enabled = true
port = http,https
filter = nginx-badbots
logpath = /var/log/nginx/access.log
maxretry = 2
EOF

systemctl restart fail2ban
fail2ban-client status
```

### Kernel Hardening

```bash
# Aplicar configurações de segurança do kernel
cat > /etc/sysctl.d/99-hardening.conf << 'EOF'
# Segurança de rede
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_syn_backlog = 2048
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0

# Proteção contra ataques
net.ipv4.tcp_rfc1337 = 1
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1

# Performance
net.core.netdev_max_backlog = 5000
net.ipv4.tcp_fastopen = 3
EOF

sysctl -p /etc/sysctl.d/99-hardening.conf
```

### Atualizações Automáticas de Segurança

```bash
# Configurar unattended-upgrades
cat > /etc/apt/apt.conf.d/50unattended-upgrades << 'EOF'
Unattended-Upgrade::Allowed-Origins {
    "${distro_id}:${distro_codename}-security";
    "${distro_id}ESMApps:${distro_codename}-apps-security";
    "${distro_id}ESM:${distro_codename}-infra-security";
};
Unattended-Upgrade::Mail "admin@nexus.com";
Unattended-Upgrade::MailReport "on-change";
Unattended-Upgrade::Automatic-Reboot "false";
EOF

# Ativar
dpkg-reconfigure --priority=low unattended-upgrades
```

---

## 20. Domínio e Subdomínios

### Configuração DNS

No painel do seu provedor de domínio, configure os seguintes registros:

```
# Registros A (apontar para o IP da VPS)
nexus.com         A    SEU_IP_VPS
www.nexus.com    A    SEU_IP_VPS
api.nexus.com    A    SEU_IP_VPS
admin.nexus.com  A    SEU_IP_VPS

# Registros CNAME (apontar para Bunny CDN)
cdn.nexus.com    CNAME  nexus.b-cdn.net

# Registros MX (Hostinger Mail)
@                MX    mx1.hostinger.com
@                MX    mx2.hostinger.com

# Registros TXT
@                TXT   v=spf1 include:hostinger.com ~all

# Registros AAAA (IPv6 - opcional)
nexus.com         AAAA  SEU_IP_V6
```

### Verificar DNS

```bash
# Verificar resolução
nslookup nexus.com
nslookup api.nexus.com
nslookup admin.nexus.com

# Verificar propagação
dig nexux.com +short
dig api.nexus.com +short
```

---

## 21. Bunny CDN

### Configuração Bunny CDN para Streaming

1. Criar um Pull Zone no painel Bunny CDN
2. Configurar como origin o servidor da API: `https://api.nexus.com`
3. Ativar otimização de vídeo

### Configuração no Nginx

No `nginx.conf`, as regras de cache para HLS já estão configuradas:

```nginx
# Master playlists (.m3u8) - Cache por 1 hora
location ~ \.m3u8$ {
    add_header Cache-Control "public, max-age=3600" always;
}

# Segmentos TS (.ts) - Cache por 1 ano
location ~ \.ts$ {
    add_header Cache-Control "public, max-age=31536000, immutable" always;
}
```

---

## 22. Serviço de E-mail (Hostinger Mail)

### Configuração SMTP

No arquivo `.env`:

```env
SMTP_SERVER=smtp.hostinger.com
SMTP_PORT=465
SMTP_USER=noreply@nexus.com
SMTP_PASSWORD=SUA_SENHA_SMTP
SMTP_SECURITY=ssl
SMTP_FROM_EMAIL=noreply@nexus.com
SMTP_FROM_NAME=NexusTwos
```

### Testar Serviço de E-mail

```bash
# Testar via container backend
docker compose exec backend python -c "
from app.services.email_service import get_email_service
svc = get_email_service()
print(f'SMTP Configurado: {svc.enabled}')
print(f'Servidor: {svc.server}:{svc.port}')
print(f'Usuário: {svc.user}')
"

# Enviar e-mail de teste
docker compose exec backend python -c "
from app.services.email_service import get_email_service
svc = get_email_service()
result = svc.send_email(
    to_email='seu-email@teste.com',
    subject='Teste NexusTwos',
    body='Este é um e-mail de teste do servidor de produção.'
)
print(f'E-mail enviado: {result}')
"
```

### Templates de E-mail Disponíveis

- **Boas-vindas** → `send_welcome_email(to_email, username)`
- **Redefinição de senha** → `send_password_reset_email(to_email, reset_token)`
- **Recibo de pagamento** → `send_payment_receipt_email(to_email, plan, amount, payment_id, status)`
- **Comunicado admin** → `send_admin_announcement_email(to_email, title, message)`

---

## 23. Firebase Cloud Messaging (FCM)

### Credenciais

1. Acessar [Firebase Console](https://console.firebase.google.com)
2. Projeto → Configurações → Contas de Serviço
3. Gerar nova chave privada
4. Salvar como `firebase-credentials.json`

### Configuração na VPS

```bash
# Criar diretório para credenciais
mkdir -p /opt/nexus/backend/firebase

# Copiar arquivo de credenciais (FAZER VIA SCP)
scp firebase-credentials.json root@SEU_IP_VPS:/opt/nexus/backend/firebase-credentials.json

# Proteger permissões
chmod 600 /opt/nexus/backend/firebase-credentials.json

# No .env, configurar:
FIREBASE_CREDENTIALS_PATH=/app/firebase-credentials.json
```

### Testar Notificação

```bash
docker compose exec backend python -c "
from app.services.firebase_service import FirebaseService
fcm = FirebaseService()
print(f'Firebase inicializado: {fcm.is_initialized()}')

# Enviar notificação de teste
result = fcm.send_notification(
    device_token='SEU_DEVICE_TOKEN_AQUI',
    title='Teste NexusTwos',
    body='Notificação de teste da produção'
)
print(f'Notificação enviada: {result}')
"
```

---

## 24. Mercado Pago

### Configuração

1. Acessar [Mercado Pago Developers](https://developers.mercadopago.com)
2. Criar aplicação e obter `ACCESS_TOKEN` de produção
3. Configurar webhook URL: `https://api.nexus.com/webhook/payments`

### Variáveis de Ambiente

```env
MERCADOPAGO_ACCESS_TOKEN=APP_USR-123456789-abcdef
MERCADOPAGO_CLIENT_ID=SEU_CLIENT_ID
MERCADOPAGO_WEBHOOK_SECRET=SEU_WEBHOOK_SECRET
WEBHOOK_URL=https://api.nexus.com
```

### Testar Integração

```bash
docker compose exec backend python -c "
from app.services.mercadopago_service import MercadoPagoService
mp = MercadoPagoService()
print(f'MercadoPago configurado com token: {mp.access_token[:10]}...')

# Criar preferência de teste
pref = mp.create_preference(
    user_id='test-uuid',
    username='Teste',
    email='teste@nexus.com',
    plan='Premium',
    price=29.90,
    description='Plano Premium - Teste'
)
print(f'Preference ID: {pref[\"preference_id\"]}')
print(f'Payment URL: {pref[\"payment_url\"]}')
"
```

---

## 25. FFmpeg

### Instalação

```bash
# FFmpeg já instalado na etapa 5
apt-get install -y ffmpeg

# Verificar instalação
ffmpeg -version
ffprobe -version
```

### Uso no Projeto

FFmpeg é usado pelo transcoder (`backend/workers/transcoder.py`) para:

1. **Converter vídeos para HLS** → Streaming adaptativo
2. **Gerar múltiplas resoluções** → 1080p, 720p, 480p
3. **Criar playlists master** → .m3u8

### Testar Transcoder

```bash
# Upload de vídeo de teste
docker compose cp video_teste.mp4 backend:/app/uploads/video_teste.mp4

# Executar transcoder
docker compose exec backend python -c "
from workers.transcoder import process_video
master = process_video('uploads/video_teste.mp4', 'storage/streams/video_teste')
print(f'Stream gerado: {master}')
"

# Verificar resultado
ls -la /opt/nexus/backend/storage/streams/video_teste/
```

---

## 26. Monitoramento (Prometheus + Grafana)

### Stack de Monitoramento

| Serviço | Porta | Função | Acesso |
|---------|-------|--------|--------|
| Prometheus | 9090 | Coleta métricas | Via SSH tunnel |
| Grafana | 3000 | Dashboards | Via SSH tunnel |
| Alertmanager | 9093 | Alertas | Via SSH tunnel |

### Acesso via SSH Tunnel

```bash
# Acessar Grafana
ssh -L 3000:localhost:3000 root@SEU_IP_VPS
# Depois abrir: http://localhost:3000

# Acessar Prometheus
ssh -L 9090:localhost:9090 root@SEU_IP_VPS
# Depois abrir: http://localhost:9090

# Acessar Alertmanager
ssh -L 9093:localhost:9093 root@SEU_IP_VPS
# Depois abrir: http://localhost:9093
```

### Credenciais Grafana

- **Usuário:** admin
- **Senha:** Definida em `GF_ADMIN_PASSWORD` no `.env`

### Configuração de Alertas

Editar `/opt/nexus/monitoring/alertmanager.yml`:

```yaml
# Configurar e-mail
smtp_smarthost: smtp.hostinger.com:465
smtp_auth_username: noreply@nexus.com
smtp_auth_password: SUA_SENHA
smtp_from: noreply@nexus.com

# Configurar Slack (opcional)
slack_api_url: https://hooks.slack.com/services/SEU/WEBHOOK

# Configurar Telegram (opcional)
telegram_configs:
  - chat_id: SEU_CHAT_ID
    bot_token: SEU_BOT_TOKEN
```

### Alertas Pré-configurados

| Alerta | Severidade | Descrição |
|--------|------------|-----------|
| HighCPUUsage | Critical | CPU > 90% por 5 min |
| HighMemoryUsage | Warning | Memória > 85% |
| LowDiskSpace | Critical | Disco < 10% livre |
| APIIsDown | Critical | API offline |
| PostgreSQLNotResponding | Critical | PostgreSQL offline |
| RedisNotResponding | Critical | Redis offline |
| ContainerStopped | Critical | Container parado |
| HighErrorRate | Warning | Erros HTTP > 5% |
| SlowAPIResponse | Warning | P95 resposta > 5s |

### Métricas Coletadas

```bash
# Métricas da aplicação
curl http://localhost:8000/metrics  # Somente internamente

# Métricas do sistema (node_exporter)
curl http://localhost:9100/metrics

# Métricas Docker (cadvisor)
curl http://localhost:8080/metrics
```

---

## 27. Comandos de Gerenciamento

### Iniciar/Parar/Reiniciar Serviços

```bash
# ===== STACK COMPLETO =====

# Iniciar tudo
cd /opt/nexus && docker compose up -d

# Parar tudo
docker compose down

# Reiniciar tudo
docker compose restart

# Ver status
docker compose ps

# ===== SERVIÇOS INDIVIDUAIS =====

# Backend
docker compose restart backend
docker compose up -d --build backend  # Reconstruir imagem

# Worker
docker compose restart worker

# Banco de dados
docker compose restart postgres

# Redis
docker compose restart redis

# Nginx
docker compose restart nginx

# Monitoramento
docker compose restart prometheus grafana alertmanager

# ===== SISTEMA =====

# Nginx do host
systemctl restart nginx
systemctl reload nginx

# Docker
systemctl restart docker

# Fail2Ban
systemctl restart fail2ban
fail2ban-client status
```

### Atualizar Aplicação

```bash
# 1. Fazer backup antes
bash /opt/nexus/backup_nexus.sh

# 2. Atualizar código
cd /opt/nexus
git pull origin main

# 3. Reconstruir e reiniciar
docker compose up -d --build

# 4. Rodar migrations
docker compose exec backend alembic upgrade head

# 5. Verificar deploy
bash /opt/nexus/verify_vps_deployment.sh
```

---

## 28. Comandos para Verificar Logs e Diagnosticar

### Logs em Tempo Real

```bash
# Log principal da aplicação
tail -f /var/log/nexus/app.log | jq .

# Log de autenticação
tail -f /var/log/nexus/auth.log | jq .

# Log de pagamentos
tail -f /var/log/nexus/payments.log | jq .

# Log de erros (apenas ERROR)
tail -f /var/log/nexus/errors.log | jq .

# Logs Docker
docker compose logs -f
docker compose logs -f backend
docker compose logs -f worker
```

### Diagnóstico de Problemas

```bash
# 1. Verificar containers rodando
docker compose ps

# 2. Verificar logs de erro do backend
docker compose logs --tail=50 backend | grep -i error

# 3. Verificar conexão com banco
docker compose exec postgres pg_isready -U postgres

# 4. Verificar conexão Redis
docker compose exec redis redis-cli -a "${REDIS_PASSWORD}" ping

# 5. Verificar health da API
curl -s http://localhost:8000/health

# 6. Verificar espaço em disco
df -h

# 7. Verificar uso de memória
free -h

# 8. Verificar uso de CPU
htop

# 9. Verificar portas em uso
ss -tlnp

# 10. Verificar logs do Nginx
tail -f /var/log/nginx/error.log
tail -f /var/log/nginx/access.log | awk '{print $1}' | sort | uniq -c | sort -rn | head -20
```

### Health Check Completo

```bash
# Script de health check
bash /opt/nexus/health_check.sh

# Verificação de deploy
bash /opt/nexus/verify_vps_deployment.sh
```

---

## 29. Atualização sem Perda de Dados

### Procedimento Seguro de Atualização

```bash
#!/bin/bash
# Script: update_nexus.sh
# Uso: bash update_nexus.sh

set -e

echo "============================================"
echo "  Atualização NexusTwos - $(date)"
echo "============================================"

# 1. Backup
echo "[1/6] Fazendo backup..."
bash /opt/nexus/backup_nexus.sh

# 2. Atualizar código
echo "[2/6] Atualizando código..."
cd /opt/nexus
git stash  # Guarda alterações locais temporárias
git pull origin main
git stash pop || true  # Restaura alterações (se houver conflito, manual)

# 3. Reconstruir imagens
echo "[3/6] Reconstruindo containers..."
docker compose build --no-cache backend worker

# 4. Iniciar serviços gradualmente
echo "[4/6] Iniciando serviços..."

# Primeiro: banco e cache
docker compose up -d postgres redis
sleep 10

# Depois: backend e worker
docker compose up -d backend worker
sleep 10

# Por último: Nginx e monitoramento
docker compose up -d nginx prometheus grafana alertmanager

# 5. Rodar migrations
echo "[5/6] Rodando migrations..."
docker compose exec backend alembic upgrade head

# 6. Verificar
echo "[6/6] Verificando deploy..."
bash /opt/nexus/verify_vps_deployment.sh

echo "============================================"
echo "  ✅ Atualização concluída!"
echo "============================================"
```

### Rollback

```bash
# Caso algo dê errado:

# 1. Voltar versão anterior do código
cd /opt/nexus
git reflog  # Ver histórico
git reset --hard HEAD@{1}  # Voltar uma versão

# 2. Reconstruir e reiniciar
docker compose up -d --build

# 3. Restaurar banco de dados (se necessário)
cat /backups/nexus/postgres_*.sql | docker compose exec -T postgres psql -U postgres nexus
```

---

## 30. Checklist Final de Produção

### ✅ Pré-Deploy

- [ ] **VPS** criada com Ubuntu 22.04 LTS
- [ ] **SSH** configurado com chave pública e root desabilitado
- [ ] **Firewall** ativo (apenas 22, 80, 443)
- [ ] **Domínio** aponta para IP da VPS (DNS propagado)
- [ ] **Backup** do .env salvo com segurança
- [ ] **Credenciais SMTP** (Hostinger) prontas
- [ ] **Firebase** credentials baixadas
- [ ] **Mercado Pago** access token de produção
- [ ] **Bunny CDN** Pull Zone criada (se aplicável)

### ✅ Ambiente

- [ ] Sistema atualizado: `apt-get update && apt-get upgrade`
- [ ] Docker instalado: `docker --version`
- [ ] Docker Compose instalado: `docker compose version`
- [ ] Git configurado: `git clone` funcionando
- [ ] Permissões corretas: `chmod 600 .env`
- [ ] Fuso horário configurado: `timedatectl`
- [ ] FFmpeg instalado: `ffmpeg -version`

### ✅ Serviços Rodando

```bash
docker compose ps
```

- [ ] **postgres** - Rodando e saudável
- [ ] **redis** - Rodando e saudável
- [ ] **backend** - Rodando e saudável
- [ ] **worker** - Rodando
- [ ] **nginx** - Rodando (portas 80/443)
- [ ] **prometheus** - Rodando
- [ ] **grafana** - Rodando
- [ ] **alertmanager** - Rodando
- [ ] **node_exporter** - Rodando
- [ ] **redis_exporter** - Rodando
- [ ] **postgres_exporter** - Rodando
- [ ] **cadvisor** - Rodando

### ✅ API e Endpoints

```bash
# Testar endpoints
curl -s http://localhost:8000/health | jq .
curl -s http://localhost:8000/ | jq .
curl -s http://localhost:8000/metrics | head -20
```

- [ ] `/health` → `{"status": "healthy"}`
- [ ] `/` → Informações da plataforma
- [ ] `/metrics` → Métricas Prometheus
- [ ] `/docs` → Swagger UI (FastAPI)

### ✅ Banco de Dados

- [ ] PostgreSQL conectável: `pg_isready`
- [ ] Tabelas criadas: `\dt` no psql
- [ ] Migrations aplicadas: `alembic current`
- [ ] Admin user configurado: `SELECT * FROM users WHERE role = 'admin'`
- [ ] Índices criados: `\di`

### ✅ Redis

- [ ] Redis respondendo: `redis-cli ping`
- [ ] Filas vazias (inicialmente): `LLEN jobs:import_media`

### ✅ SSL

- [ ] Certificados obtidos: `certbot certificates`
- [ ] HTTPS funcionando: `curl -I https://api.nexus.com`
- [ ] Renovação automática configurada: `certbot renew --dry-run`

### ✅ E-mail

- [ ] SMTP configurado e testado
- [ ] Template de boas-vindas funcional
- [ ] Template de reset de senha funcional
- [ ] Recibo de pagamento funcional

### ✅ Firebase

- [ ] Credenciais no local correto
- [ ] SDK inicializado sem erros
- [ ] Notificação de teste enviada

### ✅ Mercado Pago

- [ ] Access token de produção configurado
- [ ] Webhook URL configurada
- [ ] Preferência de pagamento criada com sucesso

### ✅ Segurança

- [ ] Firewall ativo: `ufw status`
- [ ] SSH configurado (sem root, sem senha)
- [ ] Fail2Ban ativo: `fail2ban-client status`
- [ ] .env com permissão 600
- [ ] Atualizações automáticas configuradas
- [ ] Kernel hardening aplicado
- [ ] Logs em formato JSON com rotação

### ✅ Backup e Monitoramento

- [ ] Backup automático configurado (cron)
- [ ] Health check a cada 5 minutos (cron)
- [ ] Backups sendo gerados em `/backups/nexus/`
- [ ] Restauração de backup testada
- [ ] Grafana acessível e com dados
- [ ] Alertas configurados (email/Slack/Telegram)

### ✅ Performance

- [ ] CPU < 50% em idle
- [ ] Memória < 60% em idle
- [ ] Disco < 70% utilizado
- [ ] Docker sem containers parados

### ✅ Testes Finais

| Teste | Comando | Resultado Esperado |
|-------|---------|--------------------|
| Registrar usuário | `curl -X POST http://localhost:8000/auth/register -H "Content-Type: application/json" -d '{"email":"teste@teste.com","password":"Teste@123"}'` | `201 Created` |
| Login | `curl -X POST http://localhost:8000/auth/login -H "Content-Type: application/json" -d '{"email":"teste@teste.com","password":"Teste@123"}'` | Token JWT |
| Listar mídia | `curl http://localhost:8000/media/` | Lista de catálogo |
| Health check | `curl http://localhost:8000/health` | `{"status": "healthy"}` |
| HTTPS | `curl -I https://api.nexus.com` | `200 OK` |

### 🎉 Produção Pronta!

```
╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║        ✅ SISTEMA NEXUSTWOS PRONTO PARA PRODUÇÃO!            ║
║                                                               ║
║     🌐 Site:         https://nexus.com                        ║
║     🔧 API:          https://api.nexus.com/docs               ║
║     📊 Admin:        https://admin.nexus.com                  ║
║     📈 Grafana:      http://localhost:3000 (SSH tunnel)       ║
║     📧 Suporte:      admin@nexus.com                          ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
```

---

## 📚 Referências

- [Documentação FastAPI](https://fastapi.tiangolo.com/)
- [Docker Compose](https://docs.docker.com/compose/)
- [Nginx](https://nginx.org/en/docs/)
- [Certbot](https://certbot.eff.org/)
- [Prometheus](https://prometheus.io/docs/)
- [Grafana](https://grafana.com/docs/)
- [Firebase Admin SDK](https://firebase.google.com/docs/admin/setup)
- [Mercado Pago API](https://www.mercadopago.com.br/developers)
- [Bunny CDN](https://docs.bunny.net/)
- [Hostinger Email](https://www.hostinger.com/tutorials/how-to-create-email-account)

---

**Documentação gerada em:** Julho 2026  
**Versão do Sistema:** 2.0  
**Autor:** Equipe NexusTwos

