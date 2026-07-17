# 📊 Monitoring & Deployment - Configuração Corrigida

## ✅ Problemas Resolvidos

### 1. **AlertManager** 
- ✅ Removidos placeholders hardcoded
- ✅ Agora usa variáveis de ambiente: `${ADMIN_EMAILS}`, `${SMTP_USER}`, etc
- ✅ Configurado para Hostinger (smtp.hostinger.com:465)

### 2. **Docker Compose**
- ✅ Grafana agora usa variáveis: `${GF_ADMIN_PASSWORD}` (remover hardcoded "admin")
- ✅ Novo arquivo `.env.docker-compose` para todas as variáveis

### 3. **Kubernetes Deployment**
- ✅ Adicionado `livenessProbe` e `readinessProbe`
- ✅ Adicionado limites de CPU/Memory
- ✅ Image com tag específico: `nexus/backend:v1.0.0` (não mais `latest`)
- ✅ Security context adicionado
- ✅ Rolling update strategy

### 4. **Kubernetes Ingress**
- ✅ Adicionado TLS/HTTPS com Let's Encrypt
- ✅ Adicionado ingressClassName: nginx
- ✅ Rate limiting configurado
- ✅ Redirects HTTP→HTTPS

### 5. **ConfigMap & Secrets**
- ✅ Novo arquivo `backend-config.yaml` com templates
- ✅ Separação clara entre dados públicos (ConfigMap) e sensíveis (Secrets)

## 🚀 Como Usar

### Local (Docker Compose)

```bash
# 1. Copiar arquivo de template
cp .env.docker-compose .env

# 2. Editar com suas configurações
nano .env

# 3. Subir stack
docker-compose up -d

# 4. Verificar serviços
docker-compose logs -f grafana
```

### Produção (Kubernetes)

```bash
# 1. Criar namespace
kubectl create namespace nexus

# 2. Aplicar ConfigMap e Secrets
kubectl apply -f kubernetes/backend-config.yaml

# 3. Aplicar deployment
kubectl apply -f kubernetes/backend-deployment.yaml

# 4. Aplicar service e ingress
kubectl apply -f kubernetes/service.yaml
kubectl apply -f kubernetes/ingress.yaml

# 5. Verificar status
kubectl get deployments -n nexus
kubectl get pods -n nexus
```

## 📋 Variáveis Obrigatórias

| Variável | Onde Usar | Exemplo |
|----------|-----------|---------|
| `SMTP_USER` | AlertManager email | `noreply@seu-dominio.com` |
| `SMTP_PASSWORD` | AlertManager email | `sua_senha_hostinger` |
| `SLACK_WEBHOOK_URL` | AlertManager Slack | `https://hooks.slack.com/...` |
| `ADMIN_EMAILS` | Destinatário dos alertas | `admin@seu-dominio.com` |
| `GF_ADMIN_PASSWORD` | Grafana password | `senha_forte_aqui` |

## ⚠️ Próximas Ações

1. **Editar `.env.docker-compose`** com suas credenciais reais
2. **Editar `kubernetes/backend-config.yaml`** com seus valores
3. **Configurar cert-manager** no Kubernetes para TLS automático
4. **Testar endpoints** de health check (`/health`, `/health/ready`)
5. **Configurar CI/CD** para build de images com tags específicas

## 🔒 Segurança

- ✅ Remover `latest` tag (use versionamento)
- ✅ Usar Secrets para dados sensíveis
- ✅ Habilitar HTTPS/TLS
- ✅ Health checks em produção
- ✅ Resource limits para evitar DoS
- ✅ Non-root user execution

## 📊 Monitoramento

Após deploy:

```bash
# Acessar Grafana
http://localhost:3000  (dev)
https://seu-dominio.com/grafana  (prod)

# Acessar Prometheus
http://localhost:9090  (dev)

# Acessar AlertManager
http://localhost:9093  (dev)
```

## 🐛 Troubleshooting

### AlertManager não envia emails?
```bash
# Verificar logs
docker-compose logs alertmanager

# Testar SMTP
nc -zv smtp.hostinger.com 465
```

### Grafana não conecta ao Prometheus?
```bash
# Verificar rede Docker
docker network inspect nexus_default

# Testar conectividade
docker-compose exec grafana ping prometheus
```

### Pod não inicia em Kubernetes?
```bash
# Ver eventos
kubectl describe pod <pod-name> -n nexus

# Ver logs
kubectl logs <pod-name> -n nexus

# Ver recursos disponíveis
kubectl top nodes
kubectl top pods -n nexus
```
