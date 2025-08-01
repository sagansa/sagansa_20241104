import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/constants.dart';

/// Simplified AuthService for testing auto-login without server validation
class AuthServiceSimple {
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
        print('AuthServiceSimple: Token saved successfully');

        // Store user data securely
        final userData = responseData['data']['user'];
        await _secureStorage.write(
            key: userDataKey, value: json.encode(userData));
        print('AuthServiceSimple: User data saved: ${userData['name']}');

        return responseData;
      } else {
        return {
          'status': 'error',
          'message': responseData['message'] ?? 'Login gagal'
        };
      }
    } catch (e) {
      print('AuthServiceSimple: Login error: $e');
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
      print('AuthServiceSimple: Logout completed, data cleared');
    } catch (e) {
      // Even if API call fails, clear local storage
      await _secureStorage.delete(key: tokenKey);
      await _secureStorage.delete(key: userDataKey);
      print('AuthServiceSimple: Logout error, but data cleared: $e');
      throw Exception('Gagal melakukan logout');
    }
  }

  /// Get stored token from secure storage
  Future<String?> getToken() async {
    try {
      final token = await _secureStorage.read(key: tokenKey);
      print(
          'AuthServiceSimple: Retrieved token: ${token != null ? 'exists (${token.length} chars)' : 'null'}');
      return token;
    } catch (e) {
      print('AuthServiceSimple: Error reading token: $e');
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
            'AuthServiceSimple: Retrieved user data: ${userData['name'] ?? 'unknown'}');
        return userData;
      }
      print('AuthServiceSimple: No user data found');
      return null;
    } catch (e) {
      print('AuthServiceSimple: Error reading user data: $e');
      return null;
    }
  }

  /// Simple check if user has stored credentials (no server validation)
  Future<bool> hasStoredCredentials() async {
    final token = await getToken();
    final userData = await getUserData();
    final hasCredentials = token != null && userData != null;
    print('AuthServiceSimple: Has stored credentials: $hasCredentials');
    return hasCredentials;
  }

  /// Clear all authentication data
  Future<void> clearAuthData() async {
    await _secureStorage.delete(key: tokenKey);
    await _secureStorage.delete(key: userDataKey);
    print('AuthServiceSimple: Auth data cleared');
  }
}
