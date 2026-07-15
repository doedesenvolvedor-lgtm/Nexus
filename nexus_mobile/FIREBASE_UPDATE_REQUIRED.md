# Firebase Configuration Status

## ⚠️ CRÍTICO: Atualizar google-services.json

Você alterou o `applicationId` de `com.example.nexus_mobile` para `com.nexus.streaming`.

Isso significa que **DEVE regenerar o `google-services.json`** do Firebase Console.

### 🔧 Como Regenerar:

1. Acesse [Firebase Console](https://console.firebase.google.com)
2. Selecione seu projeto Nexus
3. Vá para **Project Settings** (engrenagem)
4. Na aba **Apps**, encontre ou crie um app Android
5. **Altere o Package Name** para: `com.nexus.streaming`
6. Baixe o novo `google-services.json`
7. Substitua o arquivo em: `nexus_mobile/android/app/google-services.json`

### 📋 O que muda:

- ✅ Firebase Authentication funcionará
- ✅ Cloud Firestore se conectará
- ✅ Firebase Messaging receberá notificações
- ✅ Crashlytics registrará erros
- ✅ Analytics rastreará eventos

### ⚡ Próximas Etapas:

Após fazer isso:

```bash
flutter clean
flutter pub get
flutter build apk --release
```

---

## 🔗 Links Úteis:

- [Firebase Console](https://console.firebase.google.com)
- [Android App Signing Guide](https://developer.android.com/studio/publish/app-signing)
- [Google Play Console](https://play.google.com/console)
