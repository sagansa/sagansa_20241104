import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';
import '../services/google_autofill_service.dart';
import '../utils/constants.dart';

enum AuthState { idle, loading, success, error, checking }

class AuthProvider with ChangeNotifier {
  String _token = '';
  Map<String, dynamic>? _userData;
  AuthState _authState = AuthState.checking;
  String _errorMessage = '';
  bool _isLoading = false;
  bool _hasInitialized = false;

  final AuthService _authService = AuthService();

  // Set to false to disable token validation for testing
  static const bool enableTokenValidation = true;

  // Getters
  String get token => _token;
  Map<String, dynamic>? get userData => _userData;
  AuthState get authState => _authState;
  String get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isAuthenticated =>
      _token.isNotEmpty && _authState == AuthState.success;
  bool get hasInitialized => _hasInitialized;

  AuthProvider() {
    _initializeAuth();
  }

  /// Initialize authentication on app startup with auto-login
  Future<void> _initializeAuth() async {
    print('AuthProvider: Starting initialization...');
    _authState = AuthState.checking;
    notifyListeners();

    try {
      // Try to load stored token and user data
      final token = await _authService.getToken();
      final userData = await _authService.getUserData();

      print('AuthProvider: Token exists: ${token != null}');
      print('AuthProvider: UserData exists: ${userData != null}');

      if (token != null && userData != null) {
        // Auto-login with stored credentials
        _token = token;
        _userData = userData;
        _authState = AuthState.success;
        print('AuthProvider: Auto-login successful');

        // Validate token in background (don't block auto-login)
        if (enableTokenValidation) {
          _validateTokenInBackground();
        } else {
          print('AuthProvider: Token validation disabled for testing');
        }
      } else {
        // No stored credentials
        _token = '';
        _userData = null;
        _authState = AuthState.idle;
        print('AuthProvider: No stored credentials found');
      }
    } catch (e) {
      print('AuthProvider: Error during initialization: $e');
      // Error during initialization - still try to use stored data if available
      final token = await _authService.getToken();
      final userData = await _authService.getUserData();

      if (token != null && userData != null) {
        _token = token;
        _userData = userData;
        _authState = AuthState.success;
        print('AuthProvider: Fallback auto-login successful');
      } else {
        _token = '';
        _userData = null;
        _authState = AuthState.idle;
        print('AuthProvider: Fallback - no credentials');
      }
    }

    _hasInitialized = true;
    print('AuthProvider: Initialization complete. State: $_authState');
    notifyListeners();
  }

  /// Validate token in background without blocking auto-login
  Future<void> _validateTokenInBackground() async {
    print('AuthProvider: Starting background token validation...');
    try {
      final isValid = await _authService.validateToken();
      print('AuthProvider: Token validation result: $isValid');

      if (!isValid) {
        // Only clear auth if we get a definitive invalid response (401)
        // Don't clear on network errors
        final token = await _authService.getToken();
        if (token != null) {
          try {
            final response = await http.get(
              Uri.parse(ApiConstants.userPresence),
              headers: ApiConstants.headers(token),
            );

            print(
                'AuthProvider: Validation response status: ${response.statusCode}');

            if (response.statusCode == 401) {
              // Token definitely invalid, clear auth
              print('AuthProvider: Token invalid (401), clearing auth data');
              await _authService.clearAuthData();
              _token = '';
              _userData = null;
              _authState = AuthState.idle;
              notifyListeners();
            } else {
              print(
                  'AuthProvider: Token validation inconclusive, keeping user logged in');
            }
          } catch (e) {
            print(
                'AuthProvider: Network error during validation, keeping user logged in: $e');
          }
        }
      } else {
        print('AuthProvider: Token is valid');
      }
    } catch (e) {
      print(
          'AuthProvider: Background validation error, keeping user logged in: $e');
    }
  }

  /// Login user with email and password
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _authState = AuthState.loading;
    _errorMessage = '';
    notifyListeners();

    try {
      final result = await _authService.login(email, password);

      if (result['status'] == 'error') {
        _authState = AuthState.error;
        _errorMessage = result['message'] ?? 'Login failed';
        _setLoading(false);
        notifyListeners();
        return false;
      }

      // Success - update state with new data
      _token = result['data']['access_token'];
      _userData = result['data']['user'];
      _authState = AuthState.success;
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _authState = AuthState.error;
      _errorMessage = 'Terjadi kesalahan saat login';
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  /// Logout user and clean up all authentication data
  Future<bool> logout({bool clearCredentials = false}) async {
    _setLoading(true);
    notifyListeners();

    try {
      // Call logout service to clean up both server and local storage
      await _authService.logout();

      // Handle autofill cleanup
      await GoogleAutofillService.handleLogout(
        clearCredentials: clearCredentials,
      );

      // Clear local state
      _token = '';
      _userData = null;
      _authState = AuthState.idle;
      _errorMessage = '';

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      // Even if logout fails, clear local state
      _token = '';
      _userData = null;
      _authState = AuthState.idle;
      _errorMessage = 'Gagal melakukan logout';

      // Still try to cleanup autofill
      try {
        await GoogleAutofillService.handleLogout(
          clearCredentials: clearCredentials,
        );
      } catch (autofillError) {
        // Ignore autofill cleanup errors
      }

      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  /// Validate current token with server
  Future<bool> validateCurrentToken() async {
    if (_token.isEmpty) return false;

    try {
      final isValid = await _authService.validateToken();

      if (!isValid) {
        // Token invalid, clear authentication
        await _authService.clearAuthData();
        _token = '';
        _userData = null;
        _authState = AuthState.idle;
        notifyListeners();
      }

      return isValid;
    } catch (e) {
      return false;
    }
  }

  /// Refresh authentication state (re-validate token)
  Future<void> refreshAuth() async {
    _setLoading(true);
    notifyListeners();

    try {
      final isValid = await validateCurrentToken();

      if (!isValid) {
        _authState = AuthState.idle;
        _errorMessage = 'Session expired. Please login again.';
      }
    } catch (e) {
      _authState = AuthState.error;
      _errorMessage = 'Failed to refresh authentication';
    }

    _setLoading(false);
    notifyListeners();
  }

  /// Force re-initialization (useful for testing or error recovery)
  Future<void> reinitialize() async {
    _hasInitialized = false;
    await _initializeAuth();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
  }

  void clearError() {
    _errorMessage = '';
    if (_authState == AuthState.error) {
      _authState = AuthState.idle;
    }
    notifyListeners();
  }
}
