#!/bin/bash

# 🍎 Firebase iOS Setup - SCRIPT PARA MAC
# Execute este script no seu Mac (não no Linux!)
# Este script faz TODO o setup iOS automaticamente

set -e

echo "════════════════════════════════════════════════════"
echo "  🍎 Firebase iOS - Setup Completo para Mac"
echo "════════════════════════════════════════════════════"
echo ""

# Cores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# ============================================================
# Verificar pré-requisitos
# ============================================================
echo -e "${BLUE}[VERIFICAÇÃO] Checando pré-requisitos...${NC}"
echo ""

# Xcode
if ! command -v xcode-select &> /dev/null; then
    echo -e "${RED}❌ Xcode Command Line Tools não instalado${NC}"
    echo "   Execute: xcode-select --install"
    exit 1
fi
echo -e "${GREEN}✅ Xcode Command Line Tools${NC}"

# Flutter
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}❌ Flutter não instalado${NC}"
    echo "   Baixe em: https://flutter.dev/docs/get-started/install/macos"
    exit 1
fi
FLUTTER_VERSION=$(flutter --version | head -n 1)
echo -e "${GREEN}✅ $FLUTTER_VERSION${NC}"

# CocoaPods
if ! command -v pod &> /dev/null; then
    echo -e "${RED}❌ CocoaPods não instalado${NC}"
    echo "   Execute: sudo gem install cocoapods"
    exit 1
fi
echo -e "${GREEN}✅ CocoaPods instalado${NC}"
echo ""

# ============================================================
# ETAPA 1: Navegar para projeto
# ============================================================
echo -e "${BLUE}[1/6] Preparando projeto...${NC}"

if [ ! -f "pubspec.yaml" ]; then
    echo -e "${RED}❌ pubspec.yaml não encontrado${NC}"
    echo "   Execute este script a partir da pasta: nexus_mobile/"
    echo "   Exemplo: cd nexus_mobile && bash ../setup_ios_for_mac.sh"
    exit 1
fi

echo -e "${GREEN}✅ Projeto Flutter detectado${NC}"
echo ""

# ============================================================
# ETAPA 2: Flutter Pub Get
# ============================================================
echo -e "${BLUE}[2/6] Sincronizando dependências Flutter...${NC}"
flutter pub get
echo -e "${GREEN}✅ Dependências sincronizadas${NC}"
echo ""

# ============================================================
# ETAPA 3: CocoaPods Install
# ============================================================
echo -e "${BLUE}[3/6] Instalando Firebase SDKs via CocoaPods...${NC}"
cd ios

if [ ! -f "Podfile" ]; then
    echo -e "${RED}❌ Podfile não encontrado${NC}"
    exit 1
fi

echo "   Executando: pod install --repo-update"
pod install --repo-update

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Erro ao instalar pods${NC}"
    echo "   Tente: pod repo update && pod install"
    exit 1
fi

echo -e "${GREEN}✅ CocoaPods instalado${NC}"
cd ..
echo ""

# ============================================================
# ETAPA 4: Verificar GoogleService-Info.plist
# ============================================================
echo -e "${BLUE}[4/6] Verificando GoogleService-Info.plist...${NC}"

if [ -f "ios/Runner/GoogleService-Info.plist" ]; then
    echo -e "${GREEN}✅ GoogleService-Info.plist encontrado${NC}"
else
    echo -e "${RED}❌ GoogleService-Info.plist NÃO encontrado${NC}"
    echo "   Arquivo esperado: ios/Runner/GoogleService-Info.plist"
    exit 1
fi
echo ""

# ============================================================
# ETAPA 5: Abrir Xcode
# ============================================================
echo -e "${BLUE}[5/6] Abrindo Xcode...${NC}"
open ios/Runner.xcworkspace

echo -e "${YELLOW}⏳ Aguardando Xcode abrir (10 segundos)...${NC}"
sleep 10
echo ""

# ============================================================
# ETAPA 6: Instruções para Xcode
# ============================================================
echo -e "${BLUE}[6/6] Instruções para Xcode${NC}"
echo ""
echo -e "${YELLOW}⚠️  FAÇA ISSO NO XCODE AGORA:${NC}"
echo ""
echo "1️⃣  ADICIONAR FIREBASE SDKs"
echo "   Xcode menu → File → Add Packages"
echo "   Cole: https://github.com/firebase/firebase-ios-sdk"
echo "   Selecione versão: 10.24.0 (ou superior)"
echo "   Clique: Next"
echo ""
echo "2️⃣  SELECIONAR BIBLIOTECAS"
echo "   Marque com ✓:"
echo "   ☑️ FirebaseAnalytics"
echo "   ☑️ FirebaseMessaging"
echo "   ☑️ FirebaseCrashlytics"
echo "   Clique: Finish"
echo "   Aguarde: 5-10 minutos"
echo ""
echo "3️⃣  ADICIONAR PUSH NOTIFICATIONS"
echo "   No Xcode:"
echo "   Runner → Signing & Capabilities"
echo "   + Capability → Push Notifications"
echo ""
echo -e "${GREEN}✅ Quando terminar no Xcode:${NC}"
echo ""

# ============================================================
# Perguntar se terminou
# ============================================================
read -p "Você completou as 3 etapas acima no Xcode? (s/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Ss]$ ]]; then
    echo ""
    echo -e "${BLUE}[PRÓXIMO] Compilando app iOS...${NC}"
    
    # ============================================================
    # ETAPA BONUS: Build iOS
    # ============================================================
    flutter build ios --debug
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Build iOS compilado com sucesso${NC}"
        echo ""
        echo -e "${BLUE}🚀 Próxima etapa:${NC}"
        echo "   flutter run -d iPhone\\ 15"
        echo "   (ou seu device favorito)"
    else
        echo -e "${RED}❌ Erro ao compilar iOS${NC}"
        echo "   Tente: flutter clean && flutter pub get && flutter build ios --debug"
    fi
else
    echo ""
    echo -e "${YELLOW}Quando terminar no Xcode, execute:${NC}"
    echo "   flutter build ios --debug"
    echo "   flutter run -d iPhone\\ 15"
fi

echo ""
echo "════════════════════════════════════════════════════"
echo -e "${GREEN}✅ SETUP CONCLUÍDO!${NC}"
echo "════════════════════════════════════════════════════"
