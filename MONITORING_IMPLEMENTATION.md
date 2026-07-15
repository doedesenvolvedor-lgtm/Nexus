# Implementação Completa - Monitoramento Nexus

## 📋 Checklist de Implementação

- [x] Prometheus configurado
- [x] Grafana pronto
- [x] Alertmanager setup
- [x] Logging estruturado no FastAPI
- [x] Métricas do Prometheus integradas
- [x] Docker Compose atualizado
- [ ] Testar em desenvolvimento
- [ ] Testar em produção
- [ ] Documentar SLAs

---

## 🚀 Guia de Implementação

### Passo 1: Preparar o Ambiente

#### 1.1 Clonar/Atualizar Repositório

```bash
cd /workspaces/Nexus
git pull origin main
```

#### 1.2 Criar Diretórios de Logs

```bash
# Linux/Mac
mkdir -p /var/log/nexus
chmod 777 /var/log/nexus

# Windows (PowerShell)
New-Item -ItemType Directory -Path "C:\var\log\nexus" -Force
```

#### 1.3 Criar Volumes Docker

```bash
docker volume create prometheus_data
docker volume create grafana_data
docker volume create alertmanager_data
```

---

### Passo 2: Instalar Dependências Python

```bash
cd backend

# Atualizar requirements.txt
pip install prometheus-client python-json-logger

# Ou usar pip install -r requirements.txt
pip install -r requirements.txt
```

---

### Passo 3: Verificar Arquivos de Configuração

```bash
# Arquivos criados/atualizados:
backend/app/logging_config.py          # ✓
backend/app/metrics.py                 # ✓
backend/app/main.py                    # ✓ (atualizado)
backend/requirements.txt                # ✓ (atualizado)
monitoring/prometheus.yml               # ✓ (atualizado)
monitoring/alert_rules.yml              # ✓
monitoring/alertmanager.yml             # ✓
monitoring/alertmanager_templates.tmpl  # ✓
monitoring/grafana/provisioning/        # ✓
docker-compose.yml                      # ✓ (atualizado)
setup_monitoring.sh                     # ✓
MONITORING_SETUP.md                     # ✓
```

---

### Passo 4: Configurar Alertmanager

#### Email (Gmail)

```bash
# 1. Criar senha de app no Gmail
#    https://myaccount.google.com/apppasswords

# 2. Editar monitoring/alertmanager.yml
nano monitoring/alertmanager.yml

# Alterar:
smtp_smarthost: 'smtp.gmail.com:587'
smtp_auth_username: 'seu-email@gmail.com'
smtp_auth_password: 'sua-senha-app'
```

#### Slack

```bash
# 1. Criar webhook
#    https://api.slack.com/apps
#    → Incoming Webhooks
#    → Add New Webhook to Workspace

# 2. Editar monitoring/alertmanager.yml
slack_api_url: 'https://hooks.slack.com/services/YOUR/WEBHOOK/URL'
```

#### Telegram

```bash
# 1. Falar com @BotFather
#    → /newbot
#    → Pegar token

# 2. Encontrar chat ID
#    Falar com @userinfobot em um grupo

# 3. Editar monitoring/alertmanager.yml
chat_id: 'YOUR_CHAT_ID'
bot_token: 'YOUR_BOT_TOKEN'
```

---

### Passo 5: Iniciar Stack de Monitoramento

#### Opção A: Script Automático

```bash
bash setup_monitoring.sh all

# Ou escolher apenas um tipo de notificação:
bash setup_monitoring.sh email
bash setup_monitoring.sh slack
bash setup_monitoring.sh telegram
```

#### Opção B: Manual

```bash
# Iniciar tudo
docker-compose up -d

# Ou iniciar apenas monitoramento
docker-compose up -d prometheus grafana alertmanager
```

---

### Passo 6: Acessar Interfaces

#### Grafana (Dashboards)

```
URL: http://localhost:3000
Usuário: admin
Senha: admin
```

1. Fazer login
2. Menu lateral → Dashboards
3. Você verá o dashboard "Nexus Streaming - Sistema"

#### Prometheus (Queries)

```
URL: http://localhost:9090
```

1. Ir para Graph
2. Digitar query PromQL
3. Ver gráficos em tempo real

#### Alertmanager (Alertas)

```
URL: http://localhost:9093
```

1. Ver alertas ativos
2. Silenciar alertas
3. Ver histórico

---

### Passo 7: Testar Logging

```bash
# Verificar se logs estão sendo gerados
ls -lh /var/log/nexus/

# Ver logs em tempo real
tail -f /var/log/nexus/app.log

# Ver logs em formato JSON
tail -f /var/log/nexus/app.log | jq .
```

---

### Passo 8: Testar Métricas

```bash
# Acessar endpoint de métricas
curl http://localhost:8000/metrics | head -20

# Contar métricas
curl http://localhost:8000/metrics | wc -l

# Query no Prometheus
curl 'http://localhost:9090/api/v1/query?query=http_requests_total' | jq .
```

