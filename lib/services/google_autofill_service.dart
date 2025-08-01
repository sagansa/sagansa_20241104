import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'credential_manager.dart';

class GoogleAutofillService {
  static const String _emailAutofillHint = 'email';
  static const String _passwordAutofillHint = 'password';

  /// Get autofill hints for email field
  static List<String> get emailAutofillHints => [
        AutofillHints.email,
        AutofillHints.username,
        _emailAutofillHint,
      ];

  /// Get autofill hints for password field
  static List<String> get passwordAutofillHints => [
        AutofillHints.password,
        _passwordAutofillHint,
      ];

  /// Request to save credentials to password manager
  static Future<void> requestSaveCredentials({
    required String email,
    required String password,
  }) async {
    try {
      // Save to our secure storage
      await CredentialManager.saveCredentials(
        email: email,
        password: password,
      );

      // Request system to save credentials
      // This will trigger the system's password manager save dialog
      TextInput.finishAutofillContext(shouldSave: true);
    } catch (e) {
      throw Exception('Failed to request save credentials: $e');
    }
  }

  /// Cancel autofill context without saving
  static Future<void> cancelAutofillContext() async {
    try {
      TextInput.finishAutofillContext(shouldSave: false);
    } catch (e) {
      // Ignore errors when canceling autofill context
    }
  }

  /// Check if autofill is supported on the current platform
  static bool get isAutofillSupported {
    // Autofill is supported on Android API 26+ and iOS 12+
    // Flutter handles the platform checks internally
    return true;
  }

  /// Get saved credentials for autofill
  static Future<Map<String, String>?> getAutofillCredentials() async {
    try {
      final isEnabled = await CredentialManager.isAutofillEnabled();
      if (!isEnabled) return null;

      return await CredentialManager.getSavedCredentials();
    } catch (e) {
      return null;
    }
  }

  /// Pre-fill text controllers with saved credentials
  static Future<void> prefillCredentials({
    required TextEditingController emailController,
    required TextEditingController passwordController,
  }) async {
    try {
      final credentials = await getAutofillCredentials();
      if (credentials != null) {
        emailController.text = credentials['email'] ?? '';
        passwordController.text = credentials['password'] ?? '';
      }
    } catch (e) {
      // Ignore errors when prefilling credentials
    }
  }

  /// Show save credentials dialog
  static Future<bool> showSaveCredentialsDialog({
    required BuildContext context,
    required String email,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Simpan Kredensial'),
              content: Text(
                'Apakah Anda ingin menyimpan kredensial login untuk $email? '
                'Ini akan memungkinkan login otomatis di masa mendatang.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Tidak'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  /// Handle successful login with credential saving option
  static Future<void> handleSuccessfulLogin({
    required BuildContext context,
    required String email,
    required String password,
    bool showSaveDialog = true,
  }) async {
    try {
      final hasCredentials = await CredentialManager.hasCredentials();

      if (!hasCredentials && showSaveDialog) {
        final shouldSave = await showSaveCredentialsDialog(
          context: context,
          email: email,
        );

        if (shouldSave) {
          await requestSaveCredentials(
            email: email,
            password: password,
          );
        } else {
          cancelAutofillContext();
        }
      } else if (hasCredentials) {
        // Update existing credentials
        await CredentialManager.saveCredentials(
          email: email,
          password: password,
        );
        TextInput.finishAutofillContext(shouldSave: true);
      }
    } catch (e) {
      // Don't throw errors for credential saving failures
      // as they shouldn't block the login process
      cancelAutofillContext();
    }
  }

  /// Handle logout with credential cleanup option
  static Future<void> handleLogout({
    bool clearCredentials = false,
  }) async {
    try {
      if (clearCredentials) {
        await CredentialManager.deleteCredentials();
      }
      cancelAutofillContext();
    } catch (e) {
      // Ignore errors during logout cleanup
    }
  }
}
