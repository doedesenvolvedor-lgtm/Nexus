# ⚡ Guia de Testes Completo - Nexus Trial System

## 🎯 Índice Rápido

1. [Setup Inicial](#setup-inicial)
2. [Testes Backend](#testes-backend)
3. [Testes App Mobile](#testes-app-mobile)
4. [Testes Admin](#testes-admin)
5. [Testes E2E](#testes-e2e)
6. [Troubleshooting](#troubleshooting)

---

## 🚀 Setup Inicial

### 1. Banco de Dados

```bash
# Se usar PostgreSQL
psql -U seu_usuario -d nexus_db -f backend/database/002_add_trial_support.sql

# Verificar se as colunas foram criadas
psql -U seu_usuario -d nexus_db -c "\d subscriptions"
```

### 2. Backend

```bash
cd backend

# Instalar dependências
pip install -r requirements.txt

# Rodar servidor
python -m uvicorn app.main:app --reload --port 8000

# Deve aparecer:
# Uvicorn running on http://127.0.0.1:8000
```

### 3. App Mobile

```bash
cd nexus_mobile

# Baixar dependências
flutter pub get

# Rodar app
flutter run

# Para iOS (se aplicável):
# flutter run -d iphone
```

### 4. Admin Panel

```bash
cd admin

# Opção 1: Python SimpleHTTPServer
python -m http.server 8001

# Opção 2: Servir com nginx/apache
# Acessar: http://localhost:8001/dashboard.html

# Ou servir do backend FastAPI
# Acessar: http://localhost:8000/admin/dashboard.html
```

---

## 🧪 Testes Backend

### Teste 1: Registrar Novo Usuário (com Trial)

```bash
curl -X POST http://localhost:8000/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "usuario1@teste.com",
    "username": "usuario1",
    "password": "senha123"
  }'

# Response esperado:
# {
#   "id": "uuid",
#   "email": "usuario1@teste.com",
#   "username": "usuario1",
#   "access_token": "eyJ0eXA...",
#   "token_type": "bearer"
# }

# 💡 Salvar o access_token para próximos testes
export TOKEN="seu-token-aqui"
```

### Teste 2: Verificar Subscription do Usuário

```bash
curl http://localhost:8000/subscriptions/me \
  -H "Authorization: Bearer $TOKEN"

# Response esperado:
# {
#   "id": "uuid",
#   "user_id": "uuid",
#   "plan_type": "Trial",
#   "status": "active",
#   "trial_started_at": "2026-07-13T10:00:00",
#   "trial_ends_at": "2026-07-16T10:00:00",
#   "created_at": "2026-07-13T10:00:00",
#   "updated_at": "2026-07-13T10:00:00"
# }
```

### Teste 3: Verificar Status do Trial

```bash
curl http://localhost:8000/subscriptions/me/trial-status \
  -H "Authorization: Bearer $TOKEN"

# Response esperado:
# {
#   "is_trial": true,
#   "days_remaining": 3,
#   "trial_ends_at": "2026-07-16T10:00:00Z",
#   "plan_type": "Trial"
# }
```

### Teste 4: Fazer Upgrade do Trial

```bash
curl -X POST http://localhost:8000/subscriptions/upgrade-trial \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"new_plan": "Premium"}'

# Response esperado:
# {
#   "message": "Upgrade realizado com sucesso",
#   "plan_type": "Premium",
#   "status": "active"
# }

# Verificar status novamente
curl http://localhost:8000/subscriptions/me/trial-status \
  -H "Authorization: Bearer $TOKEN"
# Agora: "is_trial": false
```

### Teste 5: Verificar Expiração do Trial

```bash
curl -X POST http://localhost:8000/subscriptions/check-trial-expiration \
  -H "Authorization: Bearer $TOKEN"

# Response esperado:
# {
#   "is_expired": false,
#   "message": "Trial ainda ativo",
#   "days_remaining": 3
# }
```

### Teste 6: Obter Perfil do Usuário

```bash
curl http://localhost:8000/auth/me/profile \
  -H "Authorization: Bearer $TOKEN"

# Response esperado:
# {
#   "user": {
#     "id": "uuid",
#     "email": "usuario1@teste.com",
#     "username": "usuario1"
#   },
#   "subscription": {
#     "plan_type": "Trial",
#     "is_premium": true,
#     "days_remaining": 3
#   }
# }
```

---

## 📱 Testes App Mobile

### Teste 1: Login e Verificar Welcome Screen

```
1. Abrir app
2. Toque em "Cadastrar"
3. Preencher:
   - Email: usuario1@teste.com
   - Username: usuario1
   - Senha: senha123
4. Toque "Cadastrar"

Esperado:
✅ TrialWelcomeScreen aparece
✅ "3 DIAS DE PREMIUM GRÁTIS" está visível
✅ Data de término exibida
✅ Botões "COMEÇAR AGORA" e "VER PLANOS" funcionam
```

### Teste 2: Visualizar Status do Trial

```
1. Na TrialWelcomeScreen, toque "COMEÇAR AGORA"
2. Deve ir para home (ou toque no banner)
3. Toque em "Status do Trial" ou no banner

Esperado:
✅ TrialStatusScreen abre
✅ Contador regressivo mostra HH:MM:SS
✅ Atualiza a cada segundo
✅ Mostra dias, horas, minutos restantes
✅ Cards de planos visíveis
```

### Teste 3: Selecionar e Confirmar Plano

```
1. Na TrialStatusScreen (ou toque "VER PLANOS")
2. Clique em um plano (ex: Premium)
3. Toque "Confirmar Seleção"

Esperado:
✅ Plano selecionado (radio button marcado)
✅ Botão "Confirmar" habilitado
✅ (TODO: Integração com Stripe/MercadoPago)
```

### Teste 4: Verificar Notificações

```
Notificações devem ser disparadas em:

1. Dia 2 do trial (2 dias antes do fim)
   Título: "Seu trial termina amanhã!"
   
2. Último dia (2 horas antes do fim)
   Título: "Seu trial termina hoje"
   
3. Expiração
   Título: "Seu trial expirou"

Verificar em: Settings → Notifications
```

### Teste 5: Verificar Persistência

```
1. Fazer login
2. Fechas o app completamente
3. Reabrir app

Esperado:
✅ App mantém login (token salvo)
✅ Trial status é recuperado do localStorage
✅ Não pede login novamente
```

### Teste 6: Testar Deep Link

```
(Em desenvolvimento)

# Abrir app com deep link para trial
adb shell am start -W -a android.intent.action.VIEW -d "nexus://trial-status" com.nexus.app

# Ou para iOS
xcrun simctl openurl booted "nexus://trial-status"

Esperado:
✅ App abre direto na tela de trial
```

---

## 🔧 Testes Admin

### Teste 1: Acessar Login Admin

```
1. Abrir: http://localhost:8001/login.html
   (ou http://localhost:8000/admin/login.html se servindo pelo backend)

2. Preencher:
   - Email: admin@nexus.com
   - Senha: qualquer valor (modo demo)

3. Toque "Entrar"

Esperado:
✅ Redirecionado para dashboard.html
✅ Token salvo em localStorage
✅ Dashboard carrega com dados
```

### Teste 2: Visualizar Analytics

```bash
# Via curl
curl http://localhost:8000/admin/trials/analytics/summary \
  -H "Authorization: Bearer $ADMIN_TOKEN"

# Ou no dashboard:
# Ir para Tab "Analytics"

Esperado:
✅ 6 cards com:
   - Total de usuários
   - Trials ativos
   - Trials expirados
   - Convertidos para premium
   - Taxa de conversão (%)
   - Distribuição de planos
```

### Teste 3: Listar Trials Ativos

```bash
# Via curl (página 1, 10 registros)
curl "http://localhost:8000/admin/trials?skip=0&limit=10&status=active" \
  -H "Authorization: Bearer $ADMIN_TOKEN"

# Ou no dashboard:
# Ir para Tab "Usuários em Trial"
# Selecionar filtro "Ativo"

Esperado:
✅ Tabela com:
   - Email
   - Username
   - Dias restantes (badge)
   - Status
   - Botões: Ver, Estender, Cancelar
```

### Teste 4: Ver Detalhes de um Trial

```bash
# Via curl
USER_ID="seu-user-id"
curl http://localhost:8000/admin/trials/$USER_ID \
  -H "Authorization: Bearer $ADMIN_TOKEN"

# Ou no dashboard:
# Toque "Ver" em qualquer usuário

Esperado:
✅ Modal com:
   - Email, Username, data de criação
   - Status do trial
   - Dias restantes
   - Atividade (perfis criados, reproduções)
   - Botões: Estender, Cancelar
```

### Teste 5: Estender Trial

```bash
# Via curl (+3 dias)
curl -X POST http://localhost:8000/admin/trials/$USER_ID/extend \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"days": 3}'

# Response:
# {
#   "message": "Trial estendido por 3 dias.",
#   "trial_ends_at": "2026-07-19T10:00:00"
# }

# Ou no dashboard:
# Toque "Estender" em um usuário

Esperado:
✅ Trial foi estendido
✅ Novo trial_ends_at é +3 dias
✅ Tabela atualiza mostrando novos dias
```

### Teste 6: Cancelar Trial

```bash
# Via curl
curl -X POST http://localhost:8000/admin/trials/$USER_ID/cancel \
  -H "Authorization: Bearer $ADMIN_TOKEN"

# Response:
# {
#   "message": "Trial cancelado.",
#   "new_plan": "Free"
# }

# Ou no dashboard:
# Toque "Cancelar" em um usuário

Esperado:
✅ Trial foi cancelado
✅ plan_type agora é "Free"
✅ Status muda para "Expirado/Cancelado"
✅ Tabela atualiza
```

### Teste 7: Filtrar Trials

```
No dashboard - Tab "Usuários em Trial":

1. Selecionar Status: "Expirado"
2. Toque "Atualizar"

Esperado:
✅ Tabela mostra apenas trials expirados

3. Digitar um email parcial
4. Toque "Atualizar"

Esperado:
✅ Tabela filtra por email
✅ Paginação reseta para página 1
```

### Teste 8: Testar Paginação

```
No dashboard - Tab "Usuários em Trial":

1. Ter 20+ usuários em trial
2. Tabela mostra 10 por página
3. Toque em "2" na paginação

Esperado:
✅ Mostra registros 11-20
✅ Botão "1" destaca quando volta
✅ Botões "←" e "→" funcionam
```

---

## 🔗 Testes E2E (End-to-End)

### Fluxo Completo: Novo Usuário → Trial → Admin

```
PASSO 1: Cadastro com Trial Automático
├─ curl POST /auth/register (Backend)
│  └─ Response: token + subscription criada
└─ ✅ Esperado: plan_type="Trial", trial_ends_at=+3 dias

PASSO 2: Login no App Mobile
├─ App tira token do Paso 1
├─ Chama GET /subscriptions/me/trial-status
└─ ✅ Esperado: TrialWelcomeScreen aparece

PASSO 3: Verificar Contador
├─ TrialStatusScreen mostra HH:MM:SS
├─ Atualiza a cada segundo
└─ ✅ Esperado: Countdown funciona

PASSO 4: Admin Vê o Usuário
├─ Admin faz login em admin/login.html
├─ Vai para Tab "Usuários em Trial"
├─ Vê o novo usuário na tabela
└─ ✅ Esperado: Email, dias restantes, botões de ação

PASSO 5: Admin Estende Trial
├─ Admin toque "Estender"
├─ Backend faz POST /admin/trials/{id}/extend
└─ ✅ Esperado: trial_ends_at muda para +6 dias total

PASSO 6: App Verifica Novo Status
├─ App chama GET /subscriptions/me/trial-status
├─ Contador agora mostra +3 dias extras
└─ ✅ Esperado: Countdown atualizado em tempo real

PASSO 7: Usuário Faz Upgrade
├─ App chama POST /subscriptions/upgrade-trial
├─ plan_type muda para "Premium"
└─ ✅ Esperado: is_trial=false

PASSO 8: Admin Vê Conversão
├─ Admin Tab "Analytics"
├─ "Convertidos para Premium" += 1
└─ ✅ Esperado: Taxa de conversão aumenta
```

### Fluxo 2: Expiração Natural

```
PASSO 1: Aguardar Expiração
├─ Usuário tinha trial até "2026-07-16 10:00"
├─ Agora é "2026-07-16 10:01"
└─ ✅ Trial expirou

PASSO 2: App Verifica Expiração
├─ GET /subscriptions/me/trial-status
└─ ✅ Esperado: is_trial=false, days_remaining=0

PASSO 3: Notificação Dispara
├─ Notificação: "Seu trial expirou"
└─ ✅ Esperado: Notificação nativa recebida

PASSO 4: Admin Vê Expiração
├─ Tab "Usuários em Trial"
├─ Filtro "Expirado"
├─ Usuário aparece nesta lista
└─ ✅ Esperado: Status mostra "Expirado"
```

---

## 🐛 Troubleshooting

### Problema: "Erro 401 - Unauthorized"

**Causa:** Token inválido ou expirado

**Solução:**
```bash
# 1. Verificar token
echo $TOKEN

# 2. Registrar novo usuário
curl -X POST http://localhost:8000/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"teste@teste.com","username":"teste","password":"123"}'

# 3. Salvar novo token
export TOKEN="novo-token-aqui"

# 4. Tentar novamente
curl http://localhost:8000/subscriptions/me \
  -H "Authorization: Bearer $TOKEN"
```

### Problema: "Erro 403 - Forbidden"

**Causa:** Usuário não tem permissão (não é admin)

**Solução:**
```bash
# 1. Adicionar email à lista de admins
# Editar: backend/app/security_admin.py
# ADMIN_EMAILS = ["admin@nexus.com", "seu-email@teste.com"]

# 2. Fazer login com novo email
# 3. Usar novo token para chamadas admin

# OU para testes: usar admin@nexus.com diretamente
```

### Problema: "Trial_ends_at é NULL"

**Causa:** Migration SQL não foi aplicada

**Solução:**
```bash
# 1. Verificar estrutura
psql -U seu_usuario -d nexus_db -c "\d subscriptions"

# 2. Se não tem colunas, executar migration
psql -U seu_usuario -d nexus_db -f backend/database/002_add_trial_support.sql

# 3. Verificar novamente
psql -U seu_usuario -d nexus_db -c "\d subscriptions"
```

### Problema: "App não mostra TrialWelcomeScreen"

**Causa:** Variável de controle não está setada

**Solução:**
```dart
// Em lib/widgets/trial_check_widget.dart
// Adicionar:
trialProvider.showWelcomeOnFirstTrial = true;
await trialProvider.loadTrialStatus(authToken);
```

### Problema: "Notificações não estão vindo"

**Causa:** Serviço não foi inicializado

**Solução:**
```dart
// Em lib/main.dart, verificar:
await TrialNotificationService.initialize();

// Se ainda não funcionar, verificar permissions:
// Android: Permissions em AndroidManifest.xml
// iOS: Permissions em Info.plist
```

### Problema: "Dashboard está vazio"

**Causa:** Token inválido ou CORS bloqueando

**Solução:**
```javascript
// No console do navegador (F12):
localStorage.getItem('admin_token')

// Se vazio:
localStorage.setItem('admin_token', 'seu-token-aqui');
location.reload();

// Se houver erro CORS no console:
// Adicionar CORS ao backend:
from fastapi.middleware.cors import CORSMiddleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)
```

### Problema: "Contador não atualiza em tempo real"

**Causa:** Timer não foi inicializado

**Solução:**
```dart
// Em lib/screens/trial/trial_status_screen.dart
// Verificar se Timer.periodic está ativo:
_timer = Timer.periodic(Duration(seconds: 1), (_) {
  setState(() {
    _updateCountdown();
  });
});

// Garantir que dispose() cancela timer
@override
void dispose() {
  _timer?.cancel();
  super.dispose();
}
```

---

## 📊 Checklist de Validação

### Backend ✅
- [ ] Registrar novo usuário
- [ ] Verificar subscription criada com trial
- [ ] Testar GET /subscriptions/me/trial-status
- [ ] Testar POST /subscriptions/upgrade-trial
- [ ] Verificar dias_remaining diminui
- [ ] Testar endpoints de admin
- [ ] Verificar autorização de admin

### App Mobile ✅
- [ ] TrialWelcomeScreen aparece ao cadastrar
- [ ] Contador regressivo funciona
- [ ] Notificações são agendadas
- [ ] Token persiste após fechar app
- [ ] Trial banner na home
- [ ] Seleção de planos funciona
- [ ] Deep links (se implementados)

### Admin Panel ✅
- [ ] Login funciona
- [ ] Dashboard carrega analytics
- [ ] Tabela de usuários carrega
- [ ] Filtros funcionam
- [ ] Paginação funciona
- [ ] Modal abre com detalhes
- [ ] Estender trial funciona
- [ ] Cancelar trial funciona
- [ ] Taxa de conversão calcula corretamente

### E2E ✅
- [ ] Usuário novo vê trial automático
- [ ] Admin vê usuário em dashboard
- [ ] Admin pode estender
- [ ] App reflete a extensão
- [ ] Notificações disparam no tempo certo
- [ ] Taxa de conversão aumenta

---

## 📞 Referência Rápida

### Variáveis de Ambiente

```bash
# Backend
export API_URL="http://localhost:8000"
export TOKEN="seu-token-aqui"
export USER_ID="seu-user-id"
export ADMIN_TOKEN="seu-admin-token"

# App Mobile
export APP_API_URL="http://10.0.2.2:8000"  # Android emulator
export APP_API_URL="http://localhost:8000"  # iOS simulator
```

### Comandos Mais Usados

```bash
# Registrar usuário
curl -X POST $API_URL/auth/register -d '...'

# Status do trial
curl $API_URL/subscriptions/me/trial-status -H "Authorization: Bearer $TOKEN"

# Listar trials de admin
curl "$API_URL/admin/trials?skip=0&limit=10&status=active" -H "Authorization: Bearer $ADMIN_TOKEN"

# Estender trial
curl -X POST $API_URL/admin/trials/$USER_ID/extend -H "Authorization: Bearer $ADMIN_TOKEN" -d '{"days":3}'

# Ver logs (opcional)
tail -f backend.log
tail -f app.log
```

---

**Data:** 2026-07-13  
**Status:** ✅ Completo  
**Versão:** 1.0
