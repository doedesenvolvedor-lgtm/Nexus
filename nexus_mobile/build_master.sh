#!/bin/bash
# 🚀 Build Script Master para Nexustwos
# Executa todos os builds de forma automática

echo "🚀 Nexustwos - Build Master"
echo "=========================="
echo ""

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Menu
show_menu() {
    echo -e "${CYAN}Selecione uma opção:${NC}"
    echo ""
    echo -e "${YELLOW}1${NC}) Build APK Debug (Testes)"
    echo -e "${YELLOW}2${NC}) Build APK Release (Teste - Produ)"
    echo -e "${YELLOW}3${NC}) Build AAB (Google Play Store)"
    echo -e "${YELLOW}4${NC}) Build Web (Deployment)"
    echo -e "${YELLOW}5${NC}) Build Todos (APK Debug + Release + AAB + Web)"
    echo -e "${YELLOW}6${NC}) Informações de Build"
    echo -e "${YELLOW}7${NC}) Sair"
    echo ""
    echo -n "Opção [1-7]: "
}

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Verificar flutter
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}❌ Erro: Flutter não encontrado${NC}"
    echo "    Instale Flutter em: https://flutter.dev/docs/get-started/install"
    exit 1
fi

# Main loop
while true; do
    show_menu
    read -r choice
    
    case $choice in
        1)
            echo ""
            echo -e "${BLUE}▶️  Iniciando Build APK Debug...${NC}"
            echo ""
            chmod +x "$SCRIPT_DIR/build_apk_debug.sh"
            "$SCRIPT_DIR/build_apk_debug.sh"
            ;;
        
        2)
            echo ""
            echo -e "${BLUE}▶️  Iniciando Build APK Release...${NC}"
            echo ""
            chmod +x "$SCRIPT_DIR/build_apk_release.sh"
            "$SCRIPT_DIR/build_apk_release.sh"
            ;;
        
        3)
            echo ""
            echo -e "${BLUE}▶️  Iniciando Build AAB (Google Play Store)...${NC}"
            echo ""
            chmod +x "$SCRIPT_DIR/build_aab_release.sh"
            "$SCRIPT_DIR/build_aab_release.sh"
            ;;
        
        4)
            echo ""
            echo -e "${BLUE}▶️  Iniciando Build Web...${NC}"
            echo ""
            chmod +x "$SCRIPT_DIR/build_web.sh"
            "$SCRIPT_DIR/build_web.sh"
            ;;
        
        5)
            echo ""
            echo -e "${BLUE}▶️  Iniciando Build de Todos os Formatos...${NC}"
            echo ""
            
            # APK Debug
            echo -e "${YELLOW}📱 Buildando APK Debug...${NC}"
            chmod +x "$SCRIPT_DIR/build_apk_debug.sh"
            "$SCRIPT_DIR/build_apk_debug.sh"
            echo ""
            
            # APK Release
            echo -e "${YELLOW}📱 Buildando APK Release...${NC}"
            chmod +x "$SCRIPT_DIR/build_apk_release.sh"
            "$SCRIPT_DIR/build_apk_release.sh"
            echo ""
            
            # AAB
            echo -e "${YELLOW}📱 Buildando AAB...${NC}"
            chmod +x "$SCRIPT_DIR/build_aab_release.sh"
            "$SCRIPT_DIR/build_aab_release.sh"
            echo ""
            
            # Web
            echo -e "${YELLOW}🌐 Buildando Web...${NC}"
            chmod +x "$SCRIPT_DIR/build_web.sh"
            "$SCRIPT_DIR/build_web.sh"
            echo ""
            
            # Resumo
            echo -e "${GREEN}✅ Todos os builds concluídos!${NC}"
            echo ""
            echo -e "${BLUE}📊 Resumo:${NC}"
            
            if [ -f "$SCRIPT_DIR/build/app/outputs/apk/debug/app-debug.apk" ]; then
                SIZE=$(ls -lh "$SCRIPT_DIR/build/app/outputs/apk/debug/app-debug.apk" | awk '{print $5}')
                echo -e "  ${GREEN}✅${NC} APK Debug: $SIZE"
            fi
            
            if [ -f "$SCRIPT_DIR/build/app/outputs/apk/release/app-release.apk" ]; then
                SIZE=$(ls -lh "$SCRIPT_DIR/build/app/outputs/apk/release/app-release.apk" | awk '{print $5}')
                echo -e "  ${GREEN}✅${NC} APK Release: $SIZE"
            fi
            
            if [ -f "$SCRIPT_DIR/build/app/outputs/bundle/release/app-release.aab" ]; then
                SIZE=$(ls -lh "$SCRIPT_DIR/build/app/outputs/bundle/release/app-release.aab" | awk '{print $5}')
                echo -e "  ${GREEN}✅${NC} AAB: $SIZE"
            fi
            
            if [ -d "$SCRIPT_DIR/build/web" ]; then
                SIZE=$(du -sh "$SCRIPT_DIR/build/web" | awk '{print $1}')
                echo -e "  ${GREEN}✅${NC} Web: $SIZE"
            fi
            echo ""
            ;;
        
        6)
            echo ""
            echo -e "${BLUE}📊 Informações de Build${NC}"
            echo ""
            flutter --version
            echo ""
            flutter pub outdated
            echo ""
            ;;
        
        7)
            echo ""
            echo -e "${GREEN}👋 Até logo!${NC}"
            exit 0
            ;;
        
        *)
            echo -e "${RED}❌ Opção inválida. Tente novamente.${NC}"
            sleep 2
            clear
            ;;
    esac
    
    echo ""
    echo -n "Pressione Enter para continuar..."
    read
    clear
done
