# 🎬 Painel Admin - Nexus Trials

## 📋 Visão Geral

Painel administrativo completo para gerenciar o sistema de trials de 3 dias do Nexus, com visualização de usuários, estatísticas de conversão e ações de gerenciamento.

## 🎯 Funcionalidades

### 1. **Dashboard Analytics** 📊

Métricas em tempo real:
- **Total de Usuários**: Contagem de todos os usuários cadastrados
- **Trials Ativos**: Usuários com trial em progresso
- **Trials Expirados**: Usuários cujo trial terminou
- **Convertidos para Premium**: Usuários que foram de trial para plano pago
- **Taxa de Conversão**: Percentual (trial → premium)
- **Total de Trials**: Soma de todos os trials criados

### 2. **Gerenciamento de Trials** ⭐

Tabela interativa com:
- **Filtros**: Por status (Ativo/Expirado) e email
- **Informações por Usuário**:
  - Email
  - Username
  - Data de criação
  - Dias restantes (badge colorida)
  - Status (Ativo/Expirado/Convertido)
- **Ações**:
  - 👁️ Ver detalhes
  - ⏱️ Estender trial 3 dias
  - ❌ Cancelar trial
- **Paginação**: 10 usuários por página

### 3. **Detalhes do Usuário** 📝

Modal com informações completas:
- Dados do usuário (email, username, data de criação)
- Status do trial (ativo/expirado)
- Dias restantes
- Data de início e término
- Atividade (perfis criados, reproduções)
- Botões de ação (estender, cancelar)

### 4. **Distribuição de Planos** 📈

Visualização gráfica (bar chart):
- Número de usuários por tipo de plano
- Trial
- Free
- Premium
- Basic/Standard (se aplicável)

---

## 🔧 Endpoints da API

### Analytics

```
GET /admin/trials/analytics/summary
```

**Resposta:**
```json
{
  "total_users": 150,
  "active_trials": 45,
  "expired_trials": 25,
  "converted_to_premium": 20,
  "total_trials": 90,
  "conversion_rate": 22.22,
  "plan_distribution": {
    "Trial": 45,
    "Free": 60,
    "Premium": 20
  }
}
```

### Listar Trials

```
GET /admin/trials?skip=0&limit=10&status=active
```

**Query Params:**
- `skip`: Número de registros a pular (paginação)
- `limit`: Limite de registros (padrão: 100)
- `status`: Filtrar por status (`active`, `expired` ou deixar vazio)

**Resposta:**
```json
{
  "total": 45,
  "skip": 0,
  "limit": 10,
  "data": [
    {
      "user_id": "uuid",
      "email": "user@example.com",
      "username": "usuario123",
      "created_at": "2026-07-13T10:30:00",
      "trial_started_at": "2026-07-13T10:30:00",
      "trial_ends_at": "2026-07-16T10:30:00",
      "days_remaining": 2,
      "status": "active",
      "plan": "Trial"
    }
  ]
}
```

### Detalhes do Trial

```
GET /admin/trials/{user_id}
```

**Resposta:**
```json
{
  "user": {
    "id": "uuid",
    "email": "user@example.com",
    "username": "usuario123",
    "created_at": "2026-07-13T10:30:00"
  },
  "subscription": {
    "id": "uuid",
    "plan": "Trial",
    "plan_type": "Trial",
    "status": "active",
    "trial_started_at": "2026-07-13T10:30:00",
    "trial_ends_at": "2026-07-16T10:30:00",
    "days_remaining": 2,
    "created_at": "2026-07-13T10:30:00",
    "updated_at": "2026-07-13T10:30:00"
  },
  "activity": {
    "profiles_count": 2,
    "playback_count": 15
  }
}
```

### Estender Trial

```
POST /admin/trials/{user_id}/extend
Content-Type: application/json

{
  "days": 3
}
```

