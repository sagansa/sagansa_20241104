import 'package:http/http.dart' as http;
import 'dart:convert';
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
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.login),
        headers: ApiConstants.headers(null),
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        // Store token securely
        final token = responseData['data']['access_token'];
        await _secureStorage.write(key: tokenKey, value: token);

        // Store user data securely
        final userData = responseData['data']['user'];
        await _secureStorage.write(
            key: userDataKey, value: json.encode(userData));

        return responseData;
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
