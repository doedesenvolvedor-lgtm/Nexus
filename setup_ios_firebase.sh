#!/bin/bash

# 🍎 Firebase iOS Setup - Script Automático
# Este script faz TUDO menos o que requer UI do Xcode (SPM + Capabilities)

set -e  # Parar se algo falhar

echo "════════════════════════════════════════════════════"
echo "  🍎 Firebase iOS - Setup Automático"
echo "════════════════════════════════════════════════════"
echo ""

# Cores para output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# ============================================================
# ETAPA 1: Verificar Xcode
# ============================================================
echo -e "${BLUE}[1/5] Verificando Xcode...${NC}"
if ! command -v xcode-select &> /dev/null; then
    echo -e "${RED}❌ Xcode não instalado${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Xcode encontrado${NC}"
echo ""

# ============================================================
# ETAPA 2: Verificar Flutter
# ============================================================
echo -e "${BLUE}[2/5] Verificando Flutter...${NC}"
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}❌ Flutter não instalado${NC}"
    exit 1
fi
FLUTTER_VERSION=$(flutter --version | head -n 1)
echo -e "${GREEN}✅ Flutter: $FLUTTER_VERSION${NC}"
echo ""

# ============================================================
# ETAPA 3: CocoaPods - Pod Install
# ============================================================
echo -e "${BLUE}[3/5] Instalando CocoaPods (Firebase SDKs)...${NC}"
cd "$(dirname "$0")/nexus_mobile/ios"

if [ ! -f "Podfile" ]; then
    echo -e "${RED}❌ Podfile não encontrado em ios/${NC}"
    exit 1
fi

echo "📦 Executando: pod install --repo-update"
pod install --repo-update

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ CocoaPods instalado com sucesso${NC}"
else
    echo -e "${RED}❌ Erro ao instalar CocoaPods${NC}"
    echo -e "${YELLOW}💡 Dica: Tente: cd ios && pod repo update && pod install${NC}"
    exit 1
fi
echo ""

# ============================================================
# ETAPA 4: Flutter - Pub Get
# ============================================================
cd "$(dirname "$0")"
echo -e "${BLUE}[4/5] Sincronizando dependências Flutter...${NC}"
cd nexus_mobile

flutter pub get

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Dependências sincronizadas${NC}"
else
    echo -e "${RED}❌ Erro ao sincronizar dependências${NC}"
    exit 1
fi
echo ""

# ============================================================
# ETAPA 5: Build iOS
# ============================================================
echo -e "${BLUE}[5/5] Compilando app iOS (Debug)...${NC}"
echo "⏳ Isso pode levar 5-10 minutos..."

flutter build ios --debug

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Build iOS compilado com sucesso${NC}"
else
    echo -e "${RED}❌ Erro ao compilar iOS${NC}"
    echo -e "${YELLOW}💡 Dica: Tente: flutter clean && flutter pub get && flutter build ios --debug${NC}"
    exit 1
fi
echo ""

# ============================================================
# RESUMO FINAL
# ============================================================
echo "════════════════════════════════════════════════════"
echo -e "${GREEN}✅ SETUP AUTOMÁTICO CONCLUÍDO!${NC}"
echo "════════════════════════════════════════════════════"
echo ""
echo "📱 Status:"
echo -e "${GREEN}  ✅ CocoaPods instalado${NC}"
echo -e "${GREEN}  ✅ Firebase SDKs disponíveis${NC}"
echo -e "${GREEN}  ✅ Flutter dependencies sincronizadas${NC}"
echo -e "${GREEN}  ✅ App iOS compilado${NC}"
echo ""
echo "⚠️  IMPORTANTE - Falta fazer no Xcode:"
echo "  1. File → Add Packages"
echo "  2. Cole: https://github.com/firebase/firebase-ios-sdk"
echo "  3. Selecione: FirebaseAnalytics, FirebaseMessaging, FirebaseCrashlytics"
echo "  4. Clique: Finish"
echo ""
echo "  5. Runner → Signing & Capabilities"
echo "  6. + Capability → Push Notifications"
echo ""
echo "🚀 Depois disso, você pode rodar:"
echo -e "${BLUE}  flutter run -d iPhone\\ 15${NC}"
echo ""
echo "❓ Já fez essas etapas no Xcode? Se sim, rode:"
echo -e "${BLUE}  flutter run -d iPhone\\ 15${NC}"
echo "════════════════════════════════════════════════════"
