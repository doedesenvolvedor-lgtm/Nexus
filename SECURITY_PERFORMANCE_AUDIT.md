# Auditoria de Segurança e Performance - Nexus VPS

**Data da Auditoria:** 17/07/2026  
**Ambiente:** Ubuntu 24.04.4 LTS - VPS  
**Escopo:** Backend FastAPI, Banco de Dados, Infraestrutura

---

## 📊 RESUMO EXECUTIVO

| Categoria | Crítico | Alto | Médio | Total |
|-----------|---------|------|-------|-------|
| **Segurança** | 5 | 8 | 7 | **20** |
| **Performance** | 1 | 3 | 6 | **10** |
| **Infraestrutura** | 2 | 4 | 3 | **9** |

**Risco Geral: 🔴 CRÍTICO**

---

# 🔐 PROBLEMAS DE SEGURANÇA

## 🔴 CRÍTICOS (5)

### 1. **Credenciais Hardcoded em Arquivo .env**
- **Localização:** [backend/.env](backend/.env#L1)
- **Problema:** 
  ```
  DATABASE_URL=postgresql://postgres:postgres@127.0.0.1:5432/nexus
  SECRET_KEY=TroquePorUmaChaveGrandeEAleatoria
  MERCADOPAGO_PUBLIC_KEY=TEST-2c6f6311-ce1c-468e-8016-be0a81d024cb
  MERCADOPAGO_ACCESS_TOKEN=TEST-4194841891487384-...
  ```
- **Risco:** Exposição de credenciais em repositório Git, backup ou logs
- **Impacto:** Acesso não autorizado ao banco, API keys comprometidas
- **Solução:**
  - Usar secrets manager (AWS Secrets Manager, HashiCorp Vault)
  - .env deve estar em .gitignore (verificar se já está)
  - Rotacionar IMEDIATAMENTE todas as credenciais
  - Usar variáveis de ambiente criptografadas em produção

### 2. **Webhook MercadoPago Vazio - Sem Validação de Assinatura**
- **Localização:** [backend/app/routers/webhooks.py](backend/app/routers/webhooks.py#L1)
- **Problema:**
  ```python
  @router.post("/")
  async def webhook(payload: dict):
      # Validar assinatura do provedor
      # Atualizar status da assinatura
      return {"status": "ok"}
  ```
- **Risco:** Qualquer pessoa pode enviar webhooks fraudulentos, alterar status de pagamentos
- **Impacto:** CRÍTICO - Acesso gratuito aos planos, perda de receita
- **Solução:**
  - Implementar validação de assinatura HMAC com MercadoPago
  - Verificar hash do payload com chave secreta
  - Implementar idempotência (evitar duplicação)
  - Registrar todas as transações em audit log

### 3. **Admin Emails Hardcoded em Lista**
- **Localização:** [backend/app/security_admin.py#L8-L11](backend/app/security_admin.py#L8-L11)
- **Problema:**
  ```python
  ADMIN_EMAILS = [
      "admin@nexus.com",
      "admin@example.com",
  ]
  ```
- **Risco:** Qualquer mudança de permissão requer redeploy, fácil de bypassar
- **Impacto:** Privilégios administrativos não gerenciavelmente
- **Solução:**
  - Adicionar campo `is_admin: bool` na tabela `users`
  - Gerenciar permissões via banco de dados
  - Usar Role-Based Access Control (RBAC)

### 4. **Sem Validação de Força de Senha e Reset Password**
- **Localização:** [backend/app/schemas.py#L11](backend/app/schemas.py#L11), [backend/app/routers/auth.py#L153](backend/app/routers/auth.py#L153)
- **Problema:** 
  - Senha não tem requisitos de complexidade
  - Falta validação de comprimento mínimo
  - Reset password usa token simples sem validação adicional
- **Risco:** Senhas fracas, força bruta no reset
- **Solução:**
  ```python
  # No schemas.py
  from pydantic import Field
  
  class UserCreate(BaseModel):
      password: str = Field(
          min_length=12,
          regex=r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[@$!%*?&])',
          description="Mín 12 chars, 1 maiúscula, 1 minúscula, 1 dígito, 1 especial"
      )
  ```

### 5. **Sem CORS Configurado - Risco de Acesso Inadequado**
- **Localização:** [backend/app/main.py](backend/app/main.py#L1) - Falta implementação
- **Problema:** Sem configuração explícita, CORS padrão pode permitir qualquer origem
- **Risco:** XSS, CSRF, Acesso não autorizado de frontends maliciosos
- **Solução:**
  ```python
  from fastapi.middleware.cors import CORSMiddleware
  
  app.add_middleware(
      CORSMiddleware,
      allow_origins=["https://nexusstream.com", "https://app.nexusstream.com"],
      allow_credentials=True,
      allow_methods=["GET", "POST", "PUT", "DELETE"],
      allow_headers=["Authorization", "Content-Type"],
      max_age=3600,
  )
  ```

---

## 🟠 ALTO RISCO (8)

### 6. **Sem Rate Limiting - DDoS e Brute Force Vulnerável**
- **Localização:** Todos os routers - [backend/app/routers/](backend/app/routers/)
- **Problema:** Sem proteção contra múltiplas requisições
- **Risco:** Ataque de força bruta em login, DDoS
- **Solução:**
  ```python
  from slowapi import Limiter
  from slowapi.util import get_remote_address
  
  limiter = Limiter(key_func=get_remote_address)
  app.state.limiter = limiter
  
  @limiter.limit("5/minute")  # 5 requisições por minuto
  @router.post("/login")
  def login(...): ...
  ```

### 7. **Perfil Criado com ID Hardcoded**
- **Localização:** [backend/app/routers/profiles.py#L12-L17](backend/app/routers/profiles.py#L12-L17)
- **Problema:**
  ```python
  new_profile = Profile(
      user_id="00000000-0000-0000-0000-000000000000",  # BUG!
  )
  ```
- **Risco:** Todos os perfis criados vão para usuário fantasma
- **Solução:** Usar `get_current_user` da dependência

### 8. **Falta Validação de Entrada em Schemas**
- **Localização:** [backend/app/schemas.py](backend/app/schemas.py#L1)
- **Problema:** Campos sem `min_length`, `max_length`, padrões de regex
  ```python
  class UserCreate(BaseModel):
      username: Optional[str] = None  # Sem validação!
      password: str  # Sem validação!
  ```
- **Risco:** Injeção de dados maliciosos, Buffer overflow
- **Solução:** Adicionar Field validators a todos os schemas

### 9. **Exposição de Detalhes de Erro em Exceções**
- **Localização:** [backend/app/routers/payments.py#L80](backend/app/routers/payments.py#L80)
- **Problema:**
  ```python
  except Exception as e:
      raise HTTPException(status_code=400, detail=str(e))
  ```
- **Risco:** Exposição de stack trace, informações internas do sistema
- **Solução:**
  ```python
  except Exception as e:
      logger.error(f"Payment error: {e}", exc_info=True)
      raise HTTPException(status_code=400, detail="Erro ao processar pagamento")
  ```

### 10. **Sem Proteção HTTPS Completa**
- **Localização:** [nginx/nginx.conf#L29-L45](nginx/nginx.conf#L29-L45)
- **Problema:** Alguns domínios podem estar sem HTTPS redirect correto
- **Risco:** Man-in-the-middle attacks
- **Solução:** Implementar HSTS header:
  ```nginx
  add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
  ```

### 11. **Sem Controle de Acesso em Endpoints Admin**
- **Localização:** [backend/app/routers/admin.py#L17](backend/app/routers/admin.py#L17)
- **Problema:** Admin pode acessar/modificar dados de qualquer usuário
- **Risco:** Escalação de privilégios, manipulação de dados
- **Solução:** Implementar:
  - Validação de ownership (usuário só vê seus dados)
  - Audit log de todas as ações admin
  - Soft deletes ao invés de hard deletes

### 12. **Sem Proteção contra Força Bruta em API Pública**
- **Localização:** [backend/app/routers/media.py#L33-L39](backend/app/routers/media.py#L33-L39)
- **Problema:** Sem rate limiting em endpoints públicos
- **Risco:** Enumeração de conteúdo, coleta de dados
- **Solução:** Implementar rate limiting progressivo

### 13. **Passwords Armazenados em Texto em Reset**
- **Localização:** [backend/app/services/cache_service.py](backend/app/services/cache_service.py)
- **Problema:** Reset token e user_id podem estar expostos em Redis não seguro
- **Risco:** Acesso à informação de usuário se Redis for comprometido
- **Solução:**
  - Usar Redis com autenticação
  - Criptografar dados sensíveis em cache
  - Usar TTL curto (já faz 30min, OK)

---

## 🟡 MÉDIO RISCO (7)

### 14. **Sem Índices de Banco de Dados Explícitos**
- **Localização:** [backend/app/models.py](backend/app/models.py#L16)
- **Problema:** Apenas email e username têm índices
- **Risco:** Queries lentas em tabelas grandes
- **Solução:** Adicionar índices para:
  - `user_id` em `profiles`, `payments`, `subscriptions`
  - `profile_id` em `playback_history`
  - `media_id` em queries frequentes
  - `created_at` para ordenação

### 15. **Sem Validação de UUID em Routers**
- **Localização:** [backend/app/routers/profiles.py#L28](backend/app/routers/profiles.py#L28)
- **Problema:**
  ```python
  def get_profile(profile_id: str, ...):  # str ao invés de UUID
  ```
- **Risco:** Validação inadequada, possível injeção
- **Solução:** Usar `UUID` como tipo:
  ```python
  from uuid import UUID
  def get_profile(profile_id: UUID, ...):
  ```

### 16. **Não Há Proteção contra Time-Based Attacks em Senha**
- **Localização:** [backend/app/security.py#L13-L15](backend/app/security.py#L13-L15)
- **Problema:** `verify_password` pode ter timing diferente
- **Risco:** Ataques de timing podem revelar padrões
- **Solução:** Já usa bcrypt (OK), mas garantir constante time comparison

### 17. **Sem Proteção de CSRF em Formulários**
- **Localização:** Todos os POST endpoints
- **Problema:** Sem CSRF tokens
- **Risco:** Ataques cross-site request forgery
- **Solução:**
  ```python
  from fastapi_csrf_protect import CsrfProtect
  ```

### 18. **Logs Expõem Informações Sensíveis**
- **Localização:** [backend/app/logging_config.py#L62-L71](backend/app/logging_config.py#L62-L71)
- **Problema:** Logs DEBUG podem conter dados de usuário
- **Risco:** Vazamento de informações em /var/log/nexus
- **Solução:** 
  - Filtrar campos sensíveis em logs
  - Usar log levels apropriados por ambiente
  - Criptografar logs em repouso

### 19. **Sem Proteção de Informações Pessoais (PII)**
- **Localização:** Todos os schemas que retornam user data
- **Problema:** Sem masking de dados sensíveis em respostas
- **Risco:** Vazamento de emails, nomes em respostas de erro
- **Solução:** Implementar schema com exclusão de campos sensíveis

### 20. **Sem Versionamento de API**
- **Localização:** [backend/app/main.py#L17](backend/app/main.py#L17)
- **Problema:** `version="1.0"` sem versioning de endpoints
- **Risco:** Quebra de compatibilidade, mudanças inseguras
- **Solução:** Implementar versioning de API (`/v1/`, `/v2/`)

---

# ⚡ PROBLEMAS DE PERFORMANCE

## 🔴 CRÍTICO (1)

### 1. **Sem Pagination em Queries de Listagem**
- **Localização:** 
  - [backend/app/routers/admin.py#L64](backend/app/routers/admin.py#L64) - `db.query(User).all()`
  - [backend/app/routers/subscriptions.py#L19](backend/app/routers/subscriptions.py#L19) - `db.query(Subscription).all()`
- **Problema:** 
  ```python
  @router.get("/users")
  def users(db: Session = Depends(get_db)):
      return db.query(User).all()  # Carrega TODOS os usuários!
  ```
- **Risco:** Out of Memory, Timeout com crescimento de dados
- **Impacto:** Sistema inteiro pode travar com 100k+ usuários
- **Solução:**
  ```python
  @router.get("/users")
  def users(
      skip: int = Query(0, ge=0),
      limit: int = Query(10, ge=1, le=100),
      db: Session = Depends(get_db)
  ):
      return db.query(User).offset(skip).limit(limit).all()
  ```

---

## 🟠 ALTO RISCO (3)

### 2. **Sem Caching Eficiente - TTL Muito Curto**
- **Localização:** [backend/app/routers/media.py#L20-L30](backend/app/routers/media.py#L20-L30)
- **Problema:**
  ```python
  set_json(cache_key, payload, ttl_seconds=120)  # 2 minutos
  ```
- **Risco:** Hit rate baixo, muitas queries ao BD
- **Solução:** Aumentar TTL por tipo de dado:
  - Catálogo: 3600s (1h)
  - Search: 300s (5min)
  - User-specific: 60s

### 3. **Sem Connection Pooling Explícito**
- **Localização:** [backend/app/database.py#L4-L6](backend/app/database.py#L4-L6)
- **Problema:**
  ```python
  engine = create_engine(DATABASE_URL)  # Pool padrão: 5 conexões
  ```
- **Risco:** Limite de conexões atingido com múltiplos workers
- **Solução:**
  ```python
  engine = create_engine(
      DATABASE_URL,
      pool_size=20,
      max_overflow=10,
      pool_recycle=3600,
      pool_pre_ping=True,
  )
  ```

### 4. **Sem Gzip/Compression no Nginx**
- **Localização:** [nginx/nginx.conf](nginx/nginx.conf#L1)
- **Problema:** Respostas JSON não comprimidas
- **Risco:** Transferência 5-10x maior, latência aumentada
- **Solução:**
  ```nginx
  gzip on;
  gzip_types application/json text/css text/javascript;
  gzip_min_length 1000;
  ```

---

## 🟡 MÉDIO RISCO (6)

### 5. **N+1 Query Problem em Relacionamentos**
- **Localização:** [backend/app/routers/admin.py#L25-L32](backend/app/routers/admin.py#L25-L32)
- **Problema:** 
  ```python
  @router.get("/dashboard")
  def dashboard(db: Session = Depends(get_db)):
      users = db.query(User).count()  # 1 query
      profiles = db.query(Profile).count()  # 2 query
      media = db.query(MediaContent).count()  # 3 query
  ```
- **Risco:** Com 5+ queries, demora cresce exponencialmente
- **Solução:** Usar batch queries ou view no BD

### 6. **Sem Eager Loading de Relacionamentos**
- **Localização:** Todos os relacionamentos SQLAlchemy
- **Problema:** Lazy loading padrão dispara queries extras
- **Risco:** 1 query para usuário + 1 para cada profile
- **Solução:**
  ```python
  from sqlalchemy.orm import joinedload
  
  users = db.query(User).options(
      joinedload(User.profiles),
      joinedload(User.subscriptions)
  ).all()
  ```

### 7. **Logging em DEBUG Level em Produção**
- **Localização:** [backend/app/logging_config.py#L33, #69](backend/app/logging_config.py#L33)
- **Problema:**
  ```python
  "level": "DEBUG",  # DEBUG em produção = mais lento
  ```
- **Risco:** I/O disk intenso, CPU usage alto
- **Solução:** 
  ```python
  LOG_LEVEL = os.getenv("LOG_LEVEL", "INFO")  # INFO em prod
  ```

### 8. **Sem Limit de Tamanho de Request Body**
- **Localização:** [nginx/nginx.conf](nginx/nginx.conf) - Falta config
- **Problema:** Sem `client_max_body_size`
- **Risco:** Upload de arquivo muito grande = OOM
- **Solução:**
  ```nginx
  client_max_body_size 100M;
  ```

### 9. **Cache Headers Não Otimizados para Static Files**
- **Localização:** [nginx/nginx.conf#L171-L253](nginx/nginx.conf#L171-L253)
- **Problema:** Cache max-age=3600 para assets que mudam raramente
- **Risco:** Clientes sempre fazem revalidação
- **Solução:**
  ```nginx
  location ~* \.(js|css|jpg|png)$ {
      expires 1y;
      add_header Cache-Control "public, immutable";
  }
  ```

### 10. **Sem Timeout de Connection**
- **Localização:** [nginx/nginx.conf](nginx/nginx.conf)
- **Problema:** Sem `proxy_connect_timeout`, `proxy_read_timeout`
- **Risco:** Conexões presas indefinidamente
- **Solução:**
  ```nginx
  proxy_connect_timeout 10s;
  proxy_read_timeout 30s;
  ```

---

# 🏗️ PROBLEMAS DE INFRAESTRUTURA

## 🔴 CRÍTICO (2)

### 1. **Requirements.txt Sem Pinned Versions**
- **Localização:** [backend/requirements.txt](backend/requirements.txt)
- **Problema:**
  ```
  fastapi
  uvicorn[standard]  # Sem versão! Pode puxar 1.0.0 ou 0.1.0
  ```
- **Risco:** Builds inconsistentes, breaking changes entre deployments
- **Solução:**
  ```
  fastapi==0.104.1
  uvicorn[standard]==0.24.0
  sqlalchemy==2.0.23
  psycopg2-binary==2.9.9
  python-jose[cryptography]==3.3.0
  passlib[bcrypt]==1.7.4
  pydantic==2.4.2
  redis==5.0.1
  ```

### 2. **Uvicorn com Apenas 1 Worker em Produção**
- **Localização:** [backend/Dockerfile#L9](backend/Dockerfile#L9)
- **Problema:**
  ```dockerfile
  CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
  # Sem workers, sem bind para multiple cores
  ```
- **Risco:** CPU sub-utilizado, latência alta
- **Solução:**
  ```dockerfile
  CMD ["uvicorn", "app.main:app", \
       "--host", "0.0.0.0", \
       "--port", "8000", \
       "--workers", "4", \
       "--loop", "uvloop"]  # Mais rápido que asyncio
  ```

---

## 🟠 ALTO RISCO (4)

### 3. **Docker Dockerfile Sem Multi-Stage Build**
- **Localização:** [backend/Dockerfile](backend/Dockerfile)
- **Problema:**
  ```dockerfile
  FROM python:3.12-slim
  COPY requirements.txt ./
  RUN pip install --no-cache-dir -r requirements.txt
  COPY . .
  ```
- **Risco:** Imagem final contém compiladores, aumenta tamanho e superfície de ataque
- **Tamanho da imagem:** ~800MB → ~300MB com multi-stage
- **Solução:**
  ```dockerfile
  FROM python:3.12-slim as builder
  WORKDIR /app
  COPY requirements.txt ./
  RUN pip install --no-cache-dir --user -r requirements.txt
  
  FROM python:3.12-slim
  COPY --from=builder /root/.local /root/.local
  COPY app ./app
  ENV PATH=/root/.local/bin:$PATH
  CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "4"]
  ```

### 4. **Sem Health Checks no Docker Compose**
- **Localização:** [docker-compose.yml](docker-compose.yml#L31) - Backend sem healthcheck
- **Problema:**
  ```yaml
  backend:
      build: ...
      # Falta healthcheck!
  ```
- **Risco:** Container pode estar "up" mas não respondendo
- **Solução:**
  ```yaml
  backend:
      build: ...
      healthcheck:
          test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
          interval: 10s
          timeout: 5s
          retries: 3
  ```

### 5. **Sem Restart Policy no Backend**
- **Localização:** [docker-compose.yml#L31](docker-compose.yml#L31)
- **Problema:**
  ```yaml
  backend:
      build: ...
      # Falta restart: always
  ```
- **Risco:** Se travar, fica off até restart manual
- **Solução:**
  ```yaml
  backend:
      restart: always
  ```

### 6. **Logs em /var/log/nexus Sem Permissões Garantidas**
- **Localização:** [backend/app/logging_config.py#L7](backend/app/logging_config.py#L7)
- **Problema:**
  ```python
  log_dir = Path("/var/log/nexus")
  log_dir.mkdir(parents=True, exist_ok=True)  # mkdir: Permission denied?
  ```
- **Risco:** Container não tem permissão de escrita em /var/log
- **Solução:**
  - Usar volume para logs
  - Ou usar /app/logs com volume
  - Ou usar stdout/stderr com Docker logging

---

## 🟡 MÉDIO RISCO (3)

### 7. **Sem Secrets Manager para Credenciais**
- **Localização:** [docker-compose.yml#L39-L40](docker-compose.yml#L39-L40)
- **Problema:**
  ```yaml
  environment:
      DATABASE_URL: postgresql://postgres:postgres@postgres:5432/nexus
      # Credenciais em plain text no compose!
  ```
- **Risco:** Acesso ao repositório = acesso a tudo
- **Solução:**
  ```bash
  docker secret create db_password -
  # ou usar .env.production com permissões restritas (600)
  ```

### 8. **Sem Network Isolation no Docker Compose**
- **Localização:** [docker-compose.yml](docker-compose.yml#L1)
- **Problema:** Todos os containers na mesma rede padrão
- **Risco:** Container comprometido pode acessar todos os outros
- **Solução:**
  ```yaml
  networks:
      backend:
          internal: true  # Só fala com outros containers
      external:
          # Só o nginx tem acesso
  ```

### 9. **Sem Limit de Recursos em Containers**
- **Localização:** [docker-compose.yml](docker-compose.yml)
- **Problema:** Sem `mem_limit`, `cpus`
- **Risco:** 1 container pode consumir tudo
- **Solução:**
  ```yaml
  backend:
      mem_limit: 1g
      cpus: 2
      memswap_limit: 1g
  ```

---

# 📋 RECOMENDAÇÕES PRIORITÁRIAS POR IMPACTO

## IMEDIATO (Hoje)

1. ✅ **Rotacionar credenciais** do .env (DB, MercadoPago)
   - Comando: Gerar novas senhas, atualizar ENV vars no VPS

2. ✅ **Implementar validação de webhook MercadoPago**
   - Arquivo: [backend/app/routers/webhooks.py](backend/app/routers/webhooks.py)
   - Tempo: 2-3 horas

3. ✅ **Adicionar CORS configurado**
   - Arquivo: [backend/app/main.py](backend/app/main.py)
   - Tempo: 30 minutos

## CURTO PRAZO (Esta Semana)

4. ✅ **Implementar Rate Limiting**
   - Usar: `slowapi` ou `fastapi-limiter`
   - Tempo: 3-4 horas

5. ✅ **Adicionar Pagination com Limit/Offset**
   - Arquivos: `admin.py`, `subscriptions.py`, `notifications.py`
   - Tempo: 4 horas

6. ✅ **Fix Perfil Hardcoded ID Bug**
   - Arquivo: [backend/app/routers/profiles.py#L12](backend/app/routers/profiles.py#L12)
   - Tempo: 30 minutos

7. ✅ **Adicionar Validações em Schemas**
   - Arquivo: [backend/app/schemas.py](backend/app/schemas.py)
   - Tempo: 5 horas

## MÉDIO PRAZO (Próximas 2 Semanas)

8. ✅ **Pinnar versões em requirements.txt**
   - Arquivo: [backend/requirements.txt](backend/requirements.txt)
   - Tempo: 1 hora (testing)

9. ✅ **Implementar Multi-Stage Dockerfile**
   - Arquivo: [backend/Dockerfile](backend/Dockerfile)
   - Tempo: 2 horas

10. ✅ **Adicionar Connection Pooling**
    - Arquivo: [backend/app/database.py](backend/app/database.py)
    - Tempo: 1 hora

11. ✅ **Adicionar Índices de BD**
    - Arquivo: Alembic migration
    - Tempo: 2 horas

---

# 🛠️ SCRIPT DE QUICK FIXES

```bash
#!/bin/bash
# Security & Performance Quick Fixes

# 1. Backup .env atual
cp backend/.env backend/.env.backup

# 2. Gerar nova SECRET_KEY
python3 -c "import secrets; print('SECRET_KEY=' + secrets.token_urlsafe(32))" >> /tmp/new_secret.txt

# 3. Rotacionar credenciais PostgreSQL
# docker exec postgres_container ALTER ROLE postgres WITH PASSWORD 'new_secure_password';

# 4. Atualizar docker-compose com healthchecks
# docker-compose down
# docker-compose up -d --no-deps --build backend

# 5. Verificar permissões de logs
sudo chown nobody:nogroup /var/log/nexus
chmod 755 /var/log/nexus

# 6. Verificar exposição de credenciais no git
git log --all --source --remotes --oneline -- backend/.env | head -5
```

---

# 📊 CHECKLIST DE IMPLEMENTAÇÃO

## Segurança
- [ ] Implementar CORS configurado
- [ ] Implementar Rate Limiting (5 req/min login, 100 req/min API)
- [ ] Validar webhook MercadoPago com HMAC
- [ ] Adicionar validações em Schemas (min_length, pattern, etc)
- [ ] Implementar Audit Log para ações admin
- [ ] Criptografar dados sensíveis em cache Redis
- [ ] Adicionar HSTS headers
- [ ] Implementar CSRF protection
- [ ] Masking de PII em logs
- [ ] Admin via DB role, não email hardcoded

## Performance
- [ ] Adicionar Pagination com limit/offset
- [ ] Aumentar TTL de cache (especialmente catálogo)
- [ ] Connection pooling com pool_size=20
- [ ] Eager loading de relacionamentos
- [ ] Índices em foreign keys
- [ ] Gzip compression no Nginx
- [ ] Batch queries no dashboard
- [ ] Índice em created_at para ordenação

## Infraestrutura
- [ ] Pin versions em requirements.txt
- [ ] Multi-stage Dockerfile
- [ ] Uvicorn com workers=4 (ou mais)
- [ ] Health checks em todos os containers
- [ ] Restart policies (backend, worker)
- [ ] Resource limits (mem_limit, cpus)
- [ ] Network isolation docker-compose
- [ ] Secrets manager para credentials
- [ ] Logging volume para /var/log/nexus
- [ ] Proxy timeouts no Nginx

---

# 📈 MÉTRICAS A MONITORAR

```yaml
Segurança:
  - Failed login attempts por minuto
  - Admin actions audit log
  - Webhook validation failures
  - Rate limit hits por IP

Performance:
  - Response time P95
  - Database query time
  - Cache hit ratio
  - Memory usage por container
  - CPU usage
  - Active connections

Disponibilidade:
  - Container restart count
  - Health check failures
  - API uptime %
  - Error rate
```

---

# ⚠️ DEPENDÊNCIAS VULNERÁVEIS (Verificar)

```bash
# Executar periodicamente
pip install safety
safety check -r backend/requirements.txt

# Ou usar
pip install bandit
bandit -r backend/app/
```

---

**Próximos Passos:** 
1. Discutir prioridades com time
2. Criar sprints de correção
3. Implementar testes de segurança no CI/CD
4. Configurar SonarQube ou similar
5. Agenda mensal de auditorias

**Revisado:** 17/07/2026  
**Próxima Auditoria:** 17/08/2026
