# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Google ML Kit text recognition: optional script packages we don't ship.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
-keep class com.google.mlkit.vision.text.chinese.** { *; }
-keep class com.google.mlkit.vision.text.devanagari.** { *; }
-keep class com.google.mlkit.vision.text.japanese.** { *; }
-keep class com.google.mlkit.vision.text.korean.** { *; }

# Speech-to-text plugin
-keep class com.csdcorp.speech_to_text.** { *; }

# Image picker
-keep class io.flutter.plugins.imagepicker.** { *; }

# Play Core (deferred components) — only used for Play Store dynamic feature delivery, not in our APK.
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }
