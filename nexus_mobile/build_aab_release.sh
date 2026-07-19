#!/bin/bash
# 🚀 Build Script para Nexustwos - Android App Bundle (AAB)
# Gera AAB para Google Play Store

set -e

echo "🚀 Nexustwos - Android App Bundle (Release)"
echo "=========================================="
echo ""

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Diretórios
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_OUTPUT="$PROJECT_DIR/build/app/outputs/bundle/release"
KEYSTORE_PATH="$PROJECT_DIR/android/app/keystore/nexus.jks"

echo -e "${BLUE}📍 Diretório:${NC} $PROJECT_DIR"
echo -e "${BLUE}📦 Output:${NC} $BUILD_OUTPUT"
echo ""

# Verificar keystore
if [ ! -f "$KEYSTORE_PATH" ]; then
    echo -e "${RED}❌ Erro: Keystore não encontrado${NC}"
    echo -e "${YELLOW}💡 Primeiro gere o keystore:${NC}"
    echo "   ./build_apk_release.sh"
    exit 1
fi

# Verificar KEYSTORE_PASSWORD
if [ -z "$KEYSTORE_PASSWORD" ]; then
    echo -e "${RED}❌ Erro: KEYSTORE_PASSWORD não definida${NC}"
    echo "   export KEYSTORE_PASSWORD='sua_senha_aqui'"
    exit 1
fi

export KEYSTORE_PATH="$KEYSTORE_PATH"
export KEYSTORE_ALIAS="nexus_key"

echo -e "${YELLOW}🔐 Configuração de Signing:${NC}"
echo "   Keystore: $KEYSTORE_PATH"
echo "   Alias: $KEYSTORE_ALIAS"
echo ""

# Clean
echo -e "${YELLOW}🧹 Limpando builds anteriores...${NC}"
flutter clean --verbose

# Get dependencies
echo -e "${YELLOW}📚 Instalando dependências...${NC}"
flutter pub get

# Build AAB
echo -e "${YELLOW}🔨 Compilando Android App Bundle (AAB)...${NC}"
flutter build appbundle --release -v

# Verify
if [ -f "$BUILD_OUTPUT/app-release.aab" ]; then
    SIZE=$(ls -lh "$BUILD_OUTPUT/app-release.aab" | awk '{print $5}')
    echo ""
    echo -e "${GREEN}✅ Build concluído com sucesso!${NC}"
    echo -e "${GREEN}📦 AAB gerado:${NC} $BUILD_OUTPUT/app-release.aab"
    echo -e "${GREEN}📊 Tamanho:${NC} $SIZE"
    echo ""
    echo -e "${BLUE}ℹ️  Próximos passos:${NC}"
    echo "   1. Acesse Google Play Console"
    echo "   2. Vá para: Meus aplicativos > Nexustwos > Versões"
    echo "   3. Clique em Criar versão de teste"
    echo "   4. Faça upload de: $BUILD_OUTPUT/app-release.aab"
    echo "   5. Configure testes e rollout"
else
    echo -e "${RED}❌ Erro: AAB não foi gerado${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}✅ Concluído!${NC}"
