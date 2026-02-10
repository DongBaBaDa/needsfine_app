# Flutter & Dart
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# Supabase
-keep class io.supabase.** { *; }
-dontwarn io.supabase.**

# Google Sign In
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# Kakao SDK
-keep class com.kakao.** { *; }
-dontwarn com.kakao.**

# Naver Map
-keep class com.naver.maps.** { *; }
-dontwarn com.naver.maps.**

# Keep generic signatures for JSON parsing
-keepattributes Signature
-keepattributes *Annotation*

# Keep Parcelables
-keepclassmembers class * implements android.os.Parcelable {
    public static final ** CREATOR;
}

# Keep Serializable
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    !static !transient <fields>;
    !private <fields>;
    !private <methods>;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Apple Sign In
-keep class com.aboutyou.dart_packages.sign_in_with_apple.** { *; }
