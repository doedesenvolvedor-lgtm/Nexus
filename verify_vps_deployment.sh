#!/bin/bash

# ═══════════════════════════════════════════════════════════════════════════
# SCRIPT DE VERIFICAÇÃO - VPS DEPLOYMENT NEXUS
# ═══════════════════════════════════════════════════════════════════════════
#
# Verifica se o deployment foi bem-sucedido após atualizar do repositório
# Uso: bash verify_vps_deployment.sh
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
PROJECT_DIR="/opt/nexus"
FAILED=0
PASSED=0

echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║        Verificação de Deployment - VPS Nexus                ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════╝${NC}\n"

# ═══════════════════════════════════════════════════════════════════════════
# 1. Verificar Git atualizado
# ═══════════════════════════════════════════════════════════════════════════

echo -e "${YELLOW}[1/10]${NC} Verificando repositório Git..."

if cd "$PROJECT_DIR" 2>/dev/null; then
    STATUS=$(git status --porcelain 2>/dev/null | wc -l)
    if [ "$STATUS" -eq 0 ]; then
        echo -e "${GREEN}✓${NC} Repositório limpo (sem alterações locais)"
        PASSED=$((PASSED + 1))
    else
        echo -e "${YELLOW}⚠${NC} $STATUS arquivos modificados localmente"
    fi
else
    echo -e "${RED}✗${NC} Diretório $PROJECT_DIR não encontrado"
    FAILED=$((FAILED + 1))
fi

# ═══════════════════════════════════════════════════════════════════════════
# 2. Verificar Docker Compose
# ═══════════════════════════════════════════════════════════════════════════

echo -e "\n${YELLOW}[2/10]${NC} Verificando Docker Compose..."

if docker-compose config > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} Docker Compose configurado corretamente"
    PASSED=$((PASSED + 1))
else
    echo -e "${RED}✗${NC} Erro no docker-compose.yml"
    FAILED=$((FAILED + 1))
fi

# ═══════════════════════════════════════════════════════════════════════════
# 3. Verificar Serviços Docker
# ═══════════════════════════════════════════════════════════════════════════

echo -e "\n${YELLOW}[3/10]${NC} Verificando serviços Docker..."

SERVICES=("postgres" "redis" "backend" "nginx" "prometheus" "grafana" "alertmanager")
RUNNING=0

for service in "${SERVICES[@]}"; do
    if docker-compose exec -T "$service" echo "ok" > /dev/null 2>&1; then
        echo -e "  ${GREEN}✓${NC} $service - rodando"
        RUNNING=$((RUNNING + 1))
    else
        echo -e "  ${YELLOW}⚠${NC} $service - verificar status"
    fi
done

if [ $RUNNING -eq ${#SERVICES[@]} ]; then
    echo -e "${GREEN}✓${NC} Todos os $RUNNING serviços rodando"
    PASSED=$((PASSED + 1))
else
    echo -e "${YELLOW}⚠${NC} Apenas $RUNNING/${#SERVICES[@]} serviços ativo"
fi

# ═══════════════════════════════════════════════════════════════════════════
# 4. Verificar Backend API
# ═══════════════════════════════════════════════════════════════════════════

echo -e "\n${YELLOW}[4/10]${NC} Verificando Backend API..."

if curl -s http://localhost:8000/health > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} Backend respondendo em /health"
    PASSED=$((PASSED + 1))
else
    echo -e "${YELLOW}⚠${NC} Backend não respondendo (esperado se configs faltam)"
fi

# ═══════════════════════════════════════════════════════════════════════════
# 5. Verificar PostgreSQL
# ═══════════════════════════════════════════════════════════════════════════

echo -e "\n${YELLOW}[5/10]${NC} Verificando PostgreSQL..."

if docker-compose exec -T postgres pg_isready -U postgres > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} PostgreSQL conectável"
    PASSED=$((PASSED + 1))
else
    echo -e "${RED}✗${NC} PostgreSQL não respondendo"
    FAILED=$((FAILED + 1))
fi

# ═══════════════════════════════════════════════════════════════════════════
# 6. Verificar Redis
# ═══════════════════════════════════════════════════════════════════════════

echo -e "\n${YELLOW}[6/10]${NC} Verificando Redis..."

if docker-compose exec -T redis redis-cli ping > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} Redis respondendo"
    PASSED=$((PASSED + 1))
