# 🎯 Quick Start - Sistema de Trial Nexus

## ⚡ Primeiros Passos

### Backend Setup

```bash
# 1. Aplicar migration (se usando banco real)
psql -U user -d nexus_db -f backend/database/002_add_trial_support.sql

# 2. Reiniciar servidor FastAPI (mudanças já estão no código)
cd backend
python -m uvicorn app.main:app --reload

# 3. Testar endpoint
curl -X POST http://localhost:8000/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "teste@example.com",
    "username": "usuario123",
    "password": "senha123"
  }'
```

### App Mobile Setup

```bash
# 1. Instalar dependências
cd nexus_mobile
flutter pub get

# 2. Atualizar Android Manifest
# Adicionar em android/app/src/main/AndroidManifest.xml:
# <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />

# 3. Rodar app
flutter run

# 4. Ao registrar, trial será criado automaticamente
```

---

## 📱 Flows Principais

### Flow 1: Usuário Novo Vê Welcome Screen

```
1. Abre app
   ↓
2. Toca "Cadastrar"
   ↓
3. POST /auth/register
   → Sistema cria Subscription com trial
   ↓
4. TrialCheck verifica e mostra TrialWelcomeScreen
   ↓
5. Usuário clica "COMEÇAR AGORA"
   ↓
6. Home Screen com TrialBanner (info do trial)
```

### Flow 2: Usuário Clica em "Upgrade"

```
1. User clica TrialBanner ou "VER PLANOS"
   ↓
2. PlansScreen mostra 4 opções
   ↓
3. Seleciona "Premium" (R$ 40/mês)
   ↓
4. POST /subscriptions/upgrade-trial
   → Backend: atualiza Subscription
   ↓
5. App redirecionado para Home (sem trial)
   ↓
6. Acesso premium ativo por 30 dias
```

### Flow 3: Trial Expira

```
1. Contador chega a 0
   ↓
2. POST /subscriptions/check-trial-expiration
   → Backend: Subscription.status = "expired"
   ↓
3. Dialog: "Seu trial expirou"
   ↓
4. User vai para PlansScreen (sem trial)
   ↓
5. Sem acesso a conteúdo premium
```

---

## 🧪 Testing

### Teste 1: Registrar Novo Usuário

```bash
# Registrar
POST http://localhost:8000/auth/register
{
  "email": "novo@test.com",
  "username": "novo_user",
  "password": "senha123"
}

# Resposta esperada
{
  "id": "uuid-user",
  "email": "novo@test.com",
  "username": "novo_user",
  "is_premium": false
}
```

### Teste 2: Verificar Status do Trial

```bash
# Com token do passo anterior
GET http://localhost:8000/subscriptions/me/trial-status
Authorization: Bearer {seu_token}

# Resposta esperada
{
  "is_trial": true,
  "days_remaining": 3,
  "trial_ends_at": "2026-07-16T12:30:45.123456+00:00",
  "plan_type": "Trial"
}
```

### Teste 3: Fazer Upgrade

```bash
POST http://localhost:8000/subscriptions/upgrade-trial
Authorization: Bearer {seu_token}
Content-Type: application/json

{
  "plan": "Premium"
}

# Resposta esperada
{
  "message": "Upgrade para plano Premium realizado com sucesso!",
  "subscription": {
    "id": "uuid-sub",
    "plan": "Premium",
    "plan_type": "Premium",
    "status": "active",
    "trial_started_at": null,
    "trial_ends_at": null
  }
}
```

### Teste 4: Verificar Expiração

```bash
POST http://localhost:8000/subscriptions/check-trial-expiration
Authorization: Bearer {seu_token}

# Se ainda ativo
{
  "message": "Trial ainda ativo.",
  "status": "active"
}

# Se expirado
{
  "message": "Seu trial expirou. Escolha um plano para continuar.",
  "status": "expired"
}
```

---

## 🎮 Testar no App Mobile

### 1. Primeira Execução

```bash
flutter run

# Clique em "Criar Conta"
# Preencha:
#   Email: teste@example.com
#   Username: usuario_teste
#   Senha: senha123

# Você deve ver TrialWelcomeScreen
```

### 2. Testar Contador Regressivo

```dart
// Abra TrialStatusScreen
Navigator.pushNamed(context, '/trial-status');

// Você verá contador atualizado a cada segundo
```

### 3. Testar Notificações

```bash
# Modificar data do device para simular:
# - Dia 2 do trial
# - Último dia
# - Expiração

# Você deve receber notificações automáticas
```

### 4. Testar Upgrade

