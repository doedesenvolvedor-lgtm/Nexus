# 🚀 Guia Completo de Configuração - Nexus VPS

> **Data:** 2026-08-05  
> **Versão:** 2.0  
> **Ambiente:** Ubuntu 20.04/22.04 LTS

---

## 📋 ÍNDICE

1. [Pré-requisitos](#pré-requisitos)
2. [Instalação Rápida (Automática)](#instalação-rápida)
3. [Configuração Manual (Passo a Passo)](#configuração-manual)
4. [Certificados HTTPS (Let's Encrypt)](#certificados-https)
5. [Firewall & Segurança](#firewall--segurança)
6. [Banco de Dados & Redis](#banco-de-dados--redis)
7. [Domínios & DNS](#domínios--dns)
8. [Backup & Recuperação](#backup--recuperação)
9. [Troubleshooting](#troubleshooting)
10. [Checklist de Produção](#checklist-de-produção)

---

## 🎯 Pré-requisitos

### Hardware Mínimo
```
✅ RAM: 2GB (4GB+ recomendado)
✅ CPU: 1 vCPU (2+ recomendado)
✅ Disco: 50GB SSD (100GB+ recomendado)
✅ Banda: 50+ Mbps
```

### Acesso & Ferramentas
```bash
✅ SSH root access (sem senha, com chave)
✅ Ubuntu 20.04 LTS ou 22.04 LTS
✅ Domínios DNS configurados
✅ Firewall permitindo portas 22, 80, 443
```

### Credenciais Necessárias
Antes de começar, reúna:
- [ ] Token MercadoPago (APP_...)
- [ ] Credenciais Firebase JSON
- [ ] Webhook Slack (opcional)
- [ ] Token Telegram Bot (opcional)
- [ ] Senha SMTP Hostinger
- [ ] Domínios DNS registrados

---

## ⚡ Instalação Rápida (Automática)

**Tempo estimado:** 15-20 minutos

### Passo 1: SSH na VPS

```bash
ssh root@seu-ip-vps
# Exemplo: ssh root@123.45.67.89
```

### Passo 2: Baixar Script de Deploy

```bash
cd /tmp
wget https://raw.githubusercontent.com/doedesenvolvedor-lgtm/Nexus/main/deploy_vps.sh
chmod +x deploy_vps.sh
```

### Passo 3: Executar Script

```bash
sudo bash deploy_vps.sh
```

**O script vai fazer:**
✅ Atualizar pacotes do SO
✅ Instalar Docker & Docker Compose
✅ Clonar repositório Nexus
✅ Criar diretórios de dados
✅ Criar volumes Docker
✅ Iniciar stack completa
✅ Gerar primeiras credenciais

### Passo 4: Configurar .env

```bash
# Copiar arquivo de exemplo
cd /opt/nexus
cp .env.docker-compose .env

# Editar com seus valores
nano .env
```

**Variáveis essenciais:**
```env
DB_PASSWORD=gere_uma_senha_forte
REDIS_PASSWORD=gere_uma_senha_forte
SECRET_KEY=gere_uma_chave_secreta_forte
GF_ADMIN_PASSWORD=altere_para_uma_senha_forte
MERCADOPAGO_ACCESS_TOKEN=APP_seu_token
ADMIN_EMAILS=seu_email@dominio.com
```

### Passo 5: Reiniciar Stack

```bash
docker-compose restart
docker-compose ps  # Verificar se tudo está rodando
```

---

## 🔧 Configuração Manual (Passo a Passo)

**Para quem prefere fazer manualmente ou debugar problemas**

### Passo 1: Preparar VPS

```bash
# Conectar
ssh root@seu-ip-vps

# Atualizar sistema
apt-get update && apt-get upgrade -y

# Instalar dependências
apt-get install -y \
  curl \
  wget \
  git \
  docker.io \
  docker-compose \
  python3-pip \
  certbot \
  python3-certbot-nginx \
  ufw
```

### Passo 2: Verificar Docker

```bash
# Verificar versão
docker --version
docker-compose --version

# Adicionar seu usuário ao grupo docker (opcional)
usermod -aG docker root
```

### Passo 3: Criar Diretórios

```bash
# Diretórios de dados
mkdir -p /opt/nexus
mkdir -p /var/log/nexus
mkdir -p /data/postgres
mkdir -p /data/redis
mkdir -p /data/prometheus
mkdir -p /data/grafana

# Permissões
chmod 777 /var/log/nexus
chmod 755 /data/*
```

### Passo 4: Clonar Repositório

```bash
cd /opt/nexus
git clone https://github.com/doedesenvolvedor-lgtm/Nexus.git .
# Ou se já existe
git pull origin main
```

### Passo 5: Criar Arquivo .env

```bash
# Usar o arquivo .env.vps como template
cp .env.vps .env

# Ou copiar arquivo de exemplo
cp .env.example .env

# Editar valores
nano .env
```

**Valores críticos:**
```env
# Banco de dados
DB_PASSWORD=$(openssl rand -base64 32)
REDIS_PASSWORD=$(openssl rand -base64 32)

# JWT
SECRET_KEY=$(python3 -c "import secrets; print(secrets.token_urlsafe(32))")

# Grafana (MUDE!)
GF_ADMIN_PASSWORD=$(openssl rand -base64 16)

# MercadoPago
MERCADOPAGO_ACCESS_TOKEN=APP_seu_token_real
MERCADOPAGO_CLIENT_ID=seu_client_id

# Emails
ADMIN_EMAILS=seu_email@dominio.com
SMTP_USER=noreply@seudominio.com
SMTP_PASSWORD=sua_senha_hostinger
```

### Passo 6: Verificar Configuração

```bash
# Validar docker-compose.yml
docker-compose config

# Se houver erro, corrigir .env
```

### Passo 7: Criar Volumes Docker

```bash
# Volumes nomeados (persistência de dados)
docker volume create postgres_data
docker volume create redis_data
docker volume create prometheus_data
docker volume create grafana_data
```

### Passo 8: Iniciar Stack

```bash
# Em background (-d = detached)
docker-compose up -d

# Acompanhar logs em tempo real
docker-compose logs -f

# Esperar ~2 minutos para tudo inicializar
```

### Passo 9: Verificar Saúde

```bash
# Listar containers
docker-compose ps

# Esperado:
# postgres       ✅ healthy
# redis         ✅ healthy
# backend       ✅ running
# worker        ✅ running
# nginx         ✅ running
# prometheus    ✅ running
# grafana       ✅ running

# Testar API (dentro da VPS)
curl http://localhost:8000/health
```

---

## 🔒 Certificados HTTPS (Let's Encrypt)

**Tempo estimado:** 10 minutos

### Passo 1: Configurar Domínios

Antes de começar, certifique-se que seus domínios apontam para o IP da VPS:

```
www.seudominio.com      → IP_VPS
api.seudominio.com      → IP_VPS
admin.seudominio.com    → IP_VPS
```

Testar com:
```bash
nslookup www.seudominio.com
nslookup api.seudominio.com
```

### Passo 2: Criar Certificados

```bash
cd /opt/nexus

# Criar diretórios para certificados
mkdir -p certbot/www
mkdir -p certbot/conf

# Gerar certificados com webroot
docker run --rm \
  -v $(pwd)/certbot/conf:/etc/letsencrypt \
  -v $(pwd)/certbot/www:/var/www/certbot \
  certbot/certbot certonly --webroot -w /var/www/certbot \
  -d seudominio.com \
  -d www.seudominio.com \
  -d api.seudominio.com \
  -d admin.seudominio.com \
  -d privacypolicy.seudominio.com \
  -d termosdeuso.seudominio.com \
  --agree-tos \
  --email seu_email@dominio.com \
  --non-interactive
```

**Esperado:**
```
Successfully received certificate.
Certificate is saved at: /etc/letsencrypt/live/seudominio.com/fullchain.pem
Key is saved at: /etc/letsencrypt/live/seudominio.com/privkey.pem
```

### Passo 3: Recarregar Nginx

```bash
docker-compose restart nginx

# Verificar logs
docker-compose logs nginx
```

### Passo 4: Testar HTTPS

```bash
# Testar com curl
curl -I https://api.seudominio.com

# Esperado: HTTP/2 200
```

### Passo 5: Configurar Renovação Automática (Cron)

```bash
# Editar crontab
crontab -e

# Adicionar linha (renova todo dia às 3 AM):
0 3 * * * cd /opt/nexus && docker run --rm -v $(pwd)/certbot/conf:/etc/letsencrypt -v $(pwd)/certbot/www:/var/www/certbot certbot/certbot renew --webroot -w /var/www/certbot && docker-compose restart nginx >> /var/log/certbot-renewal.log 2>&1

# Salvar (Ctrl+X, Y, Enter)
```

---

## 🛡️ Firewall & Segurança

### Passo 1: Configurar UFW (Firewall)

```bash
# Habilitar UFW
ufw enable

# Permitir SSH (ANTES de ativar firewall!)
ufw allow 22/tcp

# Permitir HTTP e HTTPS
ufw allow 80/tcp
ufw allow 443/tcp

# Bloquear outros portos (NÃO exponha internos!)
# ❌ NÃO EXPONHA:
# - 5432 (PostgreSQL)
# - 6379 (Redis)
# - 8000 (Backend interno)
# - 9090 (Prometheus)
# - 9093 (AlertManager)
# - 3000 (Grafana - se quiser usar, coloque atrás de auth)

# Verificar regras
ufw status verbose
```

### Passo 2: SSH Seguro

```bash
# Editar config SSH
nano /etc/ssh/sshd_config

# Mudanças recomendadas:
# Port 22222                    # Mudar porta (opcional)
# PasswordAuthentication no      # Apenas chaves SSH
# PermitRootLogin no             # Não permitir root direto
# MaxAuthTries 3                 # Limitar tentativas
# LoginGraceTime 60              # 60 segundos para autenticar

# Salvar e reiniciar SSH
systemctl restart sshd
```

### Passo 3: Proteção DDoS (Rate Limiting)

Nginx já tem rate limiting configurado em `/opt/nexus/nginx/nginx.conf`:

```bash
# Verificar se está ativo
grep -A 5 "limit_req_zone" /opt/nexus/nginx/nginx.conf
```

### Passo 4: Backup das Chaves SSH

```bash
# Backup das chaves SSH para fora da VPS
scp -r root@seu-ip-vps:/root/.ssh /tmp/nexus-ssh-backup

# ⚠️ SEGURANÇA: Armazene em local seguro
# Não compartilhe por email!
```

---

## 🗄️ Banco de Dados & Redis

### PostgreSQL Backup/Restore

```bash
# BACKUP: Fazer dump do banco
docker-compose exec -T postgres pg_dump \
  -U postgres nexus > /tmp/nexus-backup-$(date +%Y%m%d).sql

# RESTORE: Restaurar banco
docker-compose exec -T postgres psql \
  -U postgres nexus < /tmp/nexus-backup-20260805.sql

# Verificar tamanho do banco
docker-compose exec -T postgres psql \
  -U postgres -c "SELECT pg_size_pretty(pg_database_size('nexus'));"
```

### Redis Backup/Restore

```bash
# BACKUP: Fazer snapshot
docker-compose exec -T redis redis-cli BGSAVE

# Copiar arquivo de snapshot
docker cp nexus-redis-1:/data/dump.rdb /tmp/redis-dump.rdb

# RESTORE: Copiar arquivo back
docker cp /tmp/redis-dump.rdb nexus-redis-1:/data/
docker-compose restart redis
```

### Verificar Saúde

```bash
# PostgreSQL
docker-compose exec -T postgres pg_isready -U postgres

# Redis
docker-compose exec -T redis redis-cli ping
# Esperado: PONG

# Verificar memória Redis
docker-compose exec -T redis redis-cli INFO memory
```

---

## 🌍 Domínios & DNS

### Configuração DNS (Cloudflare ou Seu Registrador)

| Tipo | Nome | Valor | TTL |
|------|------|-------|-----|
| A | @ | IP_VPS | 300 |
| A | www | IP_VPS | 300 |
| A | api | IP_VPS | 300 |
| A | admin | IP_VPS | 300 |
| CNAME | privacypolicy | www | 300 |
| CNAME | termosdeuso | www | 300 |

### Verificar DNS

```bash
# Testar resolução
nslookup www.seudominio.com
dig api.seudominio.com

# Verificar todos os subdomínios
for subdomain in www api admin privacypolicy termosdeuso; do
  echo "$subdomain.seudominio.com:"
  dig $subdomain.seudominio.com +short
done
```

---

## 💾 Backup & Recuperação

### Script de Backup Automático

O arquivo `backup_nexus.sh` já existe no repositório. Para usar:

```bash
# Editar script
nano /opt/nexus/backup_nexus.sh

# Tornar executável
chmod +x /opt/nexus/backup_nexus.sh

# Executar manualmente
/opt/nexus/backup_nexus.sh

# Agendar no cron (diário às 2 AM)
crontab -e

# Adicionar:
0 2 * * * /opt/nexus/backup_nexus.sh >> /var/log/nexus/backup.log 2>&1
```

### O que é Backed Up

```
✅ PostgreSQL (dump completo)
✅ Redis (snapshot)
✅ Prometheus (dados históricos)
✅ Grafana (dashboards e datasources)
✅ Logs (/var/log/nexus/)
✅ Configurações (.env, nginx.conf)
```

### Recuperar Backup

```bash
# Listar backups
ls -lh /data/backups/

# Restaurar banco
docker-compose exec -T postgres psql -U postgres nexus < \
  /data/backups/nexus-db-backup-20260805.sql

# Restaurar Redis
docker cp /data/backups/redis-dump-20260805.rdb nexus-redis-1:/data/dump.rdb
docker-compose restart redis
```

---

## 🔍 Troubleshooting

### Problema: Backend não inicia

```bash
# Verificar logs
docker-compose logs backend

# Verificar se banco está pronto
docker-compose logs postgres

# Testar conexão banco
docker-compose exec backend python -c \
  "from app.database import engine; print('DB OK')"

# Reiniciar
docker-compose restart backend
```

### Problema: Nginx não acha certificado

```bash
# Verificar certificados
ls -la /opt/nexus/certbot/conf/live/

# Se vazio, gerar novos
docker run --rm \
  -v /opt/nexus/certbot/conf:/etc/letsencrypt \
  -v /opt/nexus/certbot/www:/var/www/certbot \
  certbot/certbot certonly --webroot -w /var/www/certbot \
  -d seudominio.com -d www.seudominio.com
```

### Problema: Alertas não chegam

```bash
# Testar email SMTP
docker run --rm -it python:3.9 /bin/bash

python3 << EOF
import smtplib
from email.mime.text import MIMEText

try:
    with smtplib.SMTP_SSL('smtp.hostinger.com', 465) as server:
        server.login('noreply@seudominio.com', 'sua_senha')
        server.send_message(MIMEText('Teste'))
    print("✅ Email funcionando")
except Exception as e:
    print(f"❌ Erro: {e}")
EOF

# Testar Slack
curl -X POST https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK \
  -H 'Content-Type: application/json' \
  -d '{"text":"Teste Nexus"}'
```

### Problema: Disco cheio

```bash
# Ver uso de disco
df -h

# Ver o que ocupa mais espaço
du -sh /var/log/nexus/*
du -sh /data/*

# Limpar logs antigos (> 30 dias)
find /var/log/nexus -type f -mtime +30 -delete

# Limpar imagens Docker não usadas
docker image prune -a
```

### Problema: Redis fora de memória

```bash
# Verificar memória
docker-compose exec redis redis-cli INFO memory

# Aumentar memória em docker-compose.yml
# Adicionar: command: ["redis-server", "--maxmemory", "2gb", "--maxmemory-policy", "allkeys-lru"]

# Restart
docker-compose restart redis
```

### Problema: Prometheus disco cheio

```bash
# Reduzir retention em docker-compose.yml
# Mudar: --storage.tsdb.retention.time=7d para 3d

# Limpar dados antigos
docker-compose exec prometheus promtool query instant 'up' --print-step=15s

# Restart
docker-compose restart prometheus
```

---

## ✅ Checklist de Produção

Antes de marcar como "GO LIVE", valide:

### 🔐 Segurança
- [ ] SSH usando chave (não senha)
- [ ] Firewall ativo (UFW enabled)
- [ ] Apenas portas 22, 80, 443 expostas
- [ ] Certificado HTTPS válido (curl -I https://...)
- [ ] Senhas geradas com openssl (não hardcoded)
- [ ] .env não está no git
- [ ] Admin credenciais alteradas (Grafana, etc)

### 📊 Monitoramento
- [ ] Prometheus coletando métricas
- [ ] Grafana dashboards criados
- [ ] AlertManager enviando testes
- [ ] Logs em /var/log/nexus/
- [ ] Backup automático configurado (cron)

### 📧 Notificações
- [ ] Email SMTP testado
- [ ] Slack webhook testado
- [ ] Telegram bot testado
- [ ] Admin emails configurados

### 💳 Pagamentos
- [ ] MercadoPago token de PRODUÇÃO (APP_)
- [ ] Webhook MercadoPago configurado
- [ ] Teste de pagamento realizado

### 🔥 Firebase
- [ ] Credenciais service account baixadas
- [ ] firebase-credentials.json no backend
- [ ] Push notifications testadas
- [ ] Analytics ativo

### 🌍 Domínios
- [ ] www.seudominio.com → API funciona
- [ ] api.seudominio.com → Responde
- [ ] admin.seudominio.com → Carrega
- [ ] DNS propagado globalmente (dig +trace)

### ⚡ Performance
- [ ] API responde < 200ms (/health)
- [ ] Banco queries < 1s
- [ ] Redis latência < 5ms
- [ ] Nginx rate limiting funcionando

### 📱 Mobile
- [ ] Android app se conecta à VPS
- [ ] iOS app se conecta à VPS
- [ ] Push notifications recebidas
- [ ] Pagamentos funcionam

### 🔄 Continuidade
- [ ] Backup diário rodando
- [ ] Restore testado
- [ ] Plano de disaster recovery documentado
- [ ] On-call escalation configurado

---

## 📞 Suporte & Contato

Se encontrar problemas:

1. **Verificar logs:**
   ```bash
   docker-compose logs -f [service]
   tail -100 /var/log/nexus/error.log
   ```

2. **Verificar saúde:**
   ```bash
   docker-compose ps
   curl https://api.seudominio.com/health
   ```

3. **Abrir issue no GitHub:**
   - https://github.com/doedesenvolvedor-lgtm/Nexus/issues

---

## 📚 Referências Adicionais

- [VPS_DEPLOYMENT.md](/VPS_DEPLOYMENT.md) - Guia complementar
- [VPS_CHECKLIST.md](/VPS_CHECKLIST.md) - Validação pós-deploy
- [MONITORING_SETUP.md](/MONITORING_SETUP.md) - Monitoramento detalhado
- [COMMANDS_MONITORING.md](/COMMANDS_MONITORING.md) - 50+ comandos úteis
- [.env.vps](/.env.vps) - Template de variáveis de ambiente

---

**Última atualização:** 2026-08-05  
**Próxima revisão:** 2026-09-05
