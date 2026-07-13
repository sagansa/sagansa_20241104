import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';
import 'dart:developer' as developer;

/// Service untuk mengirim titik lokasi pegawai & mengelola FCM device token
/// ke backend. Dipakai oleh:
///  - workmanager (periodic ~2 jam, source: 'periodic')
///  - FCM background handler (on-demand, source: 'on_demand', bawa request_id)
class LocationService {
  static const String tokenKey = 'token';
  static const String tokenTypeKey = 'token_type';

  /// Mengambil Bearer token dari SharedPreferences. Mengembalikan null bila
  /// pegawai belum login (di background isolate, SharedPreferences tetap bisa
  /// dibaca karena tersimpan di disk).
  static Future<String?> _getBearerToken() async {
    final prefs = await SharedPreferences.getInstance();
    final tokenType = prefs.getString(tokenTypeKey) ?? 'Bearer';
    final accessToken = prefs.getString(tokenKey);
    if (accessToken == null) return null;
    return '$tokenType $accessToken';
  }

  /// Mengunggah satu titik lokasi ke server.
  ///
  /// [source] = 'periodic' (background 2 jam) atau 'on_demand' (FCM trigger).
  /// [requestId] wajib diisi untuk 'on_demand' agar server bisa mencocokkan
  /// ke permintaan admin.
  static Future<bool> sendLocation({
    required double latitude,
    required double longitude,
    required String source,
    double? accuracy,
    String? requestId,
    DateTime? capturedAt,
  }) async {
    final token = await _getBearerToken();
    if (token == null) {
      developer.log('sendLocation: belum login, batal.',
          name: 'LocationService');
      return false;
    }

    try {
      final response = await http
          .post(
            Uri.parse(ApiConstants.locationPing),
            headers: ApiConstants.headers(token),
            body: json.encode({
              'latitude': latitude,
              'longitude': longitude,
              'source': source,
              if (accuracy != null) 'accuracy': accuracy,
              if (requestId != null) 'request_id': requestId,
              if (capturedAt != null)
                'captured_at': capturedAt.toIso8601String(),
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return true;
      }
      developer.log(
        'sendLocation gagal: ${response.statusCode} ${response.body}',
        name: 'LocationService');
      return false;
    } catch (e) {
      developer.log('sendLocation error: $e', name: 'LocationService');
      return false;
    }
  }

  /// Mendaftarkan FCM token milik device ini agar admin bisa memicu permintaan
  /// lokasi on-demand. Dipanggil setelah login & setiap kali token berubah.
  static Future<bool> registerDeviceToken(
    String fcmToken, {
    String? deviceId,
  }) async {
    final token = await _getBearerToken();
    if (token == null) return false;

    try {
      final response = await http.post(
        Uri.parse(ApiConstants.deviceTokens),
        headers: ApiConstants.headers(token),
        body: json.encode({
          'token': fcmToken,
          if (deviceId != null) 'device_id': deviceId,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      developer.log('registerDeviceToken error: $e',
          name: 'LocationService');
      return false;
    }
  }

  /// Menghapus FCM token milik device ini saat logout.
  static Future<void> deregisterDeviceToken(String fcmToken) async {
    final token = await _getBearerToken();
    if (token == null) return;

    try {
      final request = http.Request(
          'DELETE', Uri.parse(ApiConstants.deviceTokens))
        ..headers.addAll(ApiConstants.headers(token))
        ..body = json.encode({'token': fcmToken});

      await request.send().timeout(const Duration(seconds: 15));
    } catch (e) {
      developer.log('deregisterDeviceToken error: $e',
          name: 'LocationService');
    }
  }
}
