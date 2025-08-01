import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

class CredentialManager {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  static const String _credentialsKey = 'saved_credentials';
  static const String _autofillEnabledKey = 'autofill_enabled';

  /// Save user credentials for autofill
  static Future<void> saveCredentials({
    required String email,
    required String password,
  }) async {
    try {
      final credentials = {
        'email': email,
        'password': password,
        'savedAt': DateTime.now().toIso8601String(),
      };

      await _storage.write(
        key: _credentialsKey,
        value: jsonEncode(credentials),
      );

      // Enable autofill by default when credentials are saved
      await setAutofillEnabled(true);
    } catch (e) {
      throw Exception('Failed to save credentials: $e');
    }
  }

  /// Retrieve saved credentials
  static Future<Map<String, String>?> getSavedCredentials() async {
    try {
      final credentialsJson = await _storage.read(key: _credentialsKey);
      if (credentialsJson == null) return null;

      final credentials = jsonDecode(credentialsJson) as Map<String, dynamic>;
      return {
        'email': credentials['email'] as String,
        'password': credentials['password'] as String,
      };
    } catch (e) {
      // If there's an error reading credentials, return null
      return null;
    }
  }

  /// Check if credentials are saved
  static Future<bool> hasCredentials() async {
    try {
      final credentials = await getSavedCredentials();
      return credentials != null;
    } catch (e) {
      return false;
    }
  }

  /// Delete saved credentials
  static Future<void> deleteCredentials() async {
    try {
      await _storage.delete(key: _credentialsKey);
      await setAutofillEnabled(false);
    } catch (e) {
      throw Exception('Failed to delete credentials: $e');
    }
  }

  /// Set autofill preference
  static Future<void> setAutofillEnabled(bool enabled) async {
    try {
      await _storage.write(
        key: _autofillEnabledKey,
        value: enabled.toString(),
      );
    } catch (e) {
      throw Exception('Failed to set autofill preference: $e');
    }
  }

  /// Check if autofill is enabled
  static Future<bool> isAutofillEnabled() async {
    try {
      final enabled = await _storage.read(key: _autofillEnabledKey);
      return enabled == 'true';
    } catch (e) {
      return false;
    }
  }

  /// Clear all stored data
  static Future<void> clearAll() async {
    try {
      await _storage.deleteAll();
    } catch (e) {
      throw Exception('Failed to clear all data: $e');
    }
  }

  /// Get credential age in days
  static Future<int?> getCredentialAge() async {
    try {
      final credentialsJson = await _storage.read(key: _credentialsKey);
      if (credentialsJson == null) return null;

      final credentials = jsonDecode(credentialsJson) as Map<String, dynamic>;
      final savedAt = DateTime.parse(credentials['savedAt'] as String);
      final now = DateTime.now();

      return now.difference(savedAt).inDays;
    } catch (e) {
      return null;
    }
  }
}
