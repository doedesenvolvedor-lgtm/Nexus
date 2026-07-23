#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════
# NEXUSTWOS - SETUP COMPLETO DE VPS EM PRODUÇÃO
# ═══════════════════════════════════════════════════════════════════════════
#
# Este script automatiza a instalação e configuração de todo o ambiente
# da VPS para o sistema NexusTwos, deixando pronto para produção.
#
# Testado em: Ubuntu 22.04 LTS e Ubuntu 24.04 LTS
#
# Uso:
#   sudo bash setup.sh                    # Instalação completa interativa
#   sudo bash setup.sh --auto             # Instalação automática (sem prompts)
#   sudo bash setup.sh --skip-metrics     # Pula instalação de métricas
#   sudo bash setup.sh --help             # Ajuda
#
# ═══════════════════════════════════════════════════════════════════════════

set -e

# ═══════════════════════════════════════════════════════════════════════════
# CONFIGURAÇÃO INICIAL
# ═══════════════════════════════════════════════════════════════════════════

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Diretórios
PROJECT_DIR="/opt/nexus"
BACKUP_DIR="/backups/nexus"
LOG_DIR="/var/log/nexus"
DATA_DIR="/data"

# Versões
PYTHON_VERSION="3.12"
POSTGRES_VERSION="16"
REDIS_VERSION="7"
NODE_VERSION="18"

# Flags
AUTO_MODE=false
SKIP_METRICS=false

# ═══════════════════════════════════════════════════════════════════════════
# FUNÇÕES DE UTILIDADE
# ═══════════════════════════════════════════════════════════════════════════

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_step() { echo -e "\n${BLUE}════════════════════════════════════════════${NC}"; echo -e "${BLUE}[$1/$TOTAL_STEPS]${NC} $2"; echo -e "${BLUE}════════════════════════════════════════════${NC}\n"; }
log_section() { echo -e "\n${CYAN}▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓${NC}"; echo -e "${CYAN}▓  $1${NC}"; echo -e "${CYAN}▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓${NC}\n"; }

print_banner() {
    echo -e "${BLUE}"
    echo '  ╔═══════════════════════════════════════════════════════════════╗'
    echo '  ║                                                              ║'
    echo '  ║     NEXUSTWOS - SETUP COMPLETO DE VPS EM PRODUÇÃO            ║'
    echo '  ║                                                              ║'
    echo '  ║     Stack: FastAPI + PostgreSQL + Redis + Docker + Nginx     ║'
    echo '  ║     Sistema: Ubuntu 22.04/24.04 LTS                          ║'
    echo '  ║                                                              ║'
    echo '  ╚═══════════════════════════════════════════════════════════════╝'
    echo -e "${NC}"
    echo ""
}

show_help() {
    echo "Uso: sudo bash setup.sh [OPÇÕES]"
    echo ""
    echo "Opções:"
    echo "  --auto             Modo automático (sem prompts interativos)"
    echo "  --skip-metrics     Pula instalação do stack de monitoramento"
    echo "  --help             Exibe esta ajuda"
    echo ""
    echo "Exemplos:"
    echo "  sudo bash setup.sh                           # Completo interativo"
    echo "  sudo bash setup.sh --auto                    # Automático"
    echo "  sudo bash setup.sh --auto --skip-metrics     # Automático sem métricas"
    exit 0
}

# ═══════════════════════════════════════════════════════════════════════════
# PARSE DE ARGUMENTOS
# ═══════════════════════════════════════════════════════════════════════════

for arg in "$@"; do
    case $arg in
        --auto) AUTO_MODE=true ;;
        --skip-metrics) SKIP_METRICS=true ;;
        --help) show_help ;;
        *) echo "Opção desconhecida: $arg"; show_help ;;
    esac
done

# ═══════════════════════════════════════════════════════════════════════════
# VERIFICAÇÕES INICIAIS
# ═══════════════════════════════════════════════════════════════════════════

# Verificar root
if [ "$EUID" -ne 0 ]; then
    log_error "Este script deve ser executado como root"
    echo "  Use: sudo bash setup.sh"
    exit 1
fi

# Verificar sistema
if [ ! -f /etc/os-release ]; then
    log_error "Sistema não suportado. Ubuntu 22.04/24.04 LTS é recomendado."
    exit 1
fi

source /etc/os-release
if [[ "$ID" != "ubuntu" ]]; then
    log_error "Sistema não suportado: $ID. Use Ubuntu."
    exit 1
fi

log_info "Sistema: $PRETTY_NAME"
log_info "Arquitetura: $(uname -m)"
log_info "Modo: $([ "$AUTO_MODE" = true ] && echo 'Automático' || echo 'Interativo')"
echo ""

# ═══════════════════════════════════════════════════════════════════════════
# CONFIGURAÇÃO INTERATIVA (se não for automático)
# ═══════════════════════════════════════════════════════════════════════════

