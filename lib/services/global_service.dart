import '../models/presence_today_model.dart';
import '../utils/constants.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class GlobalService {
  final String? token;

  GlobalService({this.token});

  Future<PresenceTodayModel> getPresenceToday() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/presence/today'),
        headers: ApiConstants.headers(token),
      );

      if (response.statusCode == AppConstants.statusSuccess) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        return PresenceTodayModel.fromJson(jsonResponse);
      } else {
        throw Exception('Gagal mengambil status presensi');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}
