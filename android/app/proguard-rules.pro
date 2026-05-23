# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }

# Project
-keep class com.vedica.labs.ind.app.chat.openmodels.** { *; }

# Native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep source info for crash reporting
-keepattributes SourceFile,LineNumberTable
-keepattributes *Annotation*

# Keep model/data classes used by sqflite
-keep class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Keep Dart functions referenced from native
-keep class _DartFunction { *; }

# Kotlin
-keep class kotlin.** { *; }

# LLM / inference libraries
-keep class org.libsdl.** { *; }
-keep class ai.onnxruntime.** { *; }
-keep class org.tensorflow.** { *; }

# Flutter Play Store deferred components (not used, but referenced in engine)
-dontwarn com.google.android.play.core.splitcompat.**
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**

# TensorFlow Lite GPU delegate (optional, referenced by tflite_flutter)
-dontwarn org.tensorflow.lite.gpu.**

# Remove debug logs in release
-assumenosideeffects class android.util.Log {
    public static boolean isLoggable(java.lang.String, int);
    public static int v(...);
    public static int d(...);
    public static int i(...);
}
