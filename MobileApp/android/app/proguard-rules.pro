# FFmpegKit — required for release APK (prevents JNI / white screen on startup)
# https://github.com/sk3llo/ffmpeg_kit_flutter/wiki/Common-Bugfixes

-keep class com.antonkarpenko.ffmpegkit.** { *; }
-dontwarn com.antonkarpenko.ffmpegkit.**

-keepclasseswithmembernames class * {
    native <methods>;
}

-keep class com.antonkarpenko.ffmpegkit.FFmpegKitConfig { *; }
-keep class com.antonkarpenko.ffmpegkit.AbiDetect { *; }
-keep class com.antonkarpenko.ffmpegkit.**Session { *; }
-keep class com.antonkarpenko.ffmpegkit.**Callback { *; }

-keep public class com.antonkarpenko.ffmpegkit.** {
    public *;
}

-keepattributes *Annotation*, Signature, InnerClasses, EnclosingMethod

# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Play Core (optional Flutter deferred components — not used in this app)
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.SplitInstallException
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManager
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManagerFactory
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest$Builder
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest
-dontwarn com.google.android.play.core.splitinstall.SplitInstallSessionState
-dontwarn com.google.android.play.core.splitinstall.SplitInstallStateUpdatedListener
-dontwarn com.google.android.play.core.tasks.OnFailureListener
-dontwarn com.google.android.play.core.tasks.OnSuccessListener
-dontwarn com.google.android.play.core.tasks.Task
