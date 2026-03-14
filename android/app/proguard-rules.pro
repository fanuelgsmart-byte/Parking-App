# ──────────────────────────────────────────────────────────────
# ParkFlow Manager - ProGuard / R8 Rules
# ──────────────────────────────────────────────────────────────
# These rules are applied when building with:
#   flutter build apk --obfuscate --split-debug-info=build/symbols
#
# Reference in android/app/build.gradle:
#   buildTypes {
#       release {
#           minifyEnabled true
#           shrinkResources true
#           proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'),
#                         'proguard-rules.pro'
#       }
#   }
# ──────────────────────────────────────────────────────────────

# Keep Flutter and Dart VM internals
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep JSON serialization models (freezed / json_serializable)
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Keep Drift / SQLCipher
-keep class org.sqlite.** { *; }
-keep class net.zetetic.database.** { *; }
-dontwarn net.zetetic.**

# Keep Flutter Secure Storage
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# Keep local_auth
-keep class androidx.biometric.** { *; }

# Keep connectivity_plus
-keep class dev.fluttercommunity.plus.connectivity.** { *; }

# Remove logging in release builds
-assumenosideeffects class android.util.Log {
    public static int v(...);
    public static int d(...);
    public static int i(...);
    public static int w(...);
    public static int e(...);
}

# Obfuscate everything else
-repackageclasses ''
-allowaccessmodification
-optimizations !code/simplification/arithmetic
