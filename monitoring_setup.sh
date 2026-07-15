#!/bin/bash

# ============================================
# NEXUS STREAMING - MONITORING & LOGGING SETUP
# ============================================
# Script para configurar monitoramento completo
# Verifica uptime, logs de Nginx, erros, etc.

set -e

echo "📊 Configurando monitoramento para Nexus Streaming..."

# ============================================
# 1. DIRETÓRIOS DE LOGS
# ============================================
echo "📁 Criando estrutura de logs..."

mkdir -p /var/log/nexus/{nginx,backend,admin,certbot}
mkdir -p /var/log/nexus/archives
chmod 755 /var/log/nexus

# ============================================
# 2. ROTAÇÃO DE LOGS (LOGROTATE)
# ============================================
echo "🔄 Configurando rotação de logs..."

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
EOF

# ============================================
# 3. SCRIPT DE MONITORAMENTO
# ============================================
echo "📈 Criando script de monitoramento..."

cat > /usr/local/bin/nexus_monitor.sh << 'EOF'
#!/bin/bash

# Script de monitoramento para Nexus Streaming
LOG_FILE="/var/log/nexus/monitor.log"
ALERT_FILE="/var/log/nexus/alerts.log"
THRESHOLDS_FILE="/etc/nexus/monitoring_thresholds.conf"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# ============================================
# FUNÇÕES DE MONITORAMENTO
# ============================================

log_event() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

alert() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ⚠️  ALERT: $1" | tee -a "$ALERT_FILE"
    # Aqui você pode adicionar envio de email ou webhook
}

check_service_status() {
    local service=$1
    local url=$2
    local expected_code=${3:-200}
    
    local http_code=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 "$url" -k)
    
    if [ "$http_code" = "$expected_code" ]; then
        echo -e "${GREEN}✓${NC} $service is UP (HTTP $http_code)"
        log_event "$service is UP (HTTP $http_code)"
        return 0
    else
        echo -e "${RED}✗${NC} $service is DOWN (HTTP $http_code, expected $expected_code)"
        alert "$service is DOWN (HTTP $http_code)"
        log_event "$service is DOWN (HTTP $http_code)"
        return 1
    fi
}

check_disk_usage() {
    local filesystem=$1
    local threshold=${2:-80}
    
    local usage=$(df -h "$filesystem" | awk 'NR==2 {print $5}' | sed 's/%//')
    
    if [ "$usage" -gt "$threshold" ]; then
        echo -e "${YELLOW}⚠${NC} Disk usage on $filesystem: ${RED}${usage}%${NC} (threshold: $threshold%)"
        alert "Disk usage on $filesystem is ${usage}% (threshold: $threshold%)"
        log_event "High disk usage on $filesystem: ${usage}%"
        return 1
    else
        echo -e "${GREEN}✓${NC} Disk usage on $filesystem: ${usage}% (OK)"
        log_event "Disk usage on $filesystem: ${usage}%"
        return 0
    fi
}

check_memory_usage() {
    local threshold=${1:-80}
    
    local mem_total=$(free -b | awk 'NR==2 {print $2}')
    local mem_used=$(free -b | awk 'NR==2 {print $3}')
    local mem_percent=$((mem_used * 100 / mem_total))
    
    if [ "$mem_percent" -gt "$threshold" ]; then
        echo -e "${YELLOW}⚠${NC} Memory usage: ${RED}${mem_percent}%${NC} (threshold: $threshold%)"
        alert "Memory usage is ${mem_percent}% (threshold: $threshold%)"
        log_event "High memory usage: ${mem_percent}%"
        return 1
    else
        echo -e "${GREEN}✓${NC} Memory usage: ${mem_percent}% (OK)"
        log_event "Memory usage: ${mem_percent}%"
        return 0
    fi
}

check_cpu_load() {
    local threshold=${1:-80}
    
    local cpu_load=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
    cpu_load=${cpu_load%.*}
    
    if [ "$cpu_load" -gt "$threshold" ]; then
        echo -e "${YELLOW}⚠${NC} CPU load: ${RED}${cpu_load}%${NC} (threshold: $threshold%)"
        alert "CPU load is ${cpu_load}% (threshold: $threshold%)"
        log_event "High CPU load: ${cpu_load}%"
        return 1
    else
        echo -e "${GREEN}✓${NC} CPU load: ${cpu_load}% (OK)"
        log_event "CPU load: ${cpu_load}%"
        return 0
    fi
}

