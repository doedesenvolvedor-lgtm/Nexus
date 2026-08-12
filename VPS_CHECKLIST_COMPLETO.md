# 📋 Checklist Pós-Deploy - Nexus VPS

> **Data:** 2026-08-05  
> **Versão:** 2.0

Após executar o script de setup, valide cada item abaixo.

---

## ✅ VERIFICAÇÃO INICIAL (5 min)

### Docker & Containers

- [ ] **Todos os containers estão rodando**
  ```bash
  docker-compose ps
  # Esperado: postgres, redis, backend, worker, nginx, prometheus, grafana = "running" ou "healthy"
  ```

- [ ] **PostgreSQL está saudável**
  ```bash
  docker-compose exec -T postgres pg_isready -U postgres
  # Esperado: "accepting connections"
  ```

- [ ] **Redis está respondendo**
  ```bash
  docker-compose exec -T redis redis-cli ping
  # Esperado: "PONG"
  ```

- [ ] **API responde em localhost**
  ```bash
  curl -I http://localhost:8000/health
  # Esperado: HTTP/1.1 200 OK
  ```

- [ ] **Nginx está rodando**
  ```bash
  curl -I http://localhost/health
  # Esperado: HTTP/1.1 200 OK
  ```

### Firewall

- [ ] **UFW está ativo**
  ```bash
  ufw status
  # Esperado: "Status: active"
  ```

- [ ] **Regras corretas**
  ```bash
  ufw status verbose
  # Esperado:
  # 22/tcp  ALLOW
  # 80/tcp  ALLOW
  # 443/tcp ALLOW
  ```

### Arquivo .env

- [ ] **.env existe**
  ```bash
  ls -la /opt/nexus/.env
  # Esperado: -rw-r--r-- ... .env
  ```

- [ ] **.env contém valores**
  ```bash
  grep -c "=" /opt/nexus/.env
  # Esperado: > 30 linhas
  ```

---

## 🔒 VALIDAÇÃO SEGURANÇA (10 min)

### Credenciais

- [ ] **Senhas foram geradas com openssl**
  ```bash
  grep "PASSWORD\|SECRET" /opt/nexus/.env | grep -v "change_me"
  # Esperado: valores longos (32+ chars)
  ```

- [ ] **MercadoPago token é de PRODUÇÃO**
  ```bash
  grep MERCADOPAGO_ACCESS_TOKEN /opt/nexus/.env
  # Esperado: APP_... (não TEST-...)
  ```

- [ ] **.env não está no git**
  ```bash
  cd /opt/nexus && git status | grep .env
  # Esperado: (vazio - não listado)
  ```

### SSH & Acesso

- [ ] **SSH usando chave (não senha)**
  ```bash
  grep PasswordAuthentication /etc/ssh/sshd_config
  # Ideal: "PasswordAuthentication no"
  ```

- [ ] **Root login desabilitado**
  ```bash
  grep PermitRootLogin /etc/ssh/sshd_config
  # Ideal: "PermitRootLogin no" (ou via key apenas)
  ```

### Certificados

- [ ] **HTTPS funcionando**
  ```bash
  curl -I https://api.seudominio.com
  # Esperado: HTTP/2 (ou HTTP/1.1) + certificado válido
  ```

- [ ] **Certificado é válido**
  ```bash
  openssl s_client -connect api.seudominio.com:443 -servername api.seudominio.com < /dev/null 2>/dev/null | openssl x509 -text -noout | grep -E "Subject:|Not After"
  # Esperado: certificado LetsEncrypt válido, expiração > 30 dias
  ```

- [ ] **Renovação automática configurada**
  ```bash
  crontab -l | grep certbot
  # Esperado: cronjob presente
  ```

---

## 📊 VALIDAÇÃO MONITORAMENTO (10 min)

### Prometheus

- [ ] **Prometheus coletando métricas**
  ```bash
  curl -s http://localhost:9090/api/v1/query?query=up | jq '.data.result | length'
  # Esperado: > 5 (múltiplas métricas)
  ```

- [ ] **Alertas carregados**
  ```bash
  curl -s http://localhost:9090/api/v1/rules | jq '.data.groups | length'
  # Esperado: > 0
  ```

### Grafana

- [ ] **Grafana acessível**
  ```bash
  curl -I http://localhost:3000
  # Esperado: HTTP/1.1 302 (redireciona para login)
  ```

- [ ] **Credenciais admin alteradas**
  ```bash
  grep GF_ADMIN_PASSWORD /opt/nexus/.env
  # Esperado: não é "admin"
  ```

- [ ] **Datasource Prometheus conectado**
  - Acesse: http://localhost:3000
  - Login com credenciais em .env
  - Configuration → Data Sources
  - Esperado: Prometheus "green" (conectado)

### AlertManager