if [ "$AUTO_MODE" = false ]; then
    echo "╔═══════════════════════════════════════════════════════════════╗"
    echo "║        CONFIGURAÇÃO DO AMBIENTE                              ║"
    echo "╚═══════════════════════════════════════════════════════════════╝"
    echo ""
    echo "Pressione ENTER para usar os valores padrão entre []"
    echo ""

    read -p "Domínio principal (ex: nexus.com) [nexus.com]: " DOMAIN
    DOMAIN=${DOMAIN:-nexus.com}

    read -p "Email do administrador [admin@${DOMAIN}]: " ADMIN_EMAIL
    ADMIN_EMAIL=${ADMIN_EMAIL:-admin@${DOMAIN}}

    read -p "Senha do banco de dados (PostgreSQL) [gerar automaticamente]: " DB_PASSWORD
    if [ -z "$DB_PASSWORD" ]; then
        DB_PASSWORD=$(openssl rand -base64 32 | tr -d '/+=' | cut -c1-20)
        log_info "Senha PostgreSQL gerada: $DB_PASSWORD"
    fi

    read -p "Senha do Redis [gerar automaticamente]: " REDIS_PASSWORD
    if [ -z "$REDIS_PASSWORD" ]; then
        REDIS_PASSWORD=$(openssl rand -base64 32 | tr -d '/+=' | cut -c1-20)
        log_info "Senha Redis gerada: $REDIS_PASSWORD"
    fi

    echo ""
    echo "═══════════════════════════════════════════════"
    echo "  CONFIGURAÇÕES DE E-MAIL (Hostinger/SMTP)"
    echo "═══════════════════════════════════════════════"
    read -p "Servidor SMTP [smtp.hostinger.com]: " SMTP_SERVER
    SMTP_SERVER=${SMTP_SERVER:-smtp.hostinger.com}

    read -p "Porta SMTP [465]: " SMTP_PORT
    SMTP_PORT=${SMTP_PORT:-465}

    read -p "Usuário SMTP (email) [noreply@${DOMAIN}]: " SMTP_USER
    SMTP_USER=${SMTP_USER:-noreply@${DOMAIN}}

    read -sp "Senha SMTP: " SMTP_PASSWORD
    echo ""
    SMTP_PASSWORD=${SMTP_PASSWORD:-}

    echo ""
    echo "═══════════════════════════════════════════════"
    echo "  MERCADO PAGO"
    echo "═══════════════════════════════════════════════"
    read -p "Mercado Pago Access Token (deixe vazio para configurar depois): " MERCADOPAGO_TOKEN
    MERCADOPAGO_TOKEN=${MERCADOPAGO_TOKEN:-}

    echo ""
    echo "═══════════════════════════════════════════════"
    echo "  FIREBASE (opcional)"
    echo "═══════════════════════════════════════════════"
    read -p "Caminho para arquivo firebase-credentials.json (deixe vazio para pular): " FIREBASE_CREDS
    FIREBASE_CREDS=${FIREBASE_CREDS:-}

    echo ""
    echo "═══════════════════════════════════════════════"
    echo "  BUNNY CDN (opcional)"
    echo "═══════════════════════════════════════════════"
    read -p "URL do Bunny CDN Pull Zone (ex: https://nexus.b-cdn.net, deixe vazio): " BUNNY_URL
    BUNNY_URL=${BUNNY_URL:-}

    echo ""
    echo "═══════════════════════════════════════════════"
    echo "  SLAK / TELEGRAM (opcional - para alertas)"
    echo "═══════════════════════════════════════════════"
    read -p "Slack Webhook URL (deixe vazio para pular): " SLACK_WEBHOOK
    SLACK_WEBHOOK=${SLACK_WEBHOOK:-}

    read -p "Telegram Chat ID (deixe vazio para pular): " TELEGRAM_CHAT_ID
    TELEGRAM_CHAT_ID=${TELEGRAM_CHAT_ID:-0}

    read -p "Senha do Grafana [admin]: " GF_PASSWORD
    GF_PASSWORD=${GF_PASSWORD:-admin}

    echo ""
    echo "═══════════════════════════════════════════════"
    echo "  REPOSITÓRIO GIT"
    echo "═══════════════════════════════════════════════"
    read -p "URL do repositório Git (https://github.com/seu-usuario/Nexus.git): " GIT_REPO
    if [ -z "$GIT_REPO" ]; then
        # Usar o repositório atual se disponível
        if [ -d "/workspaces/Nexus/.git" ]; then
            GIT_REPO="local"
            log_info "Usando repositório local: /workspaces/Nexus"
        else
            log_warn "Repositório não informado. Será usado deploy manual."
            GIT_REPO=""
        fi
    fi

    echo ""
    echo "═══════════════════════════════════════════════"
    echo "  RESUMO DAS CONFIGURAÇÕES"
    echo "═══════════════════════════════════════════════"
    echo "  Domínio:           $DOMAIN"
    echo "  Email Admin:       $ADMIN_EMAIL"
    echo "  SMTP:              $SMTP_USER@$SMTP_SERVER:$SMTP_PORT"
    echo "  Mercado Pago:      $([ -n "$MERCADOPAGO_TOKEN" ] && echo 'Configurado' || echo 'Pendente')"
    echo "  Firebase:          $([ -n "$FIREBASE_CREDS" ] && echo 'Configurado' || echo 'Pendente')"
    echo "  Bunny CDN:         $([ -n "$BUNNY_URL" ] && echo 'Configurado' || echo 'Não configurado')"
    echo "  Slack:             $([ -n "$SLACK_WEBHOOK" ] && echo 'Configurado' || echo 'Não configurado')"
    echo "  Monitoramento:     $([ "$SKIP_METRICS" = false ] && echo 'Completo' || echo 'Pulado')"
    echo ""

    read -p "Deseja continuar com estas configurações? (S/N): " CONFIRM
    if [[ ! "$CONFIRM" =~ ^[Ss]$ ]]; then
        log_error "Instalação cancelada pelo usuário."
        exit 1
    fi
else
    # Modo automático: usar valores padrão
    DOMAIN=${DOMAIN:-nexus.com}
    ADMIN_EMAIL=${ADMIN_EMAIL:-admin@${DOMAIN}}
    DB_PASSWORD=${DB_PASSWORD:-$(openssl rand -base64 32 | tr -d '/+=' | cut -c1-20)}
    REDIS_PASSWORD=${REDIS_PASSWORD:-$(openssl rand -base64 32 | tr -d '/+=' | cut -c1-20)}
    SMTP_SERVER=${SMTP_SERVER:-smtp.hostinger.com}
    SMTP_PORT=${SMTP_PORT:-465}
    SMTP_USER=${SMTP_USER:-noreply@${DOMAIN}}
    SMTP_PASSWORD=${SMTP_PASSWORD:-}
    MERCADOPAGO_TOKEN=${MERCADOPAGO_TOKEN:-}
    FIREBASE_CREDS=${FIREBASE_CREDS:-}
    BUNNY_URL=${BUNNY_URL:-}
    SLACK_WEBHOOK=${SLACK_WEBHOOK:-}
    TELEGRAM_CHAT_ID=${TELEGRAM_CHAT_ID:-0}
    GF_PASSWORD=${GF_PASSWORD:-admin}
    GIT_REPO=${GIT_REPO:-}
fi

# ═══════════════════════════════════════════════════════════════════════════
# GERAR SECRET_KEY
# ═══════════════════════════════════════════════════════════════════════════

SECRET_KEY=$(python3 -c "import secrets; print(secrets.token_urlsafe(50))" 2>/dev/null || openssl rand -base64 50 | tr -d '/+=')

