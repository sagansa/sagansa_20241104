import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class AuthService {
  static const String tokenKey = 'token';
  static const String userKey = 'user';

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http
          .post(
            Uri.parse(ApiConstants.login),
            headers: ApiConstants.headers(null),
            body: json.encode({
              'email': email,
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 30));

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        if (responseData['data'] != null) {
          final token = responseData['data']['access_token'];
          final userData = responseData['data']['user'];

          if (token != null && userData != null) {
            await _storeAuthData(token, userData);

            return {
              'status': 'success',
              'data': responseData['data'],
              'message': 'Login berhasil'
            };
          }
        }

        return {'status': 'error', 'message': 'Data login tidak valid'};
      } else {
        return {
          'status': 'error',
          'message': responseData['message'] ?? 'Login gagal'
        };
      }
    } catch (e) {
      return {'status': 'error', 'message': 'Terjadi kesalahan saat login'};
    }
  }

  Future<void> _storeAuthData(
      String token, Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(tokenKey, token);
    await prefs.setString(userKey, json.encode(userData));
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(tokenKey);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(tokenKey);
    await prefs.remove(userKey);
  }
}
