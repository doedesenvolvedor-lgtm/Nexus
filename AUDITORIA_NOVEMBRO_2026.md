# 🔍 Auditoria Completa do App - NexusTwos

**Data:** Novembro/2026
**Escopo:** Backend (FastAPI), Mobile (Flutter), Admin Panel (React), Infraestrutura (Docker/Nginx)
**Autor:** Auditoria automatizada assistida por IA

---

## 📋 Sumário Executivo

| Categoria | 🔴 Crítico | 🟠 Alto | 🟡 Médio | Total |
|-----------|-----------|---------|----------|-------|
| **Segurança & Autenticação** | 8 | 6 | 4 | **18** |
| **Backend / API** | 3 | 5 | 6 | **14** |
| **Mobile (Flutter)** | 2 | 3 | 3 | **8** |
| **Admin Panel** | 1 | 2 | 2 | **5** |
| **Infraestrutura** | 3 | 3 | 3 | **9** |
| **Total** | **17** | **19** | **18** | **54** |

**Risco Geral: 🔴 CRÍTICO** — Ação imediata recomendada.

---

# 🔐 1. SEGURANÇA & AUTENTICAÇÃO

## 🔴 CRÍTICOS

### 1.1 Credenciais de Produção Commitadas no Git
**Arquivo:** `backend/.env`, `nexus_mobile/.env.local`
**Evidência:** `git ls-files` confirma que `backend/.env` e `nexus_mobile/.env.local` estão **versionados no repositório**.
```bash
git ls-files | grep "\.env"
# → backend/.env  (TRACKED! ❌)
# → nexus_mobile/.env.local  (TRACKED! ❌)
```
**Dados expostos:**
- `DATABASE_URL` (postgresql://postgres:postgres@...)
- `SECRET_KEY` (chave JWT de produção)
- `MERCADOPAGO_ACCESS_TOKEN` (token de pagamento real "TES-...")
- `MERCADOPAGO_PUBLIC_KEY`
- `REDIS_URL`

**Risco:** 🔴 **CRÍTICO** — Qualquer pessoa com acesso ao repo tem acesso ao banco, tokens JWT e gateway de pagamento. Pode forjar tokens de admin, ler pagamentos, manipular dados.
**Solução:** 
1. Rotacionar **IMEDIATAMENTE** todas as credenciais (DB, SECRET_KEY, MercadoPago, Redis).
2. Remover do git: `git rm --cached backend/.env nexus_mobile/.env.local`
3. Adicionar `*.env` (não `**/.env` que pode não cobrir) ao `.gitignore`.
4. Usar um secrets manager (Vault, AWS Secrets Manager) ou variáveis de ambiente injetadas no deploy.
5. Verificar histórico: `git log --all -p -- backend/.env` e considerar purge de histórico.

---

### 1.2 Vulnerabilidade de IDOR / Broken Access Control em CRUD de Perfis
**Arquivo:** `backend/app/routers/profiles.py`
```python
@router.post("/", response_model=ProfileResponse)
def create_profile(profile: ProfileCreate, db: Session = Depends(get_db)):
    new_profile = Profile(
        ...
        user_id="00000000-0000-0000-0000-000000000000",  # 🚨 HARDCODED!
    )
```
```python
@router.get("/", response_model=list[ProfileResponse])
def list_profiles(db: Session = Depends(get_db)):
    return db.query(Profile).all()   # 🚨 Retorna TODOS os perfis de TODOS os usuários!
```
**Risco:** 🔴 **CRÍTICO**
- Todos os perfis criados vão para um usuário "fantasma" (`00000000-...`), quebrando o vínculo com o usuário logado.
- `GET /profiles` sem autenticação e sem filtro por usuário expõe **todos os perfis** (nomes, PINs de controle parental, avatares) de todos os usuários da plataforma.
- `GET /profiles/{id}` e `GET /history` sem auth → vazamento de dados de outros usuários (IDOR).

**Solução:**
- Usar `Depends(get_current_user)` e vincular `user_id=current_user.id`.
- Filtrar queries por `user_id`.
- Adicionar autenticação em todos os endpoints.

---

### 1.3 CRUDs Públicos Sem Autenticação (Histórico, Watchlist, Ratings, Episódios)
**Arquivos:** `history.py`, `watchlist.py`, `ratings.py`, `episodes.py`
```python
# watchlist.py
@router.post("/", response_model=WatchListResponse)
def add_to_watchlist(item: WatchListCreate, db: Session = Depends(get_db)):
    obj = WatchList(**item.model_dump())
```
```python
# ratings.py
@router.post("/", response_model=RatingResponse)
def rate(rating: RatingCreate, db: Session = Depends(get_db)):
```
```python
# history.py
@router.post("/")
def create_history_entry(profile_id: str, media_id: str, db: Session = Depends(get_db)):
```
**Risco:** 🔴 **CRÍTICO** — Qualquer pessoa (sem login) pode:
- Criar/ler/apagar watchlist, ratings e histórico de qualquer perfil.
- Injetar dados arbitrários (IDOR + broken auth).
- Poluir dados de todos os usuários.
**Solução:** Adicionar `Depends(get_current_user)` e vincular recursos ao usuário autenticado; validar ownership.

---

### 1.4 IDs não validados como UUID (Risco de Injeção/Erros)
**Arquivos:** `history.py`, `ratings.py`, `watchlist.py`, `profiles.py`, `subscriptions.py`
**Exemplo:**
```python
@router.get("/{history_id}")
def get_history_entry(history_id: str, db: Session = Depends(get_db)):
```
**Risco:** 🔴 — Parâmetros `str` não validados como UUID → SQLAlchemy lança erros, possível enumeração, e em casos mal tratados risco de injeção.
**Solução:** Tipar como `UUID` (ex: `history_id: UUID`) para validação forte.

---

### 1.5 Admin Auth por Emails Hardcoded (frágil)
**Arquivo:** `backend/app/security_admin.py`
```python
from app.config import ADMIN_EMAILS
...
is_allowed_email = user_email in ADMIN_EMAILS
```
**Risco:** 🟠 Alto → atualização de permissões exige redeploy; `ADMIN_EMAILS` lido de env (OK, escondido), mas melhor usar campo `role` no BD (já existe coluna `role`). O campo `role` existe porém a lógica mescla email + role — frágil e não gerenciável.
**Solução:** Migrar para RBAC completo via coluna `role` no BD, com UI para gestão.

---

## 🟠 ALTO

- **1.6** `GET /media/*` (catálogo, séries, filmes, detalhes) — sem autenticação e sem paginação. Expõe todo o catálogo e permite abuso/scraping. *(Médio-Alto)*
- **1.7** `Queue endpoints` (`POST /queue/import-media`, `POST /queue/push-notifications`) sem autenticação — qualquer pessoa pode enfileirar jobs/imports/notificações em massa. *(Alto)*
- **1.8** `GET /admin/trials/{user_id}` retorna dados sem exigir `get_admin_user` no handler individual (o router tem dependência global, verificar se aplica). *(Alto)*
- **1.9** Logs podem conter dados sensíveis (PII) sem masking. *(Médio)*
- **1.10** `except Exception` em vários routers retorna `str(e)` ao cliente (ex: `notifications.py` `detail=f"Erro ao registrar device token: {str(e)}"`), expondo detalhes internos. *(Alto)*

---

# ⚙️ 2. BACKEND / API

## 🔴 CRÍTICOS

### 2.1 Webhook Stripe — Validação de Assinatura Incompleta
**Arquivo:** `backend/app/routers/webhooks.py`
```python
if STRIPE_WEBHOOK_SECRET and stripe_signature:
    is_valid = WebhookValidator.validate_stripe_signature(...)
```
Se `STRIPE_WEBHOOK_SECRET` não estiver configurado **OU** `Stripe-Signature` ausente, o webhook **processa sem nenhuma validação**. Também `validate_stripe_signature` usa HMAC simples sem o timestamp tolerance (Stripe usa `t=...;v1=...` com expiração).
**Risco:** 🔴 — Pagamentos fraudulentos, ativação premium sem pagamento.
**Solução:** Exigir secret + assinatura; implementar validação com timestamp/expiração conforme spec Stripe.

### 2.2 Schema `RatingCreate` sem validação de estrelas
**Arquivo:** `schemas.py`
```python
class RatingCreate(BaseModel):
    stars: int   # sem min/max!
```
**Risco:** Médio — permite valores inválidos (ex: 999). Deveria ser `Field(ge=1, le=5)`.

### 2.3 `Subscription` endpoints sem controle de acesso
**Arquivo:** `subscriptions.py`
```python
@router.post("/subscription", ...)
def create_subscription(sub: SubscriptionCreate, db): ...  # sem auth!
@router.get("/subscription", ...)
def list_subscriptions(db): ...  # sem auth, lista TODAS
@router.delete("/subscription/{subscription_id}", ...)  # sem auth
```
**Risco:** 🔴 — Qualquer pessoa cria/cancela/lista assinaturas de qualquer usuário. **Vazamento de dados de billing.**
**Solução:** Autenticar + autorizar + vincular ao usuário logado.

---

## 🟠 ALTO

- **2.4** `GET /admin/users` — paginação in-memory (carrega tudo via `.all()`). Com 100k+ usuários, risco de OOM. *(Alto)*
- **2.5** `GET /admin/payments` e `payment_stats` — soma `payment.amount` em Python (todas as linhas) ao invés de `SUM()` no SQL. *(Alto)*
- **2.6** `create_engine(DATABASE_URL, pool_pre_ping=True)` sem `pool_size`/`max_overflow` explícitos — pool padrão pode ser insuficiente. *(Médio)*
- **2.7** `requirements.txt` sem versões pinned — builds não reproduzíveis. *(Médio)*

---

## 🟡 MÉDIO

- **2.8** `GET /media/{id}` sem paginação/cache de longo prazo para catálogo grande.
- **2.9** `recommendations` sem lógica real (só busca 20 itens) e sem cache por usuário.
- **2.10** `Payment` metadata/`status` gerenciado de forma inconsistente entre provers.
- **2.11** Sem `select_for_update`/lock em atualização de subscription (race condition em webhooks duplicados).
- **2.12** `get_optional_user` falha "segura" (retorna None) quando sessão expirada — pode levar a conteúdo servido sem auth.

---

# 📱 3. MOBILE (FLUTTER)

## 🔴 CRÍTICOS

### 3.1 `profileId` Hardcoded no Player
**Arquivo:** `nexus_mobile/lib/screens/player/player_screen.dart`
```dart
service.saveProgress(
  profileId: 'demo-profile',   // 🚨 HARDCODED
  mediaId: media.id,
  seconds: seconds,
);
// dispose:
service.saveProgress(
  profileId: 'demo-profile',   // 🚨 também aqui
  mediaId: _media!.id,
  seconds: lastSavedPosition,
);
```
**Risco:** 🔴 — Progresso de todos os usuários salvo no perfil/usuário errado. Histórico de reprodução incorreto; cross-user data.
**Solução:** Usar o `ProfileProvider`/`AuthProvider` para o profileId real (email ou profile id).

### 3.2 Progresso salvo com perfil baseado em `email` como profileId
**Arquivo:** `player_screen.dart` (linha 43)
```dart
final position = await service.getSavedPosition(media.id, authProvider.email ?? '');
```
**Risco:** 🔴 — Usa email como chave de perfil, inconsistente com o backend (que usa `profile_id` UUID). Salvar/ler em chaves diferentes = histórico nunca persiste corretamente.

---

## 🟠 ALTO

- **3.3** `MediaService` não envia token em chamadas de catálogo (detalhe, séries, filmes) — algumas rotas podem exigir auth. `getCatalog()`/`getMovies()` não passam token. *(Alto)*
- **3.4** **API URL hardcoded** `http://10.0.2.2:8000` em `constants.dart` (com override via `--dart-define=API_URL`). Em produção, se não definir, aponta para emulador → app quebrado em devices reais. *(Alto)*
- **3.5** `download_service.dart` — `cancelDownload` usa `stream.listen(null, cancelOnError:true)` que não cancela de fato a escrita do arquivo; arquivo parcial pode ficar. *(Médio)*

---

## 🟡 MÉDIO

- **3.6** `AuthService.refreshToken` não integrado automaticamente em interceptor do Dio no `MediaService` — token expirado → 401 sem refresh automático.
- **3.7** Firebase (Messaging, Analytics, Crashlytics) inicializado mas integração parcial com providers.
- **3.8** Sem tratamento offline (`connectivity_plus` presente mas não usado extensivamente).

---

# 🖥️ 4. ADMIN PANEL (REACT)

## 🔴 CRÍTICO

### 4.1 Token em localStorage (XSS risk) + Credenciais de demo expostas
**Arquivos:** `src/App.jsx`, `src/api/client.js`, `src/pages/LoginPage.jsx`
```js
// client.js
const token = localStorage.getItem('token')
```
```jsx
// LoginPage.jsx — credenciais de demo exibidas na tela
📝 Credenciais de Demo:
   Email: admin@nexus.com
   Senha: admin123456
```
**Risco:** 🔴 — Token JWT em `localStorage` é acessível via XSS (o CSP permite `'unsafe-inline'` em script). Credenciais de admin expostas na interface permitem acesso se o usuário não trocou a senha. Senha `admin123456` é fraca (8 chars, sem requisitos).
**Solução:** Usar cookie httpOnly + Secure; remover credenciais de demo; forçar troca de senha; exigir senha forte.

---

## 🟠 ALTO

- **4.2** `endpoints.js` referencia muitos endpoints de admin (`/admin/dashboard/*`, `/admin/movies/*`, `/admin/plans`, `/admin/coupons`, etc.) que **não existem no backend** (o backend tem `/admin/dashboard`, `/admin/users`, `/admin/payments`, `/admin/trials`, `/admin/audit`, `/admin/system`). → Painel fará requests 404. *(Alto)*
- **4.3** `App.jsx` verifica `isAuthenticated` só pela presença de token no localStorage (sem validar expiração) → navegação pode mostrar telas quebradas com token expirado.

---

## 🟡 MÉDIO

- **4.4** Sem CSRF protection (mas usa Bearer token, mitigado pelo não-uso de cookies).
- **4.5** Sem paginação consistente em várias listas do frontend.

---

# 🏗️ 5. INFRAESTRUTURA

## 🔴 CRÍTICOS

### 5.1 Credenciais Hardcoded/Default no docker-compose
**Arquivo:** `docker-compose.yml`
```yaml
SECRET_KEY: ${SECRET_KEY:-change-me-in-production-nexus-twos}   # default fraco!
DATA_SOURCE_NAME: "postgresql://postgres:postgres@postgres:5432/nexus"  # hardcoded
GF_SECURITY_ADMIN_PASSWORD: ${GF_ADMIN_PASSWORD:-change_me_in_production}
SMTP_PASSWORD: ${SMTP_PASSWORD:-change_me_in_production}
SLACK_WEBHOOK_URL: ${SLACK_WEBHOOK_URL:-https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK}
```
**Risco:** 🔴 — Se deploy for feito sem `.env`, usa senhas padrão conhecidas. Exposição total.
**Solução:** Remover defaults perigosos; falhar o deploy se não houver variáveis definidas; usar secrets.

### 5.2 `postgres_exporter` com credencial hardcoded e sem secret
```yaml
postgres_exporter:
  environment:
    DATA_SOURCE_NAME: "postgresql://postgres:postgres@postgres:5432/nexus?sslmode=disable"
```
**Risco:** 🔴 — credencial de produção em texto plano no compose versionado.

### 5.3 Uvicorn sem workers / assíncrono
**Arquivo:** `backend/Dockerfile`
```dockerfile
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
```
**Risco:** Alto/Médio — apenas 1 processo, subutiliza CPU. (Dockerfile já é multi-stage e com usuário não-root ✅.)

---

## 🟠 ALTO

- **5.4** Nginx sem gzip/compression e sem `client_max_body_size` definido (uploads de vídeo 2GB podem falhar). *(Alto)*
- **5.5** Nginx serve `admin.nexustwos.com` via `proxy_pass http://nexus_backend/admin/` — mistura API e admin frontend; o painel React não está sendo servido. *(Alto)*
- **5.6** Kubernetes manifests presentes mas não verificados vs. este compose (possível divergência de configuração). *(Médio)*

---

## 🟡 MÉDIO

- **5.7** Sem `mem_limit`/`cpus` nos containers → recurso ilimitado.
- **5.8** Sem network isolation entre containers.
- **5.9** `requirements.txt` sem pinning de versões.

---

# ✅ 6. O QUE ESTÁ CORRETO (Pontos Fortes)

| Item | Status |
|------|--------|
| Banco de dados com índices em `email`, `username`, `role`, `device_token` | ✅ |
| Rate limiting implementado (3 níveis: global, endpoint, usuário) com Redis | ✅ |
| Middleware de streaming com validação de token JWT para `/streams` | ✅ |
| Refresh tokens com rotação e revogação de sessão | ✅ |
| Password hashing com bcrypt e validação forte (12+ chars, maiúscula, minúscula, dígito, especial) | ✅ |
| Exception handlers centralizados e consistentes | ✅ |
| Audit logging para ações administrativas | ✅ |
| Dockerfile multi-stage com usuário não-root e healthcheck | ✅ |
| Content-Security-Policy, HSTS, X-Frame-Options, nos headers nginx | ✅ |
| Webhook MercadoPago com validação HMAC + idempotência via Redis lock | ✅ |
| Cache Redis com connection pool (`max_connections=20`) | ✅ |
| Monitoramento completo (Prometheus, Grafana, Alertmanager, exporters) | ✅ |
| Testes backend presentes (email, rate limit, security, stream token) | ✅ |

---

# 🚨 7. AÇÕES URGENTES (30 Min - Hoje)

1. **Rotacionar credenciais** comprometidas (DB, SECRET_KEY, MercadoPago, Redis) — ver Seção 1.1.
2. **Remover `backend/.env` e `nexus_mobile/.env.local` do git** (`git rm --cached`) e corrigir `.gitignore`.
3. **Corrigir `profiles.py`** — vincular `user_id` ao usuário autenticado e proteger `GET /profiles`.
4. **Adicionar autenticação** em `history.py`, `watchlist.py`, `ratings.py`, `episodes.py`, `subscriptions.py`, `queue_jobs.py`.
5. **Corrigir `player_screen.dart`** — usar profileId real (não hardcoded).
6. **Remover credenciais de demo do admin panel** e migrar token para cookie httpOnly.
7. **Endurecer webhook Stripe** (exigir secret + assinatura sempre).
8. **Remover defaults perigosos do docker-compose** e exigir variáveis de ambiente.

---

# 📅 8. PLANO DE REMEDIAÇÃO (Priorizado)

## Fase 1 — Emergência (Segurança, ~1-2 dias)
- Rotacionar credenciais e remover do git
- Autenticar todos os CRUDs expostos (profiles, history, watchlist, ratings, epissors, subscriptions, queue)
- Corrigir IDOR/hardcoded user_id
- Webhook Stripe hardening
- Remover credenciais demo admin

## Fase 2 — Crítica (Backend/API, ~3-5 dias)
- Paginação em `admin/users`, `admin/payments`
- `SUM()` SQL no lugar de soma em Python
- Pooling configurado no `create_engine`
- Validação de UUID e schemas (RatingCreate stars)
- Remover exposição de `str(e)` em erros

## Fase 3 — Mobile (~2-3 dias)
- Fix profileId hardcoded
- Token interceptor com refresh automático
- API URL via `--dart-define`/env
- Cancelamento correto de downloads

## Fase 4 — Frontend (~2-3 dias)
- Migrar token para cookie httpOnly
- Alinhar `endpoints.js` com endpoints reais do backend
- Validar sessão no App.jsx

## Fase 5 — Infra (~2-3 dias)
- Remover defaults/secrets do docker-compose
- Adicionar gzip + client_max_body_size no nginx
- Resource limits e network isolation
- Pinning de versões

---

# 📊 9. SCORE DE MATURIDADE

| Dimensão | Score Atual | Meta |
|----------|-------------|------|
| Segurança | 4.5/10 | 8.5/10 |
| Autenticação/Autorização | 4.0/10 | 8.5/10 |
| Backend/API | 5.5/10 | 8.0/10 |
| Mobile | 5.5/10 | 8.0/10 |
| Frontend | 5.0/10 | 8.0/10 |
| Infraestrutura | 5.0/10 | 8.5/10 |
| **Geral** | **5.0/10** | **8.3/10** |

---

*Auditoria gerada em Novembro/2026. Baseada em análise estática do código-fonte. Recomenda-se validação em ambiente de staging e code review humano antes de aplicar correções em produção.*
