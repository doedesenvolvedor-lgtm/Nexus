# 🚀 Guia Rápido - Painel Admin Nexustwos v2.0

## ⚡ Quick Start (5 minutos)

### 1. Iniciar o Projeto

```bash
cd /workspaces/Nexus/admin-panel-nexus
npm install  # Se for a primeira vez
npm run dev
```

**URL**: `http://localhost:3000`

### 2. Fazer Login

```
Email: admin@nexus.com
Senha: admin123456
```

### 3. Explorar o Painel

Clique nos itens do menu lateral para acessar as diferentes seções.

---

## 📖 Menu Principal

### 📊 Dashboard
- **O quê**: Visão geral da plataforma
- **Quando usar**: Para monitorar métricas em tempo real
- **Dados**: Usuários, receita, assinantes, dispositivos

### 🎬 Conteúdo
- **Filmes**: Adicione, edite e delete filmes
- **Séries**: Gerencie séries e temporadas
- **Episódios**: Configure episódios individuais
- **Canais**: IPTV/Canais ao vivo
- **Categorias**: Organize conteúdo
- **Banners**: Crie promoções

### 👥 Usuários
- **Usuários**: Gerencie contas (bloquear, alterar plano)
- **Perfis**: Subperfis com controle parental
- **Trials**: Usuários em teste (estender ou cancelar)

### 💳 Assinaturas
- **Planos**: Configure planos de assinatura
- **Assinaturas**: Ativas, canceladas, em atraso
- **Pagamentos**: Todas as transações
- **Cupons**: Descontos e promoções

### 🛠️ Ferramentas
- **Importador M3U**: Upload de listas IPTV
- **TMDb**: Sincronize dados de filmes/séries

### 📊 Monitoramento
- **Notificações**: Envie mensagens aos usuários
- **Comentários**: Aprove/rejeite comentários
- **Logs**: Histórico de atividades
- **Analytics**: Gráficos e relatórios

### ⚙️ Configurações
- Dados da plataforma
- Credenciais de APIs
- Backup do banco

### 👤 Meu Perfil
- Editar informações
- Alterar senha
- Preferências

---

## 🎯 Tarefas Comuns

### Adicionar um Novo Filme

1. Acesse **Conteúdo → Filmes**
2. Clique em **"Novo Filme"**
3. Preencha:
   - Título
   - Sinopse
   - Ano
   - Duração
   - Qualidade
   - Categoria
4. Clique em **"Criar"**

### Criar um Cupom de Desconto

1. Acesse **Assinaturas → Cupons**
2. Clique em **"Novo Cupom"**
3. Configure:
   - Código (ex: NEXUS2024)
   - Tipo (% ou R$)
   - Valor de desconto
   - Máximo de usos
4. Clique em **"Criar"**

### Importar Lista M3U

1. Acesse **Ferramentas → Importador M3U**
2. Escolha:
   - **Por URL**: Cole a URL e clique em "Importar"
   - **Por Arquivo**: Selecione arquivo local
3. Aguarde progresso chegar a 100%
4. Remova duplicatas se necessário

### Sincronizar com TMDb

1. Acesse **Ferramentas → TMDb Integration**
2. Digite nome do filme/série
3. Clique em **"Buscar"**
4. Clique em **"Sincronizar"** no resultado

### Enviar Notificação

1. Acesse **Notificações**
2. Clique em **"Enviar Notificação"**
3. Preencha:
   - Título e mensagem
   - Selecione público alvo
   - Agende se quiser (opcional)
4. Clique em **"Enviar"**

### Bloquear um Usuário

1. Acesse **Usuários → Usuários**
2. Encontre o usuário
3. Clique em **"Editar"**
4. Marque "Bloqueado"
5. Salve

### Exportar Logs

1. Acesse **Logs**
2. Clique em **"Exportar CSV"**
3. Arquivo será baixado

---

## 🎨 Interface - Elementos Principais

### Botões
- 🟣 **Primário (Purple)**: Ação principal (Criar, Salvar, Enviar)
- 🔵 **Secundário (Blue)**: Ações auxiliares (Editar, Filtrar)
- ⚫ **Ghost (Preto)**: Ações leves (Cancelar)
- 🔴 **Danger (Vermelho)**: Ações destrutivas (Deletar)

