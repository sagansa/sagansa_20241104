import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Typography scale following Material Design 3 principles.
///
/// Konvensi penting:
/// - [base] styles (displayLarge, bodyMedium, dll.) didefinisikan TANPA warna
///   dan memakai `inherit: false` agar bisa di-lerp oleh AnimatedTheme.
/// - Gunakan [lightTextTheme] / [darkTextTheme] saat mendaftarkan ThemeData.
///   Kedua builder ini mengambil base styles dan meng-inject warna yang sesuai
///   (onSurface / darkOnSurface) sehingga SEMUA widget Text default terlihat
///   di mode apapun. Ini adalah satu-satunya tempat yang perlu diubah bila
///   ingin menyesuaikan warna teks global.
class AppTypography {
  // ===========================================================================
  // Base styles (tanpa warna). inherit: false wajib supaya AnimatedTheme
  // dapat menginterpolasi (lerp) TextStyle saat transisi light <-> dark.
  // inherit: false juga men-override inheritance dari DefaultTextStyle/icon,
  // jadi warna HARUS di-inject via lightTextTheme/darkTextTheme.
  // ===========================================================================

  static const TextStyle displayLarge = TextStyle(
    inherit: false,
    fontSize: 57,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.25,
    height: 1.12,
    textBaseline: TextBaseline.alphabetic,
  );

  static const TextStyle displayMedium = TextStyle(
    inherit: false,
    fontSize: 45,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.16,
    textBaseline: TextBaseline.alphabetic,
  );

  static const TextStyle displaySmall = TextStyle(
    inherit: false,
    fontSize: 36,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.22,
    textBaseline: TextBaseline.alphabetic,
  );

  static const TextStyle headlineLarge = TextStyle(
    inherit: false,
    fontSize: 32,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.25,
    textBaseline: TextBaseline.alphabetic,
  );

  static const TextStyle headlineMedium = TextStyle(
    inherit: false,
    fontSize: 28,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.29,
    textBaseline: TextBaseline.alphabetic,
  );

  static const TextStyle headlineSmall = TextStyle(
    inherit: false,
    fontSize: 24,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.33,
    textBaseline: TextBaseline.alphabetic,
  );

  static const TextStyle titleLarge = TextStyle(
    inherit: false,
    fontSize: 22,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
    height: 1.27,
    textBaseline: TextBaseline.alphabetic,
  );

  static const TextStyle titleMedium = TextStyle(
    inherit: false,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.15,
    height: 1.50,
    textBaseline: TextBaseline.alphabetic,
  );

  static const TextStyle titleSmall = TextStyle(
    inherit: false,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.43,
    textBaseline: TextBaseline.alphabetic,
  );

  static const TextStyle labelLarge = TextStyle(
    inherit: false,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.43,
    textBaseline: TextBaseline.alphabetic,
  );

  static const TextStyle labelMedium = TextStyle(
    inherit: false,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.33,
    textBaseline: TextBaseline.alphabetic,
  );

  static const TextStyle labelSmall = TextStyle(
    inherit: false,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.45,
    textBaseline: TextBaseline.alphabetic,
  );

  static const TextStyle bodyLarge = TextStyle(
    inherit: false,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.15,
    height: 1.50,
    textBaseline: TextBaseline.alphabetic,
  );

  static const TextStyle bodyMedium = TextStyle(
    inherit: false,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
    height: 1.43,
    textBaseline: TextBaseline.alphabetic,
  );

  static const TextStyle bodySmall = TextStyle(
    inherit: false,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    height: 1.33,
    textBaseline: TextBaseline.alphabetic,
  );

  // Button styles (juga inherit: false supaya lerp aman).
  static const TextStyle buttonLarge = TextStyle(
    inherit: false,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    height: 1.25,
    textBaseline: TextBaseline.alphabetic,
  );

  static const TextStyle buttonMedium = TextStyle(
    inherit: false,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    height: 1.43,
    textBaseline: TextBaseline.alphabetic,
  );

  static const TextStyle buttonSmall = TextStyle(
    inherit: false,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    height: 1.33,
    textBaseline: TextBaseline.alphabetic,
  );

