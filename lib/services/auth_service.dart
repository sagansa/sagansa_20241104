import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/constants.dart';
import 'api_client.dart';
import 'location_tracking_service.dart';

class AuthService {
  static const List<String> allowedRoles = ['admin', 'staff', 'supervisor', 'storage-staff'];

  final ApiClient _api = ApiClient();

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final userData = await _api.post('login', body: {
        'email': email,
        'password': password,
      });

      final userRoles = List<String>.from(userData['user']['roles']);

      final hasAllowedRole =
          userRoles.any((role) => allowedRoles.contains(role));

      if (hasAllowedRole) {
        await _saveUserData(userData);
        LocationTrackingService.instance.onLogin();
        return {'success': true, 'message': 'Login successful'};
      } else {
        return {
          'success': false,
          'message': 'Anda tidak memiliki akses ke aplikasi ini'
        };
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<void> _saveUserData(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();

    // Simpan token
    final token = data['access_token'];
    if (token != null) {
      await prefs.setString('token', token.toString());
      await prefs.setString('token_type', data['token_type'] ?? 'Bearer');
      debugPrint('Token tersimpan: $token');
    }

    // Simpan data user
    final user = data['user'];
    if (user != null) {
      await prefs.setString('user', json.encode(user));
      debugPrint('User data tersimpan: ${json.encode(user)}');
    } else {
      debugPrint('Data user tidak ditemukan dalam response');
    }

    // Simpan full login data untuk HomeController
    await prefs.setString(
      AppConstants.loginDataKey,
      json.encode({
        'success': true,
        'data': data,
      }),
    );
  }

  Future<bool> hasRole(String roleToCheck) async {
    final prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString('user');

    if (userString != null) {
      final userData = json.decode(userString);
      final userRoles = List<String>.from(userData['roles']);
      return userRoles.contains(roleToCheck);
    }

    return false;
  }

  Future<bool> hasAnyAllowedRole() async {
    final prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString('user');

    if (userString != null) {
      final userData = json.decode(userString);
      final userRoles = List<String>.from(userData['roles']);
      return userRoles.any((role) => allowedRoles.contains(role));
    }

    return false;
  }

  Future<void> logout() async {
    // Hentikan pelacakan & hapus FCM token device sebelum sesi dibersihkan.
    await LocationTrackingService.instance.onLogout();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('token_type');
    await prefs.remove('user');
    await prefs.remove(AppConstants.loginDataKey);
  }
}
