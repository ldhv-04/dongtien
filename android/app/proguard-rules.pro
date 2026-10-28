# ==============================================================================
# DONG TIEN (vn.dongtien) — R8 CODE & RESOURCE SHRINKING RULES
# ==============================================================================

# 1. Flutter Engine & Plugins Core
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# 2. flutter_local_notifications plugin
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-dontwarn com.dexterous.flutterlocalnotifications.**

# 3. SQLite3 & Drift Native Library
-keepclasseswithmembernames class * {
    native <methods>;
}
-keep class org.sqlite.** { *; }
-dontwarn org.sqlite.**

# 4. Desugaring / Java 8 Time Support
-dontwarn java.time.**

# 5. File Picker & Share Plus Plugins
-keep class com.mr.flutter.plugin.filepicker.** { *; }
-keep class dev.fluttercommunity.plus.share.** { *; }

# 6. Reflection, Annotations, and Exception Signatures
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes Exceptions
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# 7. Flutter Deferred Components / Play Store Split Suppressions
-dontwarn com.google.android.play.core.**

