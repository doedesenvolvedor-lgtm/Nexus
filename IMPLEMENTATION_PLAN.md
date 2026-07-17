# PLANO DE IMPLEMENTAÇÃO - Passo a Passo

## Fase 1: EMERGÊNCIA (Dia 1 - 4 horas)

### 1.1 Rotacionar Credenciais Imediatamente
**Status:** 🔴 CRÍTICO - FAZER PRIMEIRO

```bash
# 1. Gerar nova SECRET_KEY
NEW_SECRET=$(python3 -c "import secrets; print(secrets.token_urlsafe(32))")
echo "Nova SECRET_KEY: $NEW_SECRET"

# 2. Gerar nova senha PostgreSQL
NEW_DB_PASS=$(python3 -c "import secrets; print(secrets.token_urlsafe(16))")
echo "Nova senha DB: $NEW_DB_PASS"

# 3. Atualizar .env.production (NUNCA commitar)
# Manualmente via editor seguro, não em terminal

# 4. Fazer deploy
docker-compose down
docker-compose up -d

# 5. Verificar logs
docker-compose logs -f backend
```

**Tempo:** 30 minutos  
**Risco se não fizer:** CRÍTICO - Sistema comprometido

---

### 1.2 Implementar Validação de Webhook MercadoPago
**Status:** 🔴 CRÍTICO

**Arquivo:** `backend/app/routers/webhooks.py`

```bash
cd /workspaces/Nexus/backend/app/routers

# Backup do arquivo original
cp webhooks.py webhooks.py.backup

# Usar template de SECURITY_FIXES_TEMPLATES.md seção "4. Webhook MercadoPago"
# vim webhooks.py
```

**Checklist:**
- [ ] Implementar `verify_webhook_signature()` com HMAC
- [ ] Validar payload
- [ ] Atualizar payment status
- [ ] Atualizar subscription status
- [ ] Log de auditoria
- [ ] Testar com webhook de teste do MercadoPago

**Tempo:** 2 horas  
**Teste:** `curl -X POST http://localhost:8000/webhook -d '{"test":"data"}'`

---

### 1.3 Implementar CORS Seguro
**Status:** 🔴 CRÍTICO

**Arquivo:** `backend/app/main.py`

```python
# Ver template SECURITY_FIXES_TEMPLATES.md seção "1. CORS Seguro"
```

**Checklist:**
- [ ] Adicionar CORSMiddleware
- [ ] Configurar allowed_origins com domínios específicos
- [ ] Adicionar security headers middleware
- [ ] Testar CORS com preflight request

**Teste:**
```bash
curl -X OPTIONS http://localhost:8000/health \
  -H "Origin: https://nexusstream.com" \
  -H "Access-Control-Request-Method: POST"
```

**Tempo:** 1 hora

---

## Fase 2: CRÍTICA - Semana 1 (20 horas)

### 2.1 Adicionar Pagination em Endpoints Admin
**Status:** 🔴 CRÍTICO (Performance)

**Arquivos:**
- `backend/app/routers/admin.py`
- `backend/app/routers/subscriptions.py`
- `backend/app/routers/notifications.py`

**Passos:**
```bash
# 1. Adicionar schema de pagination
# Ve SECURITY_FIXES_TEMPLATES.md seção "5. Pagination Helper"
vim backend/app/schemas.py

# 2. Atualizar cada router
vim backend/app/routers/admin.py
# Mudar: db.query(User).all()
# Para: db.query(User).offset(skip).limit(limit).all()

# 3. Testar
curl "http://localhost:8000/admin/users?skip=0&limit=10"
```

**Endpoints a atualizar:**
- `/admin/users` - linha 64
- `/admin/users/{id}/premium` - linha 77
- `/subscriptions` - linha 19
- `/notifications` - todos os `.all()`

**Tempo:** 4 horas

---

### 2.2 Implementar Rate Limiting
**Status:** 🟠 ALTO

**Arquivos:**
- `backend/requirements.txt` - adicionar `slowapi==0.1.9`
- `backend/app/main.py` - adicionar middleware
- `backend/app/routers/auth.py` - adicionar decorator

```bash
# 1. Atualizar requirements.txt
echo "slowapi==0.1.9" >> backend/requirements.txt

# 2. Instalar
pip install slowapi==0.1.9

# 3. Implementar em main.py
# Ver SECURITY_FIXES_TEMPLATES.md seção "2. Rate Limiting"

# 4. Testar
for i in {1..10}; do curl http://localhost:8000/auth/login; done
# Esperado: 429 Too Many Requests após 5 requisições
```