- [ ] **AlertManager rodando**
  ```bash
  curl -I http://localhost:9093
  # Esperado: HTTP/1.1 200
  ```

- [ ] **Configuração SMTP**
  ```bash
  grep "smtp_smarthost" /opt/nexus/monitoring/alertmanager.yml
  # Esperado: smtp.hostinger.com:465
  ```

---

## 📧 VALIDAÇÃO NOTIFICAÇÕES (15 min)

### Email SMTP

- [ ] **SMTP configurado em .env**
  ```bash
  grep "SMTP_" /opt/nexus/.env
  # Esperado: todos os valores preenchidos
  ```

- [ ] **Teste de email**
  ```bash
  docker run --rm -it python:3.9 bash -c '
  pip install -q secure-smtplib &&
  python3 << EOF
  import smtplib
  from email.mime.text import MIMEText
  
  try:
      server = smtplib.SMTP_SSL("smtp.hostinger.com", 465)
      server.login("seu_email@dominio.com", "sua_senha")
      msg = MIMEText("Teste")
      msg["Subject"] = "Teste Nexus"
      msg["From"] = "seu_email@dominio.com"
      msg["To"] = "seu_email@dominio.com"
      server.send_message(msg)
      server.quit()
      print("✅ Email enviado com sucesso")
  except Exception as e:
      print(f"❌ Erro: {e}")
  EOF
  '
  ```
  Esperado: "✅ Email enviado"

### Slack (se configurado)

- [ ] **Webhook está no .env**
  ```bash
  grep SLACK_WEBHOOK /opt/nexus/.env
  # Esperado: URL válida
  ```

- [ ] **Teste de webhook**
  ```bash
  WEBHOOK=$(grep SLACK_WEBHOOK /opt/nexus/.env | cut -d= -f2)
  curl -X POST "$WEBHOOK" \
    -H 'Content-Type: application/json' \
    -d '{"text":"✅ Teste Nexus - Setup OK"}'
  # Esperado: mensagem aparece no Slack
  ```

### Telegram (se configurado)

- [ ] **Bot token está no .env**
  ```bash
  grep TELEGRAM_BOT_TOKEN /opt/nexus/.env
  # Esperado: token presente
  ```

- [ ] **Chat ID está no .env**
  ```bash
  grep TELEGRAM_CHAT_ID /opt/nexus/.env
  # Esperado: ID numérico
  ```

---

## 💳 VALIDAÇÃO MERCADOPAGO (10 min)

- [ ] **Credenciais configuradas**
  ```bash
  grep "MERCADOPAGO_" /opt/nexus/.env
  # Esperado: ACCESS_TOKEN, CLIENT_ID, PUBLIC_KEY preenchidos
  ```

- [ ] **Webhook configurado**
  ```bash
  grep "WEBHOOK_URL" /opt/nexus/.env
  # Esperado: URL HTTPS válida (https://api.seudominio.com)
  ```

- [ ] **Teste de webhook**
  - Acesse: https://www.mercadopago.com.br/developers/panel/app
  - Selecione sua app
  - Webhooks → Testar
  - Esperado: resposta 200

---

## 🔥 VALIDAÇÃO FIREBASE (10 min)

- [ ] **Credenciais baixadas**
  ```bash
  ls -la /opt/nexus/backend/firebase-credentials.json
  # Esperado: arquivo JSON presente
  ```

- [ ] **Variáveis configuradas**
  ```bash
  grep "FIREBASE_" /opt/nexus/.env
  # Esperado: PROJECT_ID, STORAGE_BUCKET, CREDENTIALS_PATH
  ```

- [ ] **Teste de inicialização**
  ```bash
  docker-compose exec backend python -c \
    "from app.services.firebase_service import FirebaseService; fb = FirebaseService(); print('✅ Firebase OK' if fb.is_initialized() else '❌ Firebase Failed')"
  ```

---

## 🌍 VALIDAÇÃO DOMÍNIOS (10 min)

- [ ] **DNS resolvendo**
  ```bash
  nslookup www.seudominio.com
  nslookup api.seudominio.com
  # Esperado: IP da VPS
  ```

- [ ] **Domínio principal acessível**
  ```bash
  curl -I https://www.seudominio.com
  # Esperado: HTTP/2 200
  ```

- [ ] **Subdomínios acessíveis**
  ```bash
  for sub in api admin privacypolicy termosdeuso; do
    echo "$sub:"
    curl -I https://$sub.seudominio.com
  done
  # Esperado: todos retornam 200/302/404 (não connection refused)
  ```

- [ ] **Redirecionamento HTTP → HTTPS**
  ```bash
  curl -I http://api.seudominio.com
  # Esperado: HTTP/1.1 301 + Location: https://
  ```

---

## 💾 VALIDAÇÃO BACKUP (5 min)

