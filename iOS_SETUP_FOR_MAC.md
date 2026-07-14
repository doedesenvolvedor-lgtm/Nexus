# 🍎 iOS Setup - Guia para Mac

## ⚠️ Importante

Este projeto precisa ser **compilado no Mac** porque:
- Xcode só funciona em macOS
- iOS deve ser testado em device ou simulador do Mac
- CocoaPods geralmente funciona melhor no Mac

---

## 📋 Status Atual

### ✅ Já Preparado Aqui (Dev Container Linux):
```
✅ firebase_options.dart - iOS credenciais
✅ GoogleService-Info.plist - Criado
✅ NotificationService.dart - Completo
✅ AppDelegate.swift - Pronto
✅ Podfile - Configurado
✅ pubspec.yaml - Dependências
```

### ⏳ Precisa Fazer no Mac:
```
⏳ pod install --repo-update
⏳ File → Add Packages (Firebase SDKs)
⏳ Signing & Capabilities (Push Notifications)
⏳ flutter build ios
⏳ flutter run
```

---

## 🚀 Como Fazer no Mac

### OPÇÃO 1: Script Automático (Recomendado)

Copie este arquivo do dev container para seu Mac:

```bash
# No Mac, em uma pasta de trabalho:
scp -r seu_usuario@seu_container:/workspaces/Nexus/nexus_mobile ~/Nexus_Mobile

# Ou se local:
cp -r /Volumes/seu_volume/Nexus/nexus_mobile ~/Nexus_Mobile

# Depois execute:
cd ~/Nexus_Mobile
bash ../setup_ios_for_mac.sh
```

### OPÇÃO 2: Passo a Passo Manual

#### 1. Copiar Projeto para Mac
```bash
# Se estiver em cloud:
scp -r seu_usuario@server:/workspaces/Nexus ~/

# Se for local:
cd ~/Nexus/nexus_mobile
```

#### 2. Navegar para Pasta
```bash
cd ~/Nexus/nexus_mobile
```

#### 3. Sincronizar Dependências
```bash
flutter pub get
```

#### 4. Instalar Firebase SDKs
```bash
cd ios
pod install --repo-update
cd ..
```

#### 5. Abrir Xcode
```bash
open ios/Runner.xcworkspace
```

#### 6. No Xcode:

**6.1 - Adicionar Firebase SDKs**
```
File → Add Packages
Cole: https://github.com/firebase/firebase-ios-sdk
Selecione: 10.24.0 ou superior
Clique: Next

Marque:
  ☑️ FirebaseAnalytics
  ☑️ FirebaseMessaging
  ☑️ FirebaseCrashlytics

Clique: Finish
Aguarde: 5-10 minutos
```

**6.2 - Adicionar Push Notifications**
```
Runner → Signing & Capabilities
+ Capability → Push Notifications
```

#### 7. Voltar ao Terminal e Build
```bash
flutter build ios --debug
flutter run -d iPhone\ 15
```

---

## 📦 Arquivos Necessários

Estes arquivos já estão no projeto e foram preparados aqui:

```
nexus_mobile/
├── lib/
│   ├── firebase_options.dart         ✅ iOS credenciais
│   ├── main.dart                     ✅ Firebase init
│   └── services/
│       └── notification_service.dart ✅ Listeners
│
├── ios/
│   ├── Runner/
│   │   ├── GoogleService-Info.plist  ✅ Credenciais iOS
│   │   └── GeneratedPluginRegistrant.swift ✅ AppDelegate
│   ├── Podfile                       ✅ Pods
│   └── Runner.xcworkspace/
│
└── pubspec.yaml                      ✅ Dependencies
```

**Nada falta - está tudo pronto!**

---

## ✅ Checklist Mac

- [ ] Projeto copiado para Mac
- [ ] `flutter pub get` executado
- [ ] `pod install` executado
- [ ] Xcode aberto
- [ ] Firebase SDKs adicionado (SPM)
- [ ] Push Notifications capability adicionado
- [ ] `flutter build ios` compilou sem erros
- [ ] `flutter run` app rodando
- [ ] Notificações teste recebidas

---

## 🚨 Possíveis Problemas no Mac

### "Pod install falha"
```bash
cd ios
rm Podfile.lock
rm -rf Pods
pod repo update
pod install
cd ..
```

### "Xcode não encontra Firebase"
```
Fechar Xcode
rm -rf ~/Library/Developer/Xcode/DerivedData
Abrir novamente
```

### "Flutter command not found"
```bash
# Verificar se Flutter está no PATH
which flutter

# Se não estiver:
export PATH="$PATH:/path/to/flutter/bin"
```

### "Signing error"
```
Xcode → Runner → Signing & Capabilities
Verificar Team ID está preenchido
Clicar em "Try Again" se necessário
```

---

## 📱 Testando Notificações

Após app compilar e rodar:

1. Abrir [Firebase Console](https://console.firebase.google.com)
2. Projeto: **nexus-3fb82**
3. **Messaging** → **New Campaign**
4. Título: "Test"
5. Mensagem: "Hello Firebase"
6. Clique **Next**
7. Selecione device iOS
8. **Review and Publish**
9. ✅ Notificação aparece no device!

---

## 🎯 Próximos Passos (Após iOS)

```
1. ✅ iOS completo

2. ⏳ Backend Firebase (Service Account JSON)
   - Obter credenciais no Firebase Console
   - Salvar em backend/firebase-credentials.json

3. ⏳ Testar end-to-end:
   - App registra device token
   - Backend envia notificação
   - Device recebe notificação
```

---

## 📞 Precisa de Ajuda?

Se travar em algo no Mac:
1. Volta aqui no dev container
2. Me avisa qual erro
3. Posso ajudar remotamente

---

## 🔗 Referências Úteis

- [Flutter macOS Setup](https://flutter.dev/docs/get-started/install/macos)
- [Xcode Firebase Integration](https://firebase.google.com/docs/ios/setup)
- [CocoaPods Installation](https://cocoapods.org/)

---

**Boa sorte no Mac! 🚀**
