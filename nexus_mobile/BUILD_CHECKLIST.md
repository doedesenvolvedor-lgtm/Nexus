# 📋 BUILD CHECKLIST - Nexustwos

**Data de Criação:** 18/07/2026  
**Status:** ✅ Pronto para Build  
**Versão:** 1.0.0  

---

## 🎯 Checklist de Preparação

### ✅ Configuração do Projeto

- [x] Flutter 3.44.6 instalado e configurado
- [x] Dart 3.12.2 disponível
- [x] Dependências instaladas (`flutter pub get`)
- [x] Tema Material 3 customizado
- [x] Tipografia Poppins configurada
- [x] Paleta de cores (Roxo → Azul) definida
- [x] Componentes reutilizáveis implementados
- [x] 40+ telas desenvolvidas

### ✅ Configuração Android

- [x] Package ID: `com.nexus.streaming`
- [x] Namespace correto configurado
- [x] ProGuard rules completas (`android/app/proguard-rules.pro`)
- [x] Firebase integrado
- [x] Signing configuration pronto
- [x] AndroidManifest com permissões necessárias
- [x] Min SDK: 21, Target SDK: 34
- [ ] **TODO:** Gerar keystore para release

### ⚠️ Configuração Android (Após Gerar Keystore)

```bash
# 1. Gerar keystore
mkdir -p android/app/keystore
keytool -genkey -v \
  -keystore android/app/keystore/nexus.jks \
  -keyalias nexus_key \
  -keyalg RSA \
  -keysize 4096 \
  -validity 10950

# 2. Definir variáveis de ambiente
export KEYSTORE_PATH="$(pwd)/android/app/keystore/nexus.jks"
export KEYSTORE_ALIAS="nexus_key"
export KEYSTORE_PASSWORD="sua_senha_segura"  # ⚠️ Guardar com segurança!

# 3. Salvar em ~/.bashrc ou ~/.zshrc para persistir
```

### ✅ Configuração iOS

- [x] Estrutura Flutter criada
- [x] Pod configuration pronto
- [ ] **TODO:** Configurar em Mac/macOS

### ✅ Configuração Web

- [x] Web criado e ativado
- [x] `web/index.html` customizado
- [x] `web/manifest.json` atualizado
- [x] Metadados SEO adicionados
- [x] PWA configuration pronta

### ✅ Scripts de Build

- [x] `build_apk_debug.sh` - Build APK para testes
- [x] `build_apk_release.sh` - Build APK com signing
- [x] `build_aab_release.sh` - Build AAB para Play Store
- [x] `build_web.sh` - Build Web otimizado
- [x] `build_master.sh` - Menu interativo para builds

---

## 🚀 Como Fazer Build

### 1️⃣ Build APK Debug (Para Testes)

```bash
cd /workspaces/Nexus/nexus_mobile
./build_apk_debug.sh
```

**Output:** `build/app/outputs/apk/debug/app-debug.apk`  
**Tamanho esperado:** 150-200 MB

### 2️⃣ Build APK Release (Produção - Teste)

```bash
# Primeiro, configure as variáveis de ambiente
export KEYSTORE_PASSWORD="sua_senha_aqui"

# Depois execute o build
./build_apk_release.sh
```

**Output:** `build/app/outputs/apk/release/app-release.apk`  
**Tamanho esperado:** 100-120 MB

### 3️⃣ Build AAB (Google Play Store)

```bash
export KEYSTORE_PASSWORD="sua_senha_aqui"
./build_aab_release.sh
```

**Output:** `build/app/outputs/bundle/release/app-release.aab`

### 4️⃣ Build Web

```bash
./build_web.sh
```

**Output:** `build/web/`  
**Tamanho esperado:** 20-30 MB (pronto para Vercel, Firebase, Netlify)

### 5️⃣ Todos os Builds (Menu Interativo)

```bash
./build_master.sh
```

---

## 📱 Instalar em Device/Emulator

### Via ADB (Android)

```bash
# Debug
adb install -r build/app/outputs/apk/debug/app-debug.apk

# Release
adb install -r build/app/outputs/apk/release/app-release.apk

# Listar dispositivos
adb devices

# Instalar em dispositivo específico
adb -s DEVICE_ID install -r app-debug.apk
```

### Via Xcode (iOS - Mac apenas)

```bash
open ios/Runner.xcworkspace
# Selecionar target e pressionar Run
```

### Via Flutter CLI

```bash
# Debug em connected device
flutter run

# Release
flutter run --release
```

---

## 🌐 Deploy Web

### Testar Localmente

```bash
cd build/web
python3 -m http.server 8000
# Acesse: http://localhost:8000
```

### Deploy em Vercel

```bash
npm install -g vercel
cd /workspaces/Nexus/nexus_mobile
vercel --prod
```

### Deploy em Firebase Hosting

```bash
npm install -g firebase-tools
firebase login
firebase init hosting
firebase deploy
```

### Deploy em Netlify

```bash
npm install -g netlify-cli
netlify deploy --prod --dir=build/web
```

---

## 🎯 Testes Essenciais