# ═══════════════════════════════════════════════════════════════════════════
# VARIÁVEIS DE CONTROLE
# ═══════════════════════════════════════════════════════════════════════════

TOTAL_STEPS=15
CURRENT_STEP=0

# ═══════════════════════════════════════════════════════════════════════════
# PASSO 1: ATUALIZAR SISTEMA
# ═══════════════════════════════════════════════════════════════════════════

CURRENT_STEP=$((CURRENT_STEP + 1))
log_section "PASSO $CURRENT_STEP: ATUALIZAR SISTEMA OPERACIONAL"

log_info "Atualizando lista de pacotes..."
apt-get update -y -qq

log_info "Atualizando pacotes instalados..."
apt-get upgrade -y -qq

log_info "Instalando pacotes essenciais..."
apt-get install -y -qq \
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
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release \
    python3-pip \
    python3-venv \
    ffmpeg \
    build-essential \
    libpq-dev \
    libmagic1 \
    libssl-dev \
    libffi-dev \
    libxml2-dev \
    libxslt1-dev \
    zlib1g-dev

log_info "Configurando fuso horário..."
timedatectl set-timezone America/Sao_Paulo 2>/dev/null || true

log_info "Limpando cache de pacotes..."
apt-get autoremove -y -qq
apt-get autoclean -y -qq

log_info "✅ Sistema atualizado com sucesso!"

# ═══════════════════════════════════════════════════════════════════════════
# PASSO 2: CONFIGURAR FIREWALL (UFW)
# ═══════════════════════════════════════════════════════════════════════════

CURRENT_STEP=$((CURRENT_STEP + 1))
log_section "PASSO $CURRENT_STEP: CONFIGURAR FIREWALL (UFW)"

log_info "Configurando regras do firewall..."

ufw --force disable 2>/dev/null || true
ufw --force reset 2>/dev/null || true

ufw default deny incoming
ufw default allow outgoing

# Portas essenciais
ufw allow 22/tcp comment 'SSH'
ufw allow 80/tcp comment 'HTTP'
ufw allow 443/tcp comment 'HTTPS'

# Rate limiting para SSH
ufw limit 22/tcp comment 'SSH (limitado)'

ufw --force enable

log_info "Regras do firewall:"
ufw status verbose

log_info "✅ Firewall configurado com sucesso!"

# ═══════════════════════════════════════════════════════════════════════════
# PASSO 3: CONFIGURAR FAIL2BAN
# ═══════════════════════════════════════════════════════════════════════════

CURRENT_STEP=$((CURRENT_STEP + 1))
log_section "PASSO $CURRENT_STEP: CONFIGURAR FAIL2BAN"

log_info "Configurando Fail2Ban..."

cat > /etc/fail2ban/jail.local << 'EOF'
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5
destemail = admin@nexus.com
sendername = NexusTwos Security
action = %(action_mwl)s

[sshd]
enabled = true
port = ssh
filter = sshd
maxretry = 3
bantime = 7200

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
bantime = 86400

[nginx-noscript]
enabled = true
port = http,https
filter = nginx-noscript
logpath = /var/log/nginx/access.log
maxretry = 6

[nginx-noproxy]
enabled = true
port = http,https
filter = nginx-noproxy
logpath = /var/log/nginx/access.log
maxretry = 2
EOF

# Atualizar email no jail.local
sed -i "s/admin@nexus.com/$ADMIN_EMAIL/g" /etc/fail2ban/jail.local

systemctl restart fail2ban
systemctl enable fail2ban

log_info "Fail2Ban status:"
fail2ban-client status

log_info "✅ Fail2Ban configurado com sucesso!"

# ═══════════════════════════════════════════════════════════════════════════
# PASSO 4: DOCKER E DOCKER COMPOSE
# ═══════════════════════════════════════════════════════════════════════════

CURRENT_STEP=$((CURRENT_STEP + 1))
log_section "PASSO $CURRENT_STEP: INSTALAR DOCKER E DOCKER COMPOSE"

log_info "Removendo versões antigas do Docker..."
apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true

log_info "Instalando Docker via script oficial..."
curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
bash /tmp/get-docker.sh
rm /tmp/get-docker.sh

log_info "Instalando Docker Compose plugin..."
apt-get install -y -qq docker-compose-plugin 2>/dev/null || {
    log_warn "Plugin Docker Compose não disponível, instalando manualmente..."
    DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep tag_name | cut -d'"' -f4)
    curl -fsSL "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose
}

log_info "Configurando Docker para performance..."
mkdir -p /etc/docker
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

log_info "Iniciando e ativando Docker..."
systemctl enable docker
systemctl start docker

log_info "Adicionando usuário ao grupo docker..."
if [ -n "$SUDO_USER" ]; then
    usermod -aG docker "$SUDO_USER"
fi

log_info "Docker versão: $(docker --version)"
log_info "Docker Compose versão: $(docker compose version 2>/dev/null || docker-compose --version)"

log_info "✅ Docker e Docker Compose instalados com sucesso!"

# ═══════════════════════════════════════════════════════════════════════════
# PASSO 5: SSH HARDENING
# ═══════════════════════════════════════════════════════════════════════════

CURRENT_STEP=$((CURRENT_STEP + 1))
log_section "PASSO $CURRENT_STEP: HARDENING SSH"

log_info "Aplicando configurações de segurança SSH..."

# Backup da configuração original
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak.$(date +%Y%m%d)

# Aplicar hardening
sed -i 's/^#PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/^PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/^#PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/^PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/^#PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/^PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/^#PermitEmptyPasswords.*/PermitEmptyPasswords no/' /etc/ssh/sshd_config
sed -i 's/^PermitEmptyPasswords.*/PermitEmptyPasswords no/' /etc/ssh/sshd_config
sed -i 's/^#X11Forwarding.*/X11Forwarding no/' /etc/ssh/sshd_config
sed -i 's/^X11Forwarding.*/X11Forwarding no/' /etc/ssh/sshd_config

