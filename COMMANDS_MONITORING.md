# Comandos Úteis - Monitoramento Nexus

Quick reference para comandos comuns de monitoramento.

---

## 🚀 Iniciar/Parar Stack

```bash
# Iniciar tudo
docker-compose up -d

# Iniciar apenas monitoramento
docker-compose up -d prometheus grafana alertmanager

# Parar tudo
docker-compose down

# Parar e remover volumes
docker-compose down -v

# Ver status
docker-compose ps

# Ver logs em tempo real
docker-compose logs -f [service]

# Exemplo: logs do Prometheus
docker-compose logs -f prometheus

# Exemplo: logs do Grafana
docker-compose logs -f grafana
```

---

## 🔍 Prometheus

```bash
# Acessar shell do container
docker-compose exec prometheus /bin/sh

# Verificar saúde
curl http://localhost:9090/-/healthy

# Listar targets
curl http://localhost:9090/api/v1/targets | jq .

# Verificar targets problema
curl http://localhost:9090/api/v1/targets | jq '.data.activeTargets[] | select(.health != "up")'

# Query básica
curl 'http://localhost:9090/api/v1/query?query=up' | jq .

# Query com intervalo
curl 'http://localhost:9090/api/v1/query_range?query=http_requests_total&start=1h&step=1m' | jq .

# Query range com timestamps
curl 'http://localhost:9090/api/v1/query_range?query=up&start='$(date -d '1 hour ago' '+%s')'&end='$(date '+%s')'&step=60s' | jq .

# Recarregar configuração
docker-compose exec prometheus /bin/sh -c 'kill -HUP 1'
```

---

## 📊 Grafana

```bash
# Acessar Grafana API
curl -H "Authorization: Bearer $TOKEN" http://localhost:3000/api/datasources

# Listar datasources
curl http://localhost:3000/api/datasources | jq .

# Listar dashboards
curl http://localhost:3000/api/search | jq .

# Obter dashboard específico
curl http://localhost:3000/api/dashboards/db/nexus-system | jq .

# Alterar senha admin (via curl)
curl -X PUT http://admin:admin@localhost:3000/api/admin/users/1/password -H "Content-Type: application/json" -d '{"password":"newpassword"}'

# Criar API token
curl -X POST http://admin:admin@localhost:3000/api/auth/keys -H "Content-Type: application/json" -d '{"name":"API Token","role":"Viewer"}'
```

---

## 🔔 Alertmanager

```bash
# Verificar saúde
curl http://localhost:9093/-/healthy

# Ver alertas ativos
curl http://localhost:9093/api/v1/alerts | jq .

# Ver grupos de alertas
curl http://localhost:9093/api/v1/alerts/groups | jq .

# Ver status do Alertmanager
curl http://localhost:9093/api/v1/status | jq .

# Silenciar alerta por 1 hora
curl -X POST http://localhost:9093/api/v1/silences -H "Content-Type: application/json" -d '{
  "matchers": [
    {"name": "alertname", "value": "HighCPUUsage"}
  ],
  "duration": "1h"
}'

# Remover silêncio
curl -X DELETE http://localhost:9093/api/v1/silences/{silenceId}

# Enviar alerta de teste
curl -X POST http://localhost:9093/api/v1/alerts -H "Content-Type: application/json" -d '[{
  "labels": {
    "alertname": "TestAlert",
    "severity": "warning"
  },
  "annotations": {
    "summary": "Test alert"
  }
}]'
```

---

## 📝 Logs

```bash
# Ver todos os arquivos de log
ls -lh /var/log/nexus/

# Ver logs em tempo real
tail -f /var/log/nexus/app.log

# Ver logs com paginação
less /var/log/nexus/app.log

# Ver últimas 100 linhas
tail -100 /var/log/nexus/app.log

# Ver logs JSON formatado
cat /var/log/nexus/app.log | jq .

# Buscar erro específico
grep "error" /var/log/nexus/errors.log

# Buscar com contexto (5 linhas antes e depois)
grep -C 5 "error_pattern" /var/log/nexus/app.log

# Contar logs por nível
jq '.level' /var/log/nexus/app.log | sort | uniq -c

# Ver logs de um período
grep "2024-01-15" /var/log/nexus/app.log | jq .

# Análise de logs (count de endpoints)
jq '.message' /var/log/nexus/api.log | grep -oP '(?<= )[^ ]+' | sort | uniq -c | sort -rn | head -20

# Monitorar logs em tempo real com filter
tail -f /var/log/nexus/app.log | jq 'select(.level == "ERROR")'

# Comprimir logs antigos manualmente
gzip /var/log/nexus/app.log.1

# Remover logs com mais de 30 dias
find /var/log/nexus -name "*.log.*" -mtime +30 -delete

# Ver tamanho dos logs
du -h /var/log/nexus/

# Limpar todos os logs
rm /var/log/nexus/*.log*
```

