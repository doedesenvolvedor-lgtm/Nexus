# 🤖 Automação em VPS - Cron Jobs

## O que são Cron Jobs?

Cron jobs executam scripts automaticamente em horários específicos. Vamos configurar:
- ✅ Health check a cada 5 minutos
- ✅ Backup automático todos os dias às 2 AM
- ✅ Limpeza de logs antigos semanalmente

---

## 📋 Fazer Scripts Executáveis

```bash
chmod +x /opt/nexus/deploy_vps.sh
chmod +x /opt/nexus/backup_nexus.sh
chmod +x /opt/nexus/health_check.sh
```

---

## ⏰ Configurar Cron Jobs

### 1. Abrir crontab do root

```bash
sudo crontab -e
```

### 2. Adicionar jobs

Adicione as seguintes linhas no final do arquivo:

```cron
# ═══════════════════════════════════════════════════════════════════════════
# NEXUS MONITORING - CRON JOBS
# ═══════════════════════════════════════════════════════════════════════════

# Health Check - A cada 5 minutos
*/5 * * * * /opt/nexus/health_check.sh

# Backup - Todos os dias às 2 AM
0 2 * * * /opt/nexus/backup_nexus.sh

# Limpeza de logs - A cada segunda-feira às 3 AM
0 3 * * 1 find /var/log/nexus -name "*.log.*" -mtime +30 -delete

# Atualizar repositório - Toda semana às sexta 10 PM
0 22 * * 5 cd /opt/nexus && git pull origin main >> /var/log/nexus/cron.log 2>&1

# Verificar espaço em disco - Diariamente às 1 AM
0 1 * * * df -h >> /var/log/nexus/disk_usage.log

# Notificação diária - Status do sistema às 8 AM
0 8 * * * /opt/nexus/daily_report.sh

# ═══════════════════════════════════════════════════════════════════════════
```

### 3. Salvar e fechar

- Vi: `Esc` + `:wq`
- Nano: `Ctrl+X` + `y` + `Enter`

---

## ✅ Verificar Cron Jobs

### Listar cron jobs configurados

```bash
sudo crontab -l
```

### Ver histórico de execução

```bash
grep CRON /var/log/syslog | tail -20
```

### Ver logs dos jobs

```bash
tail -f /var/log/nexus/cron.log
```

---

## 📊 Criar Script de Relatório Diário

```bash
cat > /opt/nexus/daily_report.sh << 'EOF'
#!/bin/bash

# Relatório diário do sistema Nexus

REPORT_FILE="/var/log/nexus/daily_report_$(date +%Y%m%d).log"

{
  echo "═══════════════════════════════════════════════════════════"
  echo "Relatório Diário - $(date '+%d/%m/%Y %H:%M:%S')"
  echo "═══════════════════════════════════════════════════════════"
  echo ""
  
  echo "CONTAINER STATUS:"
  docker-compose ps
  echo ""
  
  echo "RECURSOS DISPONÍVEIS:"
  echo "CPU: $(top -bn1 | grep "Cpu(s)" | awk '{printf "%.1f%%", 100-$NF}')"
  echo "Memória: $(free -h | grep Mem | awk '{print $3 "/" $2}')"
  echo "Disco: $(df -h / | tail -1 | awk '{print $3 "/" $2 " (" $5 ")"}')"
  echo ""
  
  echo "ALERTAS ATIVOS:"
  curl -s http://localhost:9093/api/v1/alerts | jq '.data | length' || echo "N/A"
  echo ""
  
  echo "BACKUP STATUS:"
  ls -lh /backups/nexus | tail -3
  echo ""
  
  echo "EVENTOS LOG HOJE:"
  echo "  Erros: $(grep -c ERROR /var/log/nexus/errors.log || echo 0)"
  echo "  Warnings: $(grep -c WARNING /var/log/nexus/app.log || echo 0)"
  
  echo ""
  echo "═══════════════════════════════════════════════════════════"
  
} > $REPORT_FILE

# Enviar por email (opcional)
# cat $REPORT_FILE | mail -s "Nexus Relatório Diário" admin@nexus.com

EOF

chmod +x /opt/nexus/daily_report.sh
```

---

## 🔔 Integrar com Slack/Telegram

### Notificação de Health Check

Editar `health_check.sh` e descomente:

```bash
# Se algum serviço falhou, enviar notificação
if [ $FAILED -gt 0 ]; then
  curl -X POST https://hooks.slack.com/services/YOUR/WEBHOOK/URL \
    -H 'Content-Type: application/json' \
    -d "{\"text\": \"⚠️ ALERTA Nexus: $FAILED serviço(s) com problema\"}"
fi
```