**Resposta:**
```json
{
  "message": "Trial estendido por 3 dias.",
  "trial_ends_at": "2026-07-19T10:30:00"
}
```

### Cancelar Trial

```
POST /admin/trials/{user_id}/cancel
```

**Resposta:**
```json
{
  "message": "Trial cancelado.",
  "new_plan": "Free"
}
```

---

## 🚀 Como Usar

### 1. Acessar o Dashboard

**URL:**
```
http://localhost:3000/admin/dashboard.html
```

Ou servindo via backend:
```
GET /admin/dashboard
```

### 2. Autenticação

O dashboard espera um token no localStorage:
```javascript
localStorage.setItem('admin_token', 'seu-token-aqui');
```

Você precisa fazer login primeiro (adicionar página de login).

### 3. Tabs Principais

**Tab 1: Analytics** 📊
- Visão geral de métricas
- Estatísticas de conversão
- Distribuição de planos

**Tab 2: Usuários em Trial** ⭐
- Tabela filtrável de usuários
- Ações por usuário
- Modal de detalhes

**Tab 3: Distribuição** 📈
- Gráficos em bar chart
- Distribuição por plano
- Resumo de status

### 4. Ações Comuns

#### Ver Detalhes de um Usuário
1. Tab "Usuários em Trial"
2. Clique em "Ver" na linha do usuário
3. Modal abre com detalhes completos

#### Estender Trial
1. Clique em "Estender" na tabela OU
2. Abra detalhes e clique "Estender 3 Dias"
3. Trial será estendido por 3 dias adicionais

#### Cancelar Trial
1. Clique em "Cancelar" na tabela OU
2. Abra detalhes e clique "Cancelar Trial"
3. Usuário será movido para plano "Free"

#### Filtrar Trials
1. Selecione status no dropdown
2. (Opcional) Digite email para pesquisar
3. Clique "Atualizar"

---

## 🎨 Design & Interface

