# Suppress R8 warnings for missing java.beans classes (not available on Android)
# These classes don't exist on Android, so we add empty stubs via -keep
-keep class java.beans.** { *; }
-dontwarn java.beans.**