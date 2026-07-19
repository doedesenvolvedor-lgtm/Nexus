# 🚀 Instruções de Execução - Painel Admin Nexustwos v2.0

**Última atualização**: 19 de Julho de 2026

---

## 📋 Pré-requisitos

### Sistema
- Node.js 16+ ✅
- npm 8+ ✅
- Git ✅
- Terminal/Console ✅

### Hardware (Mínimo)
- RAM: 2GB
- Disco: 500MB
- Processador: Dual-core

---

## 💻 Passos para Executar

### 1️⃣ Clonar/Acessar o Repositório

```bash
# Navegue até a pasta do projeto
cd /workspaces/Nexus/admin-panel-nexus

# Ou clone o repositório
git clone <url-do-repositorio>
cd admin-panel-nexus
```

### 2️⃣ Instalar Dependências

```bash
# Instalar npm packages
npm install

# Aguarde até aparecer "added XXX packages"
# Pode levar 30-60 segundos na primeira vez
```

### 3️⃣ Iniciar Servidor de Desenvolvimento

```bash
# Iniciar Vite dev server
npm run dev

# Você verá algo como:
# ✓ VITE v5.4.21 ready in 426 ms
# ➜  Local:   http://localhost:3000/
```

### 4️⃣ Acessar no Navegador

```
URL: http://localhost:3000
```

### 5️⃣ Fazer Login

```
Email: admin@nexus.com
Senha: admin123456
```

### 6️⃣ Explorar o Painel

- Clique nos itens do menu lateral
- Teste as funcionalidades
- Crie alguns itens de teste

---

## 🛑 Parar o Servidor

### No Terminal

```bash
# Pressione CTRL+C para parar o servidor
^C

# Ou feche o terminal
```

---

## 🔧 Build para Produção

### Compilar

```bash
# Criar build otimizado
npm run build

# Arquivo gerado: dist/
# Pode levar 10-20 segundos
```

### Preview do Build

```bash
# Ver o build em ação
npm run preview

# Acesse: http://localhost:4173
```

### Deploy (Manual)

```bash
# Copiar pasta dist/ para seu servidor
# E servir com um web server (Nginx, Apache, etc)
```

---

## 📁 Estrutura de Pastas

```
admin-panel-nexus/
├── src/                          # Código fonte
│   ├── pages/                   # 35+ páginas
│   ├── components/              # Componentes reutilizáveis
│   ├── api/                     # Configuração API
│   ├── store/                   # State management
│   ├── App.jsx                  # Roteamento principal
│   └── main.jsx                 # Entry point
├── public/                       # Assets estáticos
├── dist/                         # Build gerado (após npm run build)
├── node_modules/                # Dependências (ignore no git)
├── vite.config.js               # Configuração Vite
├── tailwind.config.js           # Configuração Tailwind
├── package.json                 # Dependências e scripts
├── index.html                   # HTML principal
└── README.md                    # Documentação
```

---

## 📦 Scripts Disponíveis

### Development

```bash
npm run dev           # Iniciar servidor de desenvolvimento
npm run build         # Compilar para produção
npm run preview       # Preview do build
npm run lint          # Verificar erros de código
npm run format        # Formatar código
npm run type-check    # Verificar tipos TypeScript
```

---

## 🌐 URLs Importantes

| URL | Descrição |
|-----|-----------|
| http://localhost:3000 | Painel Admin |
| http://localhost:3000/login | Login |
| http://localhost:3000/dashboard | Dashboard |
| http://localhost:3000/movies | Gerenciar Filmes |
| http://localhost:3000/series | Gerenciar Séries |
| http://localhost:3000/users | Gerenciar Usuários |

---

## 🔐 Variáveis de Ambiente

### .env.local (Desenvolvimento)

```env
VITE_API_BASE_URL=http://localhost:8000/api
VITE_APP_NAME=Nexustwos Admin
VITE_APP_VERSION=2.0.0
```

### .env.production (Produção)

```env
VITE_API_BASE_URL=https://api.nexustwos.com/api
VITE_APP_NAME=Nexustwos Admin
VITE_APP_VERSION=2.0.0
```

---

## 🐛 Troubleshooting

### Problema: "Port 3000 already in use"

**Solução:**
```bash
# Opção 1: Liberar a porta
lsof -ti:3000 | xargs kill -9

# Opção 2: Usar porta diferente
npm run dev -- --port 3001
```

### Problema: "npm ERR! code ERESOLVE"

**Solução:**
```bash
# Usar --legacy-peer-deps
npm install --legacy-peer-deps

# Ou usar npm 7+
npm install
```

### Problema: "Cannot find module"

**Solução:**
```bash
# Reinstalar node_modules
rm -rf node_modules package-lock.json
npm install
```

### Problema: Página em branco

**Solução:**
1. Abra DevTools (F12)
2. Veja a aba Console
3. Procure por erros
4. Limpe cache (Ctrl+Shift+Del)
5. Recarregue (F5)

### Problema: Styling não carrega

**Solução:**
```bash
# Reconstruir Tailwind CSS
npm run build

# Ou reiniciar dev server
npm run dev
```

---

## 💡 Dicas de Desenvolvimento

