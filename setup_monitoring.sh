#!/bin/bash

# Script de Setup de Monitoramento para Nexus
# Uso: bash setup_monitoring.sh [email|slack|telegram|all]

set -e

ENVIRONMENT=${1:-all}
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}═══════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}  Setup de Monitoramento - Nexus Streaming${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════${NC}\n"

# Criar diretórios
echo -e "${GREEN}[1/6]${NC} Criando diretórios..."
mkdir -p /var/log/nexus
mkdir -p ./monitoring/grafana/provisioning/{datasources,dashboards}
chmod -R 777 /var/log/nexus
echo -e "${GREEN}✓ Diretórios criados${NC}\n"

# Criar volumes Docker
echo -e "${GREEN}[2/6]${NC} Criando volumes Docker..."
docker volume create prometheus_data 2>/dev/null || true
docker volume create grafana_data 2>/dev/null || true
docker volume create alertmanager_data 2>/dev/null || true
echo -e "${GREEN}✓ Volumes criados${NC}\n"

# Instalar dependências Python
echo -e "${GREEN}[3/6]${NC} Instalando dependências..."
cd backend
pip install -q prometheus-client python-json-logger 2>/dev/null || echo "Skipping pip install"
cd ..
echo -e "${GREEN}✓ Dependências instaladas${NC}\n"

# Configurar Alertmanager baseado na opção
echo -e "${GREEN}[4/6]${NC} Configurando Alertmanager..."

if [ "$ENVIRONMENT" = "email" ] || [ "$ENVIRONMENT" = "all" ]; then
    echo -e "${YELLOW}  → Configurar Email${NC}"
    read -p "Email para alertas: " ALERT_EMAIL
    read -p "SMTP Host (padrão: smtp.gmail.com): " SMTP_HOST
    SMTP_HOST=${SMTP_HOST:-smtp.gmail.com}
    read -p "SMTP Username: " SMTP_USER
    read -s -p "SMTP Password: " SMTP_PASS
    echo ""
    
    sed -i "s|postmaster@your-domain.com|$SMTP_USER|g" monitoring/alertmanager.yml
    sed -i "s|your-mailgun-password|$SMTP_PASS|g" monitoring/alertmanager.yml
    sed -i "s|smtp.mailgun.org:587|$SMTP_HOST:587|g" monitoring/alertmanager.yml
    sed -i "s|critical-alerts@your-domain.com|$ALERT_EMAIL|g" monitoring/alertmanager.yml
    echo -e "${GREEN}✓ Email configurado${NC}"
fi

if [ "$ENVIRONMENT" = "slack" ] || [ "$ENVIRONMENT" = "all" ]; then
    echo -e "${YELLOW}  → Configurar Slack${NC}"
    read -p "Slack Webhook URL: " SLACK_WEBHOOK
    
    sed -i "s|YOUR_SLACK_WEBHOOK_URL|$SLACK_WEBHOOK|g" monitoring/alertmanager.yml
    echo -e "${GREEN}✓ Slack configurado${NC}"
fi

if [ "$ENVIRONMENT" = "telegram" ] || [ "$ENVIRONMENT" = "all" ]; then
    echo -e "${YELLOW}  → Configurar Telegram${NC}"
    read -p "Telegram Chat ID: " TELEGRAM_CHAT_ID
    read -p "Telegram Bot Token: " TELEGRAM_BOT_TOKEN
    
    sed -i "s|YOUR_TELEGRAM_CHAT_ID|$TELEGRAM_CHAT_ID|g" monitoring/alertmanager.yml
    sed -i "s|YOUR_BOT_TOKEN|$TELEGRAM_BOT_TOKEN|g" monitoring/alertmanager.yml
    echo -e "${GREEN}✓ Telegram configurado${NC}"
fi

echo ""

# Iniciar stack
echo -e "${GREEN}[5/6]${NC} Iniciando stack de monitoramento..."
docker-compose up -d postgres redis backend worker nginx prometheus grafana alertmanager postgres_exporter redis_exporter node_exporter cadvisor
echo -e "${GREEN}✓ Stack iniciado${NC}\n"

# Aguardar serviços
echo -e "${GREEN}[6/6]${NC} Aguardando serviços ficarem prontos..."
sleep 10

# Verificar saúde
echo -e "\n${YELLOW}═══════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}  Verificando Saúde${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════${NC}\n"

services=(
    "prometheus:9090"
    "grafana:3000"
    "alertmanager:9093"
)

for service in "${services[@]}"; do
    IFS=':' read -r host port <<< "$service"
    if timeout 5 bash -c "cat < /dev/null > /dev/tcp/$host/$port" 2>/dev/null; then
        echo -e "${GREEN}✓${NC} $service está respondendo"
    else
        echo -e "${RED}✗${NC} $service não respondendo"
    fi
done

echo ""
echo -e "${YELLOW}═══════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  Setup Concluído!${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════${NC}\n"

echo -e "📊 ${GREEN}Grafana${NC}:"
echo "   URL: http://localhost:3000"
echo "   Usuário: admin"
echo "   Senha: admin (altere em produção!)\n"

echo -e "📈 ${GREEN}Prometheus${NC}:"
echo "   URL: http://localhost:9090\n"

echo -e "🔔 ${GREEN}Alertmanager${NC}:"
echo "   URL: http://localhost:9093\n"

echo -e "📝 ${GREEN}Logs${NC}:"
echo "   Localização: /var/log/nexus/\n"

echo -e "${YELLOW}Próximos passos:${NC}"
echo "1. Acessar Grafana e criar dashboards"
echo "2. Testar alertas:"
echo "   docker-compose exec alertmanager curl http://localhost:9093/api/v1/alerts"
echo "3. Ver documentação:"
echo "   cat MONITORING_SETUP.md\n"

