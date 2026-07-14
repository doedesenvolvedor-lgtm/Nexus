# Sistema de Trial de 3 Dias - Nexus Backend

## 📋 Visão Geral

Este documento descreve a implementação do sistema de trial gratuito de 3 dias para novos usuários do Nexus.

## 🎯 Funcionalidades Implementadas

### 1. **Criação Automática de Trial no Registro**
Quando um novo usuário se cadastra, um trial de 3 dias é criado automaticamente:

```
POST /auth/register
{
  "email": "usuario@example.com",
  "username": "usuario123",
  "password": "senha_segura"
}
```

**Resposta:**
```json
{
  "id": "uuid-user-id",
  "email": "usuario@example.com",
  "username": "usuario123",
  "is_premium": false
}
```

### 2. **Verificar Status do Trial**

```
GET /subscriptions/me/trial-status
Authorization: Bearer {token}
```

**Resposta:**
```json
{
  "is_trial": true,
  "days_remaining": 2,
  "trial_ends_at": "2026-07-16T23:59:00+00:00",
  "plan_type": "Trial"
}
```

### 3. **Obter Detalhes Completos da Subscription**

```
GET /subscriptions/me
Authorization: Bearer {token}
```

**Resposta:**
```json
{
  "id": "uuid-subscription-id",
  "user_id": "uuid-user-id",
  "plan": "Trial",
  "plan_type": "Trial",
  "status": "active",
  "trial_started_at": "2026-07-13T00:00:00+00:00",
  "trial_ends_at": "2026-07-16T23:59:00+00:00",
  "renewal_date": null,
  "created_at": "2026-07-13T10:30:00+00:00",
  "updated_at": "2026-07-13T10:30:00+00:00"
}
```

### 4. **Fazer Upgrade para Plano Pago**

```
POST /subscriptions/upgrade-trial
Authorization: Bearer {token}
Content-Type: application/json

{
  "plan": "Premium"
}
```

**Planos disponíveis:**
- `Basic` - R$ 15/mês
- `Standard` - R$ 25/mês
- `Premium` - R$ 40/mês

**Resposta:**
```json
{
  "message": "Upgrade para plano Premium realizado com sucesso!",
  "subscription": {
    "id": "uuid-subscription-id",
    "user_id": "uuid-user-id",
    "plan": "Premium",
    "plan_type": "Premium",
    "status": "active",
    "trial_started_at": null,
    "trial_ends_at": null,
    "renewal_date": null,
    "created_at": "2026-07-13T10:30:00+00:00",
    "updated_at": "2026-07-13T14:45:00+00:00"
  }
}
```

### 5. **Verificar e Atualizar Trials Expirados**

```
POST /subscriptions/check-trial-expiration
Authorization: Bearer {token}
```

Este endpoint verifica automaticamente se o trial do usuário expirou e atualiza o status.

**Resposta (se ativo):**
```json
{
  "message": "Trial ainda ativo.",
  "status": "active",
  "subscription": { ... }
}
```

**Resposta (se expirado):**
```json
{
  "message": "Seu trial expirou. Escolha um plano para continuar.",
  "status": "expired",
  "subscription": {
    "plan": "Free",
    "plan_type": "Free",
    "status": "expired",
    ...
  }
}
```

### 6. **Obter Perfil Completo do Usuário com Subscription**

```
GET /auth/me/profile
Authorization: Bearer {token}
```

**Resposta:**
```json
{
  "id": "uuid-user-id",
  "email": "usuario@example.com",
  "username": "usuario123",
  "is_premium": false,
  "subscription": {
    "id": "uuid-subscription-id",
    "user_id": "uuid-user-id",
    "plan": "Trial",
    "plan_type": "Trial",
    "status": "active",
    "trial_started_at": "2026-07-13T00:00:00+00:00",
    "trial_ends_at": "2026-07-16T23:59:00+00:00",
    "created_at": "2026-07-13T10:30:00+00:00",
    "updated_at": "2026-07-13T10:30:00+00:00"
  }
}
```

## 🗄️ Mudanças no Banco de Dados

### Novo Schema da Tabela `subscriptions`

```sql
ALTER TABLE subscriptions
ADD COLUMN plan_type VARCHAR(20) DEFAULT 'Free',
ADD COLUMN trial_started_at TIMESTAMP WITH TIME ZONE,
ADD COLUMN trial_ends_at TIMESTAMP WITH TIME ZONE,
ADD COLUMN created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP;
```

### Campos Adicionados

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `plan_type` | VARCHAR(20) | Tipo do plano: Trial, Free, Premium |
| `trial_started_at` | TIMESTAMP WITH TIME ZONE | Data/hora de início do trial |
| `trial_ends_at` | TIMESTAMP WITH TIME ZONE | Data/hora de término do trial |
| `created_at` | TIMESTAMP WITH TIME ZONE | Data de criação do registro |
| `updated_at` | TIMESTAMP WITH TIME ZONE | Data de atualização do registro |

## 🔧 Estrutura de Código

### Novos Arquivos

1. **`app/routers/subscriptions_trial.py`**
   - Endpoints para gerenciar trials e upgrades
   - Verificação de expiração de trials

2. **`app/services/trial_service.py`**
   - Funções auxiliares para gerenciar status de trials
   - Verificação de acesso a conteúdo premium

3. **`database/002_add_trial_support.sql`**
   - Script de migração do banco de dados

### Arquivos Modificados

1. **`app/models.py`**
   - Adicionados campos de trial ao modelo `Subscription`

2. **`app/schemas.py`**
   - Adicionados schemas para trial: `TrialStatusResponse`, `SubscriptionResponse` atualizado
   - Import de `datetime`

3. **`app/routers/auth.py`**
   - Modificado `/register` para criar trial automático
   - Adicionado endpoint `/me/profile`

4. **`app/main.py`**
   - Importado novo router `subscriptions_trial`
   - Incluído router na aplicação

## 📱 Fluxo do Usuário

```
1. Usuário instala o app
        ↓
2. Cria uma conta (POST /auth/register)
        ↓
3. Sistema cria automaticamente 3 dias de trial
        ↓
4. App obtém status do trial (GET /subscriptions/me/trial-status)
        ↓
5. Usuário assiste catálogo completo durante 3 dias
        ↓
6. Notificações aviram sobre término do trial
        ↓
7. Usuário faz upgrade (POST /subscriptions/upgrade-trial)
   OU deixa expirar e muda para plano Free

```

## ⚙️ Integração com Routers Existentes

### Em `app/media.py` (ou equivalente)

Para verificar se o usuário tem acesso ao conteúdo:

```python
from app.services.trial_service import check_premium_access

@router.get("/media/{media_id}")
def get_media(
    media_id: UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    # Verificar se tem acesso premium
    if not check_premium_access(current_user, db):
        raise HTTPException(status_code=403, detail="Acesso premium necessário.")
    
    # ... resto da lógica
```

## 🚀 Próximas Etapas

1. **Integrar com App Mobile** - Implementar tela de boas-vindas e notificações
2. **Sistema de Notificações** - Avisar antes de trial expirar
3. **Painel Admin** - Visualizar usuários em trial e análises
4. **Webhooks de Pagamento** - Integrar com Stripe e MercadoPago
5. **Background Tasks** - Job para atualizar trials expirados automaticamente

## 📞 Suporte

Para dúvidas sobre a implementação, consulte a documentação do FastAPI:
- https://fastapi.tiangolo.com/
- https://sqlalchemy.org/

---

**Implementado em:** 2026-07-13  
**Status:** ✅ Backend concluído
