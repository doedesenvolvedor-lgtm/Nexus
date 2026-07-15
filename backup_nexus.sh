#!/bin/bash

# ═══════════════════════════════════════════════════════════════════════════
# SCRIPT DE BACKUP - NEXUS MONITORING
# ═══════════════════════════════════════════════════════════════════════════
#
# Realiza backup automático de dados importantes
# Uso: bash backup_nexus.sh
# 
# Adicionar ao cron: 0 2 * * * /opt/nexus/backup_nexus.sh
#
# ═══════════════════════════════════════════════════════════════════════════

BACKUP_DIR="/backups/nexus"
DATE=$(date +%Y%m%d_%H%M%S)
LOG_FILE="/var/log/nexus/backup.log"

# Criar diretório de backup
mkdir -p $BACKUP_DIR

# Função de log
log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> $LOG_FILE
}

log "===== INICIANDO BACKUP ====="

# ═══════════════════════════════════════════════════════════════════════════
# 1. Backup Prometheus
# ═══════════════════════════════════════════════════════════════════════════

log "Fazendo backup de Prometheus..."
cd /opt/nexus

if docker-compose exec -T prometheus tar czf /tmp/prometheus_backup.tar.gz /prometheus 2>/dev/null; then
  if docker cp prometheus:/tmp/prometheus_backup.tar.gz $BACKUP_DIR/prometheus_$DATE.tar.gz 2>/dev/null; then
    SIZE=$(du -h $BACKUP_DIR/prometheus_$DATE.tar.gz | cut -f1)
    log "✓ Prometheus backup concluído ($SIZE)"
  fi
fi

# ═══════════════════════════════════════════════════════════════════════════
# 2. Backup Grafana
# ═══════════════════════════════════════════════════════════════════════════

log "Fazendo backup de Grafana..."

if docker-compose exec -T grafana grafana-cli admin export-dashboard \
  > $BACKUP_DIR/grafana_dashboards_$DATE.json 2>/dev/null; then
  SIZE=$(du -h $BACKUP_DIR/grafana_dashboards_$DATE.json | cut -f1)
  log "✓ Grafana backup concluído ($SIZE)"
fi

# ═══════════════════════════════════════════════════════════════════════════
# 3. Backup Alertmanager
# ═══════════════════════════════════════════════════════════════════════════

log "Fazendo backup de Alertmanager..."

if docker-compose exec -T alertmanager tar czf /tmp/alertmanager_backup.tar.gz /alertmanager 2>/dev/null; then
  if docker cp alertmanager:/tmp/alertmanager_backup.tar.gz $BACKUP_DIR/alertmanager_$DATE.tar.gz 2>/dev/null; then
    SIZE=$(du -h $BACKUP_DIR/alertmanager_$DATE.tar.gz | cut -f1)
    log "✓ Alertmanager backup concluído ($SIZE)"
  fi
fi

# ═══════════════════════════════════════════════════════════════════════════
# 4. Backup Logs
# ═══════════════════════════════════════════════════════════════════════════

log "Fazendo backup de logs..."

if tar czf $BACKUP_DIR/logs_$DATE.tar.gz /var/log/nexus/ 2>/dev/null; then
  SIZE=$(du -h $BACKUP_DIR/logs_$DATE.tar.gz | cut -f1)
  log "✓ Logs backup concluído ($SIZE)"
fi

# ═══════════════════════════════════════════════════════════════════════════
# 5. Limpeza de backups antigos (manter 30 dias)
# ═══════════════════════════════════════════════════════════════════════════

log "Limpando backups antigos (> 30 dias)..."

DELETED=$(find $BACKUP_DIR -type f -mtime +30 -delete | wc -l)
log "✓ $DELETED arquivos antigos removidos"

# ═══════════════════════════════════════════════════════════════════════════
# 6. Relatório
# ═══════════════════════════════════════════════════════════════════════════

TOTAL_SIZE=$(du -sh $BACKUP_DIR | cut -f1)
TOTAL_FILES=$(find $BACKUP_DIR -type f | wc -l)

log "Resumo:"
log "  Total de arquivos: $TOTAL_FILES"
log "  Tamanho total: $TOTAL_SIZE"
log "===== BACKUP CONCLUÍDO ===="
log ""

# Enviar notificação (opcional)
# curl -X POST https://hooks.slack.com/services/YOUR/WEBHOOK/URL \
#   -H 'Content-Type: application/json' \
#   -d "{\"text\": \"✓ Backup Nexus concluído. Tamanho: $TOTAL_SIZE\"}"

