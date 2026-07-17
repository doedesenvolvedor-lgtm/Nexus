#!/bin/bash

# Nexus Streaming - Automated Build Script
# Generates APK and AAB with proper signing

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Nexus Streaming - Build Automation   ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"

# Check if keystore exists
KEYSTORE_PATH="${KEYSTORE_PATH:-./android/app/keystore/nexus.jks}"

if [ ! -f "$KEYSTORE_PATH" ]; then
    echo -e "${RED}❌ Keystore not found at $KEYSTORE_PATH${NC}"
    echo -e "${YELLOW}Run: ./generate_keystore.sh${NC}"
    exit 1
fi

# Load environment variables if .env.local exists
if [ -f ".env.local" ]; then
    echo -e "${BLUE}📝 Loading environment variables from .env.local${NC}"
    source .env.local
fi

# Validate required environment variables
if [ -z "$KEYSTORE_PASSWORD" ]; then
    echo -e "${RED}❌ KEYSTORE_PASSWORD not set!${NC}"
    echo "Please set: export KEYSTORE_PASSWORD='your_password'"
    exit 1
fi

# Version info
VERSION=$(grep "^version:" pubspec.yaml | sed 's/version: //')
echo -e "${BLUE}Version: $VERSION${NC}"

# Build choice
echo ""
echo -e "${YELLOW}What would you like to build?${NC}"
echo "1) APK (for testing on device)"
echo "2) AAB (for Google Play Store)"
echo "3) Both APK and AAB"
echo "4) Clean and rebuild both"
read -p "Select option (1-4): " BUILD_CHOICE

case $BUILD_CHOICE in
    1)
        echo -e "${BLUE}📱 Building APK...${NC}"
        flutter build apk --release
        echo -e "${GREEN}✅ APK build complete!${NC}"
        echo -e "Output: ${GREEN}build/app/outputs/apk/release/app-release.apk${NC}"
        ;;
    2)
        echo -e "${BLUE}📦 Building AAB...${NC}"
        flutter build appbundle --release
        echo -e "${GREEN}✅ AAB build complete!${NC}"
        echo -e "Output: ${GREEN}build/app/outputs/bundle/release/app-release.aab${NC}"
        ;;
    3)
        echo -e "${BLUE}📱 Building APK...${NC}"
        flutter build apk --release
        echo -e "${GREEN}✅ APK build complete!${NC}"
        echo -e "Output: ${GREEN}build/app/outputs/apk/release/app-release.apk${NC}"
        
        echo ""
        echo -e "${BLUE}📦 Building AAB...${NC}"
        flutter build appbundle --release
        echo -e "${GREEN}✅ AAB build complete!${NC}"
        echo -e "Output: ${GREEN}build/app/outputs/bundle/release/app-release.aab${NC}"
        ;;
    4)
        echo -e "${YELLOW}🧹 Cleaning previous builds...${NC}"
        flutter clean
        
        echo -e "${BLUE}📱 Building APK...${NC}"
        flutter build apk --release
        echo -e "${GREEN}✅ APK build complete!${NC}"
        
        echo ""
        echo -e "${BLUE}📦 Building AAB...${NC}"
        flutter build appbundle --release
        echo -e "${GREEN}✅ AAB build complete!${NC}"
        ;;
    *)
        echo -e "${RED}Invalid option${NC}"
        exit 1
        ;;
esac

# File sizes
echo ""
echo -e "${BLUE}📊 Build Artifacts:${NC}"

if [ -f "build/app/outputs/apk/release/app-release.apk" ]; then
    SIZE=$(ls -lh build/app/outputs/apk/release/app-release.apk | awk '{print $5}')
    echo -e "  APK: ${GREEN}$SIZE${NC} - build/app/outputs/apk/release/app-release.apk"
fi

if [ -f "build/app/outputs/bundle/release/app-release.aab" ]; then
    SIZE=$(ls -lh build/app/outputs/bundle/release/app-release.aab | awk '{print $5}')
    echo -e "  AAB: ${GREEN}$SIZE${NC} - build/app/outputs/bundle/release/app-release.aab"
fi

echo ""
echo -e "${GREEN}✨ Build completed successfully!${NC}"
