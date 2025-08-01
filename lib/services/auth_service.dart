import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/constants.dart';

class AuthService {
  static const String tokenKey = 'auth_token';
  static const String userDataKey = 'user_data';

  // Configure secure storage with encryption
  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  /// Login user and store persistent token securely
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

        // Store user data securely
        final userData = responseData['data']['user'];
        await _secureStorage.write(
            key: userDataKey, value: json.encode(userData));

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
      debugPrint('AuthService: Unexpected error: $e');
      return {'status': 'error', 'message': 'Terjadi kesalahan tidak terduga'};
    }
  }

  /// Logout user and clean up tokens from both server and local storage
  Future<void> logout() async {
    try {
      final token = await getToken();

      // Call logout API to invalidate token on server
      if (token != null) {
        await http.post(
          Uri.parse(ApiConstants.logout),
          headers: ApiConstants.headers(token),
        );
      }

      // Clear all stored authentication data
      await _secureStorage.delete(key: tokenKey);
      await _secureStorage.delete(key: userDataKey);
    } catch (e) {
      // Even if API call fails, clear local storage
      await _secureStorage.delete(key: tokenKey);
      await _secureStorage.delete(key: userDataKey);
      throw Exception('Gagal melakukan logout');
    }
  }

  /// Get stored token from secure storage
  Future<String?> getToken() async {
    try {
      final token = await _secureStorage.read(key: tokenKey);
      print(
          'AuthService: Retrieved token: ${token != null ? 'exists' : 'null'}');
      return token;
    } catch (e) {
      print('AuthService: Error reading token: $e');
      return null;
    }
  }

  /// Get stored user data from secure storage
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      final userDataString = await _secureStorage.read(key: userDataKey);
      if (userDataString != null) {
        final userData = json.decode(userDataString);
        print(
            'AuthService: Retrieved user data: ${userData['name'] ?? 'unknown'}');
        return userData;
      }
      print('AuthService: No user data found');
      return null;
    } catch (e) {
      print('AuthService: Error reading user data: $e');
      return null;
    }
  }

  /// Validate token with server using user-presence endpoint
  Future<bool> validateToken() async {
    try {
      final token = await getToken();
      if (token == null) return false;

      // Use existing user-presence endpoint to validate token
      final response = await http.get(
        Uri.parse(ApiConstants.userPresence),
        headers: ApiConstants.headers(token),
      );

      // Return true for success, false only for 401 (unauthorized)
      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 401) {
        return false;
      } else {
        // For other errors (network, server error), assume token is still valid
        return true;
      }
    } catch (e) {
      // Network error or other exception - assume token is still valid
      return true;
    }
  }

  /// Check if user has valid authentication
  Future<bool> isAuthenticated() async {
    final token = await getToken();
    if (token == null) return false;

    // Validate token with server
    return await validateToken();
  }

  /// Clear all authentication data (for emergency cleanup)
  Future<void> clearAuthData() async {
    await _secureStorage.delete(key: tokenKey);
    await _secureStorage.delete(key: userDataKey);
  }
}