---

## 🔗 FastAPI Metrics

```bash
# Ver todas as métricas
curl http://localhost:8000/metrics | head -30

# Contar métricas
curl http://localhost:8000/metrics | wc -l

# Ver apenas métricas HTTP
curl http://localhost:8000/metrics | grep http_

# Ver apenas métricas de erros
curl http://localhost:8000/metrics | grep error

# Salvar em arquivo
curl http://localhost:8000/metrics > metrics.txt

# Ver valor de métrica específica
curl http://localhost:8000/metrics | grep 'http_requests_total{' | head -5

# Acompanhar métrica em tempo real
watch 'curl http://localhost:8000/metrics | grep http_requests_total | head -3'
```

---

## 🐳 Docker

```bash
# Ver containers rodando
docker-compose ps

# Ver logs de um serviço
docker-compose logs prometheus

# Ver logs em tempo real
docker-compose logs -f prometheus

# Último 100 linhas
docker-compose logs --tail=100 prometheus

# Entrar no shell do container
docker-compose exec prometheus /bin/sh

# Executar comando no container
docker-compose exec prometheus cat /etc/prometheus/prometheus.yml

# Resetar serviço
docker-compose restart prometheus

# Reconstruir imagem
docker-compose build backend

# Remover volumes
docker volume rm prometheus_data grafana_data alertmanager_data

# Ver uso de recursos
docker stats

# Ver rede do docker-compose
docker network ls | grep nexus

# Inspecionar volume
docker volume inspect prometheus_data
```

---

## 🔧 Troubleshooting

```bash
# Verificar conectividade Prometheus
docker-compose exec prometheus curl http://backend:8000/metrics

# Testar conexão PostgreSQL
docker-compose exec postgres_exporter curl http://localhost:9187/metrics | head -20

# Testar conexão Redis
docker-compose exec redis_exporter curl http://localhost:9121/metrics | head -20

# Testar DNS
docker-compose exec prometheus nslookup backend

# Verificar IP dos containers
docker inspect $(docker-compose ps -q backend) | jq '.[0].NetworkSettings.Networks'

# Testar conectividade entre containers
docker-compose exec backend curl http://prometheus:9090/-/healthy

# Ver variáveis de ambiente
docker-compose exec backend env

# Verificar permissões de arquivo
ls -la /var/log/nexus/

# Mudar permissões
sudo chmod -R 777 /var/log/nexus

# Ver espaço em disco
docker-compose exec backend df -h

# Monitorar uso de memória
docker stats --no-stream
```

---

## 📊 PromQL Queries Úteis

```bash
# Salvar query como favorito (Prometheus UI)
# http://localhost:9090/graph
# Digite a query e clique em "Save as..." 

# Requisições por segundo (última hora)
rate(http_requests_total[1m])

# Taxa de erro (últimas 5 minutos)
rate(http_requests_total{status_code=~"5.."}[5m]) * 100 / rate(http_requests_total[5m])

# Endpoints mais lentos
topk(5, histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m])))

# CPU por container
rate(container_cpu_usage_seconds_total[1m]) * 100

# Memória por container
container_memory_usage_bytes / 1024 / 1024

# Conexões PostgreSQL
pg_stat_activity_count

# Operações Redis
rate(redis_commands_processed_total[1m])

# Pagamentos por minuto
rate(payment_attempts_total[1m])

# Usuários ativos
active_users

# Taxa de sucesso de login
rate(login_attempts_total{status="success"}[1m]) / rate(login_attempts_total[1m]) * 100
```