# Adicionar configurações extras se não existirem
grep -q "^MaxAuthTries" /etc/ssh/sshd_config || echo "MaxAuthTries 3" >> /etc/ssh/sshd_config
grep -q "^MaxSessions" /etc/ssh/sshd_config || echo "MaxSessions 10" >> /etc/ssh/sshd_config
grep -q "^ClientAliveInterval" /etc/ssh/sshd_config || echo "ClientAliveInterval 300" >> /etc/ssh/sshd_config
grep -q "^ClientAliveCountMax" /etc/ssh/sshd_config || echo "ClientAliveCountMax 2" >> /etc/ssh/sshd_config
grep -q "^TCPKeepAlive" /etc/ssh/sshd_config || echo "TCPKeepAlive yes" >> /etc/ssh/sshd_config

log_info "Reiniciando SSH..."
systemctl restart sshd

log_info "✅ SSH hardening aplicado com sucesso!"
log_warn "⚠️  Certifique-se de que sua chave pública SSH está configurada em ~/.ssh/authorized_keys"
log_warn "   Ou você pode perder o acesso à VPS!"

# ═══════════════════════════════════════════════════════════════════════════
# PASSO 6: KERNEL HARDENING
# ═══════════════════════════════════════════════════════════════════════════

CURRENT_STEP=$((CURRENT_STEP + 1))
log_section "PASSO $CURRENT_STEP: HARDENING DO KERNEL"

log_info "Aplicando configurações de segurança do kernel..."

cat > /etc/sysctl.d/99-hardening.conf << 'EOF'
# ============================================
# NEXUSTWOS - KERNEL HARDENING
# ============================================

# IP Forwarding (desabilitar se não for roteador)
net.ipv4.ip_forward = 0
net.ipv6.conf.all.forwarding = 0

# Proteção contra SYN flood
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_syn_backlog = 2048
net.ipv4.tcp_syn_retries = 2
net.ipv4.tcp_synack_retries = 2

# Log de pacotes suspeitos
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.default.log_martians = 1

# Ignorar ICMP redirects
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv4.conf.all.secure_redirects = 0

# Ignorar ICMP solicitations
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0

# Proteção contra spoofing
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1

# Enviar redirects (desabilitar)
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0

# Proteção contra TIME_WAIT
net.ipv4.tcp_rfc1337 = 1
net.ipv4.tcp_fin_timeout = 15

# Aumentar limites de conexão
net.core.netdev_max_backlog = 5000
net.core.somaxconn = 1024

# TCP Fast Open
net.ipv4.tcp_fastopen = 3

# Aumentar range de portas efêmeras
net.ipv4.ip_local_port_range = 1024 65535

# Reduzir timeout keepalive
net.ipv4.tcp_keepalive_time = 300
net.ipv4.tcp_keepalive_intvl = 60
net.ipv4.tcp_keepalive_probes = 5
EOF

sysctl -p /etc/sysctl.d/99-hardening.conf

log_info "✅ Kernel hardening aplicado com sucesso!"

# ═══════════════════════════════════════════════════════════════════════════
# PASSO 7: ATUALIZAÇÕES AUTOMÁTICAS DE SEGURANÇA
# ═══════════════════════════════════════════════════════════════════════════

CURRENT_STEP=$((CURRENT_STEP + 1))
log_section "PASSO $CURRENT_STEP: ATUALIZAÇÕES AUTOMÁTICAS DE SEGURANÇA"

log_info "Configurando atualizações automáticas de segurança..."

cat > /etc/apt/apt.conf.d/50unattended-upgrades << EOF
Unattended-Upgrade::Allowed-Origins {
    "\${distro_id}:\${distro_codename}-security";
    "\${distro_id}ESMApps:\${distro_codename}-apps-security";
    "\${distro_id}ESM:\${distro_codename}-infra-security";
};
Unattended-Upgrade::DevReachtAutoFix "true";
Unattended-Upgrade::AutoFixInterceptedDpkg "true";
Unattended-Upgrade::MinimalSteps "true";
Unattended-Upgrade::RemoveUnusedDependencies "true";
Unattended-Upgrade::Automatic-Reboot "false";
Unattended-Upgrade::Mail "$ADMIN_EMAIL";
Unattended-Upgrade::MailReport "on-change";
EOF

cat > /etc/apt/apt.conf.d/20auto-upgrades << 'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "7";
APT::Periodic::Unattended-Upgrade "1";
EOF

dpkg-reconfigure --priority=low unattended-upgrades -f noninteractive 2>/dev/null || true

log_info "✅ Atualizações automáticas configuradas com sucesso!"

# ═══════════════════════════════════════════════════════════════════════════
# PASSO 8: CRIAR DIRETÓRIOS E ESTRUTURA
# ═══════════════════════════════════════════════════════════════════════════

CURRENT_STEP=$((CURRENT_STEP + 1))
log_section "PASSO $CURRENT_STEP: CRIAR ESTRUTURA DE DIRETÓRIOS"

log_info "Criando diretórios do projeto..."

mkdir -p "$PROJECT_DIR"
mkdir -p "$PROJECT_DIR/backend"
mkdir -p "$PROJECT_DIR/backend/app"
mkdir -p "$PROJECT_DIR/backend/storage/streams"
mkdir -p "$PROJECT_DIR/backend/storage/releases"
mkdir -p "$PROJECT_DIR/backend/uploads"
mkdir -p "$PROJECT_DIR/backend/logs"
mkdir -p "$PROJECT_DIR/backend/workers"
mkdir -p "$PROJECT_DIR/backend/database"
mkdir -p "$PROJECT_DIR/nginx"
mkdir -p "$PROJECT_DIR/admin"
mkdir -p "$PROJECT_DIR/monitoring"
mkdir -p "$PROJECT_DIR/monitoring/grafana/provisioning/datasources"
mkdir -p "$PROJECT_DIR/monitoring/grafana/provisioning/dashboards"
mkdir -p "$PROJECT_DIR/certbot/www"
mkdir -p "$PROJECT_DIR/certbot/conf"
mkdir -p "$LOG_DIR"
mkdir -p "$BACKUP_DIR"
mkdir -p "$DATA_DIR"

# Criar diretórios para logs
mkdir -p "$LOG_DIR/nginx"
mkdir -p "$LOG_DIR/backend"
mkdir -p "$LOG_DIR/admin"
mkdir -p "$LOG_DIR/archives"

