#!/bin/bash

# ═══════════════════════════════════════════════════════════════════════════
# SCRIPT DE SETUP MONITORAMENTO - VPS HOSTINGER
# ═══════════════════════════════════════════════════════════════════════════
# 
# Este script configura todo o stack de monitoramento em uma VPS
# Testado em: Ubuntu 20.04 LTS, Ubuntu 22.04 LTS
#
# Uso: sudo bash deploy_vps.sh
#
# ═══════════════════════════════════════════════════════════════════════════

set -e

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Variáveis
VPS_IP="0.0.0.0"  # Será detectado
DOMAIN="api.nexusstream.com"  # ALTERE PARA SEU DOMÍNIO
EMAIL="admin@nexus.com"  # ALTERE PARA SEU EMAIL

echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     Setup de Monitoramento - VPS Hostinger (Produção)        ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════╝${NC}\n"

# Verificar se é root
if [ "$EUID" -ne 0 ]; then 
  echo -e "${RED}❌ Este script deve ser executado como root${NC}"
  echo "Use: sudo bash deploy_vps.sh"
  exit 1
fi

# ═══════════════════════════════════════════════════════════════════════════
# PASSO 1: Atualizar sistema
# ═══════════════════════════════════════════════════════════════════════════

echo -e "${GREEN}[1/10]${NC} Atualizando sistema..."
apt-get update -qq
apt-get upgrade -y -qq
apt-get install -y -qq curl wget git htop ncdu jq

echo -e "${GREEN}✓ Sistema atualizado${NC}\n"

# ═══════════════════════════════════════════════════════════════════════════
# PASSO 2: Instalar Docker
# ═══════════════════════════════════════════════════════════════════════════

echo -e "${GREEN}[2/10]${NC} Instalando Docker..."

if ! command -v docker &> /dev/null; then
  curl -fsSL https://get.docker.com -o get-docker.sh
  bash get-docker.sh > /dev/null 2>&1
  rm get-docker.sh
  
  # Adicionar usuário ao grupo docker
  usermod -aG docker $SUDO_USER 2>/dev/null || true
fi

# Instalar Docker Compose
if ! command -v docker-compose &> /dev/null; then
  curl -fsSL https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
  chmod +x /usr/local/bin/docker-compose
fi

# Iniciar Docker
systemctl start docker
systemctl enable docker

echo -e "${GREEN}✓ Docker instalado (versão: $(docker --version))${NC}\n"

# ═══════════════════════════════════════════════════════════════════════════
# PASSO 3: Criar diretórios
# ═══════════════════════════════════════════════════════════════════════════

echo -e "${GREEN}[3/10]${NC} Criando diretórios..."

mkdir -p /var/log/nexus
mkdir -p /opt/nexus
mkdir -p /opt/nexus/monitoring
mkdir -p /opt/nexus/backend
mkdir -p /data/prometheus
mkdir -p /data/grafana
mkdir -p /data/postgres

