# TODO - Remediação da Auditoria NexusTwos (Nov/2026)

Plano de remediação baseado em `AUDITORIA_NOVEMBRO_2026.md` (54 problemas, risco 🔴 CRÍTICO).

---

## FASE 1: EMERGÊNCIA — Segurança (1-2 dias) 🔴

### Credenciais & Git
- [ ] Rotacionar credenciais comprometidas (DB, SECRET_KEY, MercadoPago, Redis)
- [ ] `git rm --cached backend/.env nexus_mobile/.env.local`
- [ ] Corrigir `.gitignore` para cobrir `*.env`

### Broken Access Control / IDOR (Backend)
- [x] `backend/app/routers/profiles.py` — user_id vinculado ao usuário autenticado; list/get protegidos
- [x] `backend/app/routers/history.py` — auth + ownership via join com Profile (syntax error corrigido)
- [x] `backend/app/routers/watchlist.py` — auth + ownership
- [x] `backend/app/routers/ratings.py` — auth + ownership; GET público mantido
- [x] `backend/app/routers/episodes.py` — create protegido (admin); GET público (catálogo)
- [x] `backend/app/routers/subscriptions.py` — auth + vínculo ao usuário; list/delete filtrados
- [x] `backend/app/routers/queue_jobs.py` — todos os endpoints protegidos com `get_admin_user`

### Schemas & Webhooks
- [x] `backend/app/schemas.py` — `RatingCreate.stars` ge=1, le=5
- [x] `backend/app/routers/webhooks.py` — Stripe hardening (exige secret + assinatura + idempotência)

### Controle Parental (novo módulo — complete)
- [x] `backend/app/models.py` — modelos ParentalControlSettings, ParentalPin, BlockedChannel, AccessAttempt, ContentRating
- [x] `backend/app/schemas.py` — schemas de controle parental
- [x] `backend/app/services/parental_control_service.py` — serviço completo
- [x] `backend/app/routers/parental_control.py` — router completo (import ParentalControlSettings corrigido)
- [x] `backend/app/main.py` — router registrado
- [x] `backend/app/routers/media.py` — gating no play/stream
- [x] `backend/app/routers/live_tv.py` — gating no stream de canais
- [x] Mobile Flutter — modelos, service, provider, dialogs, screens
- [x] Admin Panel React — endpoints, página, rotas, Channels.jsx

### Verificação
- [x] `python -m py_compile` em todos os routers/serviços/schemas modificados — OK ✅
- [x] `npm run build` no admin-panel-nexus — OK ✅
- [ ] `flutter analyze` no nexus_mobile — BLOCKED (Flutter SDK não disponível; código Dart verificado manualmente)

---

## FASE 2: CRÍTICA — Backend/API (3-5 dias) 🟠
- [ ] Paginação SQL real em `admin/users` (evitar `.all()` em memória)
- [ ] `SUM()` SQL no lugar de soma em Python em `admin/payments` e `payment_stats`
- [ ] Configurar `pool_size`/`max_overflow` no `create_engine`
- [ ] Tipar parâmetros de ID como `UUID` (history, ratings, watchlist, profiles, subscriptions)
- [ ] Remover exposição de `str(e)` em handlers de erro (ex: notifications.py)
- [ ] Pinning de versões no `requirements.txt`

---

## FASE 3: MOBILE Flutter (2-3 dias) 🟠
- [x] Corrigir `player_screen.dart` — remover `profileId: 'demo-profile'` hardcoded
- [x] Usar `profile_id` UUID real (não email) no player
- [x] `player_service.dart` — enviar token de autenticação (Bearer) nas chamadas de history
- [x] `player_screen.dart` — propagar token para o PlayerService
- [ ] Token interceptor com refresh automático no `MediaService`
- [ ] API URL via `--dart-define`/env (remover hardcode `10.0.2.2:8000`)
- [ ] Cancelamento correto de downloads

---

## FASE 4: ADMIN PANEL React (2-3 dias) 🟠
- [ ] Migrar token para cookie httpOnly (mitigar XSS)
- [x] Remover credenciais de demo exibidas no `LoginPage.jsx`
- [ ] Alinhar `endpoints.js` com endpoints reais do backend
- [ ] Validar expiração de sessão no `App.jsx`

---

## FASE 5: INFRAESTRUTURA (2-3 dias) 🟠
- [ ] Remover defaults/secrets perigosos do `docker-compose.yml`
- [ ] Corrigir `postgres_exporter` credencial hardcoded
- [ ] Adicionar gzip + `client_max_body_size` no nginx
- [ ] Corrigir proxy do admin panel no nginx
- [ ] Resource limits, network isolation
- [ ] Migration para RBAC via `role` no BD (remover ADMIN_EMAILS hardcoded)
- [ ] Uvicorn com workers
