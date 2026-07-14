import 'package:flutter/material.dart';

/// Elegant Midnight & Gold color palette
///
/// Palet hitam obsidian & emas metallic yang sophisticated.
/// Gold primary `#D4AF37` dipilih karena terbaca mewah di dark mode
/// namun tetap memiliki kontras yang baik di light mode. Teks pakai
/// cream (`#F5F0E1`) alih-alih pure white agar lebih nyaman di mata
/// dan terkesan premium.
class AppColors {
  // Primary Colors - Metallic Gold
  static const Color primary = Color(0xFFB8973E); // rich gold (light mode readable)
  static const Color primaryContainer = Color(0xFFF5EBC8); // warm cream-gold
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFF2A2208);

  // Secondary Colors - Warm Bronze
  static const Color secondary = Color(0xFF8C7B4A);
  static const Color secondaryContainer = Color(0xFFE8DFC4);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color onSecondaryContainer = Color(0xFF2C2410);

  // Surface Colors - Clean Warm White / Obsidian
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF7F4EC); // warm off-white
  static const Color onSurface = Color(0xFF1A1A1A);
  static const Color onSurfaceVariant = Color(0xFF5C5648); // warm gray

  // Background Colors - Warm Off-White
  static const Color background = Color(0xFFFAFAF7);
  static const Color onBackground = Color(0xFF1A1A1A);

  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color successContainer = Color(0xFFE8F5E8);
  static const Color onSuccess = Color(0xFFFFFFFF);
  static const Color onSuccessContainer = Color(0xFF1B5E20);

  static const Color warning = Color(0xFFFF9800);
  static const Color warningContainer = Color(0xFFFFF3E0);
  static const Color onWarning = Color(0xFFFFFFFF);
  static const Color onWarningContainer = Color(0xFFE65100);

  static const Color error = Color(0xFFB71C1C); // dark red
  static const Color errorContainer = Color(0xFF93000A);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color onErrorContainer = Color(0xFFFFDAD6);

  static const Color info = Color(0xFF6BA3C9); // muted blue
  static const Color infoContainer = Color(0xFFE3F2FD);
  static const Color onInfo = Color(0xFFFFFFFF);
  static const Color onInfoContainer = Color(0xFF0D47A1);

  // Neutral Colors
  static const Color outline = Color(0xFF8B8472); // warm outline
  static const Color outlineVariant = Color(0xFFD4CFC0);
  static const Color shadow = Color(0xFF000000);
  static const Color scrim = Color(0xFF000000);
  static const Color inverseSurface = Color(0xFFF0EBDC);
  static const Color inverseOnSurface = Color(0xFF2A2520);
  static const Color inversePrimary = Color(0xFFD4AF37);

  // Dark Theme Colors - Obsidian & Gold (Utama)
  //
  // Catatan refactor: surface sedikit diterangkan dari #161616 -> #1C1C1E
  // dan text dibuat putih-cream terang agar kontras optimal di dark mode.
  // Ubah nilai di blok ini untuk menyesuaikan keseluruhan dark palette.
  static const Color darkPrimary = Color(0xFFD4AF37); // metallic gold classic
  static const Color darkPrimaryContainer = Color(0xFF3D3220); // warm brown-gold
  static const Color darkOnPrimary = Color(0xFF0A0A0A); // near-black on gold
  static const Color darkOnPrimaryContainer = Color(0xFFF5EBC8); // cream on container

  static const Color darkSecondary = Color(0xFFC9B68A);
  static const Color darkSecondaryContainer = Color(0xFF2C2410);
  static const Color darkOnSecondary = Color(0xFF0A0A0A);
  static const Color darkOnSecondaryContainer = Color(0xFFE8DFC4);

  // Surface diterangkan sedikit agar konten terasa "nyala" di atas obsidian.
  static const Color darkSurface = Color(0xFF1C1C1E); // lifted charcoal
  static const Color darkSurfaceVariant = Color(0xFF2A2A2D); // input/chip bg
  // Text utama: putih-cream terang. Ubah alpha di app_typography.dart
  // (darkTextColor) bila ingin lebih terang/redup.
  static const Color darkOnSurface = Color(0xFFF5F0E1); // warm cream (elegant)
  static const Color darkOnSurfaceVariant = Color(0xFFB8B0A0); // lifted warm gray

  static const Color darkBackground = Color(0xFF0A0A0A); // obsidian
  static const Color darkOnBackground = Color(0xFFF5F0E1);

  // Gradient Colors - Gold & Charcoal Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFD4AF37), Color(0xFFB8973E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [Color(0xFF8C7B4A), Color(0xFF6B5E3A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [success, Color(0xFF388E3C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Elegant dark card gradient with subtle gold tint
  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF161616), Color(0xFF0F0F0F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Opacity variants
  static Color primaryWithOpacity(double opacity) =>
      primary.withValues(alpha: opacity);
  static Color secondaryWithOpacity(double opacity) =>
      secondary.withValues(alpha: opacity);
  static Color surfaceWithOpacity(double opacity) =>
      surface.withValues(alpha: opacity);
  static Color onSurfaceWithOpacity(double opacity) =>
      onSurface.withValues(alpha: opacity);

  // Dark gold accent helper (for legacy widgets still referencing AppTheme)
  static const Color goldAccent = darkPrimary;
}