check_nginx_errors() {
    local error_log="/var/log/nginx/error.log"
    local recent_errors=$(tail -100 "$error_log" 2>/dev/null | grep -c "error" || echo "0")
    
    if [ "$recent_errors" -gt 10 ]; then
        echo -e "${YELLOW}⚠${NC} Nginx errors detected: ${RED}$recent_errors${NC}"
        alert "Nginx has $recent_errors errors in recent log"
        log_event "Nginx errors detected: $recent_errors"
    else
        echo -e "${GREEN}✓${NC} Nginx error log is clean ($recent_errors recent errors)"
        log_event "Nginx errors: $recent_errors"
    fi
}

check_ssl_certificate_expiry() {
    local domain=$1
    local cert_path=$2
    local days_threshold=${3:-30}
    
    if [ ! -f "$cert_path" ]; then
        echo -e "${YELLOW}⚠${NC} Certificate not found: $cert_path"
        return 1
    fi
    
    local expiry_date=$(openssl x509 -enddate -noout -in "$cert_path" | cut -d= -f2)
    local expiry_epoch=$(date -d "$expiry_date" +%s)
    local now_epoch=$(date +%s)
    local days_left=$(((expiry_epoch - now_epoch) / 86400))
    
    if [ "$days_left" -lt 0 ]; then
        echo -e "${RED}✗ SSL Certificate for $domain has EXPIRED${NC}"
        alert "SSL Certificate for $domain has EXPIRED"
        log_event "SSL Certificate for $domain has EXPIRED"
        return 1
    elif [ "$days_left" -lt "$days_threshold" ]; then
        echo -e "${YELLOW}⚠${NC} SSL Certificate for $domain expires in ${RED}${days_left} days${NC}"
        alert "SSL Certificate for $domain expires in $days_left days"
        log_event "SSL Certificate for $domain expires in $days_left days"
        return 1
    else
        echo -e "${GREEN}✓${NC} SSL Certificate for $domain valid for $days_left days"
        log_event "SSL Certificate for $domain valid for $days_left days"
        return 0
    fi
}

check_docker_containers() {
    local total=$(docker ps -a --format "{{.Names}}" | wc -l)
    local running=$(docker ps --format "{{.Names}}" | wc -l)
    
    if [ "$total" -ne "$running" ]; then
        local stopped=$((total - running))
        echo -e "${YELLOW}⚠${NC} Docker: ${RED}$stopped${NC} container(s) not running (Total: $total, Running: $running)"
        alert "$stopped Docker container(s) not running"
        log_event "Docker container issue: $running/$total running"
        return 1
    else
        echo -e "${GREEN}✓${NC} Docker: All $running container(s) running"
        log_event "Docker containers: $running/$total running"
        return 0
    fi
}

# ============================================
# EXECUÇÃO DO MONITORAMENTO
# ============================================

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║     NEXUS STREAMING - MONITORING REPORT                   ║"
echo "║     $(date '+%Y-%m-%d %H:%M:%S')                              ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

echo "🔍 Verificando status dos serviços..."
check_service_status "API" "https://api.nexusstream.com" 200
check_service_status "Website" "https://nexusstream.com" 200
check_service_status "Admin" "https://admin.nexusstream.com" 200

echo ""
echo "💾 Verificando recursos do sistema..."
check_disk_usage "/"
check_memory_usage 80
check_cpu_load 80

echo ""
echo "🔐 Verificando SSL/TLS..."
check_ssl_certificate_expiry "nexusstream.com" "/etc/letsencrypt/live/nexusstream.com/fullchain.pem" 30
check_ssl_certificate_expiry "api.nexusstream.com" "/etc/letsencrypt/live/api.nexusstream.com/fullchain.pem" 30
check_ssl_certificate_expiry "admin.nexusstream.com" "/etc/letsencrypt/live/admin.nexusstream.com/fullchain.pem" 30

echo ""
echo "🐳 Verificando Docker..."
check_docker_containers

echo ""
echo "📝 Verificando logs..."
check_nginx_errors

