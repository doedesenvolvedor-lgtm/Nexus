# 🚀 Guia Completo de Preparação para Build - Nexustwos

**Data:** 18/07/2026  
**Status:** ⚙️ Pronto para implementação  
**Versão:** 1.0  

---

## 📋 Status Atual

### ✅ Configurado
- **Flutter:** v3.44.6 (stable)
- **Dart:** 3.12.2
- **Android:** Application ID correto (`com.nexus.streaming`)
- **Android:** Signing configuration para release
- **Dependências:** Todas instaladas e compiladas
- **iOS:** Estrutura básica presente

### ⚠️ Problemas Identificados
1. **Web:** Não foi criado (falta `flutter create --platforms=web`)
2. **Android:** Falta keystore para release builds
3. **Android:** Faltam ProGuard rules
4. **iOS:** Precisa de configuração de certificados
5. **CLI Tools:** SDK cmdline-tools ausentes no ambiente

### 🎯 Etapas de Configuração

---

## 1️⃣ PREPARAR ANDROID BUILD

### 1.1 Gerar Keystore para Release (PRIMEIRA VEZ)

```bash
# Criar diretório para keystore
mkdir -p android/app/keystore

# Gerar keystore (válido por 10 anos)
keytool -genkey -v \
  -keystore android/app/keystore/nexus.jks \
  -keyalias nexus_key \
  -keyalg RSA \
  -keysize 4096 \
  -validity 10950

# Respostas sugeridas:
# First and last name: Nexus Streaming
# Organizational Unit: Development
# Organization: Nexus
# City/Locality: São Paulo
# State/Province: SP
# Country Code: BR
# Keystore password: (mínimo 6 caracteres - guardar com segurança)
```

### 1.2 Configurar Variáveis de Ambiente

```bash
# Adicionar ao ~/.bashrc ou ~/.zshrc
export KEYSTORE_PATH="$(pwd)/android/app/keystore/nexus.jks"
export KEYSTORE_ALIAS="nexus_key"
export KEYSTORE_PASSWORD="sua_senha_aqui"  # ⚠️ NÃO committar no git

# Reload shell
source ~/.bashrc
```

### 1.3 Criar ProGuard Rules

```bash
# Arquivo: android/app/proguard-rules.pro
```

**Conteúdo:**
```proguard
# Firebase Rules
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-keepattributes *Annotation*

# Flutter Rules
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Video Player
-keep class com.google.android.exoplayer2.** { *; }

# Networking
-keepclasseswithmembernames class com.example.** { *; }
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# Enums
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}
```

### 1.4 Build APK (Debug)

```bash
cd nexus_mobile
flutter build apk --debug -v
```

**Output esperado:**
- `build/app/outputs/apk/debug/app-debug.apk`
- Tamanho: ~150-200 MB

### 1.5 Build APK (Release)

```bash
flutter build apk --release -v
```

**Output esperado:**
- `build/app/outputs/apk/release/app-release.apk`
- Tamanho: ~100-120 MB
- Assinado e pronto para Play Store

### 1.6 Build AAB (Android App Bundle)

```bash
flutter build appbundle --release -v
```

**Output esperado:**
- `build/app/outputs/bundle/release/app-release.aab`
- Pronto para Google Play Store

### 1.7 Verificar Build Android

```bash
# Listar informações do APK
cd build/app/outputs/apk/release/
unzip -l app-release.apk | grep -E "classes|lib|assets"

# Verificar assinatura
jarsigner -verify -verbose -certs app-release.apk
```

---

## 2️⃣ PREPARAR iOS BUILD

### 2.1 Verificar Pré-requisitos

```bash
# iOS requer Mac/macOS
# No Linux, apenas prepare o projeto

# Instalar pods (em Mac)
cd ios
pod install
cd ..
```

### 2.2 Configurar Build para iOS

```bash
# Definir Team ID e Bundle ID
flutter pub global activate cocoapods

# Verificar configuração
cd ios
xcodebuild -scheme Runner -configuration Release -showBuildSettings | grep -E "BUNDLE_ID|TEAM"
cd ..
```

### 2.3 Build iOS (Debug)

```bash
flutter build ios --debug -v
```