log_info "Ajustando permissões..."
chmod 755 "$PROJECT_DIR"
chmod 777 "$LOG_DIR"
chmod 755 "$DATA_DIR"

log_info "Diretórios criados:"
tree -d -L 2 "$PROJECT_DIR" 2>/dev/null || ls -la "$PROJECT_DIR"

log_info "✅ Estrutura de diretórios criada com sucesso!"

# ═══════════════════════════════════════════════════════════════════════════
# PASSO 9: CLONAR/COPIAR REPOSITÓRIO
# ═══════════════════════════════════════════════════════════════════════════

CURRENT_STEP=$((CURRENT_STEP + 1))
log_section "PASSO $CURRENT_STEP: CONFIGURAR CÓDIGO FONTE"

if [ "$GIT_REPO" = "local" ]; then
    log_info "Usando repositório local..."
    if [ -d "/workspaces/Nexus" ]; then
        rsync -av --exclude='node_modules' \
              --exclude='__pycache__' \
              --exclude='.git' \
              --exclude='.dart_tool' \
              --exclude='build' \
              --exclude='*.pyc' \
              --exclude='.env' \
              --exclude='.venv' \
              /workspaces/Nexus/ "$PROJECT_DIR/"
        log_info "Arquivos copiados com sucesso!"
    else
        log_error "Diretório /workspaces/Nexus não encontrado!"
        exit 1
    fi
elif [ -n "$GIT_REPO" ]; then
    log_info "Clonando repositório Git..."
    cd "$PROJECT_DIR"
    git clone "$GIT_REPO" . 2>/dev/null || {
        log_warn "Falha ao clonar. Verifique a URL e tente manualmente."
        log_info "Você pode copiar os arquivos manualmente para $PROJECT_DIR"
    }
    cd /
else
    log_warn "Nenhum repositório configurado. Você precisará copiar os arquivos manualmente."
    log_info "Use: rsync -av --exclude='node_modules' --exclude='__pycache__' --exclude='.env' /caminho/local/Nexus/ $PROJECT_DIR/"
fi

# ═══════════════════════════════════════════════════════════════════════════
# PASSO 10: CRIAR ARQUIVO .env
# ═══════════════════════════════════════════════════════════════════════════

CURRENT_STEP=$((CURRENT_STEP + 1))
log_section "PASSO $CURRENT_STEP: CRIAR VARIÁVEIS DE AMBIENTE"

log_info "Criando arquivo .env em $PROJECT_DIR/.env..."

cat > "$PROJECT_DIR/.env" << EOF
# ═══════════════════════════════════════════════════════════════════════════
# NEXUSTWOS - PRODUCTION ENVIRONMENT VARIABLES
# Gerado automaticamente em $(date '+%Y-%m-%d %H:%M:%S')
# ═══════════════════════════════════════════════════════════════════════════

# === Database ===
DATABASE_URL=postgresql://postgres:${DB_PASSWORD}@postgres:5432/nexus
DB_NAME=nexus
DB_USER=postgres
DB_PASSWORD=${DB_PASSWORD}

# === Redis ===
REDIS_URL=redis://:${REDIS_PASSWORD}@redis:6379/0
REDIS_PASSWORD=${REDIS_PASSWORD}

# === Security ===
SECRET_KEY=${SECRET_KEY}
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30
REFRESH_TOKEN_EXPIRE_DAYS=7

# === Application ===
APP_NAME=NexusTwos
ENVIRONMENT=production
LOG_LEVEL=INFO
FRONTEND_URL=https://${DOMAIN}
ADMIN_FRONTEND_URL=https://admin.${DOMAIN}
FRONTEND_RESET_PASSWORD_URL=https://${DOMAIN}/reset-password

# === SMTP (Hostinger Mail) ===
SMTP_SERVER=${SMTP_SERVER}
SMTP_PORT=${SMTP_PORT}
SMTP_USER=${SMTP_USER}
SMTP_PASSWORD=${SMTP_PASSWORD}
SMTP_SECURITY=ssl
SMTP_FROM_EMAIL=${SMTP_USER}
SMTP_FROM_NAME=NexusTwos

# === Firebase Cloud Messaging ===
FIREBASE_CREDENTIALS_PATH=/app/firebase-credentials.json

# === Mercado Pago ===
MERCADOPAGO_ACCESS_TOKEN=${MERCADOPAGO_TOKEN}
MERCADOPAGO_WEBHOOK_SECRET=
WEBHOOK_URL=https://api.${DOMAIN}

# === Stripe (opcional) ===
# STRIPE_SECRET_KEY=
# STRIPE_WEBHOOK_SECRET=
# STRIPE_PUBLISHABLE_KEY=

# === Admin & Billing ===
ADMIN_EMAILS=${ADMIN_EMAIL}
NON_BILLING_PREMIUM_EMAILS=${ADMIN_EMAIL}

# === Monitoring (Grafana) ===
GF_ADMIN_USER=admin
GF_ADMIN_PASSWORD=${GF_PASSWORD}
GF_USERS_ALLOW_SIGN_UP=false

# === Monitoring (Alertmanager) ===
SMTP_USER=${SMTP_USER}
SMTP_PASSWORD=${SMTP_PASSWORD}
SMTP_FROM_EMAIL=${SMTP_USER}
SLACK_WEBHOOK_URL=${SLACK_WEBHOOK}
TELEGRAM_CHAT_ID=${TELEGRAM_CHAT_ID}
ADMIN_EMAILS=${ADMIN_EMAIL}
EOF

# Proteger o arquivo .env
chmod 600 "$PROJECT_DIR/.env"
chown root:root "$PROJECT_DIR/.env"

log_info "✅ Arquivo .env criado e protegido!"

# ═══════════════════════════════════════════════════════════════════════════
# PASSO 11: CONFIGURAR LOGROTATE
# ═══════════════════════════════════════════════════════════════════════════

CURRENT_STEP=$((CURRENT_STEP + 1))
log_section "PASSO $CURRENT_STEP: CONFIGURAR ROTAÇÃO DE LOGS"

log_info "Configurando logrotate para logs do NexusTwos..."

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

