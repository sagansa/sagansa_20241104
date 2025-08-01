import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/auth_service.dart';

enum AuthState { idle, loading, success, error }

class AuthProvider with ChangeNotifier {
  String _token = '';
  Map<String, dynamic>? _userData;
  AuthState _authState = AuthState.idle;
  String _errorMessage = '';
  bool _isLoading = false;

  final AuthService _authService = AuthService();

  // Getters
  String get token => _token;
  Map<String, dynamic>? get userData => _userData;
  AuthState get authState => _authState;
  String get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _token.isNotEmpty;

  AuthProvider() {
    print('AuthProvider constructor called');
    _loadToken();
  }

  Future<void> _loadToken() async {
    try {
      print('Loading token...');
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('token') ?? '';
      print('Token loaded: ${_token.isNotEmpty ? 'exists' : 'empty'}');

      // Load user data if token exists
      if (_token.isNotEmpty) {
        final userDataString = prefs.getString('user');
        if (userDataString != null) {
          try {
            _userData = json.decode(userDataString);
            print('User data loaded successfully');
          } catch (e) {
            print('Error parsing user data: $e');
            _userData = null;
          }
        }
      }

      _authState = AuthState.idle;
      notifyListeners();
      print('Token loading completed');
    } catch (e) {
      print('Error loading token: $e');
      _token = '';
      _userData = null;
      _authState = AuthState.error;
      _errorMessage = 'Failed to load authentication data';
      notifyListeners();
    }
  }

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

      // Success
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

  Future<bool> logout() async {
    _setLoading(true);
    notifyListeners();

    try {
      await _authService.logout();
      _token = '';
      _userData = null;
      _authState = AuthState.idle;
      _errorMessage = '';

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
      await prefs.remove('user');

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Gagal melakukan logout';
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  Future<void> refreshAuth() async {
    _setLoading(true);
    notifyListeners();

    // Simulate refresh - in real app, you'd call an API to refresh token
    await Future.delayed(const Duration(seconds: 1));

    _setLoading(false);
    notifyListeners();
  }

  Future<void> updateToken(String newToken) async {
    _token = newToken;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', newToken);
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
  }

  void clearError() {
    _errorMessage = '';
    _authState = AuthState.idle;
    notifyListeners();
  }
}
