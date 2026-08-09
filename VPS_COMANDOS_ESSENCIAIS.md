# 🛠️ Comandos Essenciais - Nexus VPS

> **Guia Rápido de Referência**

---

## 🚀 INICIALIZAÇÃO & PARADA

### Iniciar toda a stack
```bash
cd /opt/nexus
docker-compose up -d
```

### Parar toda a stack
```bash
docker-compose down
```

### Parar mantendo dados
```bash
docker-compose stop
```

### Reiniciar tudo
```bash
docker-compose restart
```

### Reiniciar um serviço específico
```bash
docker-compose restart backend
docker-compose restart postgres
docker-compose restart redis
docker-compose restart nginx
```

### Remover containers e volumes (⚠️ PERDA DE DADOS)
```bash
docker-compose down -v
```

---

## 📊 STATUS & LOGS

### Listar containers
```bash
docker-compose ps
```

### Ver logs em tempo real
```bash
docker-compose logs -f                    # todos
docker-compose logs -f backend            # backend
docker-compose logs -f postgres           # postgres
docker-compose logs -f redis              # redis
docker-compose logs -f nginx              # nginx
docker-compose logs -f prometheus         # prometheus
docker-compose logs -f grafana            # grafana
```

### Ver últimas 100 linhas
```bash
docker-compose logs --tail=100 backend
```

### Ver logs históricos
```bash
tail -100 /var/log/nexus/error.log
tail -100 /var/log/nexus/access.log
tail -100 /var/log/nexus/app.log
```

### Seguir logs históricos
```bash
tail -f /var/log/nexus/app.log
```

---

## 🔧 CONFIGURAÇÃO

### Editar variáveis de ambiente
```bash
nano /opt/nexus/.env
```

### Validar docker-compose.yml
```bash
docker-compose config
```

### Reconstruir imagens Docker
```bash
docker-compose build
docker-compose up -d
```

### Atualizar repositório
```bash
cd /opt/nexus
git pull origin main
```

---

## 🗄️ BANCO DE DADOS

### Acessar PostgreSQL
```bash
docker-compose exec postgres psql -U postgres -d nexus
```

### Listar bancos
```bash
docker-compose exec -T postgres psql -U postgres -c "\l"
```

### Listar tabelas
```bash
docker-compose exec -T postgres psql -U postgres -d nexus -c "\dt"
```

### Executar query
```bash
docker-compose exec -T postgres psql -U postgres -d nexus -c "SELECT COUNT(*) FROM users;"
```

### Backup do banco
```bash
docker-compose exec -T postgres pg_dump -U postgres nexus > /tmp/nexus-$(date +%Y%m%d).sql
```

### Restore do banco
```bash
docker-compose exec -T postgres psql -U postgres nexus < /tmp/nexus-20260805.sql
```

### Tamanho do banco
```bash
docker-compose exec -T postgres psql -U postgres -c "SELECT pg_size_pretty(pg_database_size('nexus'));"
```

### Vacuum (limpeza)
```bash
docker-compose exec -T postgres psql -U postgres -d nexus -c "VACUUM ANALYZE;"
```

---

## 🔴 REDIS

### Acessar Redis CLI
```bash
docker-compose exec redis redis-cli
```

### Com autenticação
```bash
docker-compose exec redis redis-cli -a sua_senha
```

### Verificar status
```bash
docker-compose exec -T redis redis-cli ping
# Esperado: PONG
```

### Info do Redis
```bash
docker-compose exec -T redis redis-cli INFO
```

### Info de memória
```bash
docker-compose exec -T redis redis-cli INFO memory
```

### Verificar latência
```bash
docker-compose exec redis redis-cli --latency 10
```

### Listar todas as chaves
```bash
docker-compose exec -T redis redis-cli KEYS "*"
```

### Deletar chave
```bash
docker-compose exec redis redis-cli DEL minha_chave
```

### Limpar tudo (⚠️ CUIDADO!)
```bash
docker-compose exec redis redis-cli FLUSHALL
```

### Backup (BGSAVE)
```bash
docker-compose exec -T redis redis-cli BGSAVE
```

### Status do BGSAVE
```bash
docker-compose exec -T redis redis-cli LASTSAVE
```

---

## 🌐 NGINX & HTTPS

### Testar configuração
```bash
docker-compose exec nginx nginx -t
```

### Reconstruir Nginx
```bash
docker-compose restart nginx
```

