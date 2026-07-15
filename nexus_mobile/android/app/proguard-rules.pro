# Proguard rules for Nexus Streaming App

# Keep Flutter classes
-keep class io.flutter.** { *; }
-keep interface io.flutter.** { *; }

# Keep Firebase classes
-keep class com.google.firebase.** { *; }
-keep interface com.google.firebase.** { *; }
-keepnames class com.google.firebase.auth.FirebaseAuth
-keepnames class com.google.firebase.messaging.FirebaseMessaging

# Keep Firebase Crashlytics
-keep class com.google.firebase.crashlytics.** { *; }
-keepattributes SourceFile,LineNumberTable
-keepattributes *Annotation*

# Keep Firebase Analytics
-keep class com.google.firebase.analytics.** { *; }

# Keep native methods
-keepattributes Signature
-keepattributes SourceFile,LineNumberTable

# Keep enums
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Keep Parcelable and Serializable implementations
-keep class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}

-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Keep your app's classes
-keep class com.nexus.streaming.** { *; }
-keepclasseswithmembernames class com.nexus.streaming.** {
    native <methods>;
}

# Keep Google Services classes
-keep class com.google.android.gms.** { *; }
-keep interface com.google.android.gms.** { *; }

# Verbose logging
-verbose

# Optimization
-optimizationpasses 5
-dontusemixedcaseclassnames

# Remove logging
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
}
