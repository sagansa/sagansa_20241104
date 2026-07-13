import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

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

    request.files.add(await http.MultipartFile.fromPath('image_selfie', selfiePath));
    request.files.add(await http.MultipartFile.fromPath('left_hand', leftHandPath));
    request.files.add(await http.MultipartFile.fromPath('right_hand', rightHandPath));

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
