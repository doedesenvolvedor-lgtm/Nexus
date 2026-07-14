# 🍎 Firebase iOS - SPM (Swift Package Manager) Setup

## 📋 Passo a Passo: Adicionar Firebase SDK via Xcode

### ✅ Pré-requisitos
- ✅ Xcode aberto com `ios/Runner.xcworkspace`
- ✅ GoogleService-Info.plist já adicionado
- ✅ Bundle ID correto: `Com.app.nexus1.`

---

## 🔧 Instruções Oficiais Firebase

### 1️⃣ Abrir Swift Package Manager
```
Xcode → File → Add Packages
```

### 2️⃣ Inserir URL do Repositório Firebase
```
https://github.com/firebase/firebase-ios-sdk
```

### 3️⃣ Selecionar Versão
- **Recomendado**: Última versão (padrão)
- **Alternativa**: Versão anterior se necessário

### 4️⃣ Selecionar Bibliotecas Firebase

#### ✅ **OBRIGATÓRIOS** (Para este projeto)
- [ ] **FirebaseAnalytics** - Rastreamento de eventos
- [ ] **FirebaseMessaging** - Push Notifications
- [ ] **FirebaseCrashlytics** - Relatório de crashes

#### ⚠️ **IMPORTANTE**
Se seu app não coleta IDFA (Apple ID for Advertising):
```
Usar: FirebaseAnalyticsWithoutAdId
Em vez de: FirebaseAnalytics
```

Para este projeto: **Use `FirebaseAnalytics` normal** (já que estamos coletando dados)

#### ✅ **RECOMENDADOS** (Adicional)
- [ ] **FirebaseCore** - Núcleo do Firebase (geralmente automático)
- [ ] **GoogleDataTransport** - Transporte de dados (geralmente automático)

---

## 📦 Versão Recomendada

**Versão Estável Atual**: `10.24.0` ou superior (verifique em: https://github.com/firebase/firebase-ios-sdk/releases)

---

## 🎯 Checklist: Bibliotecas para Adicionar

```
Será solicitado para selecionar qual projeto adicionar as libs.
Selecione: Runner
```

### Essencial (Marcar ✅)
- [x] **FirebaseCore**
- [x] **FirebaseAnalytics** (ou FirebaseAnalyticsWithoutAdId)
- [x] **FirebaseMessaging**
- [x] **FirebaseCrashlytics**

### Dependências Automáticas (Podem vir junto)
- GoogleDataTransport
- GoogleUtilities
- nanopb
- PromisesObjC

---

## ⏳ Após Clicar em "Finish"

O Xcode irá:
1. ✅ Resolver dependências
2. ✅ Fazer download dos SDKs
3. ✅ Integrar com o projeto
4. ✅ Atualizar build settings

**Pode levar 2-5 minutos** dependendo da velocidade da internet.

---

## ✅ Verificar Após Conclusão

No Xcode:
1. Clique em **Runner** (root do projeto)
2. Tab **Build Phases**
3. Procure por **Link Binary With Libraries**
4. Você deve ver os frameworks do Firebase:
   - [ ] FirebaseCore.xcframework
   - [ ] FirebaseAnalytics.xcframework
   - [ ] FirebaseMessaging.xcframework
   - [ ] FirebaseCrashlytics.xcframework

---

## 🔗 Relação: Flutter + SPM

### Como Funciona:
```
pubspec.yaml (Flutter)
    ↓
firebase_core, firebase_messaging, etc
    ↓
iOS: CocoaPods (padrão do Flutter)
    ↓
Podfile carrega os SDKs
    ↓
SPM (opcional) - complementar
```

### Seu Projeto:
- ✅ **pubspec.yaml**: Já tem as dependências Flutter Firebase
- ✅ **CocoaPods**: Pod install faz o trabalho
- ⏳ **SPM (agora)**: Adicionar manualmente para melhor controle

---

## 🚨 Possíveis Erros e Soluções

### Erro: "Multiple commands produce FirebaseCore"
**Solução**: Se ambos CocoaPods e SPM tentam adicionar, remova um deles
```bash
# Opção 1: Remover do SPM (no Xcode)
# Desmarcar Firebase libs do SPM

# Opção 2: Remover Pods (manter SPM)
cd ios
rm Podfile.lock
rm -rf Pods
cd ..
```

### Erro: "FirebaseAnalytics not found"
**Solução**: Adicionar via SPM (opção que estamos fazendo agora)

### Erro: "Missing GServices-Info.plist"
**Solução**: Arquivo já está em `ios/Runner/GoogleService-Info.plist` ✅

---

## 📋 Fluxo Completo iOS

```
1. ✅ GoogleService-Info.plist → ios/Runner/
2. ✅ firebase_options.dart → credenciais
3. ✅ flutter pub get → dependências Flutter
4. ✅ pod install → CocoaPods
5. ⏳ SPM Add Packages → Firebase SDKs (AGORA)
6. ⏳ Push Notifications Capability → Xcode
7. ⏳ Build & Run → Teste
```

---

## 🎯 Próximo Passo Após SPM

1. Fechar e reabrir Xcode
2. Adicionar **Push Notifications Capability**:
   - Runner → Signing & Capabilities
   - + Capability → Push Notifications
3. Build para iOS:
   ```bash
   flutter build ios --debug
   ```

---

## 📊 Status iOS

| Item | Status |
|------|--------|
| GoogleService-Info.plist | ✅ Criado |
| firebase_options.dart | ✅ Configurado |
| CocoaPods | ✅ Pronto (pod install) |
| SPM Firebase SDKs | ⏳ **Adicionando agora** |
| Push Notifications | ⏳ Após SPM |
| Build | ⏳ Após Capabilities |

---

## 🔗 Referências Oficiais

- [Firebase iOS Setup](https://firebase.google.com/docs/ios/setup)
- [Firebase iOS SDK GitHub](https://github.com/firebase/firebase-ios-sdk)
- [Swift Package Manager - Apple](https://developer.apple.com/documentation/xcode/adding-package-dependencies-to-your-app)

---

## ✅ Após Completar Este Passo

Volta aqui e avise para:
1. Adicionar **Push Notifications Capability**
2. Fazer **Build & Run** no emulador/device
3. Testar **notificações push**
