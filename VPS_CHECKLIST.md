# ✅ Checklist Completo - Deploy VPS Nexus

## 🚀 Pré-Deployment

### Informações da VPS

- [ ] IP da VPS: ________________
- [ ] Domínio: ________________
- [ ] Usuário SSH: ________________
- [ ] Senha SSH: (salvo com segurança)
- [ ] SO: Ubuntu 20.04/22.04 LTS
- [ ] RAM: ≥ 2GB
- [ ] Disco: ≥ 50GB SSD
- [ ] Conexão: ≥ 100 Mbps

### Credenciais Preparadas

- [ ] Email SMTP (Gmail, SendGrid, etc)
  - Host: ________________
  - Usuario: ________________
  - Senha: ________________

- [ ] Slack Webhook (se usando Slack)
  - URL: ________________

- [ ] Telegram (se usando Telegram)
  - Chat ID: ________________
  - Bot Token: ________________

### Domínio Configurado

- [ ] DNS aponta para IP da VPS
- [ ] Teste: `nslookup seu-dominio.com`
- [ ] Firewall permite porta 22 (SSH)
- [ ] Firewall permite porta 80 (HTTP)
- [ ] Firewall permite porta 443 (HTTPS)

---

## 🔧 Deploy Automático

### Passo 1: SSH para VPS

```bash
ssh root@seu-ip-vps
```

- [ ] Conectado à VPS com sucesso

### Passo 2: Baixar e Executar Script

```bash
curl -o deploy_vps.sh https://raw.githubusercontent.com/doedesenvolvedor-lgtm/Nexus/main/deploy_vps.sh
sudo bash deploy_vps.sh
```

- [ ] Script baixado
- [ ] Script executado completamente
- [ ] Sem erros críticos

### Passo 3: Validar Instalação

```bash
cd /opt/nexus
docker-compose ps
```

- [ ] Prometheus rodando
- [ ] Grafana rodando
- [ ] Alertmanager rodando
- [ ] postgres_exporter rodando
- [ ] redis_exporter rodando
- [ ] node_exporter rodando
- [ ] cadvisor rodando

### Passo 4: Testar Conectividade

```bash
curl http://localhost:9090/-/healthy
curl http://localhost:3000/api/health
curl http://localhost:9093/-/healthy
```

- [ ] Prometheus respondendo
- [ ] Grafana respondendo
- [ ] Alertmanager respondendo

---

## 📊 Configuração Pós-Deploy

### 1. Acessar Grafana

- [ ] Abrir: `http://seu-ip-vps:3000`
- [ ] Login: admin / admin
- [ ] Dashboard "Nexus Streaming - Sistema" visível
- [ ] Dados sendo coletados em tempo real

### 2. Configurar Alertas

```bash
nano /opt/nexus/monitoring/alertmanager.yml
```

Adicionar:
- [ ] Credenciais SMTP (email)
- [ ] Webhook Slack (se usando)
- [ ] Token Telegram (se usando)

```bash
docker-compose restart alertmanager
```

- [ ] Alertmanager reiniciado
- [ ] Alertas sendo processados

### 3. Alterar Senha Grafana

No Grafana Web:
- [ ] Menu → Admin → Users
- [ ] Selecionar usuário "admin"
- [ ] Alterar senha
- [ ] Logout e logar novamente com nova senha

### 4. Proteger Dashboards (IMPORTANTE)

Instalar Nginx com autenticação:

```bash
apt-get install -y nginx apache2-utils
htpasswd -c /etc/nginx/.htpasswd admin
# Digite nova senha
```

- [ ] Nginx instalado
- [ ] .htpasswd criado

Criar arquivo `/etc/nginx/sites-available/default` com configuração:

- [ ] Nginx configurado para proxy reverso
- [ ] Autenticação para Prometheus
- [ ] Autenticação para Alertmanager

Reiniciar:

```bash
systemctl restart nginx
```

- [ ] Nginx reiniciado

---

## 🔐 Segurança

### HTTPS com Let's Encrypt

```bash
apt-get install -y certbot python3-certbot-nginx
certbot certonly --nginx -d seu-dominio.com
```

- [ ] Certificado obtido
- [ ] Nginx com SSL configurado

### Firewall

```bash
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw enable
```

- [ ] Firewall habilitado
- [ ] Portas liberadas apenas necessárias

### Proteger SSH

Editar `/etc/ssh/sshd_config`:

```bash
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
```

- [ ] SSH endurecido
- [ ] Apenas chaves SSH permitidas

---

## 💾 Backup e Automação

### 1. Configurar Backup

```bash
chmod +x /opt/nexus/backup_nexus.sh
```

- [ ] Script de backup executável

### 2. Configurar Health Check

```bash
chmod +x /opt/nexus/health_check.sh
./opt/nexus/health_check.sh
```

- [ ] Health check testado
- [ ] Todos serviços OK

### 3. Configurar Cron Jobs

```bash
sudo crontab -e
```

Adicionar:
```cron
*/5 * * * * /opt/nexus/health_check.sh
0 2 * * * /opt/nexus/backup_nexus.sh
0 3 * * 1 find /var/log/nexus -name "*.log.*" -mtime +30 -delete
```

