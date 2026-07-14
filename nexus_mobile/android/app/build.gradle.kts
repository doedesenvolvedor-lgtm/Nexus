// android/app/build.gradle.kts
plugins {
    id("com.android.application")
    
    // Add the Google services Gradle plugin
    id("com.google.gms.google-services")
    
    // Firebase Crashlytics plugin
    id("com.google.firebase.crashlytics")
    
    // Kotlin
    kotlin("android")
}

android {
    namespace = "com.nexus.streaming"
    compileSdk = 34

    defaultConfig {
        applicationId = "com.nexus.streaming"
        minSdk = 21
        targetSdk = 34
        versionCode = 1
        versionName = "1.0.0"

        // Multidex support (needed for Firebase)
        multiDexEnabled = true

        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
        
        debug {
            isDebuggable = true
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    buildFeatures {
        buildConfig = true
        viewBinding = false
    }
}

dependencies {
    // AndroidX libraries
    implementation("androidx.appcompat:appcompat:1.6.1")
    implementation("androidx.constraintlayout:constraintlayout:2.1.4")
    implementation("androidx.multidex:multidex:2.0.1")

    // Kotlin
    implementation("org.jetbrains.kotlin:kotlin-stdlib-jdk8:1.9.21")

    // Import the Firebase BoM (Bill of Materials)
    // This allows you to specify Firebase library versions without specifying each individually
    implementation(platform("com.google.firebase:firebase-bom:34.16.0"))

    // Firebase Core
    implementation("com.google.firebase:firebase-core")

    // Firebase Cloud Messaging (Push Notifications)
    implementation("com.google.firebase:firebase-messaging")

    // Firebase Analytics
    implementation("com.google.firebase:firebase-analytics")

    // Firebase Crashlytics
    implementation("com.google.firebase:firebase-crashlytics")

    // Firebase Performance Monitoring (Optional)
    // implementation("com.google.firebase:firebase-perf")

    // Firebase Realtime Database (Optional)
    // implementation("com.google.firebase:firebase-database")

    // Firebase Firestore (Optional)
    // implementation("com.google.firebase:firebase-firestore")

    // Firebase Storage (Optional)
    // implementation("com.google.firebase:firebase-storage")

    // Testing
    testImplementation("junit:junit:4.13.2")
    androidTestImplementation("androidx.test.ext:junit:1.1.5")
    androidTestImplementation("androidx.test.espresso:espresso-core:3.5.1")
}

// Firebase Crashlytics configuration
firebaseCrashlytics {
    nativeSymbolUploadEnabled = true
    unstrippedNativeLibsDir = "build/intermediates/merged_native_libs/release/out/lib"
}