  // Caption & overline (inherit: true karena tidak dipakai di ThemeData
  // textTheme, hanya helper internal).
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    height: 1.33,
  );

  static const TextStyle overline = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.5,
    height: 1.6,
  );

  // ===========================================================================
  // THEMED TEXT THEMES
  //
  // Inilah sumber kebenaran untuk warna teks. Gunakan di ThemeData.light/dark.
  // Untuk mengubah warna teks global di dark mode, cukup edit [darkTextColor]
  // / [darkMutedColor] di sini — seluruh app akan ikut.
  //
  // darkTextColor sengaja dipilih putih-cream terang (#FFFFFF) agar teks
  // selalu kontras & nyaman dibaca di background obsidian (#0A0A0A).
  // ===========================================================================

  /// Warna teks utama di light mode (default body/title).
  static const Color lightTextColor = AppColors.onSurface; // #1A1A1A
  /// Warna teks sekunder/muted di light mode.
  static const Color lightMutedColor = AppColors.onSurfaceVariant; // #5C5648

  /// Warna teks utama di dark mode. Putih penuh agar kontras maksimal
  /// di background obsidian. Turunkan alpha di sini bila ingin lebih lembut.
  static const Color darkTextColor = AppColors.darkOnSurface; // #F5F0E1
  /// Warna teks sekunder/muted di dark mode.
  static const Color darkMutedColor = AppColors.darkOnSurfaceVariant; // #A89F8C

  /// TextTheme untuk light mode. Semua style mendapat warna onSurface.
  static TextTheme get lightTextTheme => _buildTextTheme(
        textColor: lightTextColor,
        mutedColor: lightMutedColor,
      );

  /// TextTheme untuk dark mode. Semua style mendapat warna cream terang.
  static TextTheme get darkTextTheme => _buildTextTheme(
        textColor: darkTextColor,
        mutedColor: darkMutedColor,
      );

  /// Membangun TextTheme dengan warna yang sudah di-inject ke setiap style.
  ///
  /// Title & label sedikit lebih bold (w600) agar kontras dengan body.
  static TextTheme _buildTextTheme({
    required Color textColor,
    required Color mutedColor,
  }) {
    return TextTheme(
      // Display — pakai textColor penuh
      displayLarge: displayLarge.copyWith(color: textColor),
      displayMedium: displayMedium.copyWith(color: textColor),
      displaySmall: displaySmall.copyWith(color: textColor),
      // Headline — pakai textColor penuh
      headlineLarge: headlineLarge.copyWith(color: textColor),
      headlineMedium: headlineMedium.copyWith(color: textColor),
      headlineSmall: headlineSmall.copyWith(color: textColor),
      // Title — textColor penuh
      titleLarge: titleLarge.copyWith(color: textColor),
      titleMedium: titleMedium.copyWith(color: textColor),
      titleSmall: titleSmall.copyWith(color: textColor),
      // Body — bodyLarge & bodyMedium pakai textColor, bodySmall pakai muted
      bodyLarge: bodyLarge.copyWith(color: textColor),
      bodyMedium: bodyMedium.copyWith(color: textColor),
      bodySmall: bodySmall.copyWith(color: mutedColor),
      // Label — muted agar tidak terlalu mencolok
      labelLarge: labelLarge.copyWith(color: textColor),
      labelMedium: labelMedium.copyWith(color: mutedColor),
      labelSmall: labelSmall.copyWith(color: mutedColor),
    );
  }

  // ===========================================================================
  // Helper lama (dipertahankan untuk backward compatibility).
  // ===========================================================================

  static TextStyle displayLargeOnSurface(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return displayLarge.copyWith(
      color: isDark ? darkTextColor : lightTextColor,
    );
  }

  static TextStyle headlineMediumOnSurface(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return headlineMedium.copyWith(
      color: isDark ? darkTextColor : lightTextColor,
    );
  }

  static TextStyle titleLargeOnSurface(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return titleLarge.copyWith(
      color: isDark ? darkTextColor : lightTextColor,
    );
  }

  static TextStyle bodyLargeOnSurface(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return bodyLarge.copyWith(
      color: isDark ? darkTextColor : lightTextColor,
    );
  }

  static TextStyle bodyMediumOnSurface(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return bodyMedium.copyWith(
      color: isDark ? darkTextColor : lightTextColor,
    );
  }

  static TextStyle labelLargeOnSurface(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return labelLarge.copyWith(
      color: isDark ? darkTextColor : lightTextColor,
    );
  }

  // Error / success text styles (warna tetap sama untuk kedua mode)
  static TextStyle bodyMediumError(BuildContext context) {
    return bodyMedium.copyWith(color: AppColors.error);
  }

  static TextStyle labelMediumError(BuildContext context) {
    return labelMedium.copyWith(color: AppColors.error);
  }

  static TextStyle bodyMediumSuccess(BuildContext context) {
    return bodyMedium.copyWith(color: AppColors.success);
  }

  static TextStyle labelMediumSuccess(BuildContext context) {
    return labelMedium.copyWith(color: AppColors.success);
  }
}