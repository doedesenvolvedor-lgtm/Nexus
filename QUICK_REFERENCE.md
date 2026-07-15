# 📌 Quick Reference - Nexus Monitoring VPS

## 🚀 Deploy em 2 Minutos

```bash
ssh root@seu-ip-vps
curl -o deploy_vps.sh https://raw.githubusercontent.com/doedesenvolvedor-lgtm/Nexus/main/deploy_vps.sh
sudo bash deploy_vps.sh
```

**Resultado esperado**: Stack rodando, todos serviços UP ✓

---

## 🌐 URLs de Acesso

| Serviço | URL | Usuário | Senha |
|---------|-----|---------|-------|
| **Grafana** | http://seu-ip:3000 | admin | admin |
| **Prometheus** | http://seu-ip:9090 | - | - |
| **Alertmanager** | http://seu-ip:9093 | - | - |

---

## ⚙️ Comandos Essenciais

### Status dos Serviços

```bash
cd /opt/nexus
docker-compose ps                    # Ver todos containers
docker-compose logs -f prometheus   # Ver logs Prometheus
docker-compose logs -f grafana      # Ver logs Grafana
```

### Reiniciar Serviços

```bash
docker-compose restart prometheus
docker-compose restart grafana
docker-compose restart alertmanager
docker-compose restart --build       # Rebuild images
```

### Parando/Iniciando

```bash
docker-compose stop                  # Parar tudo
docker-compose start                 # Iniciar tudo
docker-compose down                  # Remover tudo
```

### Ver Logs em Tempo Real

```bash
tail -f /var/log/nexus/app.log | jq .           # App logs
tail -f /var/log/nexus/errors.log | jq .        # Errors
tail -f /var/log/nexus/database.log | jq .      # Database
```

---

## 📊 Grafana

### Acessar Dashboard

1. Ir para: `http://seu-ip:3000`
2. Login: `admin` / `admin`
3. Dashboard: "Nexus Streaming - Sistema"

### Métricas Principais

- **CPU Usage**: Uso de CPU em %
- **Memory Usage**: Memória utilizada em %
- **API Requests**: Requisições por segundo
- **Response Time**: Latência P95 em ms
- **Disk Usage**: Espaço em disco usado
- **Error Rate**: Taxa de erros 5xx/s

---

## 🔔 Alertmanager

### Ver Alertas Ativos

```bash
curl http://localhost:9093/api/v1/alerts | jq .
```

### Reconfigurar Alertas

1. Editar: `nano /opt/nexus/monitoring/alertmanager.yml`
2. Restart: `docker-compose restart alertmanager`

---

## 💾 Backups

### Fazer Backup Manual

```bash
/opt/nexus/backup_nexus.sh
```

### Ver Backups Existentes

```bash
ls -lh /backups/nexus/
```

### Restaurar Backup

```bash
# Parar serviços
docker-compose stop

# Restaurar Prometheus
cd /backups/nexus
tar xzf prometheus_*.tar.gz -C /data/

# Iniciar
docker-compose start
```

---

## 🏥 Health Check

### Verificar Saúde

```bash
/opt/nexus/health_check.sh
```

### Output Esperado

```
✓ prometheus - rodando
✓ grafana - rodando
✓ alertmanager - rodando
✓ Disco - 45% usado
✓ Memória - 62% usado
✓ CPU - 15% usado
```

---

## 🔍 Queries PromQL Comuns

### CPU

```promql
# CPU atual
node_cpu_seconds_total

# CPU nos últimos 5min
rate(node_cpu_seconds_total[5m]) * 100

# CPU por container
container_cpu_usage_seconds_total
```

### Memória

```promql
# Memória usada
node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes

# Container memória
container_memory_usage_bytes / 1024 / 1024
```

### Requisições API

```promql
# Taxa de requisições
rate(http_requests_total[5m])

# Erros por segundo
rate(http_requests_total{status=~"5.."}[5m])

# Latência P95
histogram_quantile(0.95, http_request_duration_seconds_bucket)
```

