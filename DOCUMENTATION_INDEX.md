# 📚 Índice de Documentação - Nexus Streaming

## 🚀 Comece Aqui

Se você é **novo no projeto**, comece por:

1. **[README.md](README.md)** - Visão geral geral
2. **[ARCHITECTURE.md](ARCHITECTURE.md)** - Arquitetura do sistema
3. **[MONITORING_SUMMARY.txt](MONITORING_SUMMARY.txt)** - Resumo visual

---

## 📊 Monitoramento (Novo)

Toda documentação sobre monitoramento, alertas e logging:

### Para Começar

- **[MONITORING_SETUP.md](MONITORING_SETUP.md)** ⭐ COMECE AQUI
  - Visão geral do sistema
  - Como iniciar
  - URLs de acesso
  - Troubleshooting
  - Checklist de produção

### Implementação Detalhada

- **[MONITORING_IMPLEMENTATION.md](MONITORING_IMPLEMENTATION.md)** - Passo a passo
  - Todos os 10 passos de implementação
  - Configuração de alertas
  - Setup de email, Slack, Telegram
  - Testar logging e métricas
  - Documentar SLAs

### Status e Referência

- **[MONITORING_STATUS.md](MONITORING_STATUS.md)** - Status completo
  - O que foi implementado
  - Alertas configurados
  - Arquivos criados/modificados
  - Validação
  - Próximos passos

### Comandos Rápidos

- **[COMMANDS_MONITORING.md](COMMANDS_MONITORING.md)** - Quick reference
  - Iniciar/parar stack
  - Queries Prometheus
  - Comandos Grafana
  - Troubleshooting
  - Análise de dados

### Sumário Visual

- **[MONITORING_SUMMARY.txt](MONITORING_SUMMARY.txt)** - Resumo visual
  - Componentes implementados
  - Métricas monitoradas
  - Alertas
  - Como começar
  - Próximas etapas

---

## 🏗️ Arquitetura e Design

### Visão Geral

- **[ARCHITECTURE.md](ARCHITECTURE.md)** - Arquitetura completa
  - Stack tecnológico
  - Fluxos de dados
  - Escalabilidade
  - Segurança
  - Capacidade
  - Deployment
  - Checklist de produção

### Segurança

- **[SECURITY.md](SECURITY.md)** - Guia de segurança
  - Boas práticas
  - Configurações seguras
  - Proteção de dados
  - Autenticação
  - Autorização

### Testes

- **[TESTING_GUIDE.md](TESTING_GUIDE.md)** - Testes da aplicação
  - Testes unitários
  - Testes de integração
  - Testes de carga
  - Cobertura

---

## 🔧 Integrações Externas

### Pagamentos

- **[MERCADOPAGO_INTEGRATION.md](MERCADOPAGO_INTEGRATION.md)**
  - Setup inicial
  - Webhook
  - Pagamentos
  - Reembolsos
  - Testes

- **[MERCADOPAGO_QUICK_START.md](MERCADOPAGO_QUICK_START.md)**
  - Guia rápido

### Firebase

- **[FIREBASE_SETUP_GUIDE.md](FIREBASE_SETUP_GUIDE.md)**
  - Android setup
  - iOS setup
  - Push notifications
  - Analytics

- **[FIREBASE_ANDROID_COMPLETE.md](FIREBASE_ANDROID_COMPLETE.md)**
  - Setup Android completo

- **[FIREBASE_IOS_SETUP.md](FIREBASE_IOS_SETUP.md)**
  - Setup iOS completo

### Legal

- **[PRIVACY_AND_TERMS_SETUP.md](PRIVACY_AND_TERMS_SETUP.md)**
  - Política de privacidade
  - Termos de serviço
  - LGPD compliance

---

## 📱 Mobile/Frontend

### iOS

- **[iOS_SETUP_FOR_MAC.md](iOS_SETUP_FOR_MAC.md)**
  - Setup no macOS
  - Xcode configuration
  - Certificados

- **[iOS_SETUP_SUMMARY.txt](iOS_SETUP_SUMMARY.txt)**
  - Resumo setup iOS

### Flutter

- **[TRIAL_MOBILE_IMPLEMENTATION.md](TRIAL_MOBILE_IMPLEMENTATION.md)**
  - Implementação Trial
  - Features de teste

---

## 🔌 Backend

### FastAPI

- `backend/app/main.py` - Aplicação principal
- `backend/app/logging_config.py` - Logging estruturado
- `backend/app/metrics.py` - Métricas Prometheus
- `backend/requirements.txt` - Dependências Python

### Routers

- `backend/app/routers/auth.py` - Autenticação
- `backend/app/routers/media.py` - Conteúdo
- `backend/app/routers/payments.py` - Pagamentos
- `backend/app/routers/admin.py` - Admin panel

### Banco de Dados

- `backend/database/init.sql` - Schema inicial
- `backend/app/database.py` - Configuração BD
- `backend/app/models.py` - SQLAlchemy models

---

## 🐳 DevOps

### Docker

- `docker-compose.yml` - Orchestração de serviços
- `backend/Dockerfile` - Imagem backend
- `mobile/Dockerfile` - Imagem mobile (se aplicável)

### Nginx

- `nginx/nginx.conf` - Configuração proxy reverso

### Kubernetes (Opcional)

- `kubernetes/` - Manifests k8s
  - `backend-deployment.yaml`
  - `postgres-deployment.yaml`
  - `redis-deployment.yaml`
  - Etc.

---

## 📊 Dados

### Banco de Dados

```
PostgreSQL
├─ users
├─ episodes
├─ watch_history
├─ ratings
├─ subscriptions
├─ transactions
└─ admin_logs
```

