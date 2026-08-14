import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'token_store.dart';

/// Service untuk upload & delete gambar langsung ke img.sagansa.id.
///
/// Menggunakan Sanctum token yang sama dengan api service (img service membaca
/// tabel personal_access_tokens di sagansa_user). Mobile upload file langsung
/// ke img service, dapat relative path string, lalu kirim path ke api service
/// sebagai form field biasa.
class ImageUploadService {
  static const String _baseUrl = String.fromEnvironment(
    'IMG_SERVICE_URL',
    defaultValue: 'https://img.sagansa.id',
  );

  /// Batas waktu menunggu response dari img service. Sebelumnya tidak ada
  /// timeout, sehingga koneksi macet menggantung spinner submit tanpa batas.
  static const Duration _timeout = Duration(seconds: 30);

  /// Ambil Sanctum token dari secure storage (TokenStore). Sebelumnya membaca
  /// dari SharedPreferences, namun token sudah dimigrasi ke secure storage —
  /// SharedPreferences kini sudah tidak menyimpan token.
  static Future<String?> _getToken() async {
    return TokenStore.instance.readToken();
  }

  /// Upload file ke img service.
  ///
  /// [directory] menentukan subfolder penyimpanan (mis. "images/FuelService").
  /// Return relative path (mis. "images/FuelService/uuid.webp").
  ///
  /// Melempar [Exception] bila gagal — pesannya memuat HTTP status code dan
  /// cuplikan body server agar mudah didiagnosis (sebelumnya error ditelan
  /// jadi `return null` sehingga pemanggil hanya bisa menampilkan pesan generik).
  static Future<String?> upload(File imageFile,
      {String directory = ''}) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Token tidak ditemukan, silakan login ulang.');
    }

    final uri = Uri.parse('$_baseUrl/api/upload');
    final request = http.MultipartRequest('POST', uri);

    request.headers.addAll({
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });

    if (directory.isNotEmpty) {
      request.fields['directory'] = directory;
    }

    request.files.add(
      await http.MultipartFile.fromPath('image', imageFile.path),
    );

    return _sendAndParse(request);
  }

  /// Upload bytes ke img service (untuk web/kIsWeb).
  ///
  /// [filename] nama file dengan extension.
  /// Return relative path atau melempar [Exception] bila gagal.
  static Future<String?> uploadBytes(
    Uint8List bytes,
    String filename, {
    String directory = '',
  }) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Token tidak ditemukan, silakan login ulang.');
    }

    final uri = Uri.parse('$_baseUrl/api/upload');
    final request = http.MultipartRequest('POST', uri);

    request.headers.addAll({
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });

    if (directory.isNotEmpty) {
      request.fields['directory'] = directory;
    }

    request.files.add(
      http.MultipartFile.fromBytes('image', bytes, filename: filename),
    );

    return _sendAndParse(request);
  }

  /// Kirim [request], validasi response, lalu ekstrak relative path "path".
  ///
  /// Dipecah ke method bersama karena logika ini sama untuk [upload] (File)
  /// maupun [uploadBytes] (web).
  static Future<String?> _sendAndParse(http.MultipartRequest request) async {
    try {
      final streamedResponse = await request.send().timeout(_timeout);
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final match =
            RegExp(r'"path"\s*:\s*"([^"]+)"').firstMatch(response.body);
        if (match != null) {
          return match.group(1);
        }
        // 2xx tapi payload tidak memuat "path" — respon server tidak sesuai
        // kontrak (mis. halaman HTML dari proxy/CDN dengan status 200).
        throw Exception(
            'Respon img service tidak valid (path tidak ditemukan).');
      }

      throw Exception(_failureMessage(response.statusCode, response.body));
    } on TimeoutException {
      throw Exception(
          'Upload timeout: img service tidak merespons dalam ${_timeout.inSeconds} detik.');
    } on Exception {
      rethrow;
    } catch (e) {
      // Error jaringan lain (SocketException, TLS failure, dll).
      throw Exception('Gagal terhubung ke img service: $e');
    }
  }

  /// Susun pesan kegagalan yang informatif: HTTP status + cuplikan body.
  static String _failureMessage(int statusCode, String body) {
    final trimmed = body.trim();
    final short = trimmed.length > 150
        ? '${trimmed.substring(0, 150)}…'
        : trimmed;
    return short.isEmpty
        ? 'Upload gagal ($statusCode).'
        : 'Upload gagal ($statusCode): $short';
  }

  /// Hapus gambar by path dari img service.
  ///
  /// Return true bila berhasil.
  static Future<bool> delete(String path) async {
    final token = await _getToken();
    if (token == null) return false;

    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/api/images'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: '{"path": "$path"}',
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('ImageUploadService: delete exception: $e');
      return false;
    }
  }
}
