#!/bin/bash
set -e

cd /workspaces/Nexus/nexus_mobile

export PATH="/home/codespace/flutter/bin:$PATH"
export ANDROID_HOME=/home/codespace/android-sdk
export GRADLE_OPTS="-Xmx1G -Xms512M"

echo "📦 Limpando build anterior..."
flutter clean

echo "📥 Baixando dependências..."
flutter pub get

echo "🔨 Compilando APK (Debug) - sem daemon..."
# Usar gradle diretamente com --no-daemon
cd android
./gradlew --no-daemon assembleDebug
cd ..

echo "✅ APK gerado com sucesso!"
find build -name "*.apk" -type f 2>/dev/null | head -5
