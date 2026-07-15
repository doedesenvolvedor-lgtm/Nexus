# 📑 Índice de Deployment - Nexus Monitoring em VPS

## 🎯 Arquivos por Propósito

### 🚀 DEPLOY (Comece aqui!)

```
┌─────────────────────────────────────────────────────────┐
│ Primeira vez? Siga este fluxo:                          │
├─────────────────────────────────────────────────────────┤
│ 1. VPS_DEPLOYMENT.md       ← Leia primeiro              │
│ 2. deploy_vps.sh           ← Execute este script        │
│ 3. VPS_CHECKLIST.md        ← Valide cada passo         │
│ 4. QUICK_REFERENCE.md      ← Mantenha como referência  │
└─────────────────────────────────────────────────────────┘
```

### 📋 DOCUMENTAÇÃO OPERACIONAL

| Arquivo | Propósito | Tempo |
|---------|-----------|-------|
| **VPS_DEPLOYMENT.md** | Deploy completo em VPS Hostinger | 30 min |
| **VPS_CHECKLIST.md** | Validar cada passo + troubleshooting | 20 min |
| **QUICK_REFERENCE.md** | Card rápido de comandos essenciais | 2 min |
| **CRON_AUTOMATION.md** | Setup cron jobs para automação | 15 min |

### 🔧 SCRIPTS AUTOMÁTICOS

| Script | O que faz | Frequência |
|--------|-----------|-----------|
| **deploy_vps.sh** | Install Docker + clone repo + start stack | Uma vez |
| **backup_nexus.sh** | Backup Prometheus/Grafana/logs | Diário (2 AM) |
| **health_check.sh** | Verifica saúde dos serviços | A cada 5 min |

### 📚 REFERÊNCIA TÉCNICA

| Arquivo | Conteúdo |
|---------|----------|
| **MONITORING_SETUP.md** | Guia completo de monitoramento |
| **COMMANDS_MONITORING.md** | 50+ comandos úteis |
| **ARCHITECTURE.md** | Visão técnica do sistema |

---

## 🗂️ Estrutura Completa

```
/workspaces/Nexus/
│
├─ 🚀 DEPLOYMENT (Novo)
│  ├─ VPS_DEPLOYMENT.md          ✓ Guia passo-a-passo
│  ├─ VPS_CHECKLIST.md           ✓ Validação completa
│  ├─ CRON_AUTOMATION.md         ✓ Automação de tarefas
│  ├─ QUICK_REFERENCE.md         ✓ Card rápido
│  ├─ deploy_vps.sh              ✓ Script auto deploy
│  ├─ backup_nexus.sh            ✓ Script backup
│  └─ health_check.sh            ✓ Script health check
│
├─ 📊 MONITORAMENTO (Core)
│  ├─ docker-compose.yml         ✓ 14 serviços
│  ├─ monitoring/
│  │  ├─ prometheus.yml          ✓ Config Prometheus
│  │  ├─ alert_rules.yml         ✓ 15+ regras
│  │  ├─ alertmanager.yml        ✓ Routing
│  │  ├─ alertmanager_templates.tmpl
│  │  └─ grafana/
│  │     └─ provisioning/
│  │        ├─ dashboards/nexus-system.json
│  │        └─ datasources/prometheus.yml
│  │
│  └─ backend/
│     ├─ app/
│     │  ├─ main.py              ✓ FastAPI app
│     │  ├─ metrics.py           ✓ Prometheus middleware
│     │  └─ logging_config.py    ✓ JSON logging
│     │
│     └─ requirements.txt        ✓ Python deps
│
└─ 📚 DOCUMENTAÇÃO (Referência)
   ├─ MONITORING_SETUP.md
   ├─ MONITORING_IMPLEMENTATION.md
   ├─ COMMANDS_MONITORING.md
   ├─ ARCHITECTURE.md
   └─ [mais 8 arquivos]
```

---

## 🎬 Começar Rápido

