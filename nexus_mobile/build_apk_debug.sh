#!/bin/bash
# 🚀 Build Script para Nexustwos - Android APK (Debug)
# Gera APK debug pronto para testes em dispositivos

set -e

echo "🚀 Nexustwos - Android Build (Debug)"
echo "=================================="
echo ""

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Diretórios
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_OUTPUT="$PROJECT_DIR/build/app/outputs/apk/debug"

echo -e "${YELLOW}📍 Diretório do Projeto:${NC} $PROJECT_DIR"
echo -e "${YELLOW}📦 Output:${NC} $BUILD_OUTPUT"
echo ""

# Clean
echo -e "${YELLOW}🧹 Limpando builds anteriores...${NC}"
flutter clean --verbose

# Get dependencies
echo -e "${YELLOW}📚 Instalando dependências...${NC}"
flutter pub get

# Build Debug APK
echo -e "${YELLOW}🔨 Compilando APK Debug...${NC}"
flutter build apk --debug -v

# Verify
if [ -f "$BUILD_OUTPUT/app-debug.apk" ]; then
    SIZE=$(ls -lh "$BUILD_OUTPUT/app-debug.apk" | awk '{print $5}')
    echo -e "${GREEN}✅ Build concluído com sucesso!${NC}"
    echo -e "${GREEN}📦 APK gerado:${NC} $BUILD_OUTPUT/app-debug.apk"
    echo -e "${GREEN}📊 Tamanho:${NC} $SIZE"
    echo ""
    echo -e "${YELLOW}💡 Para instalar em device/emulator:${NC}"
    echo "   adb install -r $BUILD_OUTPUT/app-debug.apk"
else
    echo -e "${RED}❌ Erro: APK não foi gerado${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}✅ Concluído!${NC}"
