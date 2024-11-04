import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class AuthService {
  static const String tokenKey = 'token';

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.login),
        headers: ApiConstants.headers(null),
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      print('Raw API response: ${response.body}'); // Debug log
      final responseData = json.decode(response.body);
      print('Decoded response: $responseData'); // Debug log

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();

        // Simpan token
        await prefs.setString('token', responseData['data']['access_token']);

        // Simpan data user
        final userData = responseData['data']['user'];
        await prefs.setString('user', json.encode(userData));

        print('User data saved: $userData'); // Debug log

        return responseData; // Kembalikan response asli dari API
      } else {
        print('Login failed with status: ${response.statusCode}');
        return {
          'status': 'error',
          'message': responseData['message'] ?? 'Login gagal'
        };
      }
    } catch (e) {
      print('Login error: $e');
      return {'status': 'error', 'message': 'Terjadi kesalahan saat login'};
    }
  }

  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(tokenKey);

      await http.post(
        Uri.parse(ApiConstants.logout),
        headers: ApiConstants.headers(token),
      );

      await prefs.remove(tokenKey);
    } catch (e) {
      print('Error during logout: $e');
      throw Exception('Gagal melakukan logout');
    }
  }
}