### Cache

```
Redis
├─ session_data
├─ refresh_tokens
├─ episodes_cache
├─ recommendations_cache
└─ job_queue
```

---

## 🎯 Fluxos Principais

### Autenticação

```
1. Usuário faz login
   POST /auth/login
   → Validar credenciais
   → Gerar JWT
   → Armazenar sessão em Redis
   → Retornar tokens

2. Requisições subsequentes
   Header: Authorization: Bearer {token}
   → Validar JWT
   → Recuperar sessão
   → Permitir acesso
```

### Pagamento

```
1. Usuário inicia pagamento
   POST /payment/process
   → Criar transação (BD)
   → Chamar Mercado Pago API
   → Armazenar em cache

2. Webhook Mercado Pago
   POST /webhook/payment
   → Validar signature
   → Atualizar transação
   → Ativar subscription
   → Enviar email

3. Monitoramento
   → Métrica de pagamento
   → Alertar se falha
   → Log em /var/log/nexus/payments.log
```

### Monitoramento

```
1. FastAPI emite métricas
   GET /metrics
   → Prometheus coleta

2. Prometheus armazena
   → Time-series database
   → Retention: 7 dias

3. Grafana visualiza
   → Dashboard em tempo real
   → Queries PromQL

4. Alertmanager monitora
   → Avalia regras
   → Acionada? → Enviar notificação

5. Logs centralizados
   → JSON em /var/log/nexus/
   → Rotação automática
```

---

## 🔍 Tabela de Referência Rápida

| Componente | Porta | URL | Função |
|-----------|-------|-----|--------|
| FastAPI | 8000 | http://localhost:8000 | API Backend |
| PostgreSQL | 5432 | localhost:5432 | Banco de dados |
| Redis | 6379 | localhost:6379 | Cache + Queue |
| Nginx | 80/443 | http/https | Reverse proxy |
| Grafana | 3000 | http://localhost:3000 | Dashboards |
| Prometheus | 9090 | http://localhost:9090 | Métricas |
| Alertmanager | 9093 | http://localhost:9093 | Alertas |
| Postgres Exporter | 9187 | localhost:9187 | Métricas PG |
| Redis Exporter | 9121 | localhost:9121 | Métricas Redis |
| Node Exporter | 9100 | localhost:9100 | Métricas SO |
| cAdvisor | 8080 | localhost:8080 | Métricas Docker |

---

## 📋 Checklist de Implementação

### Fase 1: Setup Inicial ✅ COMPLETO

- [x] Estrutura Docker Compose
- [x] FastAPI com routers básicos
- [x] PostgreSQL e Redis
- [x] Nginx com HTTPS
- [x] Firebase integration
- [x] Mercado Pago integration

### Fase 2: Monitoramento ✅ COMPLETO

- [x] Prometheus setup
- [x] Grafana dashboards
- [x] Alertmanager
- [x] Logging estruturado
- [x] Métricas no FastAPI
- [x] Exporters (PG, Redis, Node, Docker)

### Fase 3: Refinement ⏳ PRÓXIMO

- [ ] Testes automatizados
- [ ] CI/CD pipeline
- [ ] Performance optimization
- [ ] Security audit
- [ ] Documentation review

### Fase 4: Scale ⏳ FUTURO

- [ ] Kubernetes migration
- [ ] Multi-region setup
- [ ] APM/Distributed Tracing
- [ ] Advanced analytics

---

## 🚀 Quick Start

```bash
# 1. Clonar repo
git clone https://github.com/doedesenvolvedor-lgtm/Nexus.git
cd Nexus

# 2. Criar logs
mkdir -p /var/log/nexus && chmod 777 /var/log/nexus

# 3. Iniciar stack
docker-compose up -d

# 4. Acessar
# Grafana: http://localhost:3000 (admin/admin)
# API: http://localhost:8000/docs
# Prometheus: http://localhost:9090
```

---

## 🛟 Precisa de Ajuda?

### Documentação Específica

- **Monitoramento não funciona?** → [MONITORING_SETUP.md](MONITORING_SETUP.md#troubleshooting)
- **Alertas não enviam?** → [COMMANDS_MONITORING.md](COMMANDS_MONITORING.md#testar-alertas)
- **Logs não aparecem?** → [MONITORING_IMPLEMENTATION.md](MONITORING_IMPLEMENTATION.md#problema-logs-não-aparecem)
- **Query Prometheus?** → [COMMANDS_MONITORING.md](COMMANDS_MONITORING.md#promql-queries-úteis)

### Comandos Úteis

```bash
# Ver status
docker-compose ps

# Logs em tempo real
docker-compose logs -f backend

# Testar backend
curl http://localhost:8000/health

# Testar métricas
curl http://localhost:8000/metrics | head -20

# Ver alertas
curl http://localhost:9093/api/v1/alerts | jq .

# Testar logs
tail -f /var/log/nexus/app.log | jq .
```

---

## 📞 Contato

Para dúvidas ou problemas:

- GitHub Issues: [Nexus Issues](https://github.com/doedesenvolvedor-lgtm/Nexus/issues)
- Email: dev@nexus.com
- Discord: [Link to Discord]

---

## 📄 Licença

Este projeto está licenciado sob a [LICENSE](LICENSE)

---

## ✨ Contributors

- [doedesenvolvedor-lgtm](https://github.com/doedesenvolvedor-lgtm)
- [Copilot GitHub](https://github.com/features/copilot)

---

**Última atualização**: 2024-01-15
**Versão**: 1.0
**Status**: ✅ Produção-Ready

