# Keep TensorFlow Lite classes used via reflection
-keep class org.tensorflow.** { *; }
-dontwarn org.tensorflow.**

# Keep Google ML Kit Face Detection
-keep class com.google.mlkit.vision.** { *; }
-keep class com.google.mlkit.common.** { *; }
-dontwarn com.google.mlkit.**

# Keep Firebase classes
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Keep Flutter plugins that may use reflection
-keep class io.flutter.** { *; }
-dontwarn io.flutter.**

# Keep JNI bindings
-keepclasseswithmembers class * {
    native <methods>;
}

# Keep enums used by name
-keepclassmembers enum * { *; }

# Keep annotations
-keepattributes *Annotation*

# Keep camera classes
-keep class androidx.camera.** { *; }
-dontwarn androidx.camera.**

# Keep Hive classes
-keep class hive.** { *; }
-dontwarn hive.**
