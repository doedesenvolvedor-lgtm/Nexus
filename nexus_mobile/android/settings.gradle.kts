// settings.gradle.kts
pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }

    plugins {
        id("com.android.application") version "8.1.0"
        id("com.android.library") version "8.1.0"
        kotlin("android") version "1.9.21"
        kotlin("jvm") version "1.9.21"
        id("com.google.gms.google-services") version "4.5.0"
        id("com.google.firebase.crashlytics") version "2.9.10"
    }
}

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.name = "nexus_mobile"
include(":app")
