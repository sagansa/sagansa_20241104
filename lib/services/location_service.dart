import 'dart:developer' as developer;

import 'api_client.dart';

/// Service untuk mengirim titik lokasi pegawai & mengelola FCM device token
/// ke backend. Dipakai oleh:
///  - workmanager (periodic ~2 jam, source: 'periodic')
///  - FCM background handler (on-demand, source: 'on_demand', bawa request_id)
class LocationService {
  final ApiClient _api = ApiClient();

  /// Mengunggah satu titik lokasi ke server.
  ///
  /// [source] = 'periodic' (background 2 jam) atau 'on_demand' (FCM trigger).
  /// [requestId] wajib diisi untuk 'on_demand' agar server bisa mencocokkan
  /// ke permintaan admin.
  Future<bool> sendLocation({
    required double latitude,
    required double longitude,
    required String source,
    double? accuracy,
    String? requestId,
    DateTime? capturedAt,
  }) async {
    try {
      await _api
          .post(
            'location',
            body: {
              'latitude': latitude,
              'longitude': longitude,
              'source': source,
              if (accuracy != null) 'accuracy': accuracy,
              if (requestId != null) 'request_id': requestId,
              if (capturedAt != null)
                'captured_at': capturedAt.toIso8601String(),
            },
          )
          .timeout(const Duration(seconds: 30));
      return true;
    } catch (e) {
      developer.log('sendLocation error: $e', name: 'LocationService');
      return false;
    }
  }

  /// Mendaftarkan FCM token milik device ini agar admin bisa memicu permintaan
  /// lokasi on-demand. Dipanggil setelah login & setiap kali token berubah.
  Future<bool> registerDeviceToken(
    String fcmToken, {
    String? deviceId,
  }) async {
    try {
      await _api.post('device-tokens', body: {
        'token': fcmToken,
        if (deviceId != null) 'device_id': deviceId,
      });
      return true;
    } catch (e) {
      developer.log('registerDeviceToken error: $e',
          name: 'LocationService');
      return false;
    }
  }

  /// Menghapus FCM token milik device ini saat logout.
  Future<void> deregisterDeviceToken(String fcmToken) async {
    try {
      await _api.delete('device-tokens');
    } catch (e) {
      developer.log('deregisterDeviceToken error: $e',
          name: 'LocationService');
    }
  }
}
