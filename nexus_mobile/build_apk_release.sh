#!/bin/bash
# 🚀 Build Script para Nexustwos - Android APK (Release)
# Gera APK release pronto para produção (quase pronto para Play Store)

set -e

echo "🚀 Nexustwos - Android Build (Release)"
echo "======================================"
echo ""

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Diretórios
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_OUTPUT="$PROJECT_DIR/build/app/outputs/apk/release"
KEYSTORE_PATH="$PROJECT_DIR/android/app/keystore/nexus.jks"

echo -e "${BLUE}📍 Diretório do Projeto:${NC} $PROJECT_DIR"
echo -e "${BLUE}📦 Output:${NC} $BUILD_OUTPUT"
echo ""

# Verificar keystore
if [ ! -f "$KEYSTORE_PATH" ]; then
    echo -e "${YELLOW}⚠️  Keystore não encontrado: $KEYSTORE_PATH${NC}"
    echo -e "${YELLOW}📝 Gerando novo keystore...${NC}"
    echo ""
    echo -e "${YELLOW}ℹ️  Você será solicitado para fornecer:${NC}"
    echo "   - First and last name: Nexus Streaming"
    echo "   - Organizational Unit: Development"
    echo "   - Organization: Nexus"
    echo "   - City/Locality: São Paulo"
    echo "   - State/Province: SP"
    echo "   - Country Code: BR"
    echo "   - Keystore Password: (mínimo 6 caracteres)"
    echo ""
    
    mkdir -p "$PROJECT_DIR/android/app/keystore"
    keytool -genkey -v \
        -keystore "$KEYSTORE_PATH" \
        -keyalias nexus_key \
        -keyalg RSA \
        -keysize 4096 \
        -validity 10950
    
    echo ""
    echo -e "${GREEN}✅ Keystore criado com sucesso!${NC}"
fi

# Verificar variáveis de ambiente
if [ -z "$KEYSTORE_ALIAS" ]; then
    export KEYSTORE_ALIAS="nexus_key"
    echo -e "${YELLOW}⚠️  KEYSTORE_ALIAS não definida. Usando padrão: nexus_key${NC}"
fi

if [ -z "$KEYSTORE_PASSWORD" ]; then
    echo -e "${RED}❌ Erro: KEYSTORE_PASSWORD não está definida${NC}"
    echo -e "${YELLOW}💡 Configure a variável de ambiente:${NC}"
    echo "   export KEYSTORE_PASSWORD='sua_senha_aqui'"
    exit 1
fi

export KEYSTORE_PATH="$KEYSTORE_PATH"

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

# Build Release APK
echo -e "${YELLOW}🔨 Compilando APK Release...${NC}"
flutter build apk --release -v

# Verify
if [ -f "$BUILD_OUTPUT/app-release.apk" ]; then
    SIZE=$(ls -lh "$BUILD_OUTPUT/app-release.apk" | awk '{print $5}')
    echo ""
    echo -e "${GREEN}✅ Build concluído com sucesso!${NC}"
    echo -e "${GREEN}📦 APK gerado:${NC} $BUILD_OUTPUT/app-release.apk"
    echo -e "${GREEN}📊 Tamanho:${NC} $SIZE"
    echo ""
    
    # Verificar assinatura
    echo -e "${YELLOW}🔍 Verificando assinatura...${NC}"
    jarsigner -verify -verbose -certs "$BUILD_OUTPUT/app-release.apk" | grep -E "verified|jar verified"
    
    echo ""
    echo -e "${BLUE}ℹ️  Próximos passos:${NC}"
    echo "   1. Testar em device/emulator: adb install -r $BUILD_OUTPUT/app-release.apk"
    echo "   2. Para Play Store, use AAB: flutter build appbundle --release"
    echo "   3. Enviar para Google Play Console"
else
    echo -e "${RED}❌ Erro: APK não foi gerado${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}✅ Concluído!${NC}"
