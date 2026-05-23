import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  Map<String, dynamic>? _user;
  String? _userType;  // Tambahkan variabel _userType
  bool _isLoading = false;
  bool _isAuthenticated = false;
  String? _error;

  Map<String, dynamic>? get user => _user;
  String? get userType => _userType;  // Tambahkan getter userType
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  String? get error => _error;

  AuthProvider() {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();

    _isAuthenticated = await AuthService.isLoggedIn();
    if (_isAuthenticated) {
      _user = await AuthService.getCurrentUser();
      _userType = _user?['user_type'];  // Set _userType dari user data
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await AuthService.login(username, password);

    if (result['success'] == true) {
      _user = result['user'];
      _userType = _user?['user_type'];  // Set _userType dari data login
      _isAuthenticated = true;
      _isLoading = false;
      notifyListeners();
      return true;
    } else {
      _error = result['message'];
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    await AuthService.logout();
    
    _user = null;
    _userType = null;  // Reset _userType
    _isAuthenticated = false;
    _isLoading = false;
    notifyListeners();
  }

  // Method untuk refresh user data
  Future<void> refreshUser() async {
    if (_isAuthenticated) {
      _user = await AuthService.getCurrentUser();
      _userType = _user?['user_type'];
      notifyListeners();
    }
  }
}