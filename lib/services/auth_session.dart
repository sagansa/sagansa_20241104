import 'package:flutter/material.dart';

import 'auth_service.dart';

/// Orchestrator auto-logout saat response 401 dari backend.
///
/// Dipanggil ApiClient. Idempotent dalam window logout: bila beberapa
/// request concurrent dapat 401 bersamaan, hanya SATU proses logout yang
/// berjalan; sisanya no-op. Setelah navigasi selesai, flag di-reset agar
/// sesi berikutnya (setelah user login ulang) bisa trigger lagi.
///
/// `ApiClient` (service layer) tidak boleh pegang BuildContext — class ini
/// jembatan antara HTTP layer dan Navigator via [GlobalKey] yang di-inject
/// dari `MyApp.initState`.
class AuthSession {
  AuthSession._();
  static final AuthSession instance = AuthSession._();

  GlobalKey<NavigatorState>? _navigatorKey;
  bool _loggingOut = false;

  /// Kill switch untuk test. Set false untuk disable auto-logout.
  bool enabled = true;

  /// Di-set dari MyApp.initState. Dipakai untuk navigasi tanpa BuildContext.
  void configure(GlobalKey<NavigatorState> key) => _navigatorKey = key;

  /// Dipanggil ApiClient ketika response.statusCode == 401.
  /// Tidak throws — failure di-silent agar tidak mengganggu caller.
  Future<void> handleUnauthorized() async {
    if (!enabled || _loggingOut) return;
    _loggingOut = true;

    try {
      // Bersihkan token, data user, FCM/periodic task. AuthService.logout
      // sudah swallow error internal (backend call gagal tetap lanjut clear
      // storage). Timeout 5s mencegah hang kalau backend benar-benar down.
      await AuthService().logout().timeout(const Duration(seconds: 5));
    } catch (_) {
      // Best-effort cleanup; navigasi tetap dijalankan.
    }

    _navigateToLogin();
  }

  void _navigateToLogin() {
    final nav = _navigatorKey?.currentState;
    if (nav == null) {
      // Navigator belum ready (mis. masih di splash / belum configure).
      // Reset flag; ApiClient tetap throw 401 ke caller — main() route gate
      // akan arahkan ke /login karena token sudah dihapus.
      _loggingOut = false;
      return;
    }

    nav.pushNamedAndRemoveUntil('/login', (route) => false);

    // Tampilkan pesan user-friendly via overlay context (best-effort; tidak
    // fatal kalau overlay null).
    final ctx = nav.overlay?.context;
    if (ctx != null) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(
          content: Text('Sesi Anda telah berakhir, silakan login kembali.'),
          duration: Duration(seconds: 4),
        ),
      );
    }

    _loggingOut = false;
  }
}
