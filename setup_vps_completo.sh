#!/bin/bash

# ═══════════════════════════════════════════════════════════════════════════
# SCRIPT SETUP COMPLETO NEXUS VPS
# ═══════════════════════════════════════════════════════════════════════════
# Este script configura a VPS do Nexus do zero até pronta para produção
# 
# Uso: bash setup_vps_completo.sh
# ═══════════════════════════════════════════════════════════════════════════

set -e  # Exit se algum comando falhar

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ═══════════════════════════════════════════════════════════════════════════
# FUNÇÕES UTILITÁRIAS
# ═══════════════════════════════════════════════════════════════════════════

log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

pause() {
    read -p "Pressione ENTER para continuar..."
}

# ═══════════════════════════════════════════════════════════════════════════
# VERIFICAÇÕES PRÉ-SETUP
# ═══════════════════════════════════════════════════════════════════════════

check_requirements() {
    log_info "Verificando pré-requisitos..."
    
    # Verificar se é root
    if [[ $EUID -ne 0 ]]; then
        log_error "Este script precisa ser executado como root!"
        echo "Use: sudo bash setup_vps_completo.sh"
        exit 1
    fi
    
    # Verificar SO
    if ! grep -q "Ubuntu" /etc/os-release; then
        log_error "Este script requer Ubuntu 20.04+ LTS"
        exit 1
    fi
    
    log_success "Pré-requisitos OK"
}

# ═══════════════════════════════════════════════════════════════════════════
# GERADOR DE SENHAS SEGURAS
# ═══════════════════════════════════════════════════════════════════════════

generate_password() {
    openssl rand -base64 32
}

generate_secret_key() {
    python3 -c "import secrets; print(secrets.token_urlsafe(32))"
}

# ═══════════════════════════════════════════════════════════════════════════
# 1. ATUALIZAR SISTEMA
# ═══════════════════════════════════════════════════════════════════════════

step_update_system() {
    log_info "PASSO 1/8: Atualizando sistema operacional..."
    
    apt-get update
    apt-get upgrade -y
    apt-get install -y \
        curl \
        wget \
        git \
        docker.io \
        docker-compose \
        python3-pip \
        certbot \
        python3-certbot-nginx \
        ufw \
        htop \
        net-tools \
        unzip \
        jq
    
    log_success "Sistema atualizado"
}

# ═══════════════════════════════════════════════════════════════════════════
# 2. CONFIGURAR DOCKER
# ═══════════════════════════════════════════════════════════════════════════

step_configure_docker() {
    log_info "PASSO 2/8: Configurando Docker..."
    
    # Verificar versão
    docker --version
    docker-compose --version
    
    # Criar volumes
    docker volume create postgres_data 2>/dev/null || true
    docker volume create redis_data 2>/dev/null || true
    docker volume create prometheus_data 2>/dev/null || true
    docker volume create grafana_data 2>/dev/null || true
    
    log_success "Docker configurado"
}

# ═══════════════════════════════════════════════════════════════════════════
# 3. CRIAR DIRETÓRIOS
# ═══════════════════════════════════════════════════════════════════════════

