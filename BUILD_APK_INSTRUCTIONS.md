# 🚀 Instruções para Gerar APK do Nexus Mobile

## Opção 1: Build APK Debug (Mais rápido)
```bash
cd /workspaces/Nexus/nexus_mobile
export PATH="/home/codespace/flutter/bin:$PATH"
export ANDROID_HOME=~/android-sdk
export GRADLE_OPTS="-Xmx6G -Xms2G"

flutter build apk --debug
```

**Arquivo gerado:** `build/app/outputs/apk/debug/app-debug.apk`

---

## Opção 2: Build APK Release (Produção)
```bash
cd /workspaces/Nexus/nexus_mobile
export PATH="/home/codespace/flutter/bin:$PATH"
export ANDROID_HOME=~/android-sdk
export GRADLE_OPTS="-Xmx6G -Xms2G"

flutter build apk --release
```

**Arquivo gerado:** `build/app/outputs/apk/release/app-release.apk`

---

## Opção 3: APK com Split por Arquitetura (Recomendado)
```bash
cd /workspaces/Nexus/nexus_mobile
export PATH="/home/codespace/flutter/bin:$PATH"
export ANDROID_HOME=~/android-sdk
export GRADLE_OPTS="-Xmx6G -Xms2G"

flutter build apk --release --split-per-abi
```

**Arquivos gerados:**
- `build/app/outputs/apk/release/app-armeabi-v7a-release.apk` (ARM 32-bit)
- `build/app/outputs/apk/release/app-arm64-v8a-release.apk` (ARM 64-bit)
- `build/app/outputs/apk/release/app-x86_64-release.apk` (Intel x86_64)

---

## Opção 4: Build AAB (Google Play Bundle)
```bash
cd /workspaces/Nexus/nexus_mobile
export PATH="/home/codespace/flutter/bin:$PATH"
export ANDROID_HOME=~/android-sdk
export GRADLE_OPTS="-Xmx6G -Xms2G"

flutter build appbundle --release
```

**Arquivo gerado:** `build/app/outputs/bundle/release/app-release.aab`

---

## Verificar APK Gerado
```bash
ls -lh /workspaces/Nexus/nexus_mobile/build/app/outputs/apk/
```

---

## Erros Comuns e Soluções

### ❌ "Gradle build daemon disappeared"
**Solução:** Limpar cache e tentar novamente
```bash
cd /workspaces/Nexus/nexus_mobile
rm -rf build android/.gradle ~/.gradle
flutter clean
flutter pub get
flutter build apk --debug
```

### ❌ "Core library desugaring to be enabled"
**Solução:** Já configurado em `android/app/build.gradle.kts`
- ✅ `isCoreLibraryDesugaringEnabled = true` adicionado
- ✅ `dependencies { coreLibraryDesugaring(...) }` adicionado

### ❌ "Dependency flutter_local_notifications requires..."
**Solução:** Já atualizado para versão 17.2.4

---

## Variáveis de Ambiente Necessárias
```bash
export PATH="/home/codespace/flutter/bin:$PATH"
export ANDROID_HOME=~/android-sdk
export GRADLE_OPTS="-Xmx6G -Xms2G"
```

---

## Verificação do Ambiente
```bash
# Ver versão do Flutter
flutter --version

# Ver configuração do Android
flutter doctor -v

# Ver SDK instalado
ls -la ~/android-sdk/
```

---

## Tamanho Esperado do APK
- **Debug APK:** ~200-300 MB
- **Release APK (universal):** ~100-150 MB
- **Release APK (split per ABI):** ~50-70 MB cada

---

## Instalação do APK em Dispositivo
```bash
# Via USB (com adb)
adb install build/app/outputs/apk/debug/app-debug.apk

# Via Firebase App Distribution
# 1. Upload para Firebase
# 2. Compartilhar link com testers
```

---

**Última atualização:** 15/07/2026
**Status:** ✅ Todas as dependências e configurações prontas