/var/log/nexus/nginx/*.log {
    daily
    rotate 30
    compress
    delaycompress
    missingok
    notifempty
    create 0640 www-data adm
}

/var/log/nexus/backend/*.log {
    daily
    rotate 30
    compress
    delaycompress
    missingok
    notifempty
    create 0640 root adm
}

/var/log/nexus/archives/*.log {
    weekly
    rotate 12
    compress
    missingok
    notifempty
}
EOF

logrotate -d /etc/logrotate.d/nexus 2>/dev/null || true

log_info "✅ Logrotate configurado com sucesso!"

# ═══════════════════════════════════════════════════════════════════════════
# PASSO 12: CONFIGURAR BACKUP AUTOMÁTICO
# ═══════════════════════════════════════════════════════════════════════════

CURRENT_STEP=$((CURRENT_STEP + 1))
log_section "PASSO $CURRENT_STEP: CONFIGURAR BACKUP AUTOMÁTICO"

log_info "Criando script de backup..."

# Backup script já existe, mas vamos garantir que está no lugar certo
if [ -f "$PROJECT_DIR/backup_nexus.sh" ]; then
    chmod +x "$PROJECT_DIR/backup_nexus.sh"
    cp "$PROJECT_DIR/backup_nexus.sh" /usr/local/bin/backup_nexus.sh
    log_info "Script de backup copiado para /usr/local/bin/backup_nexus.sh"
else
    log_warn "Script backup_nexus.sh não encontrado. Será criado um script básico."
    
    cat > /usr/local/bin/backup_nexus.sh << 'SCRIPT'
#!/bin/bash
# Backup automático NexusTwos
BACKUP_DIR="/backups/nexus"
PROJECT_DIR="/opt/nexus"
LOG_DIR="/var/log/nexus"
DATE=$(date +%Y%m%d_%H%M%S)
LOG_FILE="$LOG_DIR/backup.log"

mkdir -p $BACKUP_DIR

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> $LOG_FILE; }
log "===== INICIANDO BACKUP $DATE ====="

# 1. Backup PostgreSQL
log "Backup PostgreSQL..."
cd $PROJECT_DIR
if docker compose exec -T postgres pg_dump -U postgres nexus > "$BACKUP_DIR/postgres_$DATE.sql" 2>/dev/null; then
    SIZE=$(du -h "$BACKUP_DIR/postgres_$DATE.sql" | cut -f1)
    log "PostgreSQL: OK ($SIZE)"
fi

# 2. Backup configurações
log "Backup configurações..."
tar czf "$BACKUP_DIR/config_$DATE.tar.gz" \
    $PROJECT_DIR/docker-compose.yml \
    $PROJECT_DIR/.env \
    $PROJECT_DIR/nginx/ 2>/dev/null
log "Config: OK"

# 3. Backup logs
log "Backup logs..."
tar czf "$BACKUP_DIR/logs_$DATE.tar.gz" $LOG_DIR/ 2>/dev/null
log "Logs: OK"

# 4. Limpeza (manter 30 dias)
DELETED=$(find $BACKUP_DIR -name "*.sql" -o -name "*.tar.gz" | xargs -r ls -t | tail -n +31 | xargs -r rm 2>/dev/null; echo $?)
log "Limpeza concluída"

# 5. Resumo
TOTAL_SIZE=$(du -sh $BACKUP_DIR | cut -f1)
log "Tamanho total dos backups: $TOTAL_SIZE"
log "===== BACKUP CONCLUÍDO ===="
SCRIPT
    chmod +x /usr/local/bin/backup_nexus.sh
fi

log_info "Configurando cron para backup diário às 2:00 AM..."
(crontab -l 2>/dev/null | grep -v "backup_nexus"; echo "0 2 * * * /usr/local/bin/backup_nexus.sh >> /var/log/nexus/backup.log 2>&1") | crontab -

log_info "✅ Backup automático configurado com sucesso!"

# ═══════════════════════════════════════════════════════════════════════════
# PASSO 13: VOLUMES DOCKER E CONFIGURAÇÕES ADICIONAIS
# ═══════════════════════════════════════════════════════════════════════════

CURRENT_STEP=$((CURRENT_STEP + 1))
log_section "PASSO $CURRENT_STEP: VOLUMES DOCKER E CONFIGURAÇÕES"

log_info "Criando volumes Docker para dados persistentes..."
docker volume create postgres_data 2>/dev/null || true
docker volume create redis_data 2>/dev/null || true
docker volume create prometheus_data 2>/dev/null || true
docker volume create grafana_data 2>/dev/null || true
docker volume create alertmanager_data 2>/dev/null || true

log_info "Configurando health check script..."
if [ -f "$PROJECT_DIR/health_check.sh" ]; then
    chmod +x "$PROJECT_DIR/health_check.sh"
    cp "$PROJECT_DIR/health_check.sh" /usr/local/bin/nexus_health_check.sh
    
    # Adicionar cron se não existir
    (crontab -l 2>/dev/null | grep -v "nexus_health_check"; echo "*/5 * * * * /usr/local/bin/nexus_health_check.sh >> /var/log/nexus/health.log 2>&1") | crontab -
    log_info "Health check configurado a cada 5 minutos"
fi

log_info "Configurando verify script..."
if [ -f "$PROJECT_DIR/verify_vps_deployment.sh" ]; then
    chmod +x "$PROJECT_DIR/verify_vps_deployment.sh"
fi

# ═══════════════════════════════════════════════════════════════════════════
# PASSO 14: FIREBASE CREDENTIALS (se informado)
# ═══════════════════════════════════════════════════════════════════════════

CURRENT_STEP=$((CURRENT_STEP + 1))
log_section "PASSO $CURRENT_STEP: CONFIGURAÇÕES ADICIONAIS"

if [ -n "$FIREBASE_CREDS" ] && [ -f "$FIREBASE_CREDS" ]; then
    log_info "Copiando credenciais Firebase..."
    cp "$FIREBASE_CREDS" "$PROJECT_DIR/backend/firebase-credentials.json"
    chmod 600 "$PROJECT_DIR/backend/firebase-credentials.json"
    log_info "✅ Firebase credentials configuradas!"
elif [ -n "$FIREBASE_CREDS" ]; then
    log_warn "Arquivo $FIREBASE_CREDS não encontrado. Firebase será configurado depois."
fi

