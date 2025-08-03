import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
<<<<<<< HEAD
import 'dart:async';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
=======
import 'package:shared_preferences/shared_preferences.dart';
>>>>>>> parent of f54562b (update token, password remember, logo)
import '../utils/constants.dart';

class AuthService {
  static const String tokenKey = 'token';
  static const String _tokenKey = 'authToken';

  Future<Map<String, dynamic>> login(String email, String password) async {
    debugPrint('AuthService: Starting login process');

    // Skip network check completely - just try login directly
    return await _attemptLoginWithFallback(email, password);
  }

  /// Attempt login with fallback mechanism
  Future<Map<String, dynamic>> _attemptLoginWithFallback(
      String email, String password) async {
    // Try primary URL first
    try {
      debugPrint('AuthService: Attempting login to ${ApiConstants.login}');

<<<<<<< HEAD
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
=======
      print('Raw API response: ${response.body}'); // Debug log
      final responseData = json.decode(response.body);
      print('Decoded response: $responseData'); // Debug log
>>>>>>> parent of f54562b (update token, password remember, logo)

      debugPrint('AuthService: Response status: ${response.statusCode}');
      if (ApiConstants.enableDetailedLogging) {
        debugPrint('AuthService: Response body: ${response.body}');
      }

      return await _processLoginResponse(response);
    } on SocketException catch (e) {
      debugPrint('AuthService: Socket error with primary URL: $e');
      return await _attemptLoginWithIP(email, password);
    } on TimeoutException catch (e) {
      debugPrint('AuthService: Timeout with primary URL: $e');
      return await _attemptLoginWithIP(email, password);
    } catch (e) {
      debugPrint('AuthService: Error with primary URL: $e');
      return await _attemptLoginWithIP(email, password);
    }
  }

  /// Attempt login using IP address as fallback
  Future<Map<String, dynamic>> _attemptLoginWithIP(
      String email, String password) async {
    try {
      debugPrint('AuthService: Attempting login with fallback IP');

      final response = await http
          .post(
            Uri.parse('${ApiConstants.fallbackBaseUrl}/login'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Host': 'api.sagansa.id', // Important: keep original host header
            },
            body: json.encode({
              'email': email,
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 30));

      debugPrint(
          'AuthService: Fallback response status: ${response.statusCode}');

      return await _processLoginResponse(response);
    } catch (e) {
      debugPrint('AuthService: Fallback also failed: $e');
      return {
        'status': 'error',
        'message':
            'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.'
      };
    }
  }

  /// Process login response
  Future<Map<String, dynamic>> _processLoginResponse(
      http.Response response) async {
    try {
      if (response.statusCode == 200) {
<<<<<<< HEAD
        final responseData = json.decode(response.body);

        // Validate response structure
        if (responseData['data'] == null ||
            responseData['data']['access_token'] == null ||
            responseData['data']['user'] == null) {
          return {'status': 'error', 'message': 'Format response tidak valid'};
        }

        // Store token securely
        final token = responseData['data']['access_token'];
        await _secureStorage.write(key: tokenKey, value: token);
=======
        final prefs = await SharedPreferences.getInstance();
>>>>>>> parent of f54562b (update token, password remember, logo)

        // Simpan token
        await prefs.setString('token', responseData['data']['access_token']);

        // Simpan data user
        final userData = responseData['data']['user'];
        await prefs.setString('user', json.encode(userData));

<<<<<<< HEAD
        debugPrint('AuthService: Login successful, token stored');
        return responseData;
      } else {
        // Try to parse error message from response
        try {
          final responseData = json.decode(response.body);
          final errorMessage = responseData['message'] ?? 'Login gagal';

          if (response.statusCode == 401) {
            return {'status': 'error', 'message': 'Email atau password salah'};
          } else if (response.statusCode == 422) {
            return {
              'status': 'error',
              'message': 'Data yang dimasukkan tidak valid'
            };
          } else {
            return {'status': 'error', 'message': errorMessage};
          }
        } catch (e) {
          return {
            'status': 'error',
            'message': 'Server error (${response.statusCode})'
          };
        }
=======
        print('User data saved: $userData'); // Debug log

        return responseData; // Kembalikan response asli dari API
      } else {
        print('Login failed with status: ${response.statusCode}');
        return {
          'status': 'error',
          'message': responseData['message'] ?? 'Login gagal'
        };
>>>>>>> parent of f54562b (update token, password remember, logo)
      }
    } on http.ClientException catch (e) {
      debugPrint('AuthService: Network error: $e');
      return {
        'status': 'error',
        'message':
            'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.'
      };
    } on FormatException catch (e) {
      debugPrint('AuthService: JSON parsing error: $e');
      return {'status': 'error', 'message': 'Response server tidak valid'};
    } catch (e) {
<<<<<<< HEAD
      debugPrint('AuthService: Unexpected error: $e');
      return {'status': 'error', 'message': 'Terjadi kesalahan tidak terduga'};
=======
      print('Login error: $e');
      return {'status': 'error', 'message': 'Terjadi kesalahan saat login'};
>>>>>>> parent of f54562b (update token, password remember, logo)
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

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }
}
