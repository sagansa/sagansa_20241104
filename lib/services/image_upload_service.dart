import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

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

  /// Ambil Sanctum token dari SharedPreferences.
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.tokenKey);
  }

  /// Upload file ke img service.
  ///
  /// [directory] menentukan subfolder penyimpanan (mis. "images/FuelService").
  /// Return relative path (mis. "images/FuelService/uuid.webp") atau null bila gagal.
  static Future<String?> upload(File imageFile, {String directory = ''}) async {
    final token = await _getToken();
    if (token == null) {
      debugPrint('ImageUploadService: no token, cannot upload');
      return null;
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

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final match = RegExp(r'"path"\s*:\s*"([^"]+)"').firstMatch(response.body);
        if (match != null) {
          return match.group(1);
        }
      }
      debugPrint('ImageUploadService: upload failed ${response.statusCode}: ${response.body}');
    } catch (e) {
      debugPrint('ImageUploadService: upload exception: $e');
    }
    return null;
  }

  /// Upload bytes ke img service (untuk web/kIsWeb).
  ///
  /// [filename] nama file dengan extension.
  /// Return relative path atau null bila gagal.
  static Future<String?> uploadBytes(
    Uint8List bytes,
    String filename, {
    String directory = '',
  }) async {
    final token = await _getToken();
    if (token == null) {
      debugPrint('ImageUploadService: no token, cannot upload');
      return null;
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

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final match = RegExp(r'"path"\s*:\s*"([^"]+)"').firstMatch(response.body);
        if (match != null) {
          return match.group(1);
        }
      }
      debugPrint('ImageUploadService: uploadBytes failed ${response.statusCode}');
    } catch (e) {
      debugPrint('ImageUploadService: uploadBytes exception: $e');
    }
    return null;
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