### Badges (Tags coloridas)
- 🟢 **Verde**: Sucesso, Ativo
- 🟡 **Amarelo**: Aviso, Pendente
- 🔴 **Vermelho**: Erro, Inativo
- 🟣 **Purple**: Informação

### Tabelas
- **Filtros**: Topo à esquerda
- **Paginação**: Rodapé
- **Ordenação**: Clique no cabeçalho
- **Ações**: Ícones à direita

### Modals
- Aparecem no centro
- Clique fora para fechar
- Ou clique "Cancelar"

---

## ⌨️ Atalhos Úteis

| Ação | Como |
|------|------|
| Atualizar página | F5 |
| Filtrar tabela | Use os filtros no topo |
| Buscar rápido | Ctrl+F (browser) |
| Copiar de cupom | Clique no ícone 📋 |
| Exportar | Botão no topo (CSV/PDF) |

---

## 🐛 Troubleshooting

### Página em branco
- Atualize (F5)
- Limpe cache (Ctrl+Shift+Del)
- Faça login novamente

### Tabela não carrega
- Verifique conexão de internet
- Tente atualizar
- Limpe filtros

### Modal não fecha
- Clique fora da modal
- Clique em "Cancelar"
- Pressione ESC

### Botão não funciona
- Verifique se tem permissão
- Valide os campos do formulário
- Tente novamente

---

## 📊 Dashboard - Indicadores

| Métrica | O que significa |
|---------|-----------------|
| Total de Usuários | Todos os usuários cadastrados |
| Usuários Online | Conectados agora |
| Assinantes Ativos | Planos vigentes |
| Usuários Trial | Em período de teste |
| Receita Mensal | Vendas este mês |
| Taxa de Conversão | % que viram Premium |

---

## 🔐 Segurança

- ✅ Sempre faça logout ao terminar
- ✅ Não compartilhe credenciais
- ✅ Altere senha regularmente
- ✅ Não use senhas simples
- ✅ Tenha cuidado com ações irreversíveis

---

## 📞 Dúvidas Frequentes

**P: Como resetar a senha de um usuário?**
R: Vá em Usuários → Editar usuário → Use "Resetar Senha"

**P: Posso deletar um usuário permanentemente?**
R: Sim, em Usuários → Deletar (irreversível)

**P: Como agendar uma notificação?**
R: Em Notificações → Marque "Agendar" e escolha data/hora

**P: Qual é o limite de upload?**
R: Máximo 50MB por arquivo

**P: Como fazer backup?**
R: Em Configurações → Criar Backup

**P: Posso desativar 2FA?**
R: Sim, em Meu Perfil → Segurança → Desativar 2FA

---

## 💡 Dicas Profissionais

1. **Use categorias**: Organize filmes em categorias para melhor UX
2. **Planeje banners**: Agende promoções com antecedência
3. **Monitore logs**: Revise logs diariamente
4. **Faça backups**: Backup semanal do banco de dados
5. **Teste cupons**: Sempre teste cupons antes de publicar
6. **Sincronize TMDb**: Mantenha dados atualizados
7. **Agende notificações**: Envie notificações em horários de pico
8. **Revise comentários**: Modere comentários para melhor comunidade

---

## 🎯 Checklist - Primeiro Uso

- [ ] Fazer login com sucesso
- [ ] Acessar Dashboard
- [ ] Adicionar um filme
- [ ] Criar um cupom
- [ ] Enviar uma notificação
- [ ] Visualizar logs
- [ ] Acessar perfil
- [ ] Alterar senha
- [ ] Explorar Analytics

---

## 📱 Compatibilidade

| Dispositivo | Suportado |
|-------------|-----------|
| Desktop | ✅ Totalmente |
| Tablet | ✅ Responsivo |
| Mobile | ✅ Otimizado |
| Chrome | ✅ Recomendado |
| Firefox | ✅ OK |
| Safari | ✅ OK |
| Edge | ✅ OK |

---

## 🎬 Versão

**Painel Admin Nexustwos v2.0.0**

Desenvolvido com React 18 + Vite + Tailwind CSS

Última atualização: 2026-07-19

---

**Desenvolvido com ❤️ para Nexustwos**