echo ""
echo "✅ Monitoramento concluído!"
log_event "Monitoring cycle completed successfully"
EOF

chmod +x /usr/local/bin/nexus_monitor.sh

# ============================================
# 4. CRON JOB PARA MONITORAMENTO
# ============================================
echo "⏰ Configurando agendamento de monitoramento..."

cat >> /etc/crontab << 'EOF'
# Nexus monitoring every 30 minutes
*/30 * * * * root /usr/local/bin/nexus_monitor.sh >> /var/log/nexus/monitor.log 2>&1

# Daily detailed monitoring report at 1 AM
0 1 * * * root /usr/local/bin/nexus_monitor.sh | mail -s "Nexus Daily Monitoring Report" admin@nexusstream.com
EOF

# ============================================
# 5. NGINX ACCESS LOG ANÁLISE
# ============================================
echo "📊 Criando ferramentas de análise de logs..."

cat > /usr/local/bin/analyze_nginx_logs.sh << 'EOF'
#!/bin/bash

# Análise de logs de Nginx
echo "📊 Análise de Logs Nginx - $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

LOG_FILE="/var/log/nginx/access.log"

if [ ! -f "$LOG_FILE" ]; then
    echo "❌ Log file not found: $LOG_FILE"
    exit 1
fi

echo "🔝 Top 10 IPs por requisições:"
tail -10000 "$LOG_FILE" | awk '{print $1}' | sort | uniq -c | sort -rn | head -10

echo ""
echo "🚨 Top 10 URLs com erro (4xx, 5xx):"
tail -10000 "$LOG_FILE" | awk '$9 >= 400 {print $7}' | sort | uniq -c | sort -rn | head -10

echo ""
echo "⏱️  Requisições por hora (últimas 24h):"
tail -10000 "$LOG_FILE" | awk '{print $4}' | cut -d':' -f2 | sort | uniq -c | sort -rn | head -10

echo ""
echo "✅ Total de requisições (últimas 10k):"
wc -l < "$LOG_FILE"
EOF

chmod +x /usr/local/bin/analyze_nginx_logs.sh

# ============================================
# 6. UPTIME CHECKER
# ============================================
echo "🔗 Criando uptime checker..."

cat > /usr/local/bin/uptime_check.sh << 'EOF'
#!/bin/bash

# Uptime checker para Nexus Streaming
UPTIME_LOG="/var/log/nexus/uptime.log"

check_url_uptime() {
    local url=$1
    local name=$2
    local timeout=5
    
    for i in {1..3}; do
        if curl -s --connect-timeout $timeout "$url" -o /dev/null 2>/dev/null; then
            echo "$(date '+%Y-%m-%d %H:%M:%S') - $name: UP" >> "$UPTIME_LOG"
            return 0
        fi
    done
    
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $name: DOWN" >> "$UPTIME_LOG"
    return 1
}

check_url_uptime "https://api.nexusstream.com" "API"
check_url_uptime "https://nexusstream.com" "Website"
check_url_uptime "https://admin.nexusstream.com" "Admin"
EOF

chmod +x /usr/local/bin/uptime_check.sh

# ============================================
# 7. RESUMO FINAL
# ============================================
echo ""
echo "✅ Monitoramento configurado com sucesso!"
echo ""
echo "📋 Componentes instalados:"
echo "  ✓ Rotação de logs (logrotate)"
echo "  ✓ Script de monitoramento completo"
echo "  ✓ Análise de logs Nginx"
echo "  ✓ Uptime checker"
echo "  ✓ Agendamento automático (cron)"
echo ""
echo "📊 Logs disponíveis em:"
echo "  - /var/log/nexus/monitor.log"
echo "  - /var/log/nexus/alerts.log"
echo "  - /var/log/nexus/uptime.log"
echo ""
echo "🚀 Comandos úteis:"
echo "  - Verificar status agora: /usr/local/bin/nexus_monitor.sh"
echo "  - Analisar logs: /usr/local/bin/analyze_nginx_logs.sh"
echo "  - Verificar uptime: /usr/local/bin/uptime_check.sh"
echo "  - Monitorar logs em tempo real: tail -f /var/log/nexus/monitor.log"
echo ""