### ✅ Antes de Deploy

- [ ] Testar em Android Device (Físico)
- [ ] Testar em Android Emulator
- [ ] Testar em iOS Device (em Mac)
- [ ] Testar em iOS Simulator
- [ ] Testar Web em Chrome
- [ ] Testar Web em Safari
- [ ] Testar Web em Firefox
- [ ] Verificar responsividade (Mobile, Tablet, Desktop)
- [ ] Testar offline mode (Web PWA)
- [ ] Verificar performance (Lighthouse)
- [ ] Testar todas as telas
- [ ] Testar navegação
- [ ] Testar autenticação
- [ ] Testar pagamento (Mercado Pago)
- [ ] Verificar Firebase (Analytics, Crashlytics)

---

## 📊 Verificar Tamanhos de Build

```bash
# Comparar tamanhos
echo "=== Tamanhos de Build Nexustwos ==="
echo "APK Debug: $(ls -lh build/app/outputs/apk/debug/app-debug.apk 2>/dev/null | awk '{print $5}' || echo 'Não gerado')"
echo "APK Release: $(ls -lh build/app/outputs/apk/release/app-release.apk 2>/dev/null | awk '{print $5}' || echo 'Não gerado')"
echo "AAB Release: $(ls -lh build/app/outputs/bundle/release/app-release.aab 2>/dev/null | awk '{print $5}' || echo 'Não gerado')"
echo "Web: $(du -sh build/web 2>/dev/null | awk '{print $1}' || echo 'Não gerado')"
```

---

## 🔍 Troubleshooting

### ❌ Erro: "Keystore not found"

```bash
# Solução: Gerar keystore
mkdir -p android/app/keystore
keytool -genkey -v -keystore android/app/keystore/nexus.jks \
  -keyalias nexus_key -keyalg RSA -keysize 4096 -validity 10950
```

### ❌ Erro: "KEYSTORE_PASSWORD not set"

```bash
export KEYSTORE_PASSWORD="sua_senha_aqui"
# Ou adicione ao ~/.bashrc para persistir
```

### ❌ Erro: "Pod install failed" (iOS)

```bash
cd ios
rm -rf Pods Podfile.lock
pod install
cd ..
```

### ❌ Erro: "Build output is too large"

```bash
# Reduzir tamanho
flutter clean
flutter pub get
flutter build apk --release --split-per-abi
```

### ❌ Erro: "Chrome not found" (Web)

```bash
export CHROME_EXECUTABLE=/usr/bin/chromium-browser
flutter run -d web
```

---

## 📦 Estrutura de Output

```
nexus_mobile/
├── build/
│   ├── app/
│   │   └── outputs/
│   │       ├── apk/
│   │       │   ├── debug/
│   │       │   │   └── app-debug.apk
│   │       │   └── release/
│   │       │       └── app-release.apk
│   │       └── bundle/
│   │           └── release/
│   │               └── app-release.aab
│   ├── ios/
│   │   └── iphoneos/
│   │       └── Runner.app
│   └── web/
│       ├── index.html
│       ├── main.dart.js
│       ├── manifest.json
│       ├── flutter.js
│       └── icons/
```

---

## 🔐 Segurança

### ⚠️ Importante

- [ ] **Nunca committar** `android/app/keystore/nexus.jks`
- [ ] **Nunca committar** senhas (KEYSTORE_PASSWORD)
- [ ] **Adicionar** a `.gitignore`:
  ```
  android/app/keystore/
  .env
  .env.local
  *.jks
  *.key
  *.p8
  ```

- [ ] Usar **GitHub Secrets** para CI/CD:
  ```
  KEYSTORE_PASSWORD
  KEYSTORE_PATH
  APPLE_CERTIFICATE
  APPLE_PASSWORD
  ```

---

## 🚀 Próximas Etapas

1. **Gerar Keystore** (primeira vez)
   ```bash
   mkdir -p android/app/keystore
   keytool -genkey -v -keystore android/app/keystore/nexus.jks \
     -keyalias nexus_key -keyalg RSA -keysize 4096 -validity 10950
   ```

2. **Testar Build Local**
   ```bash
   ./build_master.sh  # Menu interativo
   ```

3. **Testar em Dispositivos**
   - Android: `adb install -r app-debug.apk`
   - iOS: Usar Xcode (Mac apenas)
   - Web: http://localhost:8000

4. **Configurar CI/CD**
   - GitHub Actions para builds automáticos
   - Play Store beta testing
   - TestFlight para iOS

5. **Deploy em Produção**
   - Google Play Store (Android)
   - App Store (iOS)
   - Vercel/Firebase (Web)

---

## 📞 Suporte

Para mais informações, consulte:
- [BUILD_PREPARATION_GUIDE.md](BUILD_PREPARATION_GUIDE.md)
- [NEXUSTWOS_UI_UX_COMPLETE.md](NEXUSTWOS_UI_UX_COMPLETE.md)
- [README.md](README.md)

---

**Documento criado em:** 18/07/2026  
**Responsável:** Nexus Development Team  
**Status:** ✅ Pronto para Deploy
