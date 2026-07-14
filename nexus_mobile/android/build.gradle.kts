// Root build.gradle.kts (Project level)
plugins {
    // Kotlin DSL Plugins
    kotlin("jvm") version "1.9.21" apply false
    kotlin("android") version "1.9.21" apply false
    
    // Android Gradle Plugin
    id("com.android.application") version "8.1.4" apply false
    
    // Google services Gradle plugin
    id("com.google.gms.google-services") version "4.4.4" apply false
    
    // Firebase Crashlytics Gradle plugin
    id("com.google.firebase.crashlytics") version "3.0.7" apply false
}


allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

tasks.register("clean", Delete::class) {
    delete(rootProject.buildDir)
}
