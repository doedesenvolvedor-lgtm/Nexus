# 🚀 Deployement em VPS - Nexus Streaming

## Pré-requisitos

- ✅ VPS com Ubuntu 20.04 LTS ou 22.04 LTS
- ✅ Mínimo 2GB RAM
- ✅ 50GB disco SSD
- ✅ Acesso SSH com privilégios de root
- ✅ Domínio configurado (ex: api.nexusstream.com)

---

## 📋 Checklist Pré-Deployment

- [ ] SSH funciona: `ssh root@seu-ip-vps`
- [ ] Domínio aponta para VPS IP
- [ ] Firewall permite portas 22, 80, 443
- [ ] Você tem credenciais SMTP (para email de alertas)
- [ ] Webhook Slack criado (opcional)
- [ ] Token Telegram criado (opcional)

---

## 🚀 Deploy Rápido (Automático)

### Passo 1: SSH para VPS

```bash
ssh root@seu-ip-vps
# Exemplo: ssh root@123.45.67.89
```

### Passo 2: Baixar script de deploy

```bash
cd /tmp
wget https://raw.githubusercontent.com/doedesenvolvedor-lgtm/Nexus/main/deploy_vps.sh
# Ou
curl -o deploy_vps.sh https://raw.githubusercontent.com/doedesenvolvedor-lgtm/Nexus/main/deploy_vps.sh
```

### Passo 3: Executar script

```bash
sudo bash deploy_vps.sh
```

Isso vai:
✅ Atualizar sistema
✅ Instalar Docker
✅ Clonar repositório
✅ Criar diretórios
✅ Criar volumes
✅ Iniciar stack
✅ Verificar saúde

---

## 📝 Deploy Manual (Passo a Passo)

Se preferir fazer manualmente:

### 1. Conectar à VPS

```bash
ssh root@seu-ip-vps
```

### 2. Atualizar sistema

```bash
apt-get update && apt-get upgrade -y
apt-get install -y curl wget git docker.io docker-compose python3-pip
```

### 3. Criar diretórios

```bash
mkdir -p /var/log/nexus
mkdir -p /opt/nexus
mkdir -p /data/prometheus /data/grafana /data/postgres

chmod 777 /var/log/nexus
chmod 755 /data/*
```

### 4. Clonar repositório

```bash
cd /opt/nexus
git clone https://github.com/doedesenvolvedor-lgtm/Nexus.git .
```

### 5. Instalar dependências

```bash
pip install prometheus-client python-json-logger
```

### 6. Criar volumes Docker

```bash
docker volume create prometheus_data
docker volume create grafana_data
docker volume create alertmanager_data
```

### 7. Iniciar stack

```bash
cd /opt/nexus
docker-compose up -d prometheus grafana alertmanager postgres_exporter redis_exporter node_exporter cadvisor
```

### 8. Verificar saúde

```bash
docker-compose ps
curl http://localhost:9090/-/healthy
curl http://localhost:3000/api/health
```

---

## 🔗 Acessar Serviços

### Direto (sem proteção - NÃO USE EM PRODUÇÃO)

```
Grafana:     http://seu-ip-vps:3000
Prometheus:  http://seu-ip-vps:9090
Alertmanager: http://seu-ip-vps:9093
```

### Com Nginx + Autenticação (RECOMENDADO)

```
Grafana:     https://seu-dominio/grafana
Prometheus:  https://seu-dominio/prometheus (protegido)
Alertmanager: https://seu-dominio/alertmanager (protegido)
```

---

## 🔐 Proteger Dashboards (IMPORTANTE)

### 1. Criar arquivo .htpasswd

```bash
apt-get install -y apache2-utils
htpasswd -c /etc/nginx/.htpasswd admin
# Digite senha desejada
```

### 2. Configurar Nginx

Editar `/etc/nginx/sites-available/default`:

```nginx
server {
    listen 80;
    server_name seu-dominio.com;

    # Redirecionar HTTP para HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name seu-dominio.com;

    # Certificados SSL
    ssl_certificate /etc/letsencrypt/live/seu-dominio.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/seu-dominio.com/privkey.pem;

    # Grafana (sem auth)
    location /grafana/ {
        proxy_pass http://localhost:3000/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    # Prometheus (com auth)
    location /prometheus/ {
        auth_basic "Prometheus";
        auth_basic_user_file /etc/nginx/.htpasswd;
        
        proxy_pass http://localhost:9090/;
        proxy_set_header Host $host;
    }

    # Alertmanager (com auth)
    location /alertmanager/ {
        auth_basic "Alertmanager";
        auth_basic_user_file /etc/nginx/.htpasswd;
        
        proxy_pass http://localhost:9093/;
        proxy_set_header Host $host;
    }
}
```

### 3. Instalar Let's Encrypt

```bash
apt-get install -y certbot python3-certbot-nginx
certbot certonly --nginx -d seu-dominio.com
```

### 4. Reiniciar Nginx

```bash
systemctl restart nginx
```

