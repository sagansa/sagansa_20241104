import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';
import '../models/readiness_model.dart';
import 'image_upload_service.dart';

class ReadinessService {
  static const String _baseUrl = '${ApiConstants.baseUrl}/readiness';

  Future<Map<String, dynamic>> checkStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.tokenKey) ?? '';

    final response = await http.get(
      Uri.parse('$_baseUrl/status'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Gagal mengecek status kesiapan: ${response.statusCode}');
    }
  }

  Future<List<ReadinessModel>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.tokenKey) ?? '';

    final response = await http.get(
      Uri.parse('$_baseUrl/history'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      final data = body['data'] as List<dynamic>? ?? [];
      return data.map((item) => ReadinessModel.fromJson(item)).toList();
    } else {
      throw Exception('Gagal memuat riwayat kesiapan: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> submitReadiness({
    required String selfiePath,
    required String leftHandPath,
    required String rightHandPath,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.tokenKey) ?? '';

    var request = http.MultipartRequest('POST', Uri.parse(_baseUrl));
    request.headers.addAll({
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    });

    final uploadedSelfie =
        await ImageUploadService.upload(File(selfiePath), directory: 'images/Readiness');
    if (uploadedSelfie == null) throw Exception('Gagal upload selfie.');
    final uploadedLeft =
        await ImageUploadService.upload(File(leftHandPath), directory: 'images/Readiness');
    if (uploadedLeft == null) throw Exception('Gagal upload left hand.');
    final uploadedRight =
        await ImageUploadService.upload(File(rightHandPath), directory: 'images/Readiness');
    if (uploadedRight == null) throw Exception('Gagal upload right hand.');

    request.fields['image_selfie'] = uploadedSelfie;
    request.fields['left_hand'] = uploadedLeft;
    request.fields['right_hand'] = uploadedRight;

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['message'] ?? 'Gagal mengirim form kesiapan');
    }
  }
}
