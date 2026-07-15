# Monitoramento Nexus Streaming

## 📊 Visão Geral

O sistema de monitoramento da aplicação Nexus é composto por:

1. **Prometheus** - Coleta de métricas
2. **Grafana** - Visualização em dashboards
3. **Alertmanager** - Gerenciamento de alertas
4. **Exporters** - Coleta de métricas de componentes específicos
5. **Logging** - Registro estruturado de eventos

---

## 🏗️ Arquitetura

```
┌─────────────────────────────────────────────────┐
│         Aplicação Nexus (FastAPI)               │
│    ├─ Métricas Prometheus (:8000/metrics)      │
│    └─ Logging estruturado JSON                  │
└─────────────────────────────────────────────────┘
                      │
        ┌─────────────┼─────────────┐
        │             │             │
        ▼             ▼             ▼
   Prometheus   Alertmanager   Logs
   (9090)         (9093)     (/var/log/nexus)
        │             │             │
        │             └─────┬───────┘
        │                   │
        ▼                   ▼
    Grafana      Email/Slack/Telegram
    (3000)            (Notificações)
```

---

## 🚀 Como Iniciar

### 1. Preparar Ambiente

```bash
# Criar diretório de logs
mkdir -p /var/log/nexus
chmod 777 /var/log/nexus

# Criar volumes Docker
docker volume create prometheus_data
docker volume create grafana_data
docker volume create alertmanager_data
```

### 2. Iniciar Stack de Monitoramento

```bash
cd /workspaces/Nexus

# Iniciar todos os serviços
docker-compose up -d

# Verificar se tudo está rodando
docker-compose ps
```

### 3. Acessar Interfaces

- **Grafana**: http://localhost:3000
  - Usuário: `admin`
  - Senha: `admin` (altere em produção)

- **Prometheus**: http://localhost:9090
  - Interface de queries PromQL

- **Alertmanager**: http://localhost:9093
  - Gerenciamento de alertas

---

## 📈 Métricas Coletadas

### FastAPI (Backend)

- `http_requests_total` - Total de requisições por método, endpoint e status
- `http_request_duration_seconds` - Duração das requisições (histograma)
- `authenticated_requests_total` - Requisições autenticadas
- `api_errors_total` - Total de erros

### Sistema Operacional

- `node_cpu_seconds_total` - Uso de CPU
- `node_memory_MemAvailable_bytes` - Memória disponível
- `node_filesystem_avail_bytes` - Espaço em disco
- `node_network_receive_bytes_total` - Tráfego de rede

### PostgreSQL

- `pg_stat_activity_count` - Conexões ativas
- `pg_database_size_bytes` - Tamanho do banco
- `pg_stat_database_tup_returned` - Tuplas retornadas

### Redis

- `redis_memory_used_bytes` - Memória usada
- `redis_evicted_keys_total` - Chaves removidas
- `redis_commands_processed_total` - Comandos processados

### Docker

- `container_cpu_usage_seconds_total` - CPU de containers
- `container_memory_usage_bytes` - Memória de containers

### Negócio

- `payment_attempts_total` - Tentativas de pagamento
- `payment_amount_total` - Valor total de pagamentos
- `login_attempts_total` - Tentativas de login
- `media_imports_total` - Importações de mídia
- `tmdb_sync_operations_total` - Sincronizações com TMDb

---

## 🔔 Alertas Configurados

### Críticos (Notificação Imediata)

| Alerta | Condição | Ação |
|--------|----------|------|
| `HighCPUUsage` | CPU > 90% por 5min | Email + Slack + Telegram |
| `PostgreSQLNotResponding` | PostgreSQL offline | Email + Slack + Telegram |
| `RedisNotResponding` | Redis offline | Email + Slack + Telegram |
| `APIIsDown` | FastAPI offline | Email + Slack + Telegram |
| `LowDiskSpace` | Disco < 10% | Email + Slack |

### Warnings (Notificação com Delay)

| Alerta | Condição | Ação |
|--------|----------|------|
| `HighMemoryUsage` | Memória > 85% | Email |
| `HighErrorRate` | 5xx > 5% por 5min | Email |
| `SlowAPIResponse` | P95 > 5s | Email |
| `HighPaymentFailureRate` | Falhas > 10% | Email |

---

## 📝 Logging

### Configuração

O logging é armazenado em `/var/log/nexus/` com os seguintes arquivos:

| Arquivo | Conteúdo |
|---------|----------|
| `app.log` | Logs gerais da aplicação |
| `auth.log` | Eventos de autenticação |
| `api.log` | Requisições HTTP |
| `payments.log` | Transações de pagamento |
| `database.log` | Queries e erros de BD |
| `errors.log` | Todos os erros (de todas as categorias) |

### Rotação de Logs

- Cada arquivo: máximo 50MB
- Manter: últimos 10-20 backups comprimidos
- Limpeza automática após atingir limite

### Exemplo de Log

```json
{
  "timestamp": "2024-01-15T10:30:45.123Z",
  "level": "INFO",
  "name": "app.routers.auth",
  "message": "User login attempt",
  "user_id": "user123",
  "ip": "192.168.1.100",
  "status": "success"
}
```

---

## 🔧 Configuração do Alertmanager

### Email

Edite `monitoring/alertmanager.yml`:

```yaml
global:
  smtp_smarthost: 'smtp.gmail.com:587'
  smtp_auth_username: 'seu-email@gmail.com'
  smtp_auth_password: 'sua-senha-app'
  smtp_from: 'alerts@nexus.com'
```

### Slack

Crie webhook em https://api.slack.com/apps

```yaml
global:
  slack_api_url: 'https://hooks.slack.com/services/YOUR/WEBHOOK/URL'
```

### Telegram

Crie bot no BotFather (@botfather) no Telegram

```yaml
telegram_configs:
  - chat_id: YOUR_CHAT_ID
    api_url: 'https://api.telegram.org'
    bot_token: 'YOUR_BOT_TOKEN'
```

---

## 📊 Dashboards Grafana

### Dashboard Padrão: "Nexus Streaming - Sistema"

Mostra em tempo real:
- CPU e Memória
- Requisições API
- Tempo de resposta
- Taxa de erros
- Espaço em disco

### Como Criar Novos Dashboards

1. Acesse Grafana: http://localhost:3000
2. Clique em "+" → "Dashboard"
3. Selecione "Prometheus" como datasource
4. Adicione painéis com queries PromQL

Exemplos de queries:

```promql
# Taxa de erros
rate(http_requests_total{status_code=~"5.."}[5m])

# P95 do tempo de resposta
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))

# Usuários ativos
sum(active_users)

# Pagamentos processados por hora
rate(payment_amount_total[1h])
```

---

## 🛠️ Troubleshooting

### Prometheus não coleta métricas

```bash
# Verificar saúde
curl http://localhost:9090/api/v1/query?query=up

# Ver targets
curl http://localhost:9090/api/v1/targets
```

### Grafana sem dados

```bash
# Verificar conexão com Prometheus
curl http://prometheus:9090/api/v1/query?query=up
```

### Alertas não funcionam

```bash
# Verificar Alertmanager
curl http://localhost:9093/api/v1/status

# Ver alertas ativos
curl http://localhost:9093/api/v1/alerts
```

### Logs não aparecem

```bash
# Verificar permissões
ls -la /var/log/nexus/

# Testar logging
python -m app.main
```

---

## 🔐 Segurança

### Proteger Grafana

```bash
# Alterar senha padrão em produção
# Acesse: http://localhost:3000/admin/users
# Mude senha do usuário 'admin'
```

### Proteger Prometheus

Adicione autenticação reverse proxy (nginx):

```nginx
location /prometheus/ {
    auth_basic "Prometheus";
    auth_basic_user_file /etc/nginx/.htpasswd;
    proxy_pass http://prometheus:9090/;
}
```

### Alertmanager

Proteja credenciais em variáveis de ambiente:

```bash
export SMTP_PASSWORD="sua-senha"
export SLACK_WEBHOOK="url-do-webhook"
export TELEGRAM_BOT_TOKEN="token-do-bot"
```

---

## 📋 Checklist de Produção

- [ ] Alterar senhas padrão Grafana
- [ ] Configurar SMTP para emails de alerta
- [ ] Adicionar webhook Slack/Telegram
- [ ] Testar envio de alertas
- [ ] Aumentar retention de logs (7 dias → 30/60 dias)
- [ ] Configurar backup de Grafana dashboards
- [ ] Monitorar espaço de armazenamento Prometheus
- [ ] Configurar rotação de logs
- [ ] Testar failover de componentes
- [ ] Documentar escalação de alertas

---

## 📚 Referências

- [Prometheus Docs](https://prometheus.io/docs/)
- [Grafana Docs](https://grafana.com/docs/)
- [Alertmanager Docs](https://prometheus.io/docs/alerting/latest/overview/)
- [PromQL Guide](https://prometheus.io/docs/prometheus/latest/querying/basics/)