### Gerar certificados Let's Encrypt
```bash
cd /opt/nexus

docker run --rm \
  -v $(pwd)/certbot/conf:/etc/letsencrypt \
  -v $(pwd)/certbot/www:/var/www/certbot \
  certbot/certbot certonly --webroot -w /var/www/certbot \
  -d seudominio.com \
  -d www.seudominio.com \
  -d api.seudominio.com
```

### Renovar certificados
```bash
cd /opt/nexus

docker run --rm \
  -v $(pwd)/certbot/conf:/etc/letsencrypt \
  -v $(pwd)/certbot/www:/var/www/certbot \
  certbot/certbot renew --webroot -w /var/www/certbot
```

### Listar certificados
```bash
ls -la /opt/nexus/certbot/conf/live/
```

### Verificar validade do certificado
```bash
openssl x509 -in /opt/nexus/certbot/conf/live/seudominio.com/fullchain.pem -text -noout | grep -A2 "Validity"
```

---

## 📊 PROMETHEUS & GRAFANA

### Acessar Prometheus
```
http://localhost:9090
```

### Query PromQL (API)
```bash
curl "http://localhost:9090/api/v1/query?query=up"
```

### Acessar Grafana
```
http://localhost:3000
```

### Resetar senha Grafana
```bash
docker-compose exec grafana grafana-cli admin reset-admin-password nova_senha
```

### Verificar datasources
```bash
curl -s -u admin:senha http://localhost:3000/api/datasources | jq
```

### Recarregar dashboards
```bash
docker-compose restart grafana
```

---

## 🚨 ALERTMANAGER

### Acessar AlertManager
```
http://localhost:9093
```

### Ver alertas
```bash
curl -s http://localhost:9093/api/v1/alerts | jq
```

### Silenciar alerta
```bash
curl -X POST http://localhost:9093/api/v1/silences \
  -H "Content-Type: application/json" \
  -d '{
    "matchers": [{"name":"alertname","value":"MyAlert","isRegex":false}],
    "startsAt": "2026-08-05T12:00:00Z",
    "endsAt": "2026-08-06T12:00:00Z",
    "createdBy": "admin",
    "comment": "Maintenance"
  }'
```

---

## 🔒 FIREWALL

### Ver status
```bash
ufw status verbose
```

### Permitir porta
```bash
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
```

### Bloquear porta
```bash
ufw deny 5432/tcp
```

### Ativar firewall
```bash
ufw enable
```

### Desativar (não recomendado)
```bash
ufw disable
```

---

## 🔐 SSH & SEGURANÇA

### Gerar chave SSH
```bash
ssh-keygen -t ed25519 -C "seu_email@dominio.com"
```

### Copiar chave pública para VPS
```bash
ssh-copy-id -i ~/.ssh/id_ed25519.pub root@seu-ip-vps
```

### Conectar via SSH
```bash
ssh -i ~/.ssh/id_ed25519 root@seu-ip-vps
```

### Mudar porta SSH (em /etc/ssh/sshd_config)
```bash
nano /etc/ssh/sshd_config
# Port 22222

systemctl restart sshd
```

---

## 📈 MONITORAMENTO

### CPU
```bash
top -bn1 | head -20
```

### Memória
```bash
free -h
```

### Disco
```bash
df -h
du -sh /opt/nexus/*
du -sh /var/log/nexus/*
du -sh /data/*
```

### Rede
```bash
netstat -an | grep ESTABLISHED | wc -l
```

### Logs do sistema
```bash
journalctl -u docker -f
```

---

## 📦 DOCKER

### Ver imagens
```bash
docker images
```

### Ver volumes
```bash
docker volume ls
```

### Inspecionar container
```bash
docker inspect nexus-backend-1
```

### Copiar arquivo para container
```bash
docker cp arquivo.txt nexus-backend-1:/tmp/
```

### Copiar arquivo de container
```bash
docker cp nexus-backend-1:/tmp/arquivo.txt ./
```

### Executar comando em container
```bash
docker exec nexus-backend-1 python -c "print('Hello')"
```

### Limpar recursos não usados
```bash
docker system prune
docker system prune -a  # Remove tudo
```

---

## 🧪 TESTES & VALIDAÇÃO

### Testar API
```bash
curl -I https://api.seudominio.com/health
curl -I https://api.seudominio.com/docs
```

### Testar health check
```bash
curl https://api.seudominio.com/health | jq
```