### Opção 1: Deploy Automático (5 minutos)

```bash
# 1. Conectar à VPS
ssh root@seu-ip-vps

# 2. Download e executar script
curl -o deploy_vps.sh https://raw.githubusercontent.com/doedesenvolvedor-lgtm/Nexus/main/deploy_vps.sh
sudo bash deploy_vps.sh

# 3. Verificar status
docker-compose ps
curl http://localhost:9090/-/healthy

# 4. Acessar Grafana
# http://seu-ip-vps:3000 (admin/admin)
```

### Opção 2: Deploy Manual (30 minutos)

Siga o passo-a-passo em: `VPS_DEPLOYMENT.md` → "Deploy Manual"

### Opção 3: Deploy com Automação (1 hora)

1. Deploy automático
2. Setup HTTPS: `certbot certonly --nginx -d seu-dominio`
3. Configurar alertas: `nano monitoring/alertmanager.yml`
4. Setup cron: `crontab -e` (ver em `CRON_AUTOMATION.md`)

---

## 🚀 Fluxo de Primeiro Deploy

```
┌──────────────────┐
│  Antes do Deploy │
└────────┬─────────┘
         │
         ├─ Ler: VPS_DEPLOYMENT.md (pré-requisitos)
         ├─ Preparar: Credenciais SMTP, Slack
         ├─ Confirmar: IP, domínio, SSH
         │
┌────────▼──────────┐
│ Deploy (2 min)    │
└────────┬──────────┘
         │
         ├─ SSH: ssh root@seu-ip-vps
         ├─ Run: sudo bash deploy_vps.sh
         ├─ Wait: Auto-installation
         │
┌────────▼──────────────────┐
│ Validação (5 min)         │
└────────┬───────────────────┘
         │
         ├─ Check: docker-compose ps
         ├─ Test: curl http://localhost:9090/-/healthy
         ├─ Access: http://seu-ip:3000 (Grafana)
         │
┌────────▼──────────────────┐
│ Configuração (15 min)     │
└────────┬───────────────────┘
         │
         ├─ Alterar: Senha Grafana
         ├─ Config: monitoring/alertmanager.yml
         ├─ Enable: HTTPS (certbot)
         │
┌────────▼──────────────────┐
│ Automação (10 min)        │
└────────┬───────────────────┘
         │
         ├─ Setup: Cron jobs (health check, backup)
         ├─ Test: /opt/nexus/health_check.sh
         ├─ Test: /opt/nexus/backup_nexus.sh
         │
┌────────▼──────────────────┐
│ ✅ PRONTO PRODUÇÃO       │
└──────────────────────────┘
```

---

## 📍 Localização dos Arquivos

### Em Seu Computador (Agora)

```
/workspaces/Nexus/
├── VPS_DEPLOYMENT.md
├── VPS_CHECKLIST.md
├── QUICK_REFERENCE.md
├── CRON_AUTOMATION.md
├── deploy_vps.sh
├── backup_nexus.sh
├── health_check.sh
└── ... (outros)
```

### Na VPS (Depois do Deploy)

```
/opt/nexus/
├── VPS_DEPLOYMENT.md
├── VPS_CHECKLIST.md
├── QUICK_REFERENCE.md
├── CRON_AUTOMATION.md
├── deploy_vps.sh
├── backup_nexus.sh
├── health_check.sh
├── docker-compose.yml
├── monitoring/
├── backend/
└── ... (todo repositório)
```

---

## 🎯 Escolha Seu Documento

### "Vou fazer deploy AGORA"
**→ Abra**: `VPS_DEPLOYMENT.md`

### "Quero fazer passo a passo"
**→ Abra**: `VPS_DEPLOYMENT.md` → Seção "Deploy Manual"

### "Preciso validar se está OK"
**→ Abra**: `VPS_CHECKLIST.md`

### "Quero um comando rápido"
**→ Abra**: `QUICK_REFERENCE.md`

