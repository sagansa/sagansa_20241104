import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/asset_check_model.dart';
import '../utils/constants.dart';
import 'image_upload_service.dart';

/// Service untuk submit & melihat riwayat pemeriksaan aset.
class AssetCheckService {
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.tokenKey);
  }

  Map<String, String> _authHeaders(String? token) => {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      };

  Future<List<AssetCheckModel>> getChecks({
    int? assetId,
    int? storeId,
    String? from,
    String? to,
    int? severity,
  }) async {
    final token = await _getToken();
    if (token == null) throw Exception('Tidak ada token autentikasi.');

    final query = <String, String>{};
    if (assetId != null) query['asset_id'] = assetId.toString();
    if (storeId != null) query['store_id'] = storeId.toString();
    if (from != null) query['from'] = from;
    if (to != null) query['to'] = to;
    if (severity != null) query['severity'] = severity.toString();

    final uri =
        Uri.parse(ApiConstants.assetChecks).replace(queryParameters: query);
    final response = await http.get(uri, headers: _authHeaders(token));

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      if (json['success'] == true) {
        final List data = json['data'] ?? [];
        return data
            .map((e) => AssetCheckModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      throw Exception(json['message'] ?? 'Gagal memuat riwayat pemeriksaan.');
    }
    throw Exception(
        'Gagal memuat riwayat pemeriksaan: ${response.statusCode}');
  }

  Future<AssetCheckModel> getCheck(int id) async {
    final token = await _getToken();
    if (token == null) throw Exception('Tidak ada token autentikasi.');

    final response = await http.get(
      Uri.parse('${ApiConstants.assetChecks}/$id'),
      headers: _authHeaders(token),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      if (json['success'] == true) {
        return AssetCheckModel.fromJson(json['data']);
      }
      throw Exception(json['message'] ?? 'Data tidak ditemukan.');
    }
    throw Exception('Gagal memuat detail pemeriksaan: ${response.statusCode}');
  }

  /// Submit pemeriksaan aset. Mengirim multipart: field + checklist (JSON
  /// string) + banyak file foto + lat/lng.
  Future<Map<String, dynamic>> submitCheck({
    required int assetId,
    required String checkDate,
    required int conditionBefore,
    required int conditionAfter,
    required int severity,
    required double latitude,
    required double longitude,
    String? notes,
    List<File> photos = const [],
    List<Map<String, dynamic>> checklist = const [],
  }) async {
    final token = await _getToken();
    if (token == null) throw Exception('Tidak ada token autentikasi.');

    final request = http.MultipartRequest(
      'POST',
      Uri.parse(ApiConstants.assetChecks),
    );
    request.headers.addAll({
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });

    request.fields['asset_id'] = assetId.toString();
    request.fields['check_date'] = checkDate;
    request.fields['condition_before'] = conditionBefore.toString();
    request.fields['condition_after'] = conditionAfter.toString();
    request.fields['severity'] = severity.toString();
    request.fields['latitude'] = latitude.toString();
    request.fields['longitude'] = longitude.toString();
    if (notes != null && notes.isNotEmpty) request.fields['notes'] = notes;
    if (checklist.isNotEmpty) {
      request.fields['checklist'] = jsonEncode(checklist);
    }
    for (int i = 0; i < photos.length; i++) {
      final path = await ImageUploadService.upload(photos[i], directory: 'images/AssetCheck');
      if (path == null) throw Exception('Gagal upload gambar ke img service.');
      request.fields['photos[$i]'] = path;
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    final json = jsonDecode(response.body);

    if ((response.statusCode == 200 || response.statusCode == 201) &&
        json['success'] == true) {
      return json['data'] as Map<String, dynamic>;
    }
    throw Exception(json['message'] ?? 'Gagal menyimpan pemeriksaan.');
  }

  /// Cek apakah aset sudah diperiksa hari ini.
  Future<bool> hasCheckedToday(int assetId) async {
    final token = await _getToken();
    if (token == null) return false;

    try {
      final response = await http.get(
        Uri.parse(
            '${ApiConstants.assetChecks}/today-status/$assetId'),
        headers: _authHeaders(token),
      );
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return json['data']?['has_checked'] == true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