### Testar redirecionamento HTTP → HTTPS
```bash
curl -I http://api.seudominio.com
```

### Testar DNS
```bash
nslookup api.seudominio.com
dig api.seudominio.com
dig +trace api.seudominio.com
```

### Teste de carga (10 requisições)
```bash
for i in {1..10}; do
  curl -s https://api.seudominio.com/health >/dev/null &
done
wait
echo "✅ Teste de carga concluído"
```

### Teste de SSL
```bash
openssl s_client -connect api.seudominio.com:443 -servername api.seudominio.com
```

---

## 💾 BACKUP & RESTORE

### Backup completo
```bash
bash /opt/nexus/backup_nexus.sh
```

### Listar backups
```bash
ls -lh /data/backups/
```

### Restore manual
```bash
docker-compose exec -T postgres psql -U postgres nexus < /data/backups/nexus-db-backup-20260805.sql
```

### Backup de configurações
```bash
tar czf nexus-config-$(date +%Y%m%d).tar.gz \
  /opt/nexus/.env \
  /opt/nexus/monitoring/ \
  /opt/nexus/nginx/
```

---

## 🔄 DEPLOY & ATUALIZAÇÕES

### Atualizar código
```bash
cd /opt/nexus
git pull origin main
docker-compose build
docker-compose up -d
```

### Verificar versão
```bash
cd /opt/nexus
git log -1 --oneline
```

### Ver histórico de commits
```bash
git log --oneline -10
```

### Reverter para versão anterior
```bash
git revert HEAD
docker-compose build
docker-compose up -d
```

---

## 📧 EMAIL & NOTIFICAÇÕES

### Testar SMTP
```bash
docker run --rm -it python:3.9 bash -c '
python3 << EOF
import smtplib
from email.mime.text import MIMEText

try:
    server = smtplib.SMTP_SSL("smtp.hostinger.com", 465)
    server.login("seu_email@dominio.com", "sua_senha")
    msg = MIMEText("Teste Nexus")
    msg["Subject"] = "Teste"
    msg["From"] = "seu_email@dominio.com"
    msg["To"] = "seu_email@dominio.com"
    server.send_message(msg)
    server.quit()
    print("✅ Email OK")
except Exception as e:
    print(f"❌ {e}")
EOF
'
```

### Testar Slack
```bash
WEBHOOK=$(grep SLACK_WEBHOOK /opt/nexus/.env | cut -d= -f2)
curl -X POST "$WEBHOOK" \
  -H 'Content-Type: application/json' \
  -d '{"text":"✅ Teste Nexus OK"}'
```

### Testar Telegram
```bash
TOKEN=$(grep TELEGRAM_BOT_TOKEN /opt/nexus/.env | cut -d= -f2)
CHAT_ID=$(grep TELEGRAM_CHAT_ID /opt/nexus/.env | cut -d= -f2)

curl -X POST "https://api.telegram.org/bot${TOKEN}/sendMessage" \
  -d "chat_id=${CHAT_ID}" \
  -d "text=✅ Teste Nexus OK"
```

---

## 🐛 DEBUG & TROUBLESHOOTING

### Verificar saúde completa
```bash
docker-compose ps
curl https://api.seudominio.com/health
docker-compose exec -T postgres pg_isready -U postgres
docker-compose exec -T redis redis-cli ping
```

### Reconstruir tudo do zero
```bash
docker-compose down -v
docker-compose build --no-cache
docker-compose up -d
```

### Ver eventos Docker
```bash
docker events --filter "container=nexus-backend-1"
```

### Profiling CPU
```bash
docker stats
```

### Ver permissões de arquivo
```bash
ls -la /var/log/nexus/
ls -la /opt/nexus/
```

---

## 📚 REFERÊNCIAS RÁPIDAS

| Serviço | URL | Credenciais |
|---------|-----|-----------|
| Grafana | http://localhost:3000 | admin / (veja .env) |
| Prometheus | http://localhost:9090 | nenhuma |
| AlertManager | http://localhost:9093 | nenhuma |
| API | https://api.seudominio.com | - |
| Admin | https://admin.seudominio.com | - |

| Banco | Host | Porta | Usuário |
|------|------|-------|--------|
| PostgreSQL | postgres:5432 | 5432 | postgres |
| Redis | redis:6379 | 6379 | (senha) |

---

**Última atualização:** 2026-08-05