step_create_directories() {
    log_info "PASSO 3/8: Criando diretórios..."
    
    mkdir -p /opt/nexus
    mkdir -p /var/log/nexus
    mkdir -p /data/postgres
    mkdir -p /data/redis
    mkdir -p /data/prometheus
    mkdir -p /data/grafana
    mkdir -p /opt/nexus/certbot/www
    mkdir -p /opt/nexus/certbot/conf
    
    chmod 777 /var/log/nexus
    chmod 755 /data/*
    
    log_success "Diretórios criados"
}

# ═══════════════════════════════════════════════════════════════════════════
# 4. CLONAR REPOSITÓRIO
# ═══════════════════════════════════════════════════════════════════════════

step_clone_repo() {
    log_info "PASSO 4/8: Clonando repositório..."
    
    if [ -d "/opt/nexus/.git" ]; then
        log_info "Repositório já existe, atualizando..."
        cd /opt/nexus
        git pull origin main
    else
        git clone https://github.com/doedesenvolvedor-lgtm/Nexus.git /opt/nexus
    fi
    
    cd /opt/nexus
    log_success "Repositório clonado/atualizado"
}

# ═══════════════════════════════════════════════════════════════════════════
# 5. CONFIGURAR .ENV
# ═══════════════════════════════════════════════════════════════════════════

step_configure_env() {
    log_info "PASSO 5/8: Criando arquivo .env com credenciais seguras..."
    
    cd /opt/nexus
    
    # Gerar credenciais seguras
    DB_PASSWORD=$(generate_password)
    REDIS_PASSWORD=$(generate_password)
    SECRET_KEY=$(generate_secret_key)
    GF_ADMIN_PASSWORD=$(openssl rand -base64 16)
    
    log_info "Credenciais geradas (não repetidas, anote se necessário)"
    
    # Criar .env
    cat > .env << EOF
# ═══════════════════════════════════════════════════════════════════════════
# NEXUS VPS - Configuração Automática ($(date +%Y-%m-%d))
# ═══════════════════════════════════════════════════════════════════════════

# 🗄️  BANCO DE DADOS
DB_NAME=nexus
DB_USER=postgres
DB_PASSWORD=${DB_PASSWORD}
DATABASE_URL=postgresql://postgres:${DB_PASSWORD}@postgres:5432/nexus

# 🔴 REDIS
REDIS_PASSWORD=${REDIS_PASSWORD}
REDIS_URL=redis://:${REDIS_PASSWORD}@redis:6379/0

# 🔐 AUTENTICAÇÃO
SECRET_KEY=${SECRET_KEY}
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=1440

# 📧 EMAIL SMTP (Hostinger)
SMTP_SERVER=smtp.hostinger.com
SMTP_PORT=465
SMTP_USER=noreply@seudominio.com
SMTP_PASSWORD=sua_senha_hostinger_aqui_MUDE_ISTO
SMTP_FROM_EMAIL=noreply@seudominio.com
SMTP_FROM_NAME=Nexus Streaming
SMTP_SECURITY=ssl

# 💳 MERCADOPAGO (Obter em: https://www.mercadopago.com.br/developers/panel/app)
MERCADOPAGO_ACCESS_TOKEN=APP_seu_access_token_aqui_MUDE_ISTO
MERCADOPAGO_CLIENT_ID=seu_client_id_aqui_MUDE_ISTO
MERCADOPAGO_PUBLIC_KEY=APP_seu_public_key_aqui_MUDE_ISTO

# 🔗 URLs
API_URL=https://api.seudominio.com
WEBHOOK_URL=https://api.seudominio.com
FRONTEND_URL=https://www.seudominio.com
FRONTEND_RESET_PASSWORD_URL=https://www.seudominio.com/reset-password
APP_NAME=Nexus Streaming

# 🔥 FIREBASE (Obter service account JSON em: https://console.firebase.google.com/)
FIREBASE_PROJECT_ID=nexus-3fb82
FIREBASE_STORAGE_BUCKET=nexus-3fb82.firebasestorage.app
FIREBASE_CREDENTIALS_PATH=/app/firebase-credentials.json

# 📊 GRAFANA
GF_ADMIN_USER=admin
GF_ADMIN_PASSWORD=${GF_ADMIN_PASSWORD}
GF_USERS_ALLOW_SIGN_UP=false

# 📧 ALERTAS
ADMIN_EMAILS=seu_email@dominio.com
NON_BILLING_PREMIUM_EMAILS=seu_email@dominio.com

# 🔵 SLACK WEBHOOK (Obter em: https://api.slack.com/apps)
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK_MUDE_ISTO

# 🟢 TELEGRAM (Obter token no @BotFather do Telegram)
TELEGRAM_BOT_TOKEN=seu_telegram_bot_token_MUDE_ISTO
TELEGRAM_CHAT_ID=seu_telegram_chat_id_MUDE_ISTO

# ⚙️  AMBIENTE
ENVIRONMENT=production
DEBUG=false

# ═══════════════════════════════════════════════════════════════════════════
# ⚠️  PRÓXIMOS PASSOS - EDITE ESTE ARQUIVO
# ═══════════════════════════════════════════════════════════════════════════
# nano /opt/nexus/.env
#
# Substitua:
# - seudominio.com → seu domínio real
# - SMTP_PASSWORD → sua senha Hostinger
# - MERCADOPAGO_* → seus tokens reais (APP_, não TEST-)
# - FIREBASE_* → suas credenciais Firebase
# - SLACK_WEBHOOK_URL → seu webhook Slack
# - TELEGRAM_* → seu token Telegram
# - ADMIN_EMAILS → seus emails
# ═══════════════════════════════════════════════════════════════════════════
EOF
    
    log_success ".env criado com credenciais automáticas"
    log_warning "AÇÕES NECESSÁRIAS (abra nano .env):"
    log_warning "  1. Substitua seudominio.com pelo seu domínio"
    log_warning "  2. Coloque sua senha SMTP do Hostinger"
    log_warning "  3. Coloque tokens MercadoPago de PRODUÇÃO (APP_, não TEST-)"
    log_warning "  4. Coloque credenciais Firebase"
    log_warning "  5. Coloque webhook Slack (opcional)"
    log_warning "  6. Coloque token Telegram (opcional)"
}

# ═══════════════════════════════════════════════════════════════════════════
# 6. INICIAR STACK DOCKER
# ═══════════════════════════════════════════════════════════════════════════

step_start_docker_stack() {
    log_info "PASSO 6/8: Iniciando stack Docker..."
    
    cd /opt/nexus
    
    # Validar docker-compose.yml
    log_info "Validando docker-compose.yml..."
    docker-compose config > /dev/null || {
        log_error "docker-compose.yml inválido!"
        exit 1
    }
    
    # Iniciar
    log_info "Iniciando containers (isso pode levar 2-3 minutos)..."
    docker-compose up -d
    
    # Esperar tudo inicializar
    sleep 5
    
    # Verificar saúde
    log_info "Verificando saúde dos containers..."
    docker-compose ps
    
    log_success "Stack Docker iniciada"
}

# ═══════════════════════════════════════════════════════════════════════════
# 7. CONFIGURAR FIREWALL
# ═══════════════════════════════════════════════════════════════════════════

step_configure_firewall() {
    log_info "PASSO 7/8: Configurando Firewall (UFW)..."
    
    # Habilitar UFW
    ufw --force enable
    
    # Permitir SSH
    ufw allow 22/tcp
    
    # Permitir HTTP e HTTPS
    ufw allow 80/tcp
    ufw allow 443/tcp
    
    # Verificar
    log_info "Regras de firewall:"
    ufw status verbose
    
    log_success "Firewall configurado"
}

# ═══════════════════════════════════════════════════════════════════════════
# 8. CRIAR CERTIFICADOS HTTPS (Se domínio informado)
# ═══════════════════════════════════════════════════════════════════════════

step_configure_https() {
    log_info "PASSO 8/8: Configurando HTTPS (Let's Encrypt)..."
    
    read -p "Digite seu domínio (ex: seudominio.com): " DOMAIN
    
    if [ -z "$DOMAIN" ]; then
        log_warning "Domínio não informado, pulando HTTPS"
        return
    fi
    
    cd /opt/nexus
    
    log_info "Aguarde DNS propagar (pode levar até 5 minutos)..."
    log_info "Testando resolução de DNS..."
    
    # Testar DNS
    if ! nslookup "$DOMAIN" > /dev/null 2>&1; then
        log_error "DNS não está resolvendo $DOMAIN"
        log_info "Aguarde alguns minutos e execute depois:"
        echo "docker run --rm -v \$(pwd)/certbot/conf:/etc/letsencrypt -v \$(pwd)/certbot/www:/var/www/certbot certbot/certbot certonly --webroot -w /var/www/certbot -d $DOMAIN -d www.$DOMAIN -d api.$DOMAIN"
        return
    fi
    
    # Gerar certificados
    log_info "Gerando certificados Let's Encrypt..."
    docker run --rm \
        -v "$(pwd)/certbot/conf:/etc/letsencrypt" \
        -v "$(pwd)/certbot/www:/var/www/certbot" \
        certbot/certbot certonly --webroot -w /var/www/certbot \
        -d "$DOMAIN" \
        -d "www.$DOMAIN" \
        -d "api.$DOMAIN" \
        -d "admin.$DOMAIN" \
        --agree-tos \
        --email "admin@$DOMAIN" \
        --non-interactive 2>&1 || {
        log_error "Falha ao gerar certificados"
        log_info "Tente depois quando DNS estiver resolvido"
        return
    }
    
    # Recarregar Nginx
    docker-compose restart nginx
    
    log_success "HTTPS configurado com sucesso!"
}

# ═══════════════════════════════════════════════════════════════════════════
# MENU PRINCIPAL
# ═══════════════════════════════════════════════════════════════════════════

show_menu() {
    clear
    echo -e "${BLUE}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║        SETUP COMPLETO NEXUS VPS - $(date +%Y-%m-%d)           ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    echo "Selecione uma opção:"
    echo ""
    echo "  1) Executar setup COMPLETO (1-8)"
    echo "  2) Apenas atualizar sistema"
    echo "  3) Apenas configurar Docker"
    echo "  4) Apenas clonar/atualizar repositório"
    echo "  5) Apenas gerar .env"
    echo "  6) Apenas iniciar Docker stack"
    echo "  7) Apenas configurar firewall"
    echo "  8) Apenas configurar HTTPS"
    echo "  9) Verificar status"
    echo "  0) Sair"
    echo ""
    read -p "Opção: " option
}

# ═══════════════════════════════════════════════════════════════════════════
# VERIFICAR STATUS
# ═══════════════════════════════════════════════════════════════════════════

check_status() {
    log_info "STATUS DO SISTEMA"
    echo ""
    
    log_info "Docker:"
    docker-compose -f /opt/nexus/docker-compose.yml ps 2>/dev/null || log_error "Docker não está rodando"
    echo ""
    
    log_info "Firewall:"
    ufw status | grep -E "Status|22|80|443" || log_error "UFW não está ativo"
    echo ""
    
    log_info "Disco:"
    df -h | grep -E "Filesystem|/opt|/$"
    echo ""
    
    log_info "Memória:"
    free -h | head -2
    echo ""
    
    if [ -f "/opt/nexus/.env" ]; then
        log_success ".env existe"
    else
        log_error ".env não encontrado"
    fi
}

# ═══════════════════════════════════════════════════════════════════════════
# MAIN
# ═══════════════════════════════════════════════════════════════════════════

main() {
    while true; do
        show_menu
        
        case $option in
            1)
                log_info "Iniciando setup completo..."
                check_requirements
                step_update_system
                step_configure_docker
                step_create_directories
                step_clone_repo
                step_configure_env
                step_start_docker_stack
                step_configure_firewall
                step_configure_https
                log_success "✅ SETUP COMPLETO FINALIZADO!"
                log_info "Próximos passos:"
                log_info "  1. Edite .env: nano /opt/nexus/.env"
                log_info "  2. Coloque credenciais reais (Domínio, SMTP, MercadoPago, etc)"
                log_info "  3. Reinicie docker: docker-compose restart"
                log_info "  4. Teste: curl https://seudominio.com/health"
                pause
                ;;
            2)
                check_requirements
                step_update_system
                ;;
            3)
                step_configure_docker
                ;;
            4)
                step_create_directories
                step_clone_repo
                ;;
            5)
                step_create_directories
                step_configure_env
                ;;
            6)
                step_start_docker_stack
                ;;
            7)
                step_configure_firewall
                ;;
            8)
                step_configure_https
                ;;
            9)
                check_status
                pause
                ;;
            0)
                log_info "Saindo..."
                exit 0
                ;;
            *)
                log_error "Opção inválida!"
                pause
                ;;
        esac
    done
}

# Executar
main
