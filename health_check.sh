#!/bin/bash

# ═══════════════════════════════════════════════════════════════════════════
# SCRIPT DE HEALTH CHECK - NEXUS MONITORING
# ═══════════════════════════════════════════════════════════════════════════
#
# Verifica saúde do stack de monitoramento
# Uso: bash health_check.sh
#
# Adicionar ao cron a cada 5 minutos: */5 * * * * /opt/nexus/health_check.sh
#
# ═══════════════════════════════════════════════════════════════════════════

cd /opt/nexus

FAILED=0
SERVICES=("prometheus" "grafana" "alertmanager" "postgres_exporter" "redis_exporter" "node_exporter" "cadvisor")

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] Verificando saúde dos serviços...${NC}"
echo ""

# ═══════════════════════════════════════════════════════════════════════════
# Verificar cada serviço
# ═══════════════════════════════════════════════════════════════════════════

for service in "${SERVICES[@]}"; do
  # Verificar se container está rodando
  if docker-compose exec -T $service echo "ok" > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} $service - rodando"
  else
    echo -e "${RED}✗${NC} $service - ${RED}PARADO${NC}"
    FAILED=$((FAILED + 1))
    
    # Tentar reiniciar
    echo -e "  ${YELLOW}Tentando reiniciar...${NC}"
    docker-compose restart $service > /dev/null 2>&1
  fi
done

echo ""

# ═══════════════════════════════════════════════════════════════════════════
# Verificar saúde específica de cada serviço
# ═══════════════════════════════════════════════════════════════════════════

echo -e "${YELLOW}Verificações de Health:${NC}"
echo ""

# Prometheus
if curl -s http://localhost:9090/-/healthy > /dev/null 2>&1; then
  echo -e "${GREEN}✓${NC} Prometheus - respondendo"
else
  echo -e "${RED}✗${NC} Prometheus - ${RED}NÃO RESPONDENDO${NC}"
  FAILED=$((FAILED + 1))
fi

# Grafana
if curl -s http://localhost:3000/api/health > /dev/null 2>&1; then
  echo -e "${GREEN}✓${NC} Grafana - respondendo"
else
  echo -e "${RED}✗${NC} Grafana - ${RED}NÃO RESPONDENDO${NC}"
  FAILED=$((FAILED + 1))
fi

# Alertmanager
if curl -s http://localhost:9093/-/healthy > /dev/null 2>&1; then
  echo -e "${GREEN}✓${NC} Alertmanager - respondendo"
else
  echo -e "${RED}✗${NC} Alertmanager - ${RED}NÃO RESPONDENDO${NC}"
  FAILED=$((FAILED + 1))
fi

echo ""

# ═══════════════════════════════════════════════════════════════════════════
# Verificar recursos
# ═══════════════════════════════════════════════════════════════════════════

echo -e "${YELLOW}Recursos do Sistema:${NC}"
echo ""

# Disco
DISK_USAGE=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
if [ $DISK_USAGE -lt 80 ]; then
  echo -e "${GREEN}✓${NC} Disco - ${DISK_USAGE}% usado"
else
  echo -e "${RED}✗${NC} Disco - ${DISK_USAGE}% usado (CRÍTICO)"
  FAILED=$((FAILED + 1))
fi

# Memória
MEM_USAGE=$(free | grep Mem | awk '{printf("%d", ($3/$2)*100)}')
if [ $MEM_USAGE -lt 85 ]; then
  echo -e "${GREEN}✓${NC} Memória - ${MEM_USAGE}% usado"
else
  echo -e "${RED}✗${NC} Memória - ${MEM_USAGE}% usado (CRÍTICO)"
  FAILED=$((FAILED + 1))
fi

# CPU
CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{printf("%d", 100-$1)}')
if [ $CPU_USAGE -lt 90 ]; then
  echo -e "${GREEN}✓${NC} CPU - ${CPU_USAGE}% usado"
else
  echo -e "${RED}✗${NC} CPU - ${CPU_USAGE}% usado (CRÍTICO)"
  FAILED=$((FAILED + 1))
fi

# Logs
LOG_SIZE=$(du -sh /var/log/nexus | cut -f1)
echo -e "${GREEN}✓${NC} Logs - $LOG_SIZE"

echo ""

# ═══════════════════════════════════════════════════════════════════════════
# Relatório final
# ═══════════════════════════════════════════════════════════════════════════

if [ $FAILED -eq 0 ]; then
  echo -e "${GREEN}═══════════════════════════════════════════${NC}"
  echo -e "${GREEN}  ✓ TODOS OS SERVIÇOS OK!${NC}"
  echo -e "${GREEN}═══════════════════════════════════════════${NC}"
  exit 0
else
  echo -e "${RED}═══════════════════════════════════════════${NC}"
  echo -e "${RED}  ✗ $FAILED SERVIÇOS COM PROBLEMA${NC}"
  echo -e "${RED}═══════════════════════════════════════════${NC}"
  
  # Enviar alerta (opcional)
  # curl -X POST https://hooks.slack.com/services/YOUR/WEBHOOK/URL \
  #   -H 'Content-Type: application/json' \
  #   -d "{\"text\": \"⚠️ ALERTA: $FAILED serviços com problema na VPS\"}"
  
  exit 1
fi