### 1. Hot Module Reload (HMR)
- Mudanças no código atualizam automaticamente
- Não é necessário recarregar manual
- Veja no console: "hmr update"

### 2. DevTools do React
- Instale [React Developer Tools](https://chrome.google.com/webstore)
- Use para debug de componentes
- Inspecione props e state

### 3. Console Browser
- F12 para abrir DevTools
- Veja logs e erros
- Teste no console (JS)

### 4. Network Tab
- Veja requisições HTTP
- Verifique status codes
- Analise payloads

### 5. Performance
- Abra DevTools → Performance
- Grave ações
- Analise timing

---

## 🔄 Workflow de Desenvolvimento

### 1. Criar Nova Página

```bash
# 1. Crie o arquivo em src/pages/NomePage.jsx
# 2. Importe em src/App.jsx
# 3. Adicione rota em <Routes>
# 4. Atualize Sidebar se necessário
# 5. Teste no navegador
```

### 2. Adicionar Componente

```bash
# 1. Crie em src/components/NomeComponente.jsx
# 2. Exporte em src/components/ui/index.jsx
# 3. Importe onde precisar
# 4. Use em seus componentes
```

### 3. Adicionar Rota

```jsx
// Em src/App.jsx
<Route path="/caminho" element={<NovaPage />} />
```

---

## 📱 Testar Responsividade

### No Chrome DevTools

1. F12 → Device Toolbar (Ctrl+Shift+M)
2. Selecione dispositivo:
   - iPhone 12 (390×844)
   - iPad Air (820×1180)
   - Galaxy S21 (360×800)
   - Desktop (1920×1080)

### Resoluções Importantes

- **Mobile**: < 640px
- **Tablet**: 640px - 1024px
- **Desktop**: > 1024px

---

## 🔒 Segurança

### Antes de Deploy

```bash
# 1. Verifique vulnerabilidades
npm audit

# 2. Atualize pacotes
npm update

# 3. Teste tudo
npm run build
npm run preview

# 4. Verifique senhas
# - Não commite credenciais
# - Use .env para secrets
# - Revise .gitignore
```

---

## 📊 Performance

### Otimizações Implementadas

- ✅ Lazy loading de páginas
- ✅ Code splitting automático
- ✅ Minificação de CSS/JS
- ✅ Tree shaking
- ✅ Compressão de assets

### Verificar Performance

```bash
# Build size
npm run build

# Veja "dist/" para tamanhos

# Performance real
npm run preview

# Abra DevTools → Network
```

---

## 📚 Documentação Relacionada

- [README.md](./README.md) - Documentação principal
- [QUICK_REFERENCE.md](./QUICK_REFERENCE.md) - Guia rápido
- [CHANGELOG.md](./CHANGELOG.md) - Histórico de mudanças
- [SETUP.md](./SETUP.md) - Guia de instalação detalhado

---

## 🎯 Checklist - Primeira Execução

- [ ] Node.js 16+ instalado
- [ ] cd /workspaces/Nexus/admin-panel-nexus
- [ ] npm install (sucesso)
- [ ] npm run dev (sem erros)
- [ ] Navegador abre http://localhost:3000
- [ ] Login funciona
- [ ] Dashboard carrega
- [ ] Menu lateral funciona
- [ ] Teste uma página (ex: Filmes)
- [ ] Tudo funcionando? ✅

---

## 🚀 Próximos Passos

### Após Clonar/Baixar
1. Instale dependências
2. Configure variáveis de ambiente
3. Inicie servidor dev
4. Teste todas as páginas
5. Leia a documentação

### Para Contribuir
1. Crie uma branch (feature/xyz)
2. Faça suas mudanças
3. Teste tudo
4. Commit com mensagens claras
5. Push e crie Pull Request

### Para Deploy
1. Build para produção (npm run build)
2. Teste o build localmente
3. Faça deploy da pasta dist/
4. Configure servidor web
5. Teste em produção

---

## 📞 Suporte

### Erros Comuns

| Erro | Solução |
|------|---------|
| Port already in use | Mude porta ou feche app |
| npm ERR! code ERESOLVE | Use --legacy-peer-deps |
| Cannot find module | npm install |
| Styling quebrado | Reinicie dev server |
| Login não funciona | Verifique credenciais |

### Recursos

- 📖 [React Docs](https://react.dev)
- 📖 [Vite Docs](https://vitejs.dev)
- 📖 [Tailwind CSS](https://tailwindcss.com)
- 📖 [Framer Motion](https://www.framer.com/motion)

---

## ✅ Verificação Final

Antes de considerar pronto:

```bash
# 1. Limpar build antigo
rm -rf dist

# 2. Instalar dependências
npm install

# 3. Verificar vulnerabilidades
npm audit

# 4. Fazer build
npm run build

# 5. Preview
npm run preview

# 6. Abra em navegador e teste
```

---

## 📝 Notas

- Projeto usa Vite para rápida compilação
- React 18 com Hooks
- Tailwind CSS para estilos
- Zustand para state management
- Framer Motion para animações

---

**Desenvolvido com ❤️ para Nexustwos**

*Painel Administrativo Profissional, Moderno e Completo*

**v2.0.0** - 2026-07-19 ✅
