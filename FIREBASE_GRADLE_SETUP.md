# Firebase Android Gradle Configuration

## ✅ Arquivos Configurados

### 1. build.gradle.kts (Nível Raiz)
**Localização:** `android/build.gradle.kts`

- Adiciona plugin `com.google.gms.google-services` v4.5.0
- Adiciona plugin `com.google.firebase.firebase-crashlytics-gradle` v2.9.10
- Configura repositórios Google e Maven Central

### 2. settings.gradle.kts (Nível Raiz)
**Localização:** `android/settings.gradle.kts`

- Define plugins disponíveis
- Configura repositórios de dependências
- Inclui módulo `:app`

### 3. build.gradle.kts (Nível App)
**Localização:** `android/app/build.gradle.kts`

- Aplica plugins: `com.android.application`, `com.google.gms.google-services`, `com.google.firebase.crashlytics`, `kotlin-android`
- Configura compileSdk = 34, minSdk = 21, targetSdk = 34
- Importa Firebase BoM (Bill of Materials) v34.16.0
- Adiciona dependências:
  - Firebase Core
  - Firebase Cloud Messaging (Push Notifications)
  - Firebase Analytics
  - Firebase Crashlytics
  - AndroidX libraries
  - Kotlin stdlib

### 4. proguard-rules.pro (Nível App)
**Localização:** `android/app/proguard-rules.pro`

- Configurações ProGuard para Firebase
- Preserve classes do Firebase e Flutter
- Mantém enums e view constructors

---

## 🚀 Como Usar

### 1. Sincronizar Gradle

Abra o projeto Android em Android Studio:

```bash
cd nexus_mobile
flutter pub get
```

Ou abra `nexus_mobile/android` diretamente em Android Studio:

```bash
open -a "Android Studio" nexus_mobile/android
```

Clique em "Sync Now" para sincronizar Gradle.

### 2. Build APK

```bash
cd nexus_mobile
flutter build apk --debug      # Debug
flutter build apk --release    # Release
```

### 3. Instalar no Device

```bash
flutter run          # Em emulador/device conectado
```

---

## 📋 Versões

| Componente | Versão |
|-----------|--------|
| Android Gradle Plugin | 8.1.0 |
| Kotlin | 1.9.21 |
| Google Services Plugin | 4.5.0 |
| Firebase Crashlytics Plugin | 2.9.10 |
| Firebase BoM | 34.16.0 |
| compileSdk | 34 |
| minSdk | 21 |
| targetSdk | 34 |

---

## 🔧 Dependências Firebase Adicionadas

```kotlin
// Importa todas do Firebase BoM
implementation(platform("com.google.firebase:firebase-bom:34.16.0"))

// Firebase Core
implementation("com.google.firebase:firebase-core")

// Cloud Messaging (Push Notifications)
implementation("com.google.firebase:firebase-messaging")

// Analytics
implementation("com.google.firebase:firebase-analytics")

// Crashlytics
implementation("com.google.firebase:firebase-crashlytics")
```

---

## 📱 AndroidManifest.xml Necessário

Certifique-se de que o `AndroidManifest.xml` tem as permissões necessárias:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />  <!-- Android 13+ -->
```

---

## ✅ Checklist

- [x] `build.gradle.kts` criado no nível raiz
- [x] `settings.gradle.kts` criado
- [x] `build.gradle.kts` criado no nível app
- [x] Plugins Google Services configurados
- [x] Firebase BoM importado
- [x] Dependências Firebase adicionadas
- [x] `proguard-rules.pro` configurado
- [ ] Sincronizar Gradle em Android Studio
- [ ] Build APK
- [ ] Testar em device/emulador

---

## 🐛 Troubleshooting

### "Failed to resolve com.google.firebase:firebase-core"

```
✓ Certifique-se de que tem internet conectada
✓ Sincronize Gradle: File → Sync Now
✓ Invalide cache: File → Invalidate Caches...
```

### "Plugin with id 'com.google.gms.google-services' not found"

```
✓ Certifique-se que build.gradle.kts raiz tem o plugin
✓ Atualize Android Studio: Help → Check for Updates
```

### "google-services.json not found"

```
✓ Certifique-se que google-services.json está em:
  nexus_mobile/android/app/google-services.json
✓ Reconhecer o arquivo: File → Sync with File System
```

### Erro de compilação Kotlin

```
✓ Atualize Kotlin: Settings → Languages & Frameworks → Kotlin Compiler
✓ Limpe build: ./gradlew clean
✓ Rebuild: Build → Make Project
```

---

## 📚 Documentação Relacionada

- [FIREBASE_SETUP_GUIDE.md](../FIREBASE_SETUP_GUIDE.md) - Setup geral
- [FIREBASE_BACKEND_SETUP.md](../FIREBASE_BACKEND_SETUP.md) - Setup Backend
- [FIREBASE_STATUS.md](../FIREBASE_STATUS.md) - Status geral
- [Official Google Services Plugin](https://developers.google.com/android/guides/google-services-plugin)
- [Firebase Android Setup](https://firebase.google.com/docs/android/setup)

---

## 🎯 Próximos Passos

1. Sincronize Gradle em Android Studio
2. Build do APK (debug)
3. Teste em emulador/device
4. Verifique se push notifications funcionam
5. Monitore Crashlytics no Firebase Console
