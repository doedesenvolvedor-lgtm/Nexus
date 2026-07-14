# 🍎 Firebase iOS Setup - Guia Prático Passo a Passo

## 🎯 Objetivo
Adicionar Firebase SDKs + Push Notifications ao seu app iOS no Xcode

---

## 📱 PASSO 1: Abrir o Terminal

Copie e cole este comando:

```bash
cd /workspaces/Nexus/nexus_mobile
open ios/Runner.xcworkspace
```

**O que vai acontecer:**
- Xcode abre automaticamente
- Você vê o projeto Flutter
- Painel esquerdo mostra pastas do projeto

---

## 🔧 PASSO 2: Adicionar Firebase SDKs via SPM

### 2.1 - Clique no Menu
```
Xcode (menu superior à esquerda)
    ↓
File
    ↓
Add Packages...
```

### 2.2 - Uma janela abre
```
"Enter the URL of the package repository"

Cole aqui:
https://github.com/firebase/firebase-ios-sdk

Depois clique: "Add Package"
```

### 2.3 - Selecionar Versão
```
Você verá dropdown com versões.

Escolha:
"Up to Next Major Version" (automático)
OU
Digite: 10.24.0

Clique: "Next"
```

### 2.4 - Selecionar Bibliotecas ⭐ IMPORTANTE

Uma tela aparece com MUITAS bibliotecas. Procure por essas e **marque com ✓**:

```
☑️ FirebaseAnalytics
☑️ FirebaseMessaging
☑️ FirebaseCrashlytics
```

(As outras virão automáticas - não precisa marcar)

### 2.5 - Terminar
```
Clique: "Finish"

Xcode começa a download (2-5 minutos)
Você verá uma barra de progresso na base
```

**Quando terminar**: Você vê ✅ (não X)

---

## 📲 PASSO 3: Adicionar Push Notifications

### 3.1 - Selecionar Runner
```
Painel esquerdo (Project Navigator)
    ↓
Clique em: "Runner" (a pasta raiz)
    ↓
Abrem 3 abas no painel central: General, Signing & Capabilities, Build Settings
```

### 3.2 - Ir para Capabilities
```
Painel central: Clique na aba
"Signing & Capabilities"
```

### 3.3 - Adicionar Capability
```
Topo à direita: Clique em "+ Capability"

Uma lista dropdown aparece
Procure por: "Push Notifications"
Clique nela
```

### 3.4 - Confirmar
```
Você verá agora:
"Push Notifications ✅" listado com uma caixa de seleção

Deixe marcado ✅
```

---

## 📦 PASSO 4: Instalar Pods (CocoaPods)

### 4.1 - Abrir Terminal
```
Terminal.app (aplicativo do Mac)
OU
Xcode → View → Inspectors → Console
```

### 4.2 - Executar Comando
```bash
cd /workspaces/Nexus/nexus_mobile/ios
pod install --repo-update
```

**O que vai acontecer:**
- Baixa pods do Firebase (2-5 min)
- Você vê muitas linhas
- Termina com: "Pod installation complete!"

### 4.3 - Voltar para Xcode
```bash
cd ..
# Volta para nexus_mobile
```

---

## 🔨 PASSO 5: Build iOS

### 5.1 - Na pasta Flutter
```bash
cd /workspaces/Nexus/nexus_mobile

# Sincronizar dependências
flutter pub get

# Build para iOS
flutter build ios --debug
```

**Tempo estimado**: 5-10 minutos

**Você verá**: Muito texto, depois no final:
```
✅ Build successful
```

---

## ✅ PASSO 6: Testar

### 6.1 - Rodar no Emulador
```bash
flutter run -d iPhone\ 15
# ou qualquer device que você tem
```

**Você verá:**
- App compilando (2-3 min)
- App abrindo no emulador
- Permissão de notificações solicitada
- App normal funcionando

### 6.2 - Verificar Console
```
Xcode → View → Debug Area → Console

Procure por linhas como:
✅ Firebase inicializado
🔔 FCM Token: <seu-token-aqui>
✅ APNs Token registrado
```

---

## 📋 Checklist Rápido

```bash
# Executar em sequência:

1. open ios/Runner.xcworkspace
   # Xcode abre

2. File → Add Packages
   # Adicionar https://github.com/firebase/firebase-ios-sdk
   # Selecionar: FirebaseAnalytics, FirebaseMessaging, FirebaseCrashlytics
   # Clique Finish

3. Runner → Signing & Capabilities
   # + Capability → Push Notifications

4. Terminal:
   cd /workspaces/Nexus/nexus_mobile/ios
   pod install --repo-update
   cd ..

5. flutter pub get

6. flutter build ios --debug

7. flutter run -d iPhone\ 15
   # ou seu device
```

---

## 🚨 Se Algo Der Errado

### Erro: "Pod installation failed"
```bash
# Solução:
cd ios
rm Podfile.lock
rm -rf Pods
pod repo update
pod install
cd ..
```

### Erro: "Firebase not found"
```
Na tela de Capabilities, certifique que:
✅ Push Notifications está marcado
✅ Seu Team ID está preenchido
```

### Erro: "Build failed"
```bash
# Limpar cache:
flutter clean
flutter pub get
flutter build ios --debug
```

### Emulador não aparece
```bash
# Ver dispositivos disponíveis:
xcrun simctl list devices

# Criar novo emulador:
open /Applications/Xcode.app/Contents/Developer/Applications/Simulator.app
```

---

## ⏱️ Tempo Total Estimado

| Tarefa | Tempo |
|--------|-------|
| Abrir Xcode | 1 min |
| Adicionar Firebase SDKs | 3-5 min |
| Adicionar Capability | 1 min |
| Pod install | 3-5 min |
| flutter pub get | 1-2 min |
| flutter build ios | 5-10 min |
| flutter run | 2-3 min |
| **TOTAL** | **~20-30 min** |

---

## ✅ Quando Terminar

Você terá:
```
✅ Xcode com Firebase SDKs adicionados
✅ Push Notifications configurado
✅ App compilado para iOS
✅ App rodando no emulador
✅ Firebase funcionando (console mostra logs)
```

---

## 🎉 Próximo Passo

Depois que o app está rodando:
1. Abrir [Firebase Console](https://console.firebase.google.com)
2. Projeto: **nexus-3fb82**
3. **Messaging** → **Send Test Message**
4. Selecionar seu device
5. Enviar mensagem
6. **Notificação aparece no emulador!** 🎊

---

## 📞 Precisa de Help?

Se travar em algum passo, volta aqui e me avisa:
- Qual passo travou?
- Qual erro apareceu?
- Screenshot se possível

Vou te ajudar! 💪