- [ ] **Script de backup existe**
  ```bash
  ls -la /opt/nexus/backup_nexus.sh
  # Esperado: arquivo executável
  ```

- [ ] **Teste de backup**
  ```bash
  bash /opt/nexus/backup_nexus.sh
  # Esperado: "Backup completed successfully"
  ```

- [ ] **Arquivos de backup criados**
  ```bash
  ls -la /data/backups/
  # Esperado: arquivos .sql e .rdb
  ```

- [ ] **Cron configurado**
  ```bash
  crontab -l | grep backup
  # Esperado: cronjob presente (ex: 0 2 * * *)
  ```

---

## ⚡ VALIDAÇÃO PERFORMANCE (10 min)

### API

- [ ] **Responde rápido**
  ```bash
  time curl https://api.seudominio.com/health
  # Esperado: < 1 segundo
  ```

- [ ] **Suporta multiplas requisições**
  ```bash
  for i in {1..10}; do
    curl -s https://api.seudominio.com/health >/dev/null &
  done
  wait
  # Esperado: todas retornam 200
  ```

### Banco de Dados

- [ ] **Conexões saudáveis**
  ```bash
  docker-compose exec -T postgres psql -U postgres -c "SELECT count(*) FROM pg_stat_activity;"
  # Esperado: < 20 conexões
  ```

- [ ] **Tamanho do banco**
  ```bash
  docker-compose exec -T postgres psql -U postgres -c "SELECT pg_size_pretty(pg_database_size('nexus'));"
  # Esperado: tamanho razoável (< 10GB no início)
  ```

### Redis

- [ ] **Latência baixa**
  ```bash
  docker-compose exec redis redis-cli --latency 10
  # Esperado: < 5ms
  ```

- [ ] **Memória adequada**
  ```bash
  docker-compose exec redis redis-cli INFO memory | grep used_memory_human
  # Esperado: < 50% da memória total
  ```

### Sistema

- [ ] **Disco não está cheio**
  ```bash
  df -h / | awk 'NR==2 {print $5}'
  # Esperado: < 80%
  ```

- [ ] **Memória livre**
  ```bash
  free -h | awk 'NR==2 {print $4}'
  # Esperado: > 500MB
  ```

---

## 📱 VALIDAÇÃO MOBILE (15 min)

### Android

- [ ] **App conecta à API**
  - Abra o APK no Android
  - Verifique URL em Settings
  - Tente fazer login
  - Esperado: sucesso (ou erro de credenciais válido, não timeout)

- [ ] **Push notifications funcionam**
  - Envie teste no console
  - Esperado: notificação recebida no device

### iOS

- [ ] **App conecta à API**
  - Compile e rode no Simulator/Device
  - Verifique URL em Settings
  - Tente fazer login
  - Esperado: sucesso

- [ ] **Push notifications funcionam**
  - Envie teste no console
  - Esperado: notificação recebida

---

## 📚 DOCUMENTAÇÃO (5 min)

- [ ] **Credenciais anotadas**
  - [ ] Senha DB
  - [ ] Senha Redis
  - [ ] JWT Secret
  - [ ] Senha Grafana
  - [ ] Token MercadoPago
  - [ ] Armazenar em local seguro (não email!)

- [ ] **Plano de recuperação documentado**
  - [ ] Processo de restore de backup
  - [ ] Contatos de suporte
  - [ ] Escalation path

- [ ] **Runbook criado**
  - [ ] Comandos essenciais salvos
  - [ ] Processo de troubleshooting
  - [ ] Passos para redeploy

---

## 🎯 RESUMO FINAL

### Se TODOS os itens estão ✅:

```bash
echo "✅ DEPLOY PRONTO PARA PRODUÇÃO"
echo "🎉 Nexus está rodando com sucesso!"
```

### Comandos de Referência Rápida

```bash
# Status
docker-compose ps

# Logs
docker-compose logs -f backend

# Restart
docker-compose restart

# Health check
curl https://api.seudominio.com/health

# Backup
bash /opt/nexus/backup_nexus.sh

# Monitoramento
# Grafana: https://seu-dominio:3000
# Prometheus: https://seu-dominio:9090
# AlertManager: https://seu-dominio:9093
```

---

## 🆘 Se algo não passou:

1. **Verifique logs:**
   ```bash
   docker-compose logs [container]
   tail -50 /var/log/nexus/*
   ```

2. **Abra issue no GitHub:**
   https://github.com/doedesenvolvedor-lgtm/Nexus/issues

3. **Procure em COMMANDS_MONITORING.md:**
   Mais de 50 comandos úteis para troubleshooting

---

**Data Checklist:** ________________  
**Responsável:** ________________  
**Status Final:** ✅ PRODUÇÃO / 🚧 FALHAS ENCONTRADAS