# Configurar notificações de deploy
log_info "Criando script de health check do sistema..."

cat > /usr/local/bin/nexus_monitor.sh << 'MONITOR_SCRIPT'
#!/bin/bash
# Script de monitoramento NexusTwos
LOG_FILE="/var/log/nexus/monitor.log"
ALERT_FILE="/var/log/nexus/alerts.log"
PROJECT_DIR="/opt/nexus"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"; }
alert() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] ⚠️ ALERTA: $1" | tee -a "$ALERT_FILE"; }

echo "🔍 Verificando serviços NexusTwos..."

cd $PROJECT_DIR 2>/dev/null || { alert "Diretório do projeto não encontrado"; exit 1; }

# Verificar containers
for service in postgres redis backend worker nginx prometheus grafana alertmanager; do
    if docker compose ps --status running --services 2>/dev/null | grep -qx "$service"; then
        echo "  ✅ $service - rodando"
    else
        echo "  ❌ $service - PARADO"
        alert "Container $service está parado!"
    fi
done

# Verificar health endpoints
if curl -sf http://localhost:8000/health > /dev/null 2>&1; then
    echo "  ✅ API - saudável"
else
    echo "  ❌ API - offline"
    alert "API está offline!"
fi

# Recursos
DISK=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
MEM=$(free | grep Mem | awk '{printf("%d", ($3/$2)*100)}')

if [ "$DISK" -gt 80 ]; then alert "Disco em $DISK%"; fi
if [ "$MEM" -gt 85 ]; then alert "Memória em $MEM%"; fi

echo "  💾 Disco: ${DISK}% | Memória: ${MEM}% | $(date '+%Y-%m-%d %H:%M:%S')"
log "Monitoramento concluído - Disco: ${DISK}% - Memória: ${MEM}%"
MONITOR_SCRIPT

chmod +x /usr/local/bin/nexus_monitor.sh

log_info "Script de monitoramento criado em /usr/local/bin/nexus_monitor.sh"

# ═══════════════════════════════════════════════════════════════════════════
# PASSO 15: SCRIPTS DE GERENCIAMENTO E FINALIZAÇÃO
# ═══════════════════════════════════════════════════════════════════════════

CURRENT_STEP=$((CURRENT_STEP + 1))
log_section "PASSO $CURRENT_STEP: CRIAR SCRIPTS DE GERENCIAMENTO"

# Criar script de atualização
log_info "Criando script de atualização segura..."

cat > /usr/local/bin/update_nexus.sh << 'UPDATE_SCRIPT'
#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════
# NEXUSTWOS - ATUALIZAÇÃO SEGURA
# ═══════════════════════════════════════════════════════════════════════════
# Atualiza a aplicação sem perda de dados
# Uso: sudo bash update_nexus.sh
# ═══════════════════════════════════════════════════════════════════════════

set -e
PROJECT_DIR="/opt/nexus"
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'

echo -e "${YELLOW}════════════════════════════════════════════${NC}"
echo -e "${YELLOW}  NEXUSTWOS - ATUALIZAÇÃO SEGURA${NC}"
echo -e "${YELLOW}  $(date '+%Y-%m-%d %H:%M:%S')${NC}"
echo -e "${YELLOW}════════════════════════════════════════════${NC}"

# 1. Backup
echo -e "\n${GREEN}[1/6]${NC} Fazendo backup..."
bash /usr/local/bin/backup_nexus.sh

# 2. Atualizar código
echo -e "\n${GREEN}[2/6]${NC} Atualizando código..."
cd $PROJECT_DIR
if [ -d ".git" ]; then
    git stash 2>/dev/null || true
    git pull origin main 2>/dev/null || echo -e "${YELLOW}Aviso: git pull falhou${NC}"
    git stash pop 2>/dev/null || true
else
    echo -e "${YELLOW}Repositório Git não encontrado. Pule esta etapa.${NC}"
fi

# 3. Reconstruir
echo -e "\n${GREEN}[3/6]${NC} Reconstruindo containers..."
docker compose build --no-cache backend worker 2>/dev/null || docker-compose build --no-cache backend worker

# 4. Iniciar
echo -e "\n${GREEN}[4/6]${NC} Iniciando serviços..."
docker compose up -d postgres redis 2>/dev/null || docker-compose up -d postgres redis
sleep 10
docker compose up -d backend worker nginx 2>/dev/null || docker-compose up -d backend worker nginx
sleep 5
docker compose up -d prometheus grafana alertmanager 2>/dev/null || docker-compose up -d prometheus grafana alertmanager 2>/dev/null || true

# 5. Migrations
echo -e "\n${GREEN}[5/6]${NC} Rodando migrations..."
docker compose exec backend alembic upgrade head 2>/dev/null || echo -e "${YELLOW}Aviso: migrations falhou${NC}"

# 6. Verificar
echo -e "\n${GREEN}[6/6]${NC} Verificando deploy..."
if [ -f "$PROJECT_DIR/verify_vps_deployment.sh" ]; then
    bash "$PROJECT_DIR/verify_vps_deployment.sh" || true
fi

echo -e "\n${GREEN}════════════════════════════════════════════${NC}"
echo -e "${GREEN}  ✅ ATUALIZAÇÃO CONCLUÍDA!${NC}"
echo -e "${GREEN}════════════════════════════════════════════${NC}"
UPDATE_SCRIPT
chmod +x /usr/local/bin/update_nexus.sh

# Criar script de rollback
cat > /usr/local/bin/rollback_nexus.sh << 'ROLLBACK_SCRIPT'
#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════
# NEXUSTWOS - ROLLBACK DE EMERGÊNCIA
# ═══════════════════════════════════════════════════════════════════════════
# Uso: sudo bash rollback_nexus.sh
# ═══════════════════════════════════════════════════════════════════════════

set -e
PROJECT_DIR="/opt/nexus"
BACKUP_DIR="/backups/nexus"
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'

echo -e "${RED}════════════════════════════════════════════${NC}"
echo -e "${RED}  ⚠️  ROLLBACK DE EMERGÊNCIA${NC}"
echo -e "${RED}════════════════════════════════════════════${NC}"

# Listar backups
echo -e "\n${YELLOW}Backups disponíveis:${NC}"
ls -lh $BACKUP_DIR/postgres_*.sql 2>/dev/null | head -5 || echo "  Nenhum backup encontrado"

