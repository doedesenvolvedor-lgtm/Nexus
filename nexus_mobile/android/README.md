# Android Gradle Build Configuration for Nexus Streaming

## 📁 Estrutura de Diretórios

```
android/
├── build.gradle.kts              ← Configuração raiz (projeto)
├── settings.gradle.kts            ← Settings raiz
├── app/
│   ├── build.gradle.kts          ← Configuração app
│   ├── proguard-rules.pro         ← ProGuard rules
│   ├── google-services.json       ← Firebase config (Android)
│   └── src/
│       └── main/
│           └── AndroidManifest.xml ← Manifesto do app
```

## 🚀 Quick Start

### 1. Sync Gradle

```bash
# Via Flutter
flutter pub get

# Ou abra em Android Studio
open -a "Android Studio" android/
# Clique "Sync Now"
```

### 2. Build APK

```bash
# Debug build
flutter build apk --debug

# Release build
flutter build apk --release
```

### 3. Run em Device

```bash
flutter run
```

## 📋 O que foi Configurado

### ✅ Gradle Plugins
- Android Gradle Plugin 8.1.0
- Google Services Plugin 4.5.0
- Firebase Crashlytics Plugin 2.9.10
- Kotlin 1.9.21

### ✅ Firebase Dependencies
- Firebase Core
- Firebase Cloud Messaging (FCM)
- Firebase Analytics
- Firebase Crashlytics

### ✅ AndroidX & Support
- AndroidX AppCompat
- AndroidX ConstraintLayout
- AndroidX Multidex

## 🔑 Configurações Importantes

### compileSdk / minSdk / targetSdk
```
compileSdk = 34  (Latest)
minSdk = 21      (API 21 - Android 5.0)
targetSdk = 34   (Latest)
```

### Java Compatibility
```
sourceCompatibility = JavaVersion.VERSION_11
targetCompatibility = JavaVersion.VERSION_11
```

### Multidex Enabled
```
multiDexEnabled = true  (Firebase requer isso)
```

## 📱 Permissions (AndroidManifest.xml)

```xml
<!-- Essencial -->
<uses-permission android:name="android.permission.INTERNET" />

<!-- Android 13+ (para notificações) -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />

<!-- Opcional (depende do seu app) -->
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
```

## 🐛 Troubleshooting

### Gradle Sync Fails
```bash
# 1. Limpar cache Gradle
rm -rf ~/.gradle/caches

# 2. Sincronizar novamente
flutter pub get
```

### Build Fails com "google-services not found"
```bash
# Certifique-se que google-services.json existe em:
ls android/app/google-services.json

# Se não existe, copie de Firebase Console
```

### Compilação Lenta
```bash
# Use daemon do Gradle
export GRADLE_OPTS="-Xmx2048m"

# Ou no build.gradle
org.gradle.parallel=true
org.gradle.workers.max=8
```

### "Task 'app:compileReleaseKotlin' failed"
```bash
# Invalide cache Gradle
./gradlew clean

# Rebuild
flutter build apk --release
```

## 📚 Documentação

- [Android Gradle Plugin Docs](https://developer.android.com/build)
- [Google Services Plugin](https://developers.google.com/android/guides/google-services-plugin)
- [Firebase Android Setup](https://firebase.google.com/docs/android/setup)
- [ProGuard Manual](https://www.guardsquare.com/manual/configuration/index.html)

## ✅ Checklist

- [x] build.gradle.kts (raiz) configurado
- [x] settings.gradle.kts configurado
- [x] build.gradle.kts (app) configurado
- [x] proguard-rules.pro configurado
- [x] google-services.json adicionado
- [x] AndroidManifest.xml configurado
- [ ] Sincronizar Gradle (fazer quando abrir no Android Studio)
- [ ] Build APK de teste
- [ ] Testar em emulador/device