**Output esperado:**
- Simulador configurado
- IPA gerado em `build/ios/iphoneos/Runner.app`

### 2.4 Build iOS (Release)

```bash
flutter build ios --release -v
```

### 2.5 Build IPA para App Store

```bash
flutter build ipa --release -v
```

**Output esperado:**
- IPA gerado e pronto para App Store

---

## 3️⃣ CRIAR E PREPARAR BUILD WEB

### 3.1 Criar Projeto Web

```bash
cd /workspaces/Nexus/nexus_mobile

# Criar suporte web
flutter create --platforms=web .

# Ou se já existe, apenas ativar
flutter config --enable-web
```

### 3.2 Criar arquivo `web/index.html` customizado

```html
<!DOCTYPE html>
<html>
<head>
    <base href="$FLUTTER_BASE_HREF">
    <meta charset="UTF-8">
    <meta content="IE=Edge" http-equiv="X-UA-Compatible">
    <meta name="description" content="Nexustwos - Seu universo de entretenimento">
    <meta name="apple-mobile-web-app-capable" content="yes">
    <meta name="apple-mobile-web-app-status-bar-style" content="black">
    <meta name="apple-mobile-web-app-title" content="Nexustwos">
    <link rel="apple-touch-icon" href="icons/Icon-192.png">
    <link rel="icon" type="image/png" href="favicon.png"/>
    <link rel="manifest" href="manifest.json">
    <title>Nexustwos - Seu universo de entretenimento</title>
    <script>
        // Este script carrega o Flutter.
        {{flutter_js}}
    </script>
</head>
<body>
    <script>
        window.addEventListener('flutter-first-frame', function () {
            document.body.style.opacity = "1";
        });
    </script>
    {{flutter_app_load}}
</body>
</html>
```

### 3.3 Criar `pubspec.yaml` entry para web

```yaml
# Já está configurado em pubspec.yaml
flutter:
  uses-material-design: true
  # Adicionar se não tiver:
  web:
    generate: true
```

### 3.4 Build Web (Debug)

```bash
flutter build web --debug -v --dart-define=Dart2jsOptimization=O0
```

**Output esperado:**
- Arquivos em `build/web/`
- Tamanho: ~50-80 MB

### 3.5 Build Web (Release)

```bash
flutter build web --release -v
```

**Output esperado:**
- Arquivos otimizados em `build/web/`
- Tamanho: ~20-30 MB
- Pronto para deploy em Vercel, Netlify ou Firebase Hosting

### 3.6 Testar Web Localmente

```bash
flutter run -d web --release
```

---

## 4️⃣ PREPARAR ANDROID TV BUILD

### 4.1 Criar Flavor para Android TV

**Arquivo:** `android/app/build.gradle.kts`

```kotlin
flavorDimensions.add("platform")

productFlavors {
    create("phone") {
        dimension = "platform"
        resConfigs.add("hdpi")
        resConfigs.add("xhdpi")
        resConfigs.add("xxhdpi")
        resConfigs.add("xxxhdpi")
    }
    
    create("tv") {
        dimension = "platform"
        resConfigs.add("tvdpi")
        resConfigs.add("xhdpi")
    }
}
```

### 4.2 AndroidManifest para TV

**Arquivo:** `android/app/src/tv/AndroidManifest.xml`

```xml
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-feature android:name="android.hardware.type.television" android:required="true"/>
    <uses-feature android:name="android.software.leanback" android:required="true"/>
    
    <application>
        <!-- TV launcher intent -->
        <activity
            android:name=".MainActivity"
            android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LEANBACK_LAUNCHER"/>
            </intent-filter>
        </activity>
    </application>
</manifest>
```

### 4.3 Build APK para TV

```bash
flutter build apk --flavor tv --release -v
```

**Output esperado:**
- APK otimizado para Android TV
- `build/app/outputs/apk/tvRelease/app-tv-release.apk`

---

## 5️⃣ TESTES DE BUILD

### 5.1 Testar Android (Local)

```bash
# Debug em emulador/dispositivo
flutter run -v

# Release build
flutter run --release -v

# Build APK debug
flutter build apk --debug -v

# Build APK release
flutter build apk --release -v
```

### 5.2 Testar Web

