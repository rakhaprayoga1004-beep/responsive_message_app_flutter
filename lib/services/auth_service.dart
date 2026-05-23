// lib/services/auth_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../utils/environment.dart';

class AuthService {
  static String get baseUrl => Environment.baseUrl;
  
  // SharedPreferences Keys
  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';
  static const String _userNameKey = 'user_name';
  static const String _namaLengkapKey = 'nama_lengkap';
  static const String _userTypeKey = 'user_type';
  static const String _userEmailKey = 'user_email';
  static const String _userPhoneKey = 'user_phone';
  static const String _userAvatarKey = 'user_avatar';
  static const String _privilegeLevelKey = 'privilege_level';
  static const String _isLoggedInKey = 'is_logged_in';

  // ============================================================
  // LOGIN API CALL - MENGGUNAKAN ENVIRONMENT.BASE_URL
  // ============================================================
  
  static Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final url = Uri.parse('$baseUrl/api/login_flutter.php');
      print('📍 AuthService Login URL: $url');
      print('📍 Base URL from Environment: $baseUrl');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'username': username,
          'password': password,
        },
      ).timeout(const Duration(seconds: 30));
      
      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['user'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_tokenKey, data['user']['token']);
          await prefs.setInt(_userIdKey, data['user']['id']);
          await prefs.setString(_userNameKey, data['user']['username']);
          await prefs.setString(_namaLengkapKey, data['user']['nama_lengkap'] ?? data['user']['username']);
          await prefs.setString(_userTypeKey, data['user']['user_type']);
          await prefs.setString(_userEmailKey, data['user']['email'] ?? '');
          await prefs.setString(_userPhoneKey, data['user']['phone_number'] ?? '');
          await prefs.setString(_userAvatarKey, data['user']['avatar'] ?? 'default-avatar.png');
          await prefs.setString(_privilegeLevelKey, data['user']['privilege_level'] ?? 'Limited_Lv3');
          await prefs.setBool(_isLoggedInKey, true);
          
          print('✅ Login success - User: ${data['user']['username']}, Type: ${data['user']['user_type']}');
          return {'success': true, 'user': data['user']};
        } else {
          return {'success': false, 'message': data['message'] ?? 'Login gagal'};
        }
      } else {
        return {'success': false, 'message': 'Server error: ${response.statusCode}'};
      }
    } catch (e) {
      print('❌ Login error: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }
  
  // ============================================================
  // TOKEN MANAGEMENT
  // ============================================================
  
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }
  
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    print('✅ Token saved');
  }
  
  // ============================================================
  // USER DATA MANAGEMENT
  // ============================================================
  
  static Future<void> saveUserData(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setString(_tokenKey, user['token']?.toString() ?? '');
    await prefs.setInt(_userIdKey, user['id'] ?? 0);
    await prefs.setString(_userNameKey, user['username']?.toString() ?? '');
    await prefs.setString(_namaLengkapKey, user['nama_lengkap']?.toString() ?? '');
    await prefs.setString(_userTypeKey, user['user_type']?.toString() ?? '');
    await prefs.setString(_userEmailKey, user['email']?.toString() ?? '');
    await prefs.setString(_userPhoneKey, user['phone_number']?.toString() ?? '');
    await prefs.setString(_userAvatarKey, user['avatar']?.toString() ?? 'default-avatar.png');
    await prefs.setString(_privilegeLevelKey, user['privilege_level']?.toString() ?? 'Limited_Lv3');
    await prefs.setBool(_isLoggedInKey, true);
    
    print('✅ User data saved successfully');
    print('   - User Type: ${user['user_type']}');
    print('   - User ID: ${user['id']}');
  }
  
  // ============================================================
  // GET CURRENT USER
  // ============================================================
  
  static Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_isLoggedInKey) ?? false) {
        return {
          'id': prefs.getInt(_userIdKey),
          'username': prefs.getString(_userNameKey),
          'nama_lengkap': prefs.getString(_namaLengkapKey),
          'user_type': prefs.getString(_userTypeKey),
          'email': prefs.getString(_userEmailKey),
          'phone_number': prefs.getString(_userPhoneKey),
          'avatar': prefs.getString(_userAvatarKey),
          'privilege_level': prefs.getString(_privilegeLevelKey),
          'token': prefs.getString(_tokenKey),
        };
      }
      return null;
    } catch (e) {
      print('❌ Error getting current user: $e');
      return null;
    }
  }
  
  // ============================================================
  // GET USER INFO
  // ============================================================
  
  static Future<String?> getUserType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userTypeKey);
  }
  
  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userNameKey);
  }
  
  static Future<String?> getFullName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_namaLengkapKey);
  }
  
  static Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_userIdKey);
  }
  
  static Future<String> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userEmailKey) ?? '';
  }
  
  static Future<String> getUserPhone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userPhoneKey) ?? '';
  }
  
  static Future<String> getUserAvatar() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userAvatarKey) ?? 'default-avatar.png';
  }
  
  static Future<String> getPrivilegeLevel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_privilegeLevelKey) ?? 'Limited_Lv3';
  }
  
  // ============================================================
  // AUTHENTICATION STATUS
  // ============================================================
  
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool(_isLoggedInKey) ?? false;
    final token = prefs.getString(_tokenKey);
    return isLoggedIn && token != null && token.isNotEmpty;
  }
  
  // ============================================================
  // LOGOUT
  // ============================================================
  
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_userNameKey);
    await prefs.remove(_namaLengkapKey);
    await prefs.remove(_userTypeKey);
    await prefs.remove(_userEmailKey);
    await prefs.remove(_userPhoneKey);
    await prefs.remove(_userAvatarKey);
    await prefs.remove(_privilegeLevelKey);
    await prefs.remove(_isLoggedInKey);
    print('✅ User logged out - all data cleared');
  }
}