**Endpoints a limitar:**
- `/auth/login` - 5/minuto
- `/auth/register` - 3/minuto
- `/auth/forgot-password` - 3/hora
- `/media/search` - 100/minuto
- Resto: 100/minuto (padrão)

**Tempo:** 3 horas

---

### 2.3 Fix Perfil com ID Hardcoded
**Status:** 🟠 ALTO

**Arquivo:** `backend/app/routers/profiles.py:12`

```python
# ANTES:
new_profile = Profile(
    user_id="00000000-0000-0000-0000-000000000000",
    name=profile.name,
    avatar_url=profile.avatar_url,
    is_kids=profile.is_kids,
    pin_code=profile.pin_code,
)

# DEPOIS:
new_profile = Profile(
    user_id=current_user.id,  # ← de get_current_user
    name=profile.name,
    avatar_url=profile.avatar_url,
    is_kids=profile.is_kids,
    pin_code=profile.pin_code,
)

# Adicionar no router:
from app.dependencies import get_current_user

@router.post("/", response_model=ProfileResponse)
def create_profile(
    profile: ProfileCreate,
    current_user: User = Depends(get_current_user),  # ← NOVO
    db: Session = Depends(get_db)
):
    # código atualizado
```

**Tempo:** 30 minutos

---

### 2.4 Adicionar Validações em Schemas
**Status:** 🔴 CRÍTICO (Segurança)

**Arquivo:** `backend/app/schemas.py`

Ver template SECURITY_FIXES_TEMPLATES.md seção "3. Validações em Schemas"

**Schemas a validar:**
- [ ] UserCreate - email, username, password
- [ ] Login - email, password
- [ ] ResetPasswordRequest - token, new_password
- [ ] ProfileCreate - name, pin_code
- [ ] MediaCreate - title, description, content_type
- [ ] RatingCreate - stars (1-5)

**Teste:**
```bash
# Teste 1: Senha fraca
curl -X POST http://localhost:8000/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"123"}'
# Esperado: 422 Unprocessable Entity

# Teste 2: Senha forte
curl -X POST http://localhost:8000/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"SecurePass123!@#"}'
# Esperado: 200 OK
```

**Tempo:** 5 horas

---

### 2.5 Conectar Admin DB Field (em paralelo)
**Status:** 🔴 CRÍTICO

**Arquivos:**
- `backend/app/models.py` - adicionar `is_admin` field
- `backend/app/security_admin.py` - usar DB field
- Alembic migration

```bash
# 1. Criar migration
cd backend
alembic revision --autogenerate -m "Add is_admin field to User"

# 2. Verificar gerado em alembic/versions/XXX_add_is_admin_field.py
vim alembic/versions/*_add_is_admin_field.py

# 3. Aplicar
alembic upgrade head

# 4. Adicionar usuário admin via DB
psql postgresql://postgres:postgres@localhost:5432/nexus \
  -c "UPDATE users SET is_admin = true WHERE email = 'admin@nexusstream.com';"
```

**Tempo:** 2 horas

---

## Fase 3: ALTO RISCO - Semana 1-2 (15 horas)

### 3.1 Aumentar TTL de Cache
**Status:** 🟠 ALTO (Performance)

**Arquivo:** `backend/app/routers/media.py`

```python
# Catálogo (muda pouco)
set_json(cache_key, payload, ttl_seconds=3600)  # 1 hora, era 120s

# Search (pode mudar frequentemente)
set_json(cache_key, payload, ttl_seconds=300)  # 5 min, era 60s

# Genre
set_json(cache_key, payload, ttl_seconds=3600)  # 1 hora
```

**Teste:** Verificar hit ratio em Prometheus
```bash
rate(cache_hits_total[5m]) / rate(cache_requests_total[5m])
# Meta: > 85%
```

**Tempo:** 1 hora

---

### 3.2 Configurar Connection Pooling
**Status:** 🟠 ALTO (Performance)

**Arquivo:** `backend/app/database.py`

Ver template SECURITY_FIXES_TEMPLATES.md seção "7. Connection Pooling"

```bash
# Teste antes/depois
# Monitor: SELECT count(*) FROM pg_stat_activity;
```

**Tempo:** 1 hora

---

### 3.3 Pinnar Versões em requirements.txt
**Status:** 🟠 ALTO (Infraestrutura)

```bash
cd backend

# 1. Gerar requirements com versões atuais
pip freeze > requirements.txt.new

# 2. Validar e copiar apenas essenciais
# Manter só os packages do arquivo original

# 3. Testar em novo venv
python3 -m venv test_venv
source test_venv/bin/activate
pip install -r requirements.txt.new
python -c "import fastapi; print(fastapi.__version__)"

# 4. Usar o novo
mv requirements.txt.new requirements.txt
```