```bash
# Dev server
flutter run -d web -v

# Release build
flutter build web --release -v

# Servir localmente
cd build/web
python3 -m http.server 8000
# Acesso: http://localhost:8000
```

### 5.3 Verificar Tamanhos

```bash
# APK Android
ls -lh build/app/outputs/apk/release/app-release.apk

# Bundle Android
ls -lh build/app/outputs/bundle/release/app-release.aab

# Web
du -sh build/web/

# Comparar
echo "=== Tamanhos de Build ==="
echo "APK (Release): $(ls -lh build/app/outputs/apk/release/app-release.apk | awk '{print $5}')"
echo "AAB (Release): $(ls -lh build/app/outputs/bundle/release/app-release.aab | awk '{print $5}')"
echo "Web (Release): $(du -sh build/web/ | awk '{print $1}')"
```

---

## 6️⃣ DEPLOY

### 6.1 Deploy Web (Vercel)

```bash
# Instalar Vercel CLI
npm install -g vercel

# Deploy
vercel --prod
```

**Configuração `vercel.json`:**
```json
{
  "buildCommand": "flutter build web --release",
  "outputDirectory": "build/web"
}
```

### 6.2 Deploy Web (Firebase)

```bash
# Instalar Firebase CLI
npm install -g firebase-tools

# Inicializar
firebase init hosting

# Deploy
firebase deploy
```

### 6.3 Deploy Android (Google Play Store)

1. Gerar AAB release
2. Assinar com certificado
3. Enviar para Google Play Console
4. Configurar testes e rollout

```bash
flutter build appbundle --release
# Enviar build/app/outputs/bundle/release/app-release.aab para Play Console
```

### 6.4 Deploy iOS (App Store)

1. Gerar IPA release
2. Assinar com certificado Apple
3. Enviar para App Store Connect via Xcode/Transporter

```bash
flutter build ipa --release
# Usar Xcode ou Apple Transporter para enviar
```

---

## 7️⃣ TROUBLESHOOTING

### ❌ Erro: "SDK cmdline-tools not found"

```bash
# Solução
sdkmanager "cmdline-tools;latest" --sdk_root=$ANDROID_HOME
```

### ❌ Erro: "Keystore not found"

```bash
# Verificar caminho
echo $KEYSTORE_PATH
ls -la android/app/keystore/nexus.jks

# Regenerar se necessário
keytool -genkey -v -keystore android/app/keystore/nexus.jks \
  -keyalias nexus_key -keyalg RSA -keysize 4096 -validity 10950
```

### ❌ Erro: "Pod install failed" (iOS)

```bash
cd ios
rm -rf Pods Podfile.lock
pod install
cd ..
```

### ❌ Erro: "Chrome not found" (Web)

```bash
export CHROME_EXECUTABLE=/usr/bin/chromium-browser
flutter run -d web
```

### ❌ Erro: "Gradle sync failed"

```bash
cd android
./gradlew clean
./gradlew build
cd ..
```

---

## 📊 Checklist Final

### ✅ Antes de Deploy

- [ ] Android APK (debug) testado em device/emulator
- [ ] Android APK (release) gerado e verificado
- [ ] Android AAB (release) gerado para Play Store
- [ ] iOS build preparado (em Mac)
- [ ] Web build criado e testado
- [ ] Android TV APK testado
- [ ] Todas as telas testadas em cada plataforma
- [ ] Permissões verificadas (AndroidManifest, Info.plist)
- [ ] Certificados válidos (iOS)
- [ ] Keystore seguro (Android)
- [ ] Firebase configurado em todas as plataformas
- [ ] Analytics e Crashlytics funcionando

### 🔐 Segurança

- [ ] Keystore.jks adicionado a `.gitignore`
- [ ] Senhas não estão commitadas
- [ ] Certificados iOS seguros
- [ ] API keys protegidas
- [ ] Dados sensíveis em .env

---

## 🚀 Próximas Etapas

1. **Implementar keystore Android**
2. **Criar build web**
3. **Gerar builds de teste**
4. **Testar em múltiplos devices**
5. **Configurar CI/CD (GitHub Actions)**
6. **Deploy em produção**

---

**Documento criado em:** 18/07/2026  
**Última atualização:** 18/07/2026  
**Responsável:** Nexus Development Team
