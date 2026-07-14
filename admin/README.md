# ⚡ Quick Start - Painel Admin Nexus

## 🎯 Setup Rápido

### 1. Backend

Endpoints de admin já estão em `backend/app/routers/admin.py`:

```bash
# Listar trials
GET /admin/trials?skip=0&limit=10&status=active

# Analytics
GET /admin/trials/analytics/summary

# Detalhes
GET /admin/trials/{user_id}

# Ações
POST /admin/trials/{user_id}/extend
POST /admin/trials/{user_id}/cancel
```

### 2. Dashboard

Abrir arquivo:
```
admin/dashboard.html
```

Ou servir com Python:
```bash
cd admin
python -m http.server 8001
# Acessar: http://localhost:8001/dashboard.html
```

### 3. Adicionar Token

No console do navegador:
```javascript
localStorage.setItem('admin_token', 'seu-token-aqui');
```

## 📊 Funcionalidades Principais

### Dashboard (Tab 1)
- 6 cards com métricas
- Taxa de conversão trial → premium
- Distribuição de planos

### Trials (Tab 2)
- Tabela de usuários em trial
- Filtros (status, email)
- Paginação (10 por página)
- Botões: Ver, Estender, Cancelar

### Details Modal
- Clique "Ver" em qualquer usuário
- Vê atividade (perfis, reproduções)
- Estende ou cancela trial

## 🔧 Endpoints Principais

### 1. Listar Trials Ativos
```bash
curl http://localhost:8000/admin/trials?status=active \
  -H "Authorization: Bearer {token}"
```

### 2. Analytics
```bash
curl http://localhost:8000/admin/trials/analytics/summary \
  -H "Authorization: Bearer {token}"
```

### 3. Estender Trial
```bash
curl -X POST http://localhost:8000/admin/trials/{user_id}/extend \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json" \
  -d '{"days": 3}'
```

### 4. Cancelar Trial
```bash
curl -X POST http://localhost:8000/admin/trials/{user_id}/cancel \
  -H "Authorization: Bearer {token}"
```

## 🎨 Dashboard

- **Tema**: Escuro com roxo (#667eea)
- **Responsivo**: Adapta para mobile
- **Rápido**: Totalmente client-side
- **Seguro**: Usa Bearer token

## 📱 Screenshots Mental

```
┌─────────────────────────────────────────┐
│ 🎬 Nexus Admin - Painel de Trials       │
├─────────────────────────────────────────┤
│  [📊 Analytics] [⭐ Trials] [📈 Distrib]│
├─────────────────────────────────────────┤
│                                         │
│  Total Usuários: 150   Trials: 90      │
│  Ativos: 45            Taxa: 22.22%    │
│  Expirados: 25         Premium: 20     │
│                                         │
├─────────────────────────────────────────┤
│ Email         | Username | Dias | Ações│
│─────────────────────────────────────────│
│ user@test.com | user123  | 2    | [...] │
│ outro@test.com| outro    | 1    | [...] │
└─────────────────────────────────────────┘
```

## ✅ Checklist

- [x] Endpoints de admin implementados
- [x] Dashboard HTML criado
- [x] Tabela com filtros
- [x] Modal de detalhes
- [x] Analytics em cards
- [x] Paginação funcional
- [x] Ações (estender, cancelar)
- [x] Responsivo

## 🚀 Próximo Passo

Implementar **Login de Admin** para autenticar usuários

---

**Status:** ✅ Pronto para Uso  
**Data:** 2026-07-13
