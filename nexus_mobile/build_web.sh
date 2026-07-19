#!/bin/bash
# 🌐 Build Script para Nexustwos - Web
# Gera aplicação web otimizada para deploy

set -e

echo "🌐 Nexustwos - Web Build"
echo "======================="
echo ""

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Diretórios
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_OUTPUT="$PROJECT_DIR/build/web"

echo -e "${BLUE}📍 Diretório:${NC} $PROJECT_DIR"
echo -e "${BLUE}📦 Output:${NC} $BUILD_OUTPUT"
echo ""

# Verificar Chrome/Chromium
if ! command -v chromium-browser &> /dev/null && ! command -v google-chrome &> /dev/null && ! command -v chrome &> /dev/null; then
    echo -e "${YELLOW}⚠️  Chrome/Chromium não encontrado${NC}"
    echo -e "${YELLOW}💡 Para testar localmente, instale Chrome/Chromium${NC}"
    echo "   sudo apt-get install chromium-browser"
fi

# Clean
echo -e "${YELLOW}🧹 Limpando builds anteriores...${NC}"
flutter clean --verbose

# Get dependencies
echo -e "${YELLOW}📚 Instalando dependências...${NC}"
flutter pub get

# Build Web
echo -e "${YELLOW}🔨 Compilando Web Release...${NC}"
flutter build web --release -v

# Verify
if [ -d "$BUILD_OUTPUT" ] && [ -f "$BUILD_OUTPUT/index.html" ]; then
    SIZE=$(du -sh "$BUILD_OUTPUT" | awk '{print $1}')
    FILES=$(find "$BUILD_OUTPUT" -type f | wc -l)
    
    echo ""
    echo -e "${GREEN}✅ Build concluído com sucesso!${NC}"
    echo -e "${GREEN}📁 Diretório:${NC} $BUILD_OUTPUT"
    echo -e "${GREEN}📊 Tamanho:${NC} $SIZE"
    echo -e "${GREEN}📂 Arquivos:${NC} $FILES"
    echo ""
    
    echo -e "${BLUE}ℹ️  Próximos passos:${NC}"
    echo ""
    echo -e "${YELLOW}1️⃣  Testar localmente:${NC}"
    echo "   cd $BUILD_OUTPUT"
    echo "   python3 -m http.server 8000"
    echo "   # Acesse: http://localhost:8000"
    echo ""
    
    echo -e "${YELLOW}2️⃣  Deploy em Vercel:${NC}"
    echo "   npm install -g vercel"
    echo "   vercel --prod"
    echo ""
    
    echo -e "${YELLOW}3️⃣  Deploy em Firebase:${NC}"
    echo "   npm install -g firebase-tools"
    echo "   firebase login"
    echo "   firebase init hosting"
    echo "   firebase deploy"
    echo ""
    
    echo -e "${YELLOW}4️⃣  Deploy em Netlify:${NC}"
    echo "   npm install -g netlify-cli"
    echo "   netlify deploy --prod --dir=$BUILD_OUTPUT"
    echo ""
    
    echo -e "${BLUE}📄 Arquivos importantes:${NC}"
    echo "   - index.html"
    echo "   - main.dart.js"
    echo "   - manifest.json"
    echo "   - icons/"
    echo "   - flutter.js"
    
else
    echo -e "${RED}❌ Erro: Build web não foi gerado${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}✅ Concluído!${NC}"