---

### Passo 9: Testar Alertas

```bash
# Simular alerta crítico
# Editar um valor no prometheus.yml temporariamente

# Ou forçar via shell:
docker-compose exec prometheus /bin/sh -c 'echo "ALERTS 1" | nc prometheus 9090'

# Verificar alertas ativos
curl http://localhost:9093/api/v1/alerts | jq .
```

---

### Passo 10: Documentar e Escalar

#### Criar Runbooks

Arquivo: `RUNBOOKS.md`

```markdown
## Runbook - CPU Alta

**Alerta**: `HighCPUUsage`
**Severidade**: CRÍTICA

### Verificação
1. SSH no servidor
2. `top -b -n 1 | head -20`
3. Identificar processo consumindo CPU

### Ações
1. Verificar se é consumo esperado
2. Se anómalo:
   - Reiniciar container: `docker-compose restart backend`
   - Escalar para desenvolvedor
3. Monitorar por 10 min

### Escalação
- **Nível 1 (DevOps)**: Investigar e tentar resolver
- **Nível 2 (Backend)**: Se problema persistir, revisar código
- **Nível 3 (CTO)**: Se > 30min de downtime
```

#### Criar SLA

```
Disponibilidade esperada: 99.9%
Tempo de resposta P95: < 500ms
Taxa de erro aceitável: < 0.1%
```

---

## 🔍 Queries PromQL Úteis

### Aplicação

```promql
# Requisições por segundo
rate(http_requests_total[1m])

# Taxa de erro
rate(http_requests_total{status_code=~"5.."}[5m])

# P95 do tempo de resposta
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))

# Usuários online
active_users

# Pagamentos por dia
rate(payment_amount_total[24h])
```

### Sistema

```promql
# CPU
100 - (avg(rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# Memória
(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100

# Disco
(node_filesystem_avail_bytes / node_filesystem_size_bytes) * 100
```

### Banco de Dados

```promql
# Conexões ativas
pg_stat_activity_count

# Queries lentas
pg_stat_statements_mean_exec_time > 1000

# Tamanho do banco
pg_database_size_bytes
```

---

## 🛠️ Troubleshooting

### Problema: Prometheus não coleta métricas

**Solução:**
```bash
# Verificar se backend está saudável
curl http://localhost:8000/health

# Verificar métricas
curl http://localhost:8000/metrics

# Checar configuração Prometheus
docker-compose logs prometheus | grep error

# Recarregar configuração
docker-compose restart prometheus
```

### Problema: Grafana sem dados

**Solução:**
```bash
# Verificar conexão datasource
http://grafana:3000/api/datasources

# Testar query Prometheus
curl 'http://prometheus:9090/api/v1/query?query=up'

# Ver logs Grafana
docker-compose logs grafana
```

### Problema: Alertas não são enviados

**Solução:**
```bash
# Verificar configuração Alertmanager
curl http://localhost:9093/api/v1/status

# Ver alertas ativos
curl http://localhost:9093/api/v1/alerts

# Verificar logs
docker-compose logs alertmanager

# Testar conexão SMTP
docker-compose exec alertmanager telnet smtp.gmail.com 587
```

### Problema: Logs não aparecem

**Solução:**
```bash
# Verificar permissões
ls -la /var/log/nexus/

# Dar permissões
chmod 777 /var/log/nexus

# Verificar volume Docker
docker volume inspect prometheus_data

# Testar logging manualmente
python -c "from app.logging_config import setup_logging; setup_logging(); import logging; logging.info('Test')"
```

---

## 📊 Métricas por Severidade

### Críticas (Alertar Imediatamente)

- API indisponível
- PostgreSQL offline
- Redis offline
- Disco < 10%
- CPU > 90% por 5min

### Warnings (Alertar com Delay 2h)

- Memória > 85%
- Taxa de erro > 5%
- Resposta > 5s (P95)
- Falhas pagamento > 10%
- Inodes < 5%

### Info (Alertar com Delay 12h)

- Taxa requisições alta
- Média memória > 70%
- Disco > 70%

---

## 🔐 Checklist de Segurança

- [ ] Alterar senha Grafana
- [ ] Usar HTTPS para Grafana (nginx reverse proxy)
- [ ] Não committar credenciais no git
- [ ] Usar variáveis de ambiente
- [ ] Proteger endpoints Prometheus/Alertmanager
- [ ] Rotação de logs configurada
- [ ] Backups de dados Prometheus
- [ ] Alertas para falhas de autenticação
- [ ] Monitoramento de acesso aos logs

---

## 📚 Próximas Etapas

1. ✅ Implementar monitoramento básico
2. ⏭️ Adicionar autenticação nos dashboards
3. ⏭️ Criar alertas personalizados por aplicação
4. ⏭️ Integrar com sistema de tickets (Jira, etc)
5. ⏭️ Implementar SLOs e error budgets
6. ⏭️ Escalar para múltiplos ambientes