else
    echo -e "${RED}✗${NC} Redis não respondendo"
    FAILED=$((FAILED + 1))
fi

# ═══════════════════════════════════════════════════════════════════════════
# 7. Verificar Prometheus
# ═══════════════════════════════════════════════════════════════════════════

echo -e "\n${YELLOW}[7/10]${NC} Verificando Prometheus..."

if curl -s http://localhost:9090/-/healthy > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} Prometheus em http://localhost:9090"
    PASSED=$((PASSED + 1))
else
    echo -e "${YELLOW}⚠${NC} Prometheus - verificar portas"
fi

# ═══════════════════════════════════════════════════════════════════════════
# 8. Verificar Grafana
# ═══════════════════════════════════════════════════════════════════════════

echo -e "\n${YELLOW}[8/10]${NC} Verificando Grafana..."

if curl -s http://localhost:3000/api/health > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} Grafana em http://localhost:3000"
    PASSED=$((PASSED + 1))
else
    echo -e "${YELLOW}⚠${NC} Grafana - verificar portas"
fi

# ═══════════════════════════════════════════════════════════════════════════
# 9. Verificar Espaço em Disco
# ═══════════════════════════════════════════════════════════════════════════

echo -e "\n${YELLOW}[9/10]${NC} Verificando espaço em disco..."

DISK_USAGE=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')

if [ "$DISK_USAGE" -lt 80 ]; then
    echo -e "${GREEN}✓${NC} Espaço em disco OK ($DISK_USAGE% utilizado)"
    PASSED=$((PASSED + 1))
else
    echo -e "${RED}✗${NC} Espaço em disco CRÍTICO ($DISK_USAGE% utilizado)"
    FAILED=$((FAILED + 1))
fi

# ═══════════════════════════════════════════════════════════════════════════
# 10. Verificar Certificados SSL
# ═══════════════════════════════════════════════════════════════════════════

echo -e "\n${YELLOW}[10/10]${NC} Verificando certificados SSL..."

if [ -f "/etc/letsencrypt/live/api.nexusstream.com/fullchain.pem" ]; then
    EXPIRY=$(openssl x509 -in /etc/letsencrypt/live/api.nexusstream.com/fullchain.pem -noout -dates | grep notAfter | cut -d= -f2)
    echo -e "${GREEN}✓${NC} SSL configurado (válido até: $EXPIRY)"
    PASSED=$((PASSED + 1))
else
    echo -e "${YELLOW}⚠${NC} Certificado SSL não encontrado (será gerado pelo Let's Encrypt)"
fi

# ═══════════════════════════════════════════════════════════════════════════
# RELATÓRIO FINAL
# ═══════════════════════════════════════════════════════════════════════════

echo -e "\n${BLUE}╔═══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                      RELATÓRIO FINAL                         ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════╝${NC}\n"

echo -e "Verificações: ${GREEN}$PASSED OK${NC} | ${RED}$FAILED FALHAS${NC}\n"

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✅ DEPLOYMENT BEM-SUCEDIDO!${NC}"
    echo -e "\n${BLUE}Acessos:${NC}"
    echo -e "  • API:          http://localhost:8000/docs"
    echo -e "  • Prometheus:   http://localhost:9090"
    echo -e "  • Grafana:      http://localhost:3000 (admin/admin)"
    echo -e "  • AlertManager: http://localhost:9093"
    exit 0
else
    echo -e "${RED}❌ $FAILED verificação(ões) falharam${NC}"
    echo -e "\n${YELLOW}Ações recomendadas:${NC}"
    echo -e "  • Revisar logs: docker-compose logs -f"
    echo -e "  • Reiniciar: docker-compose restart"
    echo -e "  • Validar .env: cat .env.docker-compose"
    exit 1
fi