- [ ] Health check cada 5 minutos
- [ ] Backup diário às 2 AM
- [ ] Limpeza de logs antigos

### 4. Verificar Backups

```bash
ls -lh /backups/nexus/
```

- [ ] Diretório de backup criado
- [ ] Primeiro backup concluído

---

## 📝 Logs e Monitoramento

### Verificar Logs

```bash
tail -f /var/log/nexus/app.log | jq .
```

- [ ] Logs sendo gerados
- [ ] Formato JSON estruturado
- [ ] Arquivo "app.log" existe

### Ver Métricas

```bash
curl http://localhost:8000/metrics | head -20
```

- [ ] Endpoint /metrics respondendo
- [ ] Métricas sendo coletadas

### Verificar Alertas

```bash
curl http://localhost:9093/api/v1/alerts | jq .
```

- [ ] API Alertmanager respondendo
- [ ] Estrutura JSON válida

---

## 🧪 Testar Funcionalidades

### 1. Testar Alert Email

Editar `monitoring/alertmanager.yml` temporariamente com threshold muito baixo:

```yaml
- alert: HighCPUUsage
  expr: 'cpu_usage > 0'  # Sempre true para testar
  for: 1m
```

- [ ] Alerta disparado
- [ ] Email recebido em 5 minutos

### 2. Testar Slack

Se configurado:

```bash
curl -X POST "YOUR_SLACK_WEBHOOK_URL" \
  -H 'Content-Type: application/json' \
  -d '{"text": "Test Alert from Nexus"}'
```

- [ ] Mensagem recebida no Slack

### 3. Testar Telegram

Se configurado:

- [ ] Mensagem recebida no chat Telegram

---

## 📊 Performance

### Verificar Recursos

```bash
docker stats
free -h
df -h
```

- [ ] CPU: < 50%
- [ ] Memória: < 60%
- [ ] Disco: < 70%

### Verificar Network

```bash
curl -I http://seu-dominio/grafana
```

- [ ] Resposta HTTP 200/301
- [ ] Tempo resposta < 500ms

---

## 📋 Documentação

- [ ] `MONITORING_SETUP.md` lido
- [ ] `VPS_DEPLOYMENT.md` lido
- [ ] `CRON_AUTOMATION.md` lido
- [ ] `COMMANDS_MONITORING.md` salvo como referência

### Documentação Local

```bash
# Ver em qualquer momento
cd /opt/nexus
cat MONITORING_SETUP.md
cat COMMANDS_MONITORING.md
```

---

## 👥 Equipe e Suporte

### Treinar Equipe

- [ ] DevOps conhece como acessar Grafana
- [ ] DevOps conhece como ver alertas
- [ ] DevOps conhece como ver logs
- [ ] Desenvolvedores conhecem como fazer queries PromQL

### Documentação Interna

- [ ] Criar wiki interna com:
  - [ ] Credenciais de acesso (seguro)
  - [ ] Runbooks de problemas comuns
  - [ ] Contatos de suporte

---

## 🚨 Checklist de Produção (Crítico)

- [ ] **HTTPS ativo** com certificado válido
- [ ] **Senha Grafana alterada** de admin/admin
- [ ] **Autenticação no Prometheus** configurada
- [ ] **Autenticação no Alertmanager** configurada
- [ ] **Firewall habilitado** permitindo apenas portas necessárias
- [ ] **SSH endurecido** (sem root, apenas chaves)
- [ ] **Backup automático** configurado e testado
- [ ] **Health check** rodando a cada 5 minutos
- [ ] **Alertas** configurados (email, Slack, Telegram)
- [ ] **Logs** sendo coletados em `/var/log/nexus/`

---

## 📞 Suporte e Troubleshooting

### Problema Comum: Serviço parou

```bash
docker-compose ps
docker-compose restart SERVICE_NAME
docker-compose logs SERVICE_NAME
```

### Problema: Alertas não enviando

```bash
docker-compose logs alertmanager
nano monitoring/alertmanager.yml  # Verificar configuração
docker-compose restart alertmanager
```

### Problema: Sem espaço em disco

```bash
df -h
du -sh /data/*
du -sh /var/log/nexus/*
# Limpar backups antigos
find /backups/nexus -mtime +30 -delete
```

### Contato

- 📧 Email: dev@nexus.com
- 🐙 GitHub Issues: [Nexus Issues](https://github.com/doedesenvolvedor-lgtm/Nexus/issues)
- 💬 Discord: [Link to Discord]

---

## ✨ Conclusão

- [ ] Todos os itens acima foram checados
- [ ] Sistema em produção e monitorado
- [ ] Equipe treinada
- [ ] Documentação disponível

**Data de Deploy**: ________________
**Responsável**: ________________
**IP VPS**: ________________
**Domínio**: ________________

---

## 🎉 Status Final

```
[ ] DEV ✓
[ ] STAGING ✓
[✓] PRODUÇÃO - Sistema Pronto!
```

**Próximas ações**: Monitorar por 24h e ajustar thresholds conforme necessário.