# Restaurar PostgreSQL
LATEST_BACKUP=$(ls -t $BACKUP_DIR/postgres_*.sql 2>/dev/null | head -1)
if [ -n "$LATEST_BACKUP" ]; then
    echo -e "\n${GREEN}Restaurando PostgreSQL de: $LATEST_BACKUP${NC}"
    cd $PROJECT_DIR
    cat "$LATEST_BACKUP" | docker compose exec -T postgres psql -U postgres nexus 2>/dev/null || \
    cat "$LATEST_BACKUP" | docker-compose exec -T postgres psql -U postgres nexus
    echo -e "${GREEN}✅ PostgreSQL restaurado!${NC}"
else
    echo -e "${RED}Nenhum backup encontrado para restaurar.${NC}"
fi

echo -e "\n${YELLOW}Reiniciando serviços...${NC}"
cd $PROJECT_DIR
docker compose restart 2>/dev/null || docker-compose restart 2>/dev/null || true

echo -e "\n${GREEN}════════════════════════════════════════════${NC}"
echo -e "${GREEN}  ✅ ROLLBACK CONCLUÍDO!${NC}"
echo -e "${GREEN}════════════════════════════════════════════${NC}"
ROLLBACK_SCRIPT
chmod +x /usr/local/bin/rollback_nexus.sh

log_info "Scripts de gerenciamento criados:"
echo "  → /usr/local/bin/update_nexus.sh    (atualização segura)"
echo "  → /usr/local/bin/rollback_nexus.sh   (rollback de emergência)"
echo "  → /usr/local/bin/backup_nexus.sh     (backup manual)"
echo "  → /usr/local/bin/nexus_monitor.sh    (monitoramento)"
echo "  → /usr/local/bin/nexus_health_check.sh (health check)"

# ═══════════════════════════════════════════════════════════════════════════
# RESUMO FINAL
# ═══════════════════════════════════════════════════════════════════════════

log_section "INSTALAÇÃO CONCLUÍDA!"

echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                                                              ║${NC}"
echo -e "${GREEN}║        ✅ SISTEMA NEXUSTWOS PRONTO PARA PRODUÇÃO!            ║${NC}"
echo -e "${GREEN}║                                                              ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${YELLOW}════════════════════════════════════════════${NC}"
echo -e "${YELLOW}  PRÓXIMOS PASSOS${NC}"
echo -e "${YELLOW}════════════════════════════════════════════${NC}"
echo ""

echo -e "${GREEN}1. Configurar o arquivo .env (se necessário):${NC}"
echo "   nano $PROJECT_DIR/.env"
echo ""

echo -e "${GREEN}2. Iniciar a stack Docker:${NC}"
echo "   cd $PROJECT_DIR"
echo "   docker compose up -d"
echo ""

echo -e "${GREEN}3. Configurar SSL com Certbot:${NC}"
echo "   certbot certonly --nginx -d ${DOMAIN} -d www.${DOMAIN}"
echo "   certbot certonly --nginx -d api.${DOMAIN}"
echo "   certbot certonly --nginx -d admin.${DOMAIN}"
echo ""

echo -e "${GREEN}4. Rodar migrations do banco:${NC}"
echo "   docker compose exec backend alembic upgrade head"
echo ""

echo -e "${GREEN}5. Verificar deploy:${NC}"
echo "   bash $PROJECT_DIR/verify_vps_deployment.sh"
echo ""

echo -e "${YELLOW}════════════════════════════════════════════${NC}"
echo -e "${YELLOW}  INFORMAÇÕES IMPORTANTES${NC}"
echo -e "${YELLOW}════════════════════════════════════════════${NC}"
echo ""
echo -e "  🌐 Domínio:              ${CYAN}https://${DOMAIN}${NC}"
echo -e "  🔧 API:                  ${CYAN}https://api.${DOMAIN}${NC}"
echo -e "  📊 Admin:                ${CYAN}https://admin.${DOMAIN}${NC}"
echo -e "  📈 Grafana:              ${CYAN}ssh -L 3000:localhost:3000 root@SEU_IP${NC}"
echo -e "  💾 Backup dir:           ${CYAN}$BACKUP_DIR${NC}"
echo -e "  📝 Logs dir:             ${CYAN}$LOG_DIR${NC}"
echo -e "  🐳 Projeto dir:          ${CYAN}$PROJECT_DIR${NC}"
echo -e "  🔑 .env file:            ${CYAN}$PROJECT_DIR/.env${NC}"
echo ""

echo -e "${RED}⚠️  ATENÇÃO - AÇÕES OBRIGATÓRIAS:${NC}"
echo -e "  • Configure sua chave SSH pública (senão perde acesso!)"
echo -e "  • Configure os certificados SSL com Certbot"
echo -e "  • Altere a senha do Grafana após o primeiro acesso"
echo -e "  • Configure as credenciais do Mercado Pago no .env"
echo -e "  • Configure as credenciais Firebase no .env"
echo -e "  • Faça backup do arquivo .env em local seguro"
echo ""

echo -e "${YELLOW}════════════════════════════════════════════${NC}"
echo -e "${YELLOW}  LOGS DA INSTALAÇÃO${NC}"
echo -e "${YELLOW}════════════════════════════════════════════${NC}"
echo ""
echo "  Instalação registrada em: $LOG_DIR/setup.log"
echo ""

# Salvar log da instalação
{
    echo "========================================"
    echo "NEXUSTWOS SETUP - $(date)"
    echo "========================================"
    echo "Domain: $DOMAIN"
    echo "Admin Email: $ADMIN_EMAIL"
    echo "Docker: $(docker --version 2>/dev/null)"
    echo "Docker Compose: $(docker compose version 2>/dev/null || docker-compose --version 2>/dev/null)"
    echo "Firewall: $(ufw status 2>/dev/null | head -1)"
    echo "Fail2Ban: $(fail2ban-client status 2>/dev/null | head -1)"
    echo "========================================"
} > "$LOG_DIR/setup.log" 2>/dev/null

log_info "Setup completo! Reinicie o terminal para aplicar todas as alterações de grupo."
log_info "Comando: exec bash -l"

