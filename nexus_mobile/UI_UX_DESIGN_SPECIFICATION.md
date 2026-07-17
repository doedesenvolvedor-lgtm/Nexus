# 🎬 NEXUSTWOS - UI/UX DESIGN SPECIFICATION (COMPLETA)

## Documento de Design Premium para Streaming

**Versão:** 1.0  
**Data:** 2024-07-17  
**Status:** ✅ PRONTO PARA IMPLEMENTAÇÃO  
**Plataformas:** iOS (14+), Android (8.0+), Tablet, Web  

---

## 📑 ÍNDICE

1. [Paleta de Cores](#paleta-de-cores)
2. [Tipografia](#tipografia)
3. [Componentes Reutilizáveis](#componentes-reutilizáveis)
4. [Telas Principais (40+)](#telas-principais)
5. [Fluxo de Navegação](#fluxo-de-navegação)
6. [Animações & Transições](#animações--transições)
7. [Guidelines & Padrões](#guidelines--padrões)

---

## 🎨 PALETA DE CORES

### Cores Primárias
- **Roxo Principal:** `#6D28FF`
- **Azul Principal:** `#2B7FFF`
- **Roxo Destaque:** `#8A4DFF`
- **Gradiente Primário:** Roxo → Azul

### Fundos
- **Background Principal:** `#090909`
- **Cards:** `#151515`
- **Cards Hover:** `#1F1F1F`

### Texto
- **Primário:** `#FFFFFF`
- **Secundário:** `#B3B3B3`
- **Terciário:** `#808080`

### Semânticas
- **Sucesso:** `#10B981`
- **Erro:** `#F87171`
- **Aviso:** `#FB923C`
- **Info:** `#3B82F6`

---

## 🔤 TIPOGRAFIA

### Fonte Principal: Poppins
- **Títulos (H1-H3):** Bold (700)
- **Botões:** SemiBold (600)
- **Corpo:** Regular (400)
- **Pequeno:** Regular (400)

### Tamanhos
- **Título Grande:** 32px (Bold)
- **Título Médio:** 24px (Bold)
- **Título Pequeno:** 20px (Bold)
- **Subtítulo:** 18px (SemiBold)
- **Corpo Grande:** 16px (Regular)
- **Corpo Médio:** 14px (Regular)
- **Corpo Pequeno:** 12px (Regular)
- **Label:** 11px (SemiBold)

---

## 🧩 COMPONENTES REUTILIZÁVEIS

### 1. BOTÕES

#### Botão Primário (Gradiente)
- Altura: 56px
- Padding: 16px (vertical), 32px (horizontal)
- Raio: 12px
- Gradiente: Roxo → Azul
- Sombra: 0 10px 20px (Roxo 40% opacity)
- Estado Loading: Spinner branco

#### Botão Secundário (Outline)
- Altura: 56px
- Borda: 2px Roxo
- Raio: 12px
- Background: Transparent

#### Botão Ternário (Text only)
- Sem background
- Cor: Roxo
- Efeito ripple ao toque

### 2. CARDS MEDIA

#### Media Card (Poster)
- Tamanho: 150x225px
- Raio: 12px
- Sombra: 0 4px 8px (Preto 30%)
- Badge Rating (top-right)
- Overlays em hover

#### Séries Card (Landscape)
- Tamanho: 16:9 aspect ratio
- Play button overlay
- Progresso de episódio

### 3. INPUT FIELDS

#### Text Field
- Height: 56px
- Border: 1px (cardBackground)
- Focus: 2px Roxo
- Padding: 16px
- Raio: 12px
- Placeholder: TextSecondary (opacity 0.6)

#### Password Field
- Mesmo as Text Field
- Toggle visibilidade (icon)

#### Textarea
- Min Lines: 4
- Max Lines: 8
- Mesmos estilos

### 4. CHIPS & TAGS

#### Categoria Tag
- Padding: 16px (h), 8px (v)
- Raio: 20px
- Selected: Gradiente primário
- Unselected: Card background + border

#### Premium Badge
- Padding: 12px (h), 8px (v)
- Raio: 20px
- Gradiente: Roxo → Azul
- Texto: Bold, branco

### 5. CAROUSELS

#### Horizontal Carousel
- Height: 280px (media card + label)
- Scroll horizontal suave
- Velocity-based fling
- Pagination dots opcionais

#### Vertical Scroll
- Infinite scroll
- Pull-to-refresh
- Skeleton loading na base

### 6. SHIMMER LOADING

#### Skeleton Screens
- Gradiente animado 2 cores
- Motion: left to right
- Duration: 2s
- Mesmo shape que elemento final

---

## 📱 TELAS PRINCIPAIS (40+)

### AUTENTICAÇÃO (5 telas)

#### 1. Splash Screen
- Logo centralizado (N gradiente)
- Nome "Nexustwos"
- Animação Fade In (1.5s)
- Transição automática

#### 2. Login Screen
- Logo topo (80x80)
- Email field
- Senha field (com toggle)
- Botão "Entrar"
- Link "Esqueci senha"
- Social buttons (Google, Apple)
- Link "Criar Conta"

#### 3. Cadastro Screen
- Campo: Nome
- Campo: Email
- Campo: Senha
- Campo: Confirmar Senha
- Validações em tempo real
- Bônus: "🎉 Você ganhou 3 dias grátis!"
- Botão: "Criar Conta"

#### 4. Recuperar Senha
- Email input
- "Recuperar Senha" button
- Status: "Email enviado"
- Link: "Voltar ao login"

#### 5. Nova Senha
- Token verificado
- Campo: Senha nova
- Campo: Confirmar
- Botão: "Alterar Senha"
- Sucesso: "Senha alterada!"

---

### HOME & EXPLORAÇÃO (8 telas)

#### 6. Home Screen (PRINCIPAL)
```
┌─────────────────────────────────┐
│ 🔔                              │ (AppBar com notificações)
├─────────────────────────────────┤
│                                 │
│  [ Featured Banner 16:9 ]       │ (Auto-scroll 5s)
│     Título | Sinopse | ▶        │
│                                 │
├─────────────────────────────────┤
│ Continuar Assistindo            │ (Carousel)
│  [Card] [Card] [Card]→          │
├─────────────────────────────────┤
│ Lançamentos                     │ (Carousel)
│  [Card] [Card] [Card]→          │
├─────────────────────────────────┤
│ Em Alta                         │ (Carousel)
│  [Card] [Card] [Card]→          │
├─────────────────────────────────┤
│ Recomendados pra você           │ (Carousel)
│  [Card] [Card] [Card]→          │
└─────────────────────────────────┘
```

#### 7. Categorias
- Tabs horizontais: Todos, Filmes, Séries, Animes, Infantil, Documentários
- Grid de cards
- Scroll infinito
- 3 colunas (mobile)

#### 8. Filtros & Descoberta
- Filter chips: Gênero, Ano, Rating, Qualidade, Idioma
- Multi-select
- Aplicar / Limpar
- Grid resultado
- Ordenação: Populares, Novos, Rating

#### 9. Pesquisa
- Search bar (sticky top)
- Historico de buscas
- Trending tags
- Auto-complete
- Resultado em grid

#### 10. Pesquisa com Voz
- Ícone microfone
- Recording state
- Waveform animation
- Processing
- Resultado escrito

#### 11. Top 10
- Lista ranking 1-10
- Item: Posição + Card + Episódios (se série)
- Badges: "Novo em #3"
- Scroll vertical

#### 12. Tendências
- Timeline: Hoje, Semana, Mês
- Top titles animados
- View count badge
- Share button

#### 13. "Novo & Popular"
- Banner "Novo em Nexustwos"
- Cards em destaque
- Data de lançamento
- Social proof (views, likes)

---

### DETALHES & PLAYER (6 telas)

#### 14. Filme/Série - Detalhes
```
┌──────────────────────────┐
│    [ Banner 16:9 ]       │ (Play overlay)
├──────────────────────────┤
│  [Poster] Título         │
│           Ano • Gênero   │
│           ⭐ 8.5 (123K)   │
│                          │
│ Sinopse: Lorem ipsum...  │
│                          │
│ [▶ Assistir] [❤][➕][⋮]  │
│                          │
│ Elenco:                  │
│  [Avatar] Nome           │
│  [Avatar] Nome           │
│                          │
│ Títulos Relacionados     │
│  [Card] [Card] [Card]    │
└──────────────────────────┘
```

#### 15. Episódios (Séries)
- Seletor: Temporada (dropdown)
- Lista episódios:
  - Thumbnail
  - "S01E01 - Título"
  - Duração
  - Sinopse truncada
  - Play button

#### 16. Player de Vídeo
```
┌──────────────────────────────┐
│                              │
│   [ VIDEO PLAYER ]           │
│                              │
│ (Controles ao passar mouse)  │
│                              │
│ [⏮] [⏯] [⏭] | ━━━○──── |    │
│ [🔊] [CC] [⚙️] [↗]           │
│                              │
└──────────────────────────────┘
```
- Controles: Play, Pause, Volume, Progresso, CC, Qualidade, Fullscreen
- Auto-pause ao minimizar
- Continuar assistindo (salva posição)
- Próximo episódio (auto-play timer)

#### 17. Seletor de Idiomas & Legendas
- Switcher: Português, English, Español
- CC: On/Off + Tamanho
- Opcionalidades

#### 18. Relatório de Problemas (Player)
- "Problema ao reproduzir?"
- Conexão / Qualidade / Buffering / Outro
- Detalhes
- Enviar

#### 19. Continuar Assistindo (Carrossel + Tela)
- Lista com thumbnail + progresso
- Badge: "Ep 3/10"
- Resumir / Recomeçar buttons
- Remover da lista

---

### FAVORITOS & MINHA LISTA (4 telas)

#### 20. Favoritos
```
Grid 2-3 colunas de media cards
- Poster com overlay:
  - Play button
  - Remove button (X)
```
- Ações: Remover, Compartilhar
- Estados vazios: "Nenhum favorito"

#### 21. Minha Lista
- Adicionados recentemente
- Carryover: Play/Remove
- Categoria vazia

#### 22. Watchlist
- Fila de watchlist
- Reorganizar (drag-drop)
- Prioridade
- Remover

#### 23. Favoritos Sincronizados
- Cloud sync badge
- "Sincronizado com sua conta"
- Dados na nuvem

---

### DOWNLOADS (2 telas)

#### 24. Downloads
```
┌────────────────────────┐
│ Filme/Série            │
│ [████░░░░] 45% (240MB) │
│ [Parar] [Remover]      │
├────────────────────────┤
│ Outro Filme            │
│ [██████████] 100%      │
│ [Apagar]               │
└────────────────────────┘
```
- Progresso em %
- Tamanho real
- Pause/Resume
- Delete

#### 25. Configuração de Downloads
- Qualidade padrão (HD/Full HD)
- WiFi only toggle
- Auto-download
- Armazenamento restante

---

### PERFIL & USUÁRIO (7 telas)

#### 26. Meu Perfil
```
┌──────────────────────┐
│     [Avatar]         │
│      João Silva      │
│                      │
│ 📧 joao@email.com    │
│ 💳 Premium           │
│ ⏳ Dia 45/365        │
│                      │
│ [Editar Perfil]      │
│ [Mudança Avatar]     │
│ [Histórico]          │
│ [Configurações]      │
│ [Sair]               │
└──────────────────────┘
```

#### 27. Editar Perfil
- Nome (edit)
- Email (read-only)
- Bio
- Avatar (change)
- Salvar button

#### 28. Alterar Avatar
- Grid de avatares pré-definidos
- Upload custom
- Crop tool
- Preview

#### 29. Histórico de Assistência
- Timeline: Hoje, Ontem, Semana passada
- Titles com timestamp
- Remover individual
- Limpar tudo button

#### 30. Notificações
```
┌──────────────────────┐
│ 🎬 Novo Lançamento   │
│ "Série XYZ S2"       │
│ Há 2 horas           │ [Remover]
├──────────────────────┤
│ 👤 Novo Perfil       │
│ Cadastro confirmado  │
│ Hoje                 │ [Remover]
└──────────────────────┘
```
- Lista com timestamp
- Delete individual
- Mark as read
- Limpar tudo

#### 31. Gerenciar Notificações (Preferências)
- Novo conteúdo: Toggle
- Promoções: Toggle
- Atualizações: Toggle
- Sons: Toggle
- Vibração: Toggle

#### 32. Múltiplos Perfis
- Lista de perfis criados
- Ícone + Nome
- Edit / Delete per profile
- Adicionar novo perfil
- Age rating (Kids, Teen, Adult)

---

### CONFIGURAÇÕES & SISTEMA (6 telas)

#### 33. Configurações Principais
```
┌──────────────────────────┐
│ 🌙 Tema                 │
│    ○ Escuro (default)   │
│    ○ Claro             │
│                         │
│ 🌍 Idioma               │
│    Português (Brasil)   │
│                         │
│ 📺 Reprodução           │
│    [Preferência...]     │
│                         │
│ 🎮 Qualidade            │
│    [Automático]         │
│                         │
│ 🔊 Áudio                │
│    Português (Dublado)  │
│    [Editar...]          │
│                         │
│ 📞 Contato Suporte      │
│ 📋 Política Privacidade │
│ ⚖️  Termos de Uso        │
│ ℹ️  Sobre               │
│ ➡️  Logout              │
└──────────────────────────┘
```

#### 34. Controle Parental
- PIN setup (4 dígitos)
- Age Rating: Livre, 12, 14, 16, 18
- Restrições por gênero
- Bloqueio de compra (in-app)

#### 35. Qualidade Padrão
- WiFi: Full HD / 4K
- Mobile: HD / Full HD
- Auto: Automática (recomendado)
- Dados: Econômico

#### 36. Privacidade & Dados
- Compartilhamento: Personalizado / Anônimo / Nunca
- Histórico: Salvar / Não salvar
- Tracking ads: Toggle
- Sincronização: Toggle

#### 37. Sobre
- Versão: 1.0.0 (Build 42)
- Desenvolvedor
- Website
- Social links

#### 38. Edição de Conta
- Email: pode mudar
- Senha: change button
- 2FA: Toggle

---

### ASSINATURAS & PAGAMENTO (4 telas)

#### 39. Planos (Subscriptions)
```
Mostrar 3 cards:

🟣 BÁSICO — R$ 10/mês
2 telas | Full HD
✅ Inclui: ...
[ASSINAR]

🔵 STANDARD — R$ 20/mês
4 telas | Full HD
✅ Inclui: ...
[ASSINAR]

👑 PREMIUM — R$ 30/mês ⭐ Mais Popular
6 telas | 4K HDR
✅ Inclui: ...
[ASSINAR]
```

#### 40. Confirmação de Pagamento
- Plano selecionado
- Valor total
- Métodos: Cartão, PayPal, Google Pay, Apple Pay
- Dados do cartão (se necessário)
- Termos: Checkbox
- Confirmar button

#### 41. Histórico de Pagamentos
```
┌──────────────────────┐
│ Premium              │
│ R$ 30,00             │
│ Cartão ****1234      │
│ 15/07/2024           │
│ Status: ✅ Aprovado  │
├──────────────────────┤
│ Standard             │
│ R$ 20,00             │
│ 15/06/2024           │
│ Status: ✅ Aprovado  │
└──────────────────────┘
```

#### 42. Gerenciar Assinatura
- Plano atual
- Próxima cobrança
- Alterar plano
- Cancelar assinatura
- Histórico

---

### ADMIN & DASHBOARD (6 telas)

#### 43. Dashboard Admin
```
┌───────────────────────────────┐
│ 📊 DASHBOARD ADMIN            │
├───────────────────────────────┤
│ Usuários: 125.342             │
│ Receita: R$ 1.250.000 (Mês)   │
│ Assinantes: 85.432            │
│ Taxa Churn: 2.3%              │
│                               │
│ [Gráfico Receita]             │
│ [Gráfico Usuários]            │
│                               │
│ Últimas Transações:           │
│ - João Silva Premium $30      │
│ - Maria Santos Standard $20   │
│ - Carlos Brás Básico $10      │
└───────────────────────────────┘
```

#### 44. Gerenciar Usuários
- Tabela: ID, Nome, Email, Plano, Data Criação
- Buscar / Filtrar
- Ações: Edit, Delete, Ban, Email
- Bulk actions

#### 45. Gerenciar Conteúdo (Filmes/Séries)
- Upload de novo filme/série
- Editor de metadados
- Gerenciar episódios
- Imagens (poster, banner)
- Trailers

#### 46. Análises & Reports
- Gráfico Receita (Linha)
- Gráfico Usuários (Bar)
- Gráfico Churn (Pie)
- Tabela Top 10 conteúdo
- CSV Export

#### 47. Notificações Admin
- Alertas: Pagamento falhado, Erro servidor, Novo bug report
- Lista com timestamp
- Marcar lido
- Ações rápidas

#### 48. Logs & Auditorias
- Tabela: Timestamp, Usuário, Ação, Status
- Filtros: Tipo, Data, Usuário
- Export logs

---

## 🔄 FLUXO DE NAVEGAÇÃO

### Bottom Navigation (Móvel)
```
┌────────────────────────────────┐
│                                │
│      [Tela Ativa]              │
│                                │
├────────────────────────────────┤
│ 🏠      🔍      ❤️      📥    👤 │
│ Home  Search  Favorites Download Profile
└────────────────────────────────┘
```

### Drawer/Sidebar (Tablet/Desktop)
- Logo
- Home
- Explorar
- Minha Lista
- Downloads
- Favoritos
- Notificações
- Perfil
- Configurações
- Admin (se for admin)
- Logout

---

## ✨ ANIMAÇÕES & TRANSIÇÕES

### Transições de Tela
- **Entrada padrão:** Slide right (200ms)
- **Saída padrão:** Fade out (150ms)
- **Especiais:** Zoom in + fade (300ms)

### Micro-interações
- **Botão pressionado:** Ripple + Scale 0.95 (100ms)
- **Card hover:** Lift + shadow increase (150ms)
- **Carrossel:** Velocity-based fling + deceleration
- **Pull-to-refresh:** Rotation + scale animation

### Loading
- **Shimmer:** Loop 2s horizontal
- **Spinner:** 360° rotation (indefinido)
- **Skeleton:** Múltiplos shimmers staggered

---

## 📐 GUIDELINES & PADRÕES

### Spacing
- **Micro:** 4px, 8px
- **Pequeno:** 12px, 16px
- **Médio:** 24px, 32px
- **Grande:** 40px, 48px

### Elevation/Sombra
- **Card padrão:** 0 4px 8px (preto 15%)
- **Card hover:** 0 10px 20px (preto 25%)
- **Modal:** 0 20px 40px (preto 40%)

### Border Radius
- **Botões:** 12px
- **Cards:** 12px
- **Input:** 12px
- **Avatar:** circle (50%)
- **Badges:** 20px

### Responsive Breakpoints
- **Mobile:** < 600px (1-2 colunas)
- **Tablet:** 600px - 1024px (2-3 colunas)
- **Desktop:** > 1024px (3-4 colunas)

---

## 🎬 RESULTADO FINAL

✅ **40+ Telas desenhadas**  
✅ **Design premium & moderno**  
✅ **Componentes reutilizáveis**  
✅ **Animações suaves**  
✅ **Responsivo (mobile/tablet/web)**  
✅ **Acessível (WCAG AA)**  
✅ **Performance otimizada**  

**Pronto para implementação em Flutter com excelente UX! 🚀**