```dart
// Em PlansScreen
// Selecione "Premium"
// Clique "Confirmar"
// O app simula pagamento e atualiza para home
```

---

## 🛠️ Configurações Importantes

### Backend Config

**`app/routers/subscriptions_trial.py`** - Modificar dias de trial:

```python
# Mudar de 3 para X dias
trial_ends_at = trial_started_at + timedelta(days=3)  # ← Aqui
```

### Mobile Config

**`lib/utils/constants.dart`** - API URL:

```dart
// Para emulador Android
const apiUrl = "http://10.0.2.2:8000";

// Para device físico
const apiUrl = "http://seu-ip:8000";

// Para iOS
const apiUrl = "http://localhost:8000";
```

**`lib/services/trial_notification_service.dart`** - Customizar mensagens:

```dart
// Mudar texto das notificações aqui
'🎬 Seu trial termina amanhã!'  // ← Mensagens
```

---

## 🔍 Troubleshooting Rápido

### Problema: "Erro ao obter status do trial"

**Solução:**
```
1. Verificar se token é válido
2. Verificar se API_URL está correto
3. Verificar se backend está rodando
```

### Problema: "Subscription não encontrada"

**Solução:**
```
1. Verificar se user foi criado via /auth/register
2. Verificar banco de dados:
   SELECT * FROM subscriptions WHERE user_id = 'seu-id';
3. Se vazio, criar manualmente:
   INSERT INTO subscriptions (user_id, plan, plan_type, status, ...)
```

### Problema: "Notificações não aparecem"

**Solução:**
```
1. Verificar se TrialNotificationService.initialize() foi chamado
2. Verificar permissões no AndroidManifest.xml
3. Verificar se recurso de notificações está habilitado no device
```

### Problema: "Counter não atualiza"

**Solução:**
```
1. Verificar se DateTime do backend tem timezone UTC
2. Verificar se Timer não foi cancelado (StateDisposed)
3. Verificar se TrialProvider está sendo observado (Consumer/Provider)
```

---

## 📊 Métricas & Eventos

### Eventos para Rastrear

```dart
// Evento 1: Usuário vê welcome screen
Analytics.logEvent('trial_welcome_shown', {
  'days_remaining': 3,
  'timestamp': DateTime.now(),
});

// Evento 2: Usuário clica em upgrade
Analytics.logEvent('upgrade_clicked', {
  'from': 'welcome_screen',
  'trial_days_remaining': 2,
});

// Evento 3: Upgrade bem-sucedido
Analytics.logEvent('upgrade_successful', {
  'plan': 'Premium',
  'price': 40,
  'timestamp': DateTime.now(),
});

// Evento 4: Trial expirado
Analytics.logEvent('trial_expired', {
  'user_id': userId,
  'timestamp': DateTime.now(),
});
```

---

## 📚 Arquivos de Referência

### Backend
- `backend/app/routers/subscriptions_trial.py` - Endpoints
- `backend/app/services/trial_service.py` - Lógica
- `backend/app/models.py` - Modelo Subscription
- `TRIAL_IMPLEMENTATION.md` - Documentação completa

### App Mobile
- `nexus_mobile/lib/providers/trial_provider.dart` - Estado
- `nexus_mobile/lib/services/trial_service.dart` - APIs
- `nexus_mobile/lib/screens/trial/*.dart` - Telas
- `nexus_mobile/lib/widgets/trial_*.dart` - Widgets
- `TRIAL_MOBILE_IMPLEMENTATION.md` - Documentação completa

---

## 🎓 Próximo Passo

Deseja implementar:
- [ ] **Painel Admin** - Visualizar usuários em trial
- [ ] **Integração Stripe** - Processar pagamentos reais
- [ ] **Integração MercadoPago** - Mais opções de pagamento
- [ ] **Analytics** - Dashboard de conversões
- [ ] **Webhooks** - Notificações de pagamento

---

## 📞 Suporte Rápido

**Pergunta:** Como mudar período do trial?  
**Resposta:** Em `backend/app/routers/auth.py`, linha com `timedelta(days=3)`

**Pergunta:** Como customizar cores?  
**Resposta:** Em cada screen Flutter, procure por `Colors.purple`

**Pergunta:** Como testar expiração?  
**Resposta:** Mudar data do device ou modificar `trial_ends_at` no banco

**Pergunta:** Como desabilitar notificações?  
**Resposta:** Comentar `TrialNotificationService.initialize()` em `main.dart`

---

**Última Atualização:** 2026-07-13  
**Status:** ✅ Pronto para Produção  
**Próximo Milestone:** Painel Admin