Ver template SECURITY_FIXES_TEMPLATES.md seção "10. Requirements.txt"

**Tempo:** 2 horas (com testes)

---

### 3.4 Multi-Stage Dockerfile
**Status:** 🟠 ALTO (Infraestrutura)

**Arquivo:** `backend/Dockerfile.prod`

Ver template SECURITY_FIXES_TEMPLATES.md seção "8. Multi-Stage Dockerfile"

```bash
# 1. Criar Dockerfile.prod
cp backend/Dockerfile backend/Dockerfile.prod
# Editar com template

# 2. Build e teste
docker build -f backend/Dockerfile.prod -t nexus-backend-prod:latest backend/

# 3. Comparar tamanho
docker images | grep nexus-backend

# 4. Atualizar docker-compose.yml
# mudar: build: context: ./backend
# para: build:
#         context: ./backend
#         dockerfile: Dockerfile.prod
```

**Tempo:** 3 horas (com testes)

---

### 3.5 Docker Compose com Healthchecks
**Status:** 🟠 ALTO (Infraestrutura)

**Arquivo:** `docker-compose.yml`

Ver template SECURITY_FIXES_TEMPLATES.md seção "9. Docker Compose"

```bash
# 1. Atualizar docker-compose.yml com healthchecks

# 2. Testar
docker-compose up -d
docker-compose ps
# Ver STATUS: "Up (healthy)"

# 3. Verificar logs de health
docker-compose logs backend | grep -i health
```

**Tempo:** 2 horas

---

## Fase 4: MÉDIO RISCO - Semana 2 (12 horas)

### 4.1 Adicionar Índices de BD
**Status:** 🟡 MÉDIO

```sql
-- Índices a adicionar
CREATE INDEX idx_profile_user_id ON profiles(user_id);
CREATE INDEX idx_payment_user_id ON payments(user_id);
CREATE INDEX idx_subscription_user_id ON subscriptions(user_id);
CREATE INDEX idx_playback_history_profile_id ON playback_history(profile_id);
CREATE INDEX idx_playback_history_media_id ON playback_history(media_id);
CREATE INDEX idx_user_created_at ON users(created_at);

-- Via alembic
alembic revision --autogenerate -m "Add database indexes"
```

**Tempo:** 2 horas

---

### 4.2 Nginx com Gzip + Headers
**Status:** 🟠 ALTO

**Arquivo:** `nginx/nginx.conf`

Ver template SECURITY_FIXES_TEMPLATES.md seção "11. Nginx"

```bash
# 1. Editar nginx.conf
vim nginx/nginx.conf

# 2. Validar sintaxe
docker run --rm -v /workspaces/Nexus/nginx:/etc/nginx nginx:latest nginx -t

# 3. Recarregar
docker-compose exec nginx nginx -s reload

# 4. Testar gzip
curl -I -H "Accept-Encoding: gzip" http://localhost:80/health
# Ver: Content-Encoding: gzip
```

**Tempo:** 2 horas

---

### 4.3 Implementar UUID Validation
**Status:** 🟡 MÉDIO

**Arquivos:** Todos os routers com `{id: str}`

```python
# ANTES:
def get_profile(profile_id: str, ...):

# DEPOIS:
from uuid import UUID
def get_profile(profile_id: UUID, ...):
```

**Routers a atualizar:**
- profiles.py
- ratings.py
- watchlist.py
- subscriptions.py

**Tempo:** 3 horas

---

### 4.4 Audit Logging
**Status:** 🟡 MÉDIO

**Arquivo:** `backend/app/middlewares/audit.py` (novo)

Ver template SECURITY_FIXES_TEMPLATES.md seção "13. Audit Logging"

```bash
# 1. Criar arquivo
touch backend/app/middlewares/audit.py
# Adicionar template

# 2. Integrar em main.py
# app.add_middleware(audit_middleware)

# 3. Verificar logs
tail -f /var/log/nexus/audit.log
```

**Tempo:** 2 horas

---

### 4.5 CSRF Protection (Opcional para API)
**Status:** 🟡 MÉDIO

Para APIs REST puras, CSRF é menos crítico, mas:

```bash
pip install fastapi-csrf-protect

# Em main.py
from fastapi_csrf_protect import CsrfProtect
# ... configuração
```

**Tempo:** 2 horas (se necessário)

---

## Fase 5: TESTES E VALIDAÇÃO (8 horas)