### Notificação de Backup

Editar `backup_nexus.sh` e descomente:

```bash
# Após completar backup
curl -X POST https://hooks.slack.com/services/YOUR/WEBHOOK/URL \
  -H 'Content-Type: application/json' \
  -d "{\"text\": \"✓ Backup Nexus concluído. Tamanho: $TOTAL_SIZE\"}"
```

---

## 🧪 Testar Cron Jobs

### Testar health check

```bash
/opt/nexus/health_check.sh
```

Deve mostrar status de todos os serviços.

### Testar backup

```bash
/opt/nexus/backup_nexus.sh
```

Deve criar arquivo de backup em `/backups/nexus/`.

### Testar relatório

```bash
/opt/nexus/daily_report.sh
```

Deve criar arquivo de relatório em `/var/log/nexus/`.

---

## 📝 Ver Log de Cron

```bash
# Últimas 50 execuções
grep CRON /var/log/syslog | tail -50

# Filtrar por job específico
grep "health_check" /var/log/syslog
```

---

## 🚨 Troubleshooting

### Cron job não está executando

**Problema**: Script não roda automaticamente

**Solução**:
```bash
# 1. Verificar permissões
ls -la /opt/nexus/*.sh

# 2. Dar permissão de execução
chmod +x /opt/nexus/*.sh

# 3. Verificar se cron está rodando
systemctl status cron

# 4. Ver logs
grep CRON /var/log/syslog | tail -20
```

### Email do cron não está sendo enviado

**Problema**: Cron tenta enviar email

**Solução**: Instalar Postfix ou redirecionar para arquivo:

```bash
# Instalar postfix (mail server leve)
apt-get install -y postfix

# Ou redirecionar output para arquivo
0 2 * * * /opt/nexus/backup_nexus.sh >> /var/log/nexus/backup.log 2>&1
```

### Variáveis de ambiente não funcionam no cron

**Problema**: Variáveis não estão disponíveis no cron

**Solução**: Adicionar ao topo do crontab:

```cron
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
DOCKER_HOST=unix:///var/run/docker.sock

# Jobs aqui...
```

---

## 📊 Exemplo de Agendamento Completo

```cron
# System Maintenance (root)
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
MAILTO=admin@nexus.com

# ═══════════════════════════════════════════════════════════════════════════
# MONITORING & BACKUP
# ═══════════════════════════════════════════════════════════════════════════

# Health Check - A cada 5 minutos
*/5 * * * * /opt/nexus/health_check.sh >> /var/log/nexus/health_check.log 2>&1

# Backup completo - Diariamente às 2 AM
0 2 * * * /opt/nexus/backup_nexus.sh >> /var/log/nexus/backup.log 2>&1

# Relatório diário - Às 8 AM
0 8 * * * /opt/nexus/daily_report.sh

# ═══════════════════════════════════════════════════════════════════════════
# MAINTENANCE
# ═══════════════════════════════════════════════════════════════════════════

# Atualizar repositório - Sexta-feira às 22h
0 22 * * 5 cd /opt/nexus && git pull origin main

# Limpeza de logs antigos - Segunda-feira às 3 AM
0 3 * * 1 find /var/log/nexus -name "*.log.*" -mtime +30 -delete

# Limpeza de backups antigos - Segunda-feira às 3:30 AM
30 3 * * 1 find /backups/nexus -type f -mtime +30 -delete

# Verificar espaço em disco - Diariamente às 1 AM
0 1 * * * df -h >> /var/log/nexus/disk_usage.log

# ═══════════════════════════════════════════════════════════════════════════
# DOCKER MAINTENANCE
# ═══════════════════════════════════════════════════════════════════════════

# Limpar imagens não utilizadas - Semanalmente
0 3 * * 0 docker system prune -f

# Verificar docker compose - A cada hora
0 * * * * cd /opt/nexus && docker-compose ps >> /var/log/nexus/docker_status.log

# ═══════════════════════════════════════════════════════════════════════════
```

---

## 🎯 Checklist de Automação

- [ ] Scripts têm permissão de execução
- [ ] Crontab editado com jobs
- [ ] Health check testado
- [ ] Backup testado
- [ ] Relatório testado
- [ ] Logs de cron sendo gerados
- [ ] Notificações Slack/Telegram configuradas
- [ ] Diretório de backup existe
- [ ] Espaço em disco suficiente para backups

---

## 📚 Referências

- [Cron Documentation](https://man7.org/linux/man-pages/man5/crontab.5.html)
- [Crontab Guru](https://crontab.guru) - Gerador de expressões cron
- [Docker Compose CLI](https://docs.docker.com/compose/reference/)

