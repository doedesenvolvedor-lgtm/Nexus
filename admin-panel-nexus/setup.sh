#!/bin/bash

# Script para verificar e atualizar o painel administrativo

echo "🚀 Verificando integridade do painel administrativo..."

# Verificar se node_modules existe
if [ ! -d "node_modules" ]; then
    echo "📦 Instalando dependências..."
    npm install
fi

# Verificar se arquivo .env.local existe
if [ ! -f ".env.local" ]; then
    echo "⚙️  Criando arquivo .env.local..."
    cp .env.example .env.local
    echo "📝 Edite .env.local com suas configurações"
fi

# Verificar versão do Node
NODE_VERSION=$(node -v)
echo "✅ Node.js: $NODE_VERSION"

# Verificar versão do npm
NPM_VERSION=$(npm -v)
echo "✅ npm: $NPM_VERSION"

# Listar scripts disponíveis
echo ""
echo "📋 Scripts disponíveis:"
echo ""
echo "  npm run dev        - Iniciar desenvolvimento"
echo "  npm run build      - Build para produção"
echo "  npm run preview    - Preview do build"
echo "  npm run lint       - Verificar código"
echo "  npm run format     - Formatar código"
echo ""
echo "✨ Painel pronto para usar!"