### "Tenho um problema"
**→ Abra**: `QUICK_REFERENCE.md` → "Troubleshooting Rápido"

### "Quero 50+ comandos"
**→ Abra**: `COMMANDS_MONITORING.md`

### "Preciso entender tudo"
**→ Abra**: `ARCHITECTURE.md`

### "Quero automatizar com cron"
**→ Abra**: `CRON_AUTOMATION.md`

---

## ⏱️ Tempo Necessário

```
Deploy Automático:    2 min  ⚡ (recomendado)
Deploy Manual:        30 min ⏱️
Pós-Deploy Setup:     15 min 🔧
Cron Automation:      10 min ⚙️
HTTPS Setup:          10 min 🔐
─────────────────────────────
TOTAL PRIMEIRA VEZ:   67 min 🎉
```

Próximas execuções: 2 minutos ⚡

---

## 💾 Checklist Mínimo

- [ ] SSH para VPS
- [ ] `sudo bash deploy_vps.sh` (aguardar finalização)
- [ ] Verificar: `docker-compose ps`
- [ ] Acessar: `http://seu-ip:3000` (Grafana)
- [ ] Alterar senha admin em Grafana
- [ ] Configurar alertas em `monitoring/alertmanager.yml`
- [ ] Restart: `docker-compose restart alertmanager`
- [ ] Setup HTTPS com `certbot`
- [ ] Pronto! ✅

---

## 🆘 Suporte Rápido

| Problema | Solução |
|----------|---------|
| Deploy falhou | Ver logs: `docker-compose logs` |
| Serviço parou | Restart: `docker-compose restart SERVICE` |
| Sem dados | Verificar datasource em Grafana |
| Alertas não funciona | Verificar config em `alertmanager.yml` |
| Disco cheio | Limpar logs: `find /var/log/nexus -mtime +30 -delete` |

---

## 📚 Documentação Completa

```
VPS_DEPLOYMENT.md          Guia visual + passo-a-passo
VPS_CHECKLIST.md           Checklist interativo 100+ itens
CRON_AUTOMATION.md         Setup agendamento automático
QUICK_REFERENCE.md         Card de 1 página rápida
MONITORING_SETUP.md        Guia completo original
COMMANDS_MONITORING.md     Referência 50+ comandos
ARCHITECTURE.md            Diagrama + visão técnica
DEPLOYMENT_INDEX.md        Este arquivo (você está aqui!)
```

---

## ✨ Pro Tips

💡 **Abra em 2 abas**:
1. Terminal SSH
2. Navegador com `QUICK_REFERENCE.md`

💡 **Imprima**:
`QUICK_REFERENCE.md` cabe em 1 página impressa!

💡 **Salve em favoritos**:
`COMMANDS_MONITORING.md` → 50+ comandos prontos

💡 **Monitore sempre**:
`health_check.sh` roda sozinho a cada 5 min

---

## 🎉 Conclusão

Você tem tudo que precisa para:
- ✅ Deploy em 2 minutos
- ✅ Validar funcionamento
- ✅ Configurar alertas
- ✅ Automatizar tarefas
- ✅ Troubleshoot problemas
- ✅ Rodar em produção

**Próximo passo**: Abra `VPS_DEPLOYMENT.md` e comece! 🚀

---

## 📊 Resumo Executivo

| Aspecto | Status |
|--------|--------|
| **Documentação** | ✅ 4 guias novos + 8 de referência |
| **Automação** | ✅ Deploy 100% automático |
| **Backup** | ✅ Automático diário com retenção 30d |
| **Healthcheck** | ✅ A cada 5 minutos |
| **Alertas** | ✅ 15+ regras prontas |
| **HTTPS** | ✅ Let's Encrypt integrado |
| **Produção** | ✅ Pronto para usar |

---

**Status**: ✅ 100% Completo e Pronto para Produção
**Última atualização**: 2024
**Versão**: 1.0