---

## 🚨 Testar Alertas

```bash
# Simular CPU alta (diminuir threshold temporariamente em alert_rules.yml)
docker-compose exec prometheus sed -i 's/> 90/> 0/g' /etc/prometheus/rules/alert_rules.yml

# Verificar alertas disparam
curl http://localhost:9093/api/v1/alerts | jq '.data | length'

# Restaurar
docker-compose exec prometheus sed -i 's/> 0/> 90/g' /etc/prometheus/rules/alert_rules.yml

# Testar envio de email manualmente
docker-compose exec alertmanager telnet smtp.gmail.com 587

# Testar webhook Slack
curl -X POST "YOUR_SLACK_WEBHOOK_URL" -H 'Content-Type: application/json' -d '{
  "text": "🔔 Test Alert from Prometheus"
}'

# Simular low disk space
# Editar prometheus.yml e mudar: "< 10%" para "< 90%"

# Recarregar Prometheus
docker-compose exec prometheus kill -HUP 1

# Esperar alerta disparar
sleep 30
curl http://localhost:9093/api/v1/alerts | jq .
```

---

## 📈 Análise de Performance

```bash
# Ver endpoints mais requisitados
curl http://localhost:9090/api/v1/query?query='sum(rate(http_requests_total%5B1h%5D))by(endpoint)' | jq '.data.result | sort_by(.value | tonumber) | reverse | .[0:10]'

# Ver endpoints mais lentos
curl 'http://localhost:9090/api/v1/query?query=histogram_quantile(0.95,rate(http_request_duration_seconds_bucket[1h]))by(endpoint)' | jq '.data.result | sort_by(.value | tonumber) | reverse | .[0:10]'

# Ver endpoints com mais erros
curl 'http://localhost:9090/api/v1/query?query=sum(rate(http_requests_total{status_code=~"5.."}[1h]))by(endpoint)' | jq '.data.result | sort_by(.value | tonumber) | reverse | .[0:10]'

# Capacidade de memória
curl 'http://localhost:9090/api/v1/query?query=node_memory_MemAvailable_bytes/node_memory_MemTotal_bytes' | jq '.data.result[0].value[1]'
```

---

## 🔐 Segurança

```bash
# Alterar senha Grafana
docker-compose exec grafana grafana-cli admin reset-admin-password newpassword

# Listar usuários Grafana
docker-compose exec grafana grafana-cli admin users list

# Ver logs de segurança
grep -i "auth\|login\|password" /var/log/nexus/auth.log

# Verificar acessos não autorizados
grep "401\|403" /var/log/nexus/api.log

# Audit de mudanças em configuração
git log --oneline monitoring/
```

---

## 📚 Documentação Online

```bash
# Abrir Prometheus no navegador
open http://localhost:9090

# Abrir Grafana
open http://localhost:3000

# Abrir Alertmanager
open http://localhost:9093

# Abrir FastAPI docs
open http://localhost:8000/docs

# Abrir FastAPI redoc
open http://localhost:8000/redoc
```

---

## 💡 Dicas e Truques

```bash
# Alias para comandos frequentes (adicionar ao ~/.bashrc)
alias nexus-logs='tail -f /var/log/nexus/app.log | jq .'
alias nexus-alerts='curl http://localhost:9093/api/v1/alerts | jq .'
alias nexus-metrics='curl http://localhost:8000/metrics'
alias nexus-health='docker-compose ps'

# Monitorar métrica em tempo real
watch -n 1 'curl http://localhost:9090/api/v1/query?query=http_requests_total | jq ".data.result[0].value[1]"'

# Export de dados
curl http://localhost:9090/api/v1/query_range?query=up&start=1d&step=5m > prometheus_data.json

# Análise de logs com AWK
awk '{print $1}' /var/log/nexus/api.log | sort | uniq -c | sort -rn

# Encontrar erros nos últimos 10 minutos
jq 'select(.timestamp > now - 600) | select(.level == "ERROR")' /var/log/nexus/errors.log
```

---

## 🎓 Referências

- Prometheus API: http://localhost:9090/api/v1/
- Grafana API: http://localhost:3000/api/
- Alertmanager API: http://localhost:9093/api/v1/

