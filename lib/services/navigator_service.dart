// ====================================================================
// Navigator global — agar service layer bisa navigasi tanpa BuildContext
// (deep-link saat notifikasi di-tap, auto-logout, dll).
// ====================================================================

import 'package:flutter/material.dart';

/// Key global NavigatorState yang di-inject ke MaterialApp.navigatorKey dari
/// main.dart. Service layer (notification router, AuthSession) menggunakannya
/// untuk push route tanpa BuildContext.
class NavigatorService {
  NavigatorService._();

  /// Satu-satunya instance key, diakses statis dari mana saja.
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
}