### Tema
- **Background**: Gradiente roxo/azul escuro
- **Primária**: Roxo (#667eea)
- **Secundária**: Violeta (#764ba2)
- **Sucesso**: Verde (#34d399)
- **Erro**: Vermelho (#f87171)

### Componentes
- Cards com backdrop blur
- Badges de status coloridas
- Bar charts para distribuição
- Modal com transições suaves
- Tabela responsiva
- Paginação funcional

### Responsividade
- Layout adapta para mobile
- Cards em grid adaptativo
- Tabela com scroll horizontal se necessário
- Modais 90% da largura em mobile

---

## 🔐 Segurança

### Autenticação

O dashboard usa token bearer:
```javascript
const token = localStorage.getItem('admin_token');

fetch('/admin/trials', {
    headers: {
        'Authorization': `Bearer ${token}`
    }
});
```

### Autorização

Backend verifica permissão de admin:
```python
# Em app/security_admin.py
@require_admin
def get_admin_user(current_user: User):
    # Apenas admins
    pass
```

**Adicionar admins:**
1. Editar `ADMIN_EMAILS` em `app/security_admin.py`, OU
2. Adicionar campo `is_admin` ao modelo User

### CORS

Se dashboard estiver em origem diferente:
```python
# Em app/main.py
from fastapi.middleware.cors import CORSMiddleware

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

---

## 📊 Métricas & Análises

### Conversão de Trial

```
Taxa = (Convertidos para Premium / Total de Trials) × 100

Exemplo:
- Total de Trials: 90
- Convertidos: 20
- Taxa: 22.22%
```

### Status dos Trials

```
Ativo: trial_ends_at > agora
Expirado: trial_ends_at <= agora
Convertido: plan_type = "Premium"
```

### Dias Restantes

```
dias_restantes = ceil((trial_ends_at - agora).days)

Exemplo:
- Expira em 2026-07-16 15:30
- Agora é 2026-07-14 10:00
- Dias restantes: 2
```

---

## 🛠️ Customização

### Mudar Limite de Paginação

**Em dashboard.html:**
```javascript
const ITEMS_PER_PAGE = 10;  // ← Mudar aqui
```

### Mudar Dias de Extensão

**Em dashboard.html (função extendTrialDirect):**
```javascript
body: JSON.stringify({ days: 3 })  // ← Mudar aqui
```

**Ou via API:**
```bash
curl -X POST http://localhost:8000/admin/trials/{user_id}/extend \
  -H "Authorization: Bearer token" \
  -d '{"days": 7}'
```

### Adicionar Coluna à Tabela

**Em renderTrialsTable():**
```javascript
<td>${trial.seu_campo_novo}</td>
```

### Customizar Cores

**Em dashboard.html (CSS):**
```css
--primary: #667eea;  /* Cor roxo */
--secondary: #764ba2; /* Cor violeta */
```

---

## 🐛 Troubleshooting

### "Erro ao carregar analytics"

**Causa**: Token inválido ou endpoint não existe
**Solução**: 
1. Verificar token: `localStorage.getItem('admin_token')`
2. Verificar se backend está rodando
3. Verificar CORS se dashboard em origin diferente

### "Tabela vazia"

**Causa**: Nenhum trial encontrado
**Solução**:
1. Criar novo usuário com `/auth/register`
2. Mudar filtro para "Todos"
3. Verificar banco de dados: `SELECT * FROM subscriptions WHERE plan_type='Trial';`

### "Botões de ação desativados"

**Causa**: Trial já expirou ou foi cancelado
**Solução**: Status do trial permite ações apenas se "ativo"

### "Modal não fecha"

**Causa**: JavaScript erro
**Solução**: 
1. Abrir console (F12)
2. Verificar erros
3. Fazer refresh na página

---

## 📱 API Reference Rápida

```bash
# 1. Listar trials ativos (página 1)
curl http://localhost:8000/admin/trials?skip=0&limit=10&status=active \
  -H "Authorization: Bearer {token}"

# 2. Ver analytics
curl http://localhost:8000/admin/trials/analytics/summary \
  -H "Authorization: Bearer {token}"

# 3. Ver detalhes de um usuário
curl http://localhost:8000/admin/trials/{user_id} \
  -H "Authorization: Bearer {token}"

# 4. Estender trial por 3 dias
curl -X POST http://localhost:8000/admin/trials/{user_id}/extend \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json" \
  -d '{"days": 3}'

# 5. Cancelar trial
curl -X POST http://localhost:8000/admin/trials/{user_id}/cancel \
  -H "Authorization: Bearer {token}"
```

---

## ✅ Checklist de Setup

- [ ] Backend endpoints implementados em `app/routers/admin.py`
- [ ] Segurança de admin em `app/security_admin.py`
- [ ] Dashboard HTML em `admin/dashboard.html`
- [ ] CORS configurado se necessário
- [ ] Token de autenticação funcionando
- [ ] Testar listar trials
- [ ] Testar estender trial
- [ ] Testar cancelar trial
- [ ] Testar filtros
- [ ] Testar paginação

---

## 🚀 Próximos Passos

1. **Autenticação de Admin**
   - [ ] Página de login separada
   - [ ] Validação de credenciais
   - [ ] Sessão com expiração

2. **Melhorias de UI**
   - [ ] Gráficos com biblioteca (Chart.js, D3.js)
   - [ ] Exportar dados (CSV, PDF)
   - [ ] Temas claro/escuro

3. **Funcionalidades Adicionais**
   - [ ] Criar novo admin
   - [ ] Ver histórico de ações
   - [ ] Notificações em tempo real
   - [ ] Bulk actions (estender múltiplos)

4. **Analytics Avançado**
   - [ ] Gráficos de tendência
   - [ ] Comparação período a período
   - [ ] Coortes de usuários
   - [ ] Churn rate

---

**Data:** 2026-07-13  
**Status:** ✅ Completo  
**Versão:** 1.0
