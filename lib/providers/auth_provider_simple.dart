import 'package:flutter/material.dart';
import '../services/auth_service_simple.dart';

enum AuthState { idle, loading, success, error, checking }

/// Simplified AuthProvider for testing auto-login without server validation
class AuthProviderSimple with ChangeNotifier {
  String _token = '';
  Map<String, dynamic>? _userData;
  AuthState _authState = AuthState.checking;
  String _errorMessage = '';
  bool _isLoading = false;
  bool _hasInitialized = false;

  final AuthServiceSimple _authService = AuthServiceSimple();

  // Getters
  String get token => _token;
  Map<String, dynamic>? get userData => _userData;
  AuthState get authState => _authState;
  String get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isAuthenticated =>
      _token.isNotEmpty && _authState == AuthState.success;
  bool get hasInitialized => _hasInitialized;

  AuthProviderSimple() {
    _initializeAuth();
  }

  /// Initialize authentication on app startup with simple auto-login
  Future<void> _initializeAuth() async {
    print('AuthProviderSimple: Starting initialization...');
    _authState = AuthState.checking;
    notifyListeners();

    try {
      // Check if we have stored credentials
      final hasCredentials = await _authService.hasStoredCredentials();

      if (hasCredentials) {
        // Load stored credentials
        final token = await _authService.getToken();
        final userData = await _authService.getUserData();

        if (token != null && userData != null) {
          _token = token;
          _userData = userData;
          _authState = AuthState.success;
          print('AuthProviderSimple: Auto-login successful');
        } else {
          _authState = AuthState.idle;
          print('AuthProviderSimple: Failed to load credentials');
        }
      } else {
        _authState = AuthState.idle;
        print('AuthProviderSimple: No stored credentials');
      }
    } catch (e) {
      print('AuthProviderSimple: Error during initialization: $e');
      _authState = AuthState.error;
      _errorMessage = 'Failed to initialize authentication';
    }

    _hasInitialized = true;
    print(
        'AuthProviderSimple: Initialization complete. State: $_authState, Authenticated: $isAuthenticated');
    notifyListeners();
  }

  /// Login user with email and password
  Future<bool> login(String email, String password) async {
    print('AuthProviderSimple: Starting login...');
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
        print('AuthProviderSimple: Login failed: $_errorMessage');
        return false;
      }

      // Success - update state with new data
      _token = result['data']['access_token'];
      _userData = result['data']['user'];
      _authState = AuthState.success;
      _setLoading(false);
      notifyListeners();
      print('AuthProviderSimple: Login successful');
      return true;
    } catch (e) {
      _authState = AuthState.error;
      _errorMessage = 'Terjadi kesalahan saat login';
      _setLoading(false);
      notifyListeners();
      print('AuthProviderSimple: Login error: $e');
      return false;
    }
  }

  /// Logout user and clean up all authentication data
  Future<bool> logout() async {
    print('AuthProviderSimple: Starting logout...');
    _setLoading(true);
    notifyListeners();

    try {
      // Call logout service to clean up both server and local storage
      await _authService.logout();

      // Clear local state
      _token = '';
      _userData = null;
      _authState = AuthState.idle;
      _errorMessage = '';

      _setLoading(false);
      notifyListeners();
      print('AuthProviderSimple: Logout successful');
      return true;
    } catch (e) {
      // Even if logout fails, clear local state
      _token = '';
      _userData = null;
      _authState = AuthState.idle;
      _errorMessage = 'Gagal melakukan logout';
      _setLoading(false);
      notifyListeners();
      print('AuthProviderSimple: Logout error: $e');
      return false;
    }
  }

  /// Force re-initialization (useful for testing)
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
