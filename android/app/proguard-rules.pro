# Flutter and plugin registrant classes are reflected by the Android embedding.
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugins.** { *; }

# local_auth uses AndroidX biometric / fragment APIs through plugin code.
-keep class androidx.biometric.** { *; }
-keep class androidx.fragment.app.** { *; }
