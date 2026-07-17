# 🚀 Guia: Atualizar VPS com as Novas Correções

## 📋 Resumo das Mudanças Commitadas

✅ **Android Build** - Corrigir package ID e Firebase
✅ **Docker** - Conexões usando nomes de serviços  
✅ **Scripts** - Todas as permissões +x  
✅ **Monitoring** - Variáveis de ambiente, sem placeholders  
✅ **Kubernetes** - Health checks, resource limits, TLS  
✅ **Configurações** - Templates de .env  

Todas as **validações passam** ✓

---

## 🔧 Passo a Passo: Atualizar na VPS

### **Passo 1: SSH para a VPS**
```bash
ssh root@seu-ip-vps
cd /opt/nexus
```

### **Passo 2: Atualizar repositório**
```bash
git pull origin main
```

### **Passo 3: Parar serviços atuais (se rodando)**
```bash
docker-compose down
```

### **Passo 4: Copiar configurações de ambiente**
```bash
# Se não existe .env em Docker Compose
cp .env.docker-compose .env

# Editar com suas configurações reais
nano .env
```

**Variáveis importantes a preencher:**
```bash
GF_ADMIN_PASSWORD=sua_senha_forte
SMTP_USER=noreply@seu-dominio.com
SMTP_PASSWORD=sua_senha_hostinger
SLACK_WEBHOOK_URL=https://hooks.slack.com/...
ADMIN_EMAILS=admin@seu-dominio.com
MERCADOPAGO_ACCESS_TOKEN=seu_token_real
```

### **Passo 5: Reconstruir e iniciar serviços**
```bash
docker-compose up -d --build

# Ver logs em tempo real
docker-compose logs -f backend
```

### **Passo 6: Executar verificação**
```bash
bash verify_vps_deployment.sh
```

---

## ✅ Verificações Automáticas

O script `verify_vps_deployment.sh` verifica:

```
✓ [1/10] Git repository - limpo e atualizado
✓ [2/10] Docker Compose - configurado
✓ [3/10] Docker Services - todos rodando
✓ [4/10] Backend API - /health endpoint
✓ [5/10] PostgreSQL - conectável
✓ [6/10] Redis - respondendo
✓ [7/10] Prometheus - métricas
✓ [8/10] Grafana - dashboard
✓ [9/10] Espaço em disco - > 20% livre
✓ [10/10] Certificados SSL - válidos
```

---

## 🌐 Acessar Serviços Após Deploy

| Serviço | URL | Credenciais |
|---------|-----|-------------|
| **API Docs** | `http://seu-ip:8000/docs` | N/A |
| **Prometheus** | `http://seu-ip:9090` | N/A |
| **Grafana** | `http://seu-ip:3000` | admin / sua_senha |
| **AlertManager** | `http://seu-ip:9093` | N/A |

---

## 🔍 Troubleshooting

### **Backend não inicia?**
```bash
# Ver logs
docker-compose logs backend

# Verificar variáveis de ambiente
docker-compose config | grep DATABASE_URL

# Reiniciar apenas backend
docker-compose restart backend
```

### **Prometheus não coleta métricas?**
```bash
# Verificar conectividade
docker-compose exec prometheus curl -s http://backend:8000/metrics

# Ver target status
curl -s http://localhost:9090/api/v1/targets | jq
```

### **Grafana não conecta ao Prometheus?**
```bash
# Testar rede Docker
docker-compose exec grafana ping prometheus

# Verificar data source em Grafana UI
# Acesse: http://seu-ip:3000 → Configuration → Data Sources
```

### **Alertas não sendo enviados?**
```bash
# Verificar alertmanager logs
docker-compose logs alertmanager

# Testar SMTP
docker-compose exec alertmanager telnet smtp.hostinger.com 465

# Validar arquivo de config
docker-compose exec alertmanager amtool config routes
```

---

## 📊 Monitorar Saúde Contínua

```bash
# Ver status dos containers em tempo real
watch docker-compose ps

# Monitorar logs
docker-compose logs --tail=100 -f

# Ver métricas de recursos
docker stats

# Monitorar via cron a cada 5 minutos
*/5 * * * * /opt/nexus/health_check.sh >> /var/log/nexus/health.log 2>&1
```

---

## 🔄 Atualizar Periodicamente

Para novos updates:

```bash
cd /opt/nexus
git pull origin main
docker-compose up -d --build
bash verify_vps_deployment.sh
```

---

## 📈 Próximas Etapas

1. ✅ Deploy dos serviços
2. ⏳ Configurar domínio customizado (nginx)
3. ⏳ Habilitar HTTPS com Let's Encrypt
4. ⏳ Configurar backups automáticos
5. ⏳ Testar fluxo de pagamentos (MercadoPago)

---

## 💡 Dicas

- **Backup antes de atualizar:** `bash backup_nexus.sh`
- **Monitorar com Grafana:** Acesse e configure dashboards
- **Alertas críticos:** Revise alertas em Production
- **Logs estruturados:** JSON logging habilitado por padrão

---

**Status:** ✅ Pronto para Deploy  
**Última atualização:** 2026-07-17  
**Versão:** 1.0
