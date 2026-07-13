import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

class NetworkService {
  static const Duration _lookupTimeout = Duration(seconds: 5);
  static const Duration _httpTimeout = Duration(seconds: 10);

  /// Check if device has internet connectivity.
  ///
  /// Melakukan beberapa lookup DNS secara paralel (menggunakan [Future.any])
  /// dan mengembalikan `true` begitu salah satu berhasil, sehingga lebih cepat
  /// daripada menunggu setiap lookup satu per satu.
  static Future<bool> hasInternetConnection() async {
    try {
      // Untuk IP address gunakan InternetAddress() (reverse DNS via lookup
      // untuk IP seringkali gagal/bukan yang kita maksud).
      final lookups = <Future<dynamic>>[
        InternetAddress.lookup('google.com').timeout(_lookupTimeout),
        InternetAddress.lookup('cloudflare.com').timeout(_lookupTimeout),
        InternetAddress('8.8.8.8').reverse().timeout(_lookupTimeout),
      ];

      // Race semua lookup; kembalikan true begitu satu pun sukses.
      await Future.any(
        lookups.map((lookup) async {
          final result = await lookup;
          if (result is List<InternetAddress>) {
            if (result.isNotEmpty && result.first.rawAddress.isNotEmpty) {
              return true;
            }
            throw Exception('empty result');
          }
          // InternetAddress (dari reverse())
          return true;
        }),
      );
      debugPrint('NetworkService: Internet connection confirmed');
      return true;
    } on TimeoutException {
      debugPrint('NetworkService: All DNS lookups timed out');
      return false;
    } catch (e) {
      debugPrint('NetworkService: Error checking internet: $e');
      return false;
    }
  }

  /// Check if API server is reachable.
  ///
  /// Mencoba HEAD request ke endpoint `/login`. Setiap response (selain
  /// server error 5xx) dianggap menandakan server dapat dijangkau.
  static Future<bool> isApiServerReachable() async {
    try {
      final response = await http
          .head(
            Uri.parse('${ApiConstants.baseUrl}/login'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(_httpTimeout);

      return response.statusCode < 500;
    } catch (e) {
      debugPrint('NetworkService: API server not reachable via domain: $e');

      // Coba dengan fallback URL (mis. IP address) sebagai cadangan.
      if (ApiConstants.fallbackBaseUrl == ApiConstants.baseUrl) {
        // Tidak ada fallback berbeda yang dikonfigurasi; hindari retry duplikat.
        return false;
      }

      try {
        final response = await http
            .head(
              Uri.parse('${ApiConstants.fallbackBaseUrl}/login'),
              headers: {
                'Accept': 'application/json',
                // Pertahankan host asli agar virtual host di sisi server tetap
                // dapat merouting request dengan benar.
                'Host': Uri.parse(ApiConstants.baseUrl).host,
              },
            )
            .timeout(_httpTimeout);

        return response.statusCode < 500;
      } catch (fallbackError) {
        debugPrint(
            'NetworkService: API server not reachable via fallback: $fallbackError');
        return false;
      }
    }
  }

  /// Get network status with detailed information.
  static Future<NetworkStatus> getNetworkStatus() async {
    debugPrint('NetworkService: Starting network status check...');

    final hasInternet = await hasInternetConnection();
    debugPrint('NetworkService: Internet check result: $hasInternet');

    if (!hasInternet) {
      return NetworkStatus(
        isConnected: false,
        canReachApi: false,
        message: 'Tidak ada koneksi internet',
      );
    }

    final canReachApi = await isApiServerReachable();
    debugPrint('NetworkService: API server check result: $canReachApi');

    if (!canReachApi) {
      return NetworkStatus(
        isConnected: true,
        canReachApi: false,
        message: 'Server API tidak dapat dijangkau',
      );
    }

    return NetworkStatus(
      isConnected: true,
      canReachApi: true,
      message: 'Koneksi normal',
    );
  }

  /// Try to resolve DNS for API domain.
  static Future<String?> resolveApiDomain() async {
    try {
      final result =
          await InternetAddress.lookup('api.sagansa.id').timeout(_lookupTimeout);
      if (result.isNotEmpty) {
        return result.first.address;
      }
      return null;
    } catch (e) {
      debugPrint('NetworkService: DNS resolution failed: $e');
      return null;
    }
  }
}

class NetworkStatus {
  final bool isConnected;
  final bool canReachApi;
  final String message;

  NetworkStatus({
    required this.isConnected,
    required this.canReachApi,
    required this.message,
  });

  bool get isFullyConnected => isConnected && canReachApi;
}