### 5.1 Testes de Segurança
```bash
# 1. SQL Injection
curl -X GET "http://localhost:8000/media/search?q='; DROP TABLE users; --"
# Esperado: Apenas resultado de search, sem erro SQL

# 2. XSS
curl -X GET "http://localhost:8000/media/search?q=<script>alert('xss')</script>"
# Esperado: String escapada

# 3. Rate Limiting
for i in {1..10}; do 
  curl -X POST http://localhost:8000/auth/login -d '{}' -H "Content-Type: application/json"
  echo "Request $i"
done
# Esperado: 429 após 5

# 4. CORS
curl -X OPTIONS http://localhost:8000/health \
  -H "Origin: https://malicious.com" \
  -H "Access-Control-Request-Method: POST"
# Esperado: Sem header Access-Control-Allow-Origin

# 5. Password Strength
curl -X POST http://localhost:8000/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","username":"test","password":"123"}'
# Esperado: 422 Unprocessable Entity
```

### 5.2 Load Testing
```bash
# Instalar locust
pip install locust

# Criar arquivo locustfile.py
cat > backend/locustfile.py << 'EOF'
from locust import HttpUser, task, between

class NexusUser(HttpUser):
    wait_time = between(1, 5)
    
    @task
    def get_health(self):
        self.client.get("/health")
    
    @task
    def get_media(self):
        self.client.get("/media/")

if __name__ == "__main__":
    import subprocess
    subprocess.run(["locust", "-f", "locustfile.py"])
EOF

# Executar
locust -f backend/locustfile.py -u 100 -r 10 --host=http://localhost:8000
```

### 5.3 Performance Benchmark
```bash
# Antes vs Depois

# Query time
time psql postgresql://postgres:postgres@localhost:5432/nexus \
  -c "SELECT COUNT(*) FROM users;"

# Response time
time curl -s http://localhost:8000/media/ | head -c 1000

# Cache hit rate
curl http://localhost:8000/metrics | grep cache
```

---

## Checklist de Validação Final

### Segurança ✓
- [ ] Credenciais rotacionadas
- [ ] Webhook MercadoPago validando HMAC
- [ ] CORS configurado
- [ ] Rate limiting funcionando
- [ ] Validações em schemas
- [ ] Sem print statements expostos
- [ ] Admin via DB field
- [ ] Sem SQL injection
- [ ] Logs sem dados sensíveis

### Performance ✓
- [ ] Pagination em todos endpoints
- [ ] Cache com TTL adequado
- [ ] Connection pooling
- [ ] Índices em BD
- [ ] Gzip no Nginx
- [ ] Response time < 200ms (P95)
- [ ] Memory stable
- [ ] CPU < 50%

### Infraestrutura ✓
- [ ] Requirements com versões
- [ ] Multi-stage Dockerfile
- [ ] Healthchecks todos containers
- [ ] Restart policies
- [ ] Resource limits
- [ ] Logs em volume
- [ ] Nginx timeouts
- [ ] SSL/TLS configurado

---

## Rollback Plan

Se algo der errado:

```bash
# 1. Reverter deploy
git checkout HEAD~1
docker-compose down
docker-compose build --no-cache
docker-compose up -d

# 2. Reverter BD
alembic downgrade -1

# 3. Reverter .env
cp .env.backup .env

# 4. Verificar status
docker-compose ps
docker-compose logs -f backend
```

---

## Métricas de Sucesso

| Métrica | Antes | Meta |
|---------|-------|------|
| Segurança OWASP | 30% | 80% |
| Response Time P95 | >500ms | <200ms |
| Cache Hit Ratio | 20% | >85% |
| Uptime | 95% | 99.9% |
| Failed Requests | 2% | <0.1% |

---

## Timeline

| Fase | Duração | Início | Fim |
|------|---------|--------|-----|
| 1. Emergência | 4h | Hoje | +4h |
| 2. Crítica | 20h | Amanhã | +1.5 dias |
| 3. Alto Risco | 15h | +1.5d | +3 dias |
| 4. Médio Risco | 12h | +3d | +4.5 dias |
| 5. Testes | 8h | +4.5d | +5.5 dias |
| **Total** | **59h** | **Hoje** | **+5.5 dias** |

**Recomendação:** Distribuir trabalho entre 2-3 dev com code review em cada PR.

---

## Responsabilidades

| Pessoa | Fase | Tarefas |
|--------|------|---------|
| DevOps | 1, 3, 4 | Infra, Docker, Nginx |
| Backend Dev 1 | 2, 4 | Segurança, Schemas, Validações |
| Backend Dev 2 | 2, 3 | Performance, Caching, BD |
| QA/Security | 5 | Testes, Validação |

---

**Aprovação Necessária:**
- [ ] Tech Lead
- [ ] Security Officer
- [ ] DevOps Lead
- [ ] Product Manager

**Status:** 🟡 PENDENTE APROVAÇÃO