---

## ⚙️ Configurar Alertas

### Email (SMTP)

Editar `/opt/nexus/monitoring/alertmanager.yml`:

```yaml
global:
  smtp_smarthost: 'smtp.gmail.com:587'
  smtp_auth_username: 'seu-email@gmail.com'
  smtp_auth_password: 'sua-senha-app'
  smtp_from: 'alerts@nexus.com'
```

### Slack

```yaml
slack_api_url: 'https://hooks.slack.com/services/YOUR/WEBHOOK/URL'
```

### Telegram

```yaml
telegram_configs:
  - chat_id: 'YOUR_CHAT_ID'
    bot_token: 'YOUR_BOT_TOKEN'
```

### Aplicar mudanças

```bash
docker-compose restart alertmanager
```

---

## 📊 Monitorar Performance

### Ver logs em tempo real

```bash
tail -f /var/log/nexus/app.log | jq .
```

### Uso de disco

```bash
df -h
du -sh /data/*
du -sh /var/log/nexus/*
```

### Uso de memória

```bash
free -h
docker stats --no-stream
```

### Ver containers rodando

```bash
docker-compose ps
```

---

## 🔄 Backups

### Backup de dados Prometheus

```bash
# Manual
docker exec prometheus tar czf /prometheus_backup.tar.gz /prometheus
docker cp prometheus:/prometheus_backup.tar.gz /backups/prometheus_$(date +%Y%m%d).tar.gz

# Automático (cron)
0 2 * * * /opt/nexus/backup_prometheus.sh
```

### Backup de dados Grafana

```bash
docker exec grafana grafana-cli admin export-dashboard /tmp/dashboard.json
```

### Script de backup automático

```bash
#!/bin/bash
BACKUP_DIR="/backups"
DATE=$(date +%Y%m%d_%H%M%S)

# Prometheus
docker exec prometheus tar czf /prometheus_backup.tar.gz /prometheus
docker cp prometheus:/prometheus_backup.tar.gz $BACKUP_DIR/prometheus_$DATE.tar.gz

# Grafana
docker exec grafana grafana-cli admin export-dashboard > $BACKUP_DIR/grafana_$DATE.json

# Manter apenas 30 dias
find $BACKUP_DIR -type f -mtime +30 -delete

echo "Backup concluído: $DATE"
```

---

## 🆘 Troubleshooting

### Prometheus não coleta métricas

```bash
# Verificar logs
docker-compose logs prometheus

# Verificar connectivity
docker exec prometheus curl http://backend:8000/metrics

# Recarregar config
docker-compose exec prometheus kill -HUP 1
```

### Grafana sem dados

```bash
# Verificar datasource
curl http://localhost:3000/api/datasources

# Recriar datasource
docker-compose restart grafana
```

### Alertas não enviando

```bash
# Ver logs Alertmanager
docker-compose logs alertmanager

# Testar SMTP
docker-compose exec alertmanager \
  telnet smtp.gmail.com 587
```

### Espaço em disco cheio

```bash
# Ver uso
du -sh /var/log/nexus/*

# Limpar logs antigos
find /var/log/nexus -name "*.log.*" -mtime +30 -delete

# Comprimir logs
gzip /var/log/nexus/*.log.1
```

---

## 📋 Checklist Pós-Deploy

- [ ] Stack rodando: `docker-compose ps`
- [ ] Grafana acessível: http://seu-ip:3000
- [ ] Prometheus respondendo: http://seu-ip:9090/-/healthy
- [ ] Logs sendo gerados: `ls -lh /var/log/nexus/`
- [ ] Alertas configurados em alertmanager.yml
- [ ] Firewall permitindo apenas portas necessárias
- [ ] Backups configurados no cron
- [ ] HTTPS ativo com certificado válido
- [ ] Dashboards customizados criados
- [ ] Equipe treinada

---

## 🔄 Atualizações

### Atualizar repositório

```bash
cd /opt/nexus
git pull origin main
docker-compose up -d --build
```

### Atualizar imagens Docker

```bash
docker-compose pull
docker-compose up -d
```

---

## 🗑️ Remover Stack

### Parar containers

```bash
cd /opt/nexus
docker-compose down
```

### Remover volumes

```bash
docker volume rm prometheus_data grafana_data alertmanager_data
```

### Remover tudo (incluindo dados)

```bash
cd /opt/nexus
docker-compose down -v
rm -rf /opt/nexus
rm -rf /data/prometheus /data/grafana /data/postgres
rm -rf /var/log/nexus
```

---

## 📞 Suporte

Documentação completa:
- `MONITORING_SETUP.md` - Guia completo
- `COMMANDS_MONITORING.md` - Referência de comandos
- `MONITORING_STATUS.md` - Status de implementação
- `ARCHITECTURE.md` - Visão geral do sistema

---

## ✨ Conclusão

Seu sistema de monitoramento está **pronto para produção** em VPS!

🚀 Próximo passo: Executar `sudo bash deploy_vps.sh`

