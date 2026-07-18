# 📚 Setup e Guia de Instalação

## 🔧 Pré-requisitos

- Node.js 16+ (recomendado 18+)
- npm ou yarn
- Git

## 📦 Instalação Completa

### 1. Instalar Dependências

```bash
cd /workspaces/Nexus/admin-panel-nexus
npm install
```

### 2. Configurar Variáveis de Ambiente

Criar arquivo `.env.local` na raiz do projeto:

```env
# API Base URL
REACT_APP_API_URL=http://localhost:8000

# Firebase (opcional)
REACT_APP_FIREBASE_API_KEY=your_key
REACT_APP_FIREBASE_PROJECT_ID=your_id

# Analytics (opcional)
REACT_APP_GA_ID=your_ga_id
```

### 3. Iniciar Desenvolvimento

```bash
npm run dev
```

O painel estará disponível em `http://localhost:3000`

### 4. Credenciais de Demo

```
Email: admin@nexus.com
Senha: admin123456
```

## 🏗️ Estrutura de Pastas Criada

```
admin-panel-nexus/
├── src/
│   ├── api/                    # Configuração de API
│   ├── components/             # Componentes React
│   │   ├── ui/                # Componentes base
│   │   ├── Layout/            # Layout components
│   │   ├── Charts.jsx         # Gráficos
│   │   ├── Table.jsx          # Tabelas
│   │   └── Notification.jsx   # Notificações
│   ├── pages/                 # Páginas do aplicativo
│   │   ├── Dashboard.jsx
│   │   ├── Movies.jsx
│   │   ├── Users.jsx
│   │   ├── Subscriptions.jsx
│   │   ├── Trials.jsx
│   │   ├── Payments.jsx
│   │   ├── Analytics.jsx
│   │   ├── Notifications.jsx
│   │   ├── Settings.jsx
│   │   └── LoginPage.jsx
│   ├── store/                 # Zustand stores
│   ├── App.jsx                # Main app component
│   ├── main.jsx               # Entry point
│   ├── index.css              # Global styles
│   └── theme.js               # Theme configuration
├── index.html
├── package.json
├── vite.config.js
├── tailwind.config.js
└── README.md
```

## 🎯 Próximas Etapas

### 1. Implementar Páginas Restantes

Páginas que ainda precisam de implementação:
- Series (Séries)
- Episodes (Episódios)
- Channels (Canais ao Vivo)
- Categories (Categorias)
- Banners
- Profiles (Perfis de Usuário)
- Plans (Planos de Assinatura)
- Coupons (Cupons)
- Importer (Importador M3U)
- Comments (Comentários)
- Logs
- Profile (Perfil Admin)

### 2. Conectar com Backend

Verificar se os endpoints do backend estão de acordo com `src/api/endpoints.js`

### 3. Customizações

Adicionar logo, favicon e assets da marca Nexustwos

### 4. Testes

- Testar todas as funcionalidades
- Testar responsividade
- Testar performance
- Testar em diferentes navegadores

## 🚀 Comandos Úteis

```bash
# Desenvolvimento
npm run dev

# Build para produção
npm run build

# Preview do build
npm run preview

# Linting
npm run lint

# Format de código
npm run format

# Type checking (quando adicionar TypeScript)
npm run type-check
```

## 📱 Responsividade

O painel é 100% responsivo:
- ✅ Desktop (1024px+)
- ✅ Tablet (768px - 1023px)
- ✅ Mobile (< 768px)

## 🎨 Personalização

### Cores

Editar em `tailwind.config.js`:
```js
colors: {
  nexus: {
    bg: '#090909',
    card: '#151515',
    primary: '#6D28FF',
    // ...
  }
}
```

### Componentes

Adicionar novos componentes em `src/components/ui/index.jsx`

### Páginas

Criar nova página em `src/pages/NovaPage.jsx` e importar em `App.jsx`

## 🔗 Integração com Backend

Todos os endpoints estão pré-configurados. Apenas verifique:

1. URL base da API (`.env.local`)
2. Headers CORS no backend
3. Autenticação JWT
4. Estrutura de resposta dos dados

## 📊 Performance

- Build otimizado com Vite
- Code splitting automático
- Lazy loading de componentes
- Caching inteligente de estado

## 🔒 Segurança

- Token JWT armazenado em localStorage
- Autenticação automática em requisições
- Logout automático em erro 401
- HTTPS recomendado em produção

## ❓ Troubleshooting

### Porta 3000 em uso
```bash
# Kill process
lsof -ti:3000 | xargs kill -9

# Ou usar outra porta
npm run dev -- --port 3001
```

### Erro de dependências
```bash
# Limpar cache
npm cache clean --force

# Reinstalar
rm -rf node_modules package-lock.json
npm install
```

### CORS Error
Verificar configuração de CORS no backend:
```python
# Django/FastAPI
CORS_ALLOWED_ORIGINS = [
    "http://localhost:3000",
    "http://localhost:5173",
]
```

## 📞 Suporte

Para dúvidas técnicas, verificar:
1. Documentação do README.md
2. Comentários no código
3. Exemplos em components/
4. Documentação das bibliotecas

---

**Setup Completo!** 🎉 O painel está pronto para desenvolvimento e pode ser customizado conforme necessário.
