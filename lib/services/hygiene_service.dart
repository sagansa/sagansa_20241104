import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';
import '../models/hygiene_model.dart';
import 'image_upload_service.dart';

class HygieneService {
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.tokenKey);
  }

  Map<String, String> _authHeaders(String token) {
    return {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<List<RoomModel>> getRooms() async {
    final token = await _getToken();
    if (token == null) throw Exception('Tidak ada token autentikasi.');

    final response = await http.get(
      Uri.parse(ApiConstants.hygieneRooms),
      headers: _authHeaders(token),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final data = json['data'] as List<dynamic>? ?? [];
      return data.map((e) => RoomModel.fromJson(e)).toList();
    }
    throw Exception('Gagal memuat daftar ruangan.');
  }

  Future<bool> checkTodayStatus({int? storeId}) async {
    final token = await _getToken();
    if (token == null) throw Exception('Tidak ada token autentikasi.');

    final query = storeId != null ? '?store_id=$storeId' : '';
    final response = await http.get(
      Uri.parse('${ApiConstants.hygieneTodayStatus}$query'),
      headers: _authHeaders(token),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return json['data']?['has_submitted_today'] ?? false;
    }
    throw Exception('Gagal mengecek status hari ini.');
  }

  Future<HygieneModel> submitHygiene({
    required int storeId,
    required List<Map<String, dynamic>> rooms,
  }) async {
    final token = await _getToken();
    if (token == null) throw Exception('Tidak ada token autentikasi.');

    var request = http.MultipartRequest('POST', Uri.parse(ApiConstants.hygiene));
    request.headers.addAll({
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    });

    request.fields['store_id'] = storeId.toString();

    for (int i = 0; i < rooms.length; i++) {
      final room = rooms[i];
      request.fields['rooms[$i][room_id]'] = room['room_id'].toString();

      if (room['condition'] != null) {
        request.fields['rooms[$i][condition]'] = room['condition'].toString();
      }
      if (room['notes'] != null) {
        request.fields['rooms[$i][notes]'] = room['notes'] as String;
      }
      if (room['image_path'] != null) {
        final path = await ImageUploadService.upload(
          File(room['image_path'] as String),
          directory: 'images/Hygiene',
        );
        if (path == null) throw Exception('Gagal upload gambar ke img service.');
        request.fields['rooms[$i][image]'] = path;
      }
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 201) {
      final json = jsonDecode(response.body);
      return HygieneModel.fromJson(json['data']);
    }
    final errorData = jsonDecode(response.body);
    throw Exception(errorData['message'] ?? 'Gagal mengirim laporan kebersihan.');
  }

  Future<List<HygieneModel>> getHistory() async {
    final token = await _getToken();
    if (token == null) throw Exception('Tidak ada token autentikasi.');

    final response = await http.get(
      Uri.parse(ApiConstants.hygiene),
      headers: _authHeaders(token),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final data = json['data'] as List<dynamic>? ?? [];
      return data.map((e) => HygieneModel.fromJson(e)).toList();
    }
    throw Exception('Gagal memuat riwayat kebersihan.');
  }

  Future<HygieneModel> getDetail(int id) async {
    final token = await _getToken();
    if (token == null) throw Exception('Tidak ada token autentikasi.');

    final response = await http.get(
      Uri.parse('${ApiConstants.hygiene}/$id'),
      headers: _authHeaders(token),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return HygieneModel.fromJson(json['data']);
    }
    throw Exception('Gagal memuat detail kebersihan.');
  }

  /// Nilai laporan kebersihan utuh. [status] 2 = setuju, 3 = tolak.
  Future<HygieneModel> updateStatus(int id, int status) async {
    final token = await _getToken();
    if (token == null) throw Exception('Tidak ada token autentikasi.');

    final response = await http.patch(
      Uri.parse('${ApiConstants.hygiene}/$id'),
      headers: _authHeaders(token),
      body: jsonEncode({'status': status}),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return HygieneModel.fromJson(json['data']);
    }
    final errorData = jsonDecode(response.body);
    throw Exception(errorData['message'] ?? 'Gagal menilai laporan kebersihan.');
  }

  /// Nilai kondisi satu ruangan (satu gambar) pada laporan kebersihan.
  /// [condition] 1 = bersih, 2 = perlu perhatian, 3 = kotor.
  Future<HygieneRoomModel> updateRoomStatus(int roomId, int condition) async {
    final token = await _getToken();
    if (token == null) throw Exception('Tidak ada token autentikasi.');

    final response = await http.patch(
      Uri.parse('${ApiConstants.hygieneRoomUpdate}/$roomId'),
      headers: {
        ..._authHeaders(token),
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'condition': condition}),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return HygieneRoomModel.fromJson(json['data']);
    }
    final errorData = jsonDecode(response.body);
    throw Exception(errorData['message'] ?? 'Gagal menilai ruangan.');
  }
}
