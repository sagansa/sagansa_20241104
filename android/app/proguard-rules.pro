# ==========================================================================
# Sagansa — ProGuard/R8 keep rules
#
# Aktif bersama minifyEnabled + shrinkResources di buildTypes.release.
# Flutter sendiri sudah memaketkan sebagian besar rules lewat consumer rules
# dari plugin, tetapi beberapa library di bawah perlu keep eksplisit untuk
# menghindari runtime crash (reflection, serialization, JNI).
# ==========================================================================

# --- Flutter core ---
# Flutter engine memakai reflection untuk plugin registrant & native bindings.
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# --- GetX (state management, dependency injection) ---
# GetX memakai reflection untuk binding controller. Pertahankan annotation &
# default constructor.
-keep class get.** { *; }
-keep @io.flutter.embedding.android.FlutterActivity class *
-keepclassmembers class * {
    @get.* <methods>;
}

# --- Syncfusion Flutter Calendar / DateRangePicker ---
# Syncfusion memakai reflection untuk recurrence engine & data mapping.
-keep class com.syncfusion.** { *; }
-dontwarn com.syncfusion.**

# --- sqflite (local database audit logs) ---
-keep class com.tekartik.sqflite.** { *; }
-dontwarn com.tekartik.sqflite.**

# --- flutter_local_notifications ---
# Channel & scheduled notification butuh akses ke class receiver via reflection.
-keep class com.dexterous.** { *; }
-dontwarn com.dexterous.**

# --- Geolocator ---
-keep class com.baseflow.** { *; }
-dontwarn com.baseflow.**

# --- Workmanager (periodic location ping) ---
# callbackDispatcher & @pragma('vm:entry-point') Dart functions dilarang di-
# tree-shake, tapi native side tetap butuh class worker ter-keep.
-keep class dev.fluttercommunity.workmanager.** { *; }
-dontwarn dev.fluttercommunity.workmanager.**

# --- image_picker / flutter_image_compress ---
-keep class io.flutter.plugins.imagepicker.** { *; }
-keep class com.yalantis.** { *; }
-dontwarn com.yalantis.**

# --- Firebase (opsional, tidak aktif di rilis awal, tapi SDK tetap di-pull) ---
# Consumer rules firebase sudah lengkap, pertahankan untuk saat modul FCM
# diaktifkan kembali nanti.
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# --- PDF / printing ---
-keep class com.davemorrissey.labs.** { *; }
-dontwarn com.davemorrissey.labs.**

# --- General safety ---
# Pertahankan enum values (sering dipakai via reflection di serialization).
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Kotlin metadata — pertahankan agar interoperabilitas reflection Kotlin aman.
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# Compat warnings dari library yang tidak relevan — silent.
-dontwarn com.google.android.play.core.**
-dontwarn io.flutter.embedding.engine.deferredcomponents.**
-dontwarn javax.annotation.**
