// lib/utils/auth_manager.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthManager {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';
  static const String _userTypeKey = 'user_type';
  static const String _userNameKey = 'user_name';
  
  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }
  
  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }
  
  Future<void> saveUserId(int userId) async {
    await _storage.write(key: _userIdKey, value: userId.toString());
  }
  
  Future<int?> getUserId() async {
    final userId = await _storage.read(key: _userIdKey);
    return userId != null ? int.tryParse(userId) : null;
  }
  
  Future<void> saveUserType(String userType) async {
    await _storage.write(key: _userTypeKey, value: userType);
  }
  
  Future<String?> getUserType() async {
    return await _storage.read(key: _userTypeKey);
  }
  
  Future<void> saveUserName(String userName) async {
    await _storage.write(key: _userNameKey, value: userName);
  }
  
  Future<String?> getUserName() async {
    return await _storage.read(key: _userNameKey);
  }
  
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
  
  Future<void> clear() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userIdKey);
    await _storage.delete(key: _userTypeKey);
    await _storage.delete(key: _userNameKey);
  }
}