### Disco

```promql
# Uso de disco
node_filesystem_avail_bytes / node_filesystem_size_bytes * 100

# I/O por segundo
rate(node_disk_io_reads_completed_total[5m])
```

---

## 🚨 Troubleshooting Rápido

| Problema | Solução |
|----------|---------|
| Serviço parado | `docker-compose restart SERVICE` |
| Sem dados Grafana | Verificar datasource em Configuration > Data Sources |
| Alertas não enviando | Verificar `alertmanager.yml`, verificar SMTP/webhook |
| Disco cheio | `find /var/log/nexus -mtime +30 -delete` |
| Prometheus lento | Aumentar retention ou reduzir scrape interval |
| Memória alta | `docker stats` e `docker system prune -f` |

---

## 🔧 Configurações Pós-Deploy

### 1. Alterar Senha Grafana

GUI:
1. Grafana → Admin → Users → admin
2. Alterar senha
3. Logout e login com nova senha

### 2. Configurar Alertas

Editar `/opt/nexus/monitoring/alertmanager.yml`:

```yaml
global:
  smtp_smarthost: 'smtp.gmail.com:587'
  smtp_auth_username: 'email@gmail.com'
  smtp_auth_password: 'senha'
```

```bash
docker-compose restart alertmanager
```

### 3. Adicionar HTTPS

```bash
certbot certonly --nginx -d seu-dominio.com
# Copiar certificados para Nginx config
systemctl restart nginx
```

---

## 📋 Cron Jobs

```bash
# Ver cron jobs
crontab -l

# Editar
crontab -e

# Exemplo (health check cada 5min)
*/5 * * * * /opt/nexus/health_check.sh
0 2 * * * /opt/nexus/backup_nexus.sh
```

---

## 🔐 Segurança

### SSH Endurecido

```bash
# Desabilitar root login
sed -i 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config

# Desabilitar senha (apenas chaves)
sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config

systemctl restart sshd
```

### Firewall

```bash
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 3000/tcp    # Grafana
ufw enable
```

---

## 📈 Monitorar Performance

```bash
# Recursos em tempo real
docker stats

# Espaço em disco
df -h

# Top processos
top -b -n 1

# Redes
netstat -an
```

---

## 🆘 Comandos de Emergência

```bash
# Resetar Grafana (perder dados)
docker-compose exec grafana grafana-cli admin reset-admin-password admin123

# Resetar Prometheus retention
docker-compose exec prometheus promtool query instant 'up' --format=json

# Resetar Alertmanager
docker-compose exec alertmanager amtool config routes

# Ver uso disco Prometheus
du -sh /data/prometheus

# Limpar espaço
docker system prune -a -f
```

---

## 📚 Documentação

```
/opt/nexus/MONITORING_SETUP.md      # Guia completo
/opt/nexus/COMMANDS_MONITORING.md    # 50+ comandos
/opt/nexus/ARCHITECTURE.md           # Visão técnica
/opt/nexus/VPS_DEPLOYMENT.md         # Deploy detalhado
```

---

## 📱 Contacto

- 📧 **Email**: dev@nexus.com  
- 🐙 **GitHub**: doedesenvolvedor-lgtm/Nexus  
- 💬 **Discord**: [Link]  
- 📞 **Suporte 24/7**: support@nexus.com

---

## ⏱️ Próximos Passos

```
1. ✅ Deploy executado
2. ⏳ Alterar senha Grafana
3. ⏳ Configurar alertas (SMTP/Slack/Telegram)
4. ⏳ Setup HTTPS
5. ⏳ Criar backups
6. ⏳ Monitorar por 24h
7. ⏳ Ajustar thresholds conforme necessário
```

---

**Última atualização**: $(date)  
**Versão**: 1.0  
**Status**: ✅ Pronto para produção

