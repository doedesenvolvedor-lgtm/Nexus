# 🚀 Guia Completo: Gerar APK e AAB para Nexus Streaming

## ✅ Problemas Corrigidos

- [x] Application ID alterado para `com.nexus.streaming` (era `com.example.nexus_mobile`)
- [x] Namespace atualizado em `build.gradle.kts`
- [x] Signing configuration configurado para release builds
- [x] Permissões adicionadas ao `AndroidManifest.xml`
- [x] ProGuard rules criado para otimização
- [x] Keystore script gerado

---

## 📋 Pré-requisitos

1. **Flutter instalado** (versão 3.3.0+)
   ```bash
   flutter --version
   ```

2. **Android SDK configurado**
   ```bash
   flutter doctor
   ```

3. **Keytool disponível** (geralmente vem com Java)
   ```bash
   keytool -version
   ```

---

## 🔑 Passo 1: Gerar o Keystore

Um keystore é necessário para assinar seu APK/AAB. Execute:

```bash
chmod +x generate_keystore.sh
./generate_keystore.sh
```

Isso criará um arquivo `android/app/keystore/nexus.jks`.

**⚠️ IMPORTANTE**: Guarde a senha em local seguro! Você precisará dela sempre que compilar.

---

## 🏗️ Passo 2: Configurar Variáveis de Ambiente

Defina as variáveis de ambiente com seus dados:

```bash
export KEYSTORE_PATH="$(pwd)/android/app/keystore/nexus.jks"
export KEYSTORE_ALIAS="nexus_key"
export KEYSTORE_PASSWORD="sua_senha_aqui"
```

Ou crie um arquivo `.env.local` na raiz do projeto (não commite):

```
KEYSTORE_PATH=/full/path/to/keystore/nexus.jks
KEYSTORE_ALIAS=nexus_key
KEYSTORE_PASSWORD=sua_senha_aqui
```

---

## 📦 Passo 3: Atualizar Dependências Flutter

```bash
flutter pub get
flutter pub upgrade
```

---

## 🔨 Passo 4: Gerar APK (para testes em dispositivo)

```bash
# Build APK release
flutter build apk --release

# Build APK com split por ABI (menor tamanho)
flutter build apk --release --split-per-abi
```

O APK será criado em:
- `build/app/outputs/apk/release/app-release.apk`
- `build/app/outputs/apk/release/app-armeabi-v7a-release.apk`
- `build/app/outputs/apk/release/app-arm64-v8a-release.apk`
- `build/app/outputs/apk/release/app-x86_64-release.apk`

---

## 📲 Passo 5: Gerar AAB (para Google Play Store)

AAB é obrigatório para publicar na Play Store:

```bash
flutter build appbundle --release
```

O AAB será criado em:
- `build/app/outputs/bundle/release/app-release.aab`

---

## 🧪 Passo 6: Testar APK em Dispositivo

```bash
# Instalar APK em dispositivo conectado
adb install build/app/outputs/apk/release/app-release.apk

# Ou deixar Flutter fazer isso:
flutter install --release
```

---

## 📊 Verificar Assinatura do APK

Confirmar que o APK foi assinado corretamente:

```bash
jarsigner -verify -verbose -certs build/app/outputs/apk/release/app-release.apk
```

---

## 🐛 Troubleshooting

### Erro: "Keystore not found"
```bash
# Verifique se o caminho está correto
ls -la android/app/keystore/nexus.jks
```

### Erro: "Invalid password"
```bash
# Regenere o keystore
./generate_keystore.sh
```

### Erro: "Gradle build failed"
```bash
# Limpe build anterior
flutter clean
flutter pub get
flutter build apk --release
```

### APK muito grande
Use split por ABI ou ProGuard:
```bash
flutter build apk --release --split-per-abi
```

### Firebase não funciona em release
1. Regenere `google-services.json` com o novo package `com.nexus.streaming`
2. Substitua o arquivo em `android/app/`
3. Execute `flutter clean` antes de rebuild

---

## 📈 Próximas Etapas: Publicar na Play Store

1. Criar conta Google Play Developer ($25 USD)
2. Criar aplicativo no Console Play Developer
3. Preparar screenshots e descrição
4. Fazer upload do AAB
5. Configurar testes (closed testing)
6. Submeter para revisão

---

## 🔒 Segurança

**NUNCA**:
- ❌ Commite o arquivo `nexus.jks` ao repositório
- ❌ Compartilhe a senha do keystore
- ❌ Coloque credenciais em código-fonte

**SEMPRE**:
- ✅ Guarde o keystore em local seguro
- ✅ Use variáveis de ambiente
- ✅ Mantenha backup seguro
- ✅ Use o mesmo keystore para todas as atualizações

---

## 📚 Recursos Úteis

- [Flutter Build Documentation](https://flutter.dev/docs/deployment/android)
- [Google Play Console](https://play.google.com/console)
- [Android App Signing](https://developer.android.com/studio/publish/app-signing)

---

## ✨ Checklist Final

Antes de submeter à Play Store:

- [ ] Build APK gerado com sucesso
- [ ] Build AAB gerado com sucesso
- [ ] APK testado em dispositivo físico
- [ ] Firebase funcionando (Crashlytics, Analytics)
- [ ] Permissões funcionando (câmera, microfone)
- [ ] Performance testada
- [ ] Screenshots preparados
- [ ] Descrição e changelog prontos
- [ ] Keystore backup criado
- [ ] Versão incrementada no `pubspec.yaml`

