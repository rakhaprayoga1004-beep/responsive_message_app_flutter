// lib/services/token_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class TokenService {
  static const String _tokenKey = 'auth_token';
  
  static Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);
      return token;
    } catch (e) {
      print('❌ Error getting token: $e');
      return null;
    }
  }
  
  static bool isTokenValid(String token) {
    if (token.isEmpty) return false;
    
    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        print('🔐 Invalid token format - wrong number of parts');
        return false;
      }
      
      // Decode payload
      String payload = parts[1];
      while (payload.length % 4 != 0) {
        payload += '=';
      }
      final decoded = base64.decode(payload);
      final jsonString = utf8.decode(decoded);
      final payloadData = json.decode(jsonString);
      
      // Check expiration
      if (payloadData.containsKey('exp')) {
        final exp = payloadData['exp'];
        if (exp is int) {
          final expiryDate = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
          if (expiryDate.isBefore(DateTime.now())) {
            print('🔐 Token expired at: $expiryDate');
            return false;
          }
        }
      }
      
      print('🔐 Token valid - user_type: ${payloadData['user_type']}');
      return true;
    } catch (e) {
      print('🔐 Invalid token format - $e');
      return false;
    }
  }
  
  static Map<String, dynamic>? decodeToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      
      String payload = parts[1];
      while (payload.length % 4 != 0) {
        payload += '=';
      }
      final decoded = base64.decode(payload);
      final jsonString = utf8.decode(decoded);
      return json.decode(jsonString);
    } catch (e) {
      print('❌ Error decoding token: $e');
      return null;
    }
  }
}