chmod 777 /var/log/nexus
chmod 755 /data/*

echo -e "${GREEN}✓ Diretórios criados${NC}\n"

# ═══════════════════════════════════════════════════════════════════════════
# PASSO 4: Clonar repositório (se necessário)
# ═══════════════════════════════════════════════════════════════════════════

echo -e "${GREEN}[4/10]${NC} Configurando repositório..."

if [ ! -d "/opt/nexus/.git" ]; then
  echo "Clonando repositório Nexus..."
  git clone https://github.com/doedesenvolvedor-lgtm/Nexus.git /opt/nexus
else
  echo "Atualizando repositório..."
  cd /opt/nexus
  git pull origin main
  cd -
fi

cd /opt/nexus

echo -e "${GREEN}✓ Repositório configurado${NC}\n"

# ═══════════════════════════════════════════════════════════════════════════
# PASSO 5: Detectar IP da VPS
# ═══════════════════════════════════════════════════════════════════════════

echo -e "${GREEN}[5/10]${NC} Detectando IP da VPS..."

VPS_IP=$(curl -s https://api.ipify.org)

echo -e "${GREEN}✓ IP da VPS: ${YELLOW}${VPS_IP}${NC}\n"

# ═══════════════════════════════════════════════════════════════════════════
# PASSO 6: Criar volumes Docker
# ═══════════════════════════════════════════════════════════════════════════

echo -e "${GREEN}[6/10]${NC} Criando volumes Docker..."

docker volume create prometheus_data 2>/dev/null || true
docker volume create grafana_data 2>/dev/null || true
docker volume create alertmanager_data 2>/dev/null || true

echo -e "${GREEN}✓ Volumes criados${NC}\n"

# ═══════════════════════════════════════════════════════════════════════════
# PASSO 7: Instalar dependências Python
# ═══════════════════════════════════════════════════════════════════════════

echo -e "${GREEN}[7/10]${NC} Instalando dependências Python..."

pip install -q prometheus-client python-json-logger 2>/dev/null || \
pip3 install -q prometheus-client python-json-logger

echo -e "${GREEN}✓ Dependências Python instaladas${NC}\n"

# ═══════════════════════════════════════════════════════════════════════════
# PASSO 8: Configurar firewall
# ═══════════════════════════════════════════════════════════════════════════

echo -e "${GREEN}[8/10]${NC} Configurando firewall..."

# UFW (se instalado)
if command -v ufw &> /dev/null; then
  ufw allow 22/tcp 2>/dev/null || true
  ufw allow 80/tcp 2>/dev/null || true
  ufw allow 443/tcp 2>/dev/null || true
  ufw allow 3000/tcp 2>/dev/null || true  # Grafana (restrito em produção)
  ufw allow 9090/tcp 2>/dev/null || true  # Prometheus (restrito em produção)
  ufw allow 9093/tcp 2>/dev/null || true  # Alertmanager (restrito em produção)
fi

echo -e "${GREEN}✓ Firewall configurado${NC}\n"

# ═══════════════════════════════════════════════════════════════════════════
# PASSO 9: Iniciar stack
# ═══════════════════════════════════════════════════════════════════════════

echo -e "${GREEN}[9/10]${NC} Iniciando stack de monitoramento..."

cd /opt/nexus

# Iniciar serviços de monitoramento
docker-compose up -d prometheus grafana alertmanager \
  postgres_exporter redis_exporter node_exporter cadvisor 2>/dev/null

# Aguardar inicialização
sleep 15

echo -e "${GREEN}✓ Stack iniciado${NC}\n"

# ═══════════════════════════════════════════════════════════════════════════
# PASSO 10: Verificar saúde
# ═══════════════════════════════════════════════════════════════════════════

echo -e "${GREEN}[10/10]${NC} Verificando saúde dos serviços...\n"

echo -e "${YELLOW}Verificações:${NC}"

# Prometheus
if curl -s http://localhost:9090/-/healthy > /dev/null 2>&1; then
  echo -e "  ${GREEN}✓${NC} Prometheus respondendo"
else
  echo -e "  ${RED}✗${NC} Prometheus não respondendo"
fi

# Grafana
if curl -s http://localhost:3000/api/health > /dev/null 2>&1; then
  echo -e "  ${GREEN}✓${NC} Grafana respondendo"
else
  echo -e "  ${RED}✗${NC} Grafana não respondendo"
fi

# Alertmanager
if curl -s http://localhost:9093/-/healthy > /dev/null 2>&1; then
  echo -e "  ${GREEN}✓${NC} Alertmanager respondendo"
else
  echo -e "  ${RED}✗${NC} Alertmanager não respondendo"
fi

echo -e "\n${BLUE}╔═══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║           Setup Concluído com Sucesso!                       ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════╝${NC}\n"

echo -e "${YELLOW}Próximas etapas:${NC}\n"

echo -e "${GREEN}1. Acessar Grafana:${NC}"
echo "   URL: http://${VPS_IP}:3000"
echo "   Usuário: admin"
echo "   Senha: admin (${RED}ALTERE EM PRODUÇÃO${NC})"
echo ""

echo -e "${GREEN}2. Configurar alertas:${NC}"
echo "   Editar: /opt/nexus/monitoring/alertmanager.yml"
echo "   Adicionar credenciais SMTP/Slack/Telegram"
echo "   Reiniciar: docker-compose restart alertmanager"
echo ""

echo -e "${GREEN}3. Proteger dashboards (IMPORTANTE):${NC}"
echo "   Configurar Nginx com autenticação básica"
echo "   Desabilitar acesso direto às portas 9090, 9093"
echo "   Ver: /opt/nexus/MONITORING_SETUP.md"
echo ""

echo -e "${GREEN}4. Configurar HTTPS:${NC}"
echo "   Using Certbot com Let's Encrypt"
echo "   certbot certonly --standalone -d ${DOMAIN}"
echo ""

echo -e "${GREEN}5. Ver logs:${NC}"
echo "   tail -f /var/log/nexus/app.log | jq ."
echo ""

echo -e "${GREEN}6. Status dos containers:${NC}"
echo "   docker-compose ps"
echo ""

echo -e "${YELLOW}Documentação:${NC}"
echo "  • MONITORING_SETUP.md"
echo "  • COMMANDS_MONITORING.md"
echo "  • MONITORING_IMPLEMENTATION.md"
echo ""

