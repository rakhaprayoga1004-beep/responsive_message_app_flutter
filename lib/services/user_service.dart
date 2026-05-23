// lib/services/user_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';

class UserService {
  // Gunakan Constants.apiUrl yang sudah benar
  final String baseUrl = Constants.apiUrl;
  
  // ==========================================================================
  // SESSION MANAGEMENT
  // ==========================================================================
  
  /// Mendapatkan session ID dari SharedPreferences
  Future<String?> _getSessionId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? sessionId = prefs.getString('session_id');
      
      // Cek juga auth_token untuk backward compatibility
      if (sessionId == null) {
        sessionId = prefs.getString('auth_token');
      }
      
      print('📝 Retrieved session_id: $sessionId');
      return sessionId;
    } catch (e) {
      print('Error getting session_id: $e');
      return null;
    }
  }
  
  /// Membangun headers untuk request
  Future<Map<String, String>> _getHeaders() async {
    final sessionId = await _getSessionId();
    
    // PERBAIKAN: Gunakan nama session yang sama dengan server (RMSESSID)
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'X-Requested-With': 'XMLHttpRequest',
    };
    
    // Tambahkan cookie jika ada session ID
    if (sessionId != null && sessionId.isNotEmpty) {
      headers['Cookie'] = 'RMSESSID=$sessionId';
      print('🔐 Adding session cookie: RMSESSID=$sessionId');
    } else {
      print('⚠️ Warning: No session cookie found! User might not be logged in.');
    }
    
    return headers;
  }
  
  /// Menyimpan session ID setelah login
  Future<void> saveSession(String sessionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('session_id', sessionId);
      print('💾 Session saved: $sessionId');
    } catch (e) {
      print('Error saving session: $e');
    }
  }
  
  /// Menghapus session saat logout
  Future<void> clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('session_id');
      await prefs.remove('auth_token');
      print('🗑️ Session cleared');
    } catch (e) {
      print('Error clearing session: $e');
    }
  }
  
  /// Cek apakah user sudah login
  Future<bool> isLoggedIn() async {
    final sessionId = await _getSessionId();
    return sessionId != null && sessionId.isNotEmpty;
  }

  // ==========================================================================
  // GET USERS - Untuk menampilkan daftar user
  // ==========================================================================
  Future<Map<String, dynamic>> getUsers({
    String? search,
    String? userType,
    String? status,
    int page = 1,
    int limit = 20,
    String sort = 'newest',
  }) async {
    try {
      // Cek login status
      if (!await isLoggedIn()) {
        return {
          'success': false,
          'message': 'Silakan login terlebih dahulu',
          'unauthorized': true,
        };
      }
      
      final headers = await _getHeaders();
      
      // Build query parameters
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
        'sort': sort,
      };
      
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (userType != null && userType.isNotEmpty && userType != 'Semua') {
        queryParams['user_type'] = userType;
      }
      if (status != null && status.isNotEmpty && status != 'Semua') {
        queryParams['status'] = status;
      }
      
      final uri = Uri.parse('$baseUrl/users.php').replace(
        queryParameters: queryParams,
      );
      
      print('📡 GET Users Request:');
      print('  URL: $uri');
      print('  Headers: $headers');
      
      final response = await http.get(uri, headers: headers).timeout(
        const Duration(seconds: 30),
      );
      
      print('📡 Response:');
      print('  Status: ${response.statusCode}');
      print('  Body preview: ${response.body.substring(0, response.body.length > 300 ? 300 : response.body.length)}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success'] == true) {
          List<User> users = [];
          if (data['data'] != null && data['data'] is List) {
            users = (data['data'] as List)
                .map((json) => User.fromJson(json))
                .toList();
          }
          
          return {
            'success': true,
            'users': users,
            'total': data['total'] ?? 0,
            'page': data['page'] ?? page,
            'total_pages': data['total_pages'] ?? 1,
            'stats': data['stats'] ?? {},
          };
        } else {
          return {
            'success': false,
            'message': data['message'] ?? 'Gagal memuat data users',
          };
        }
      } else if (response.statusCode == 401) {
        print('❌ Unauthorized - Session expired');
        await clearSession();
        return {
          'success': false,
          'message': 'Sesi habis, silakan login kembali',
          'unauthorized': true,
        };
      } else {
        return {
          'success': false,
          'message': 'HTTP Error: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('❌ Error fetching users: $e');
      return {
        'success': false,
        'message': 'Koneksi error: ${e.toString()}',
      };
    }
  }

  // ==========================================================================
  // GET USER BY ID - Untuk detail user
  // ==========================================================================
  Future<Map<String, dynamic>> getUserById(int id) async {
  try {
    if (!await isLoggedIn()) {
      return {
        'success': false,
        'message': 'Silakan login terlebih dahulu',
        'unauthorized': true,
      };
    }
    
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl/user_detail.php?id=$id');
    
    print('📡 GET User Detail Request:');
    print('  URL: $uri');
    
    final response = await http.get(uri, headers: headers).timeout(
      const Duration(seconds: 30),
    );
    
    print('📡 Response status: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print('📡 Response data keys: ${data.keys}');
      
      if (data['success'] == true) {
        // PERBAIKAN: Data user ada di 'data', BUKAN 'user'
        final userData = data['data'];
        
        // Debug: print privilege_level
        print('📝 privilege_level from API: ${userData['privilege_level']}');
        print('📝 messages count: ${data['messages']?.length ?? 0}');
        
        final user = User.fromJson(userData);
        
        return {
          'success': true,
          'user': user,
          'stats_cards': data['stats_cards'] ?? {},
          'messages': data['messages'] ?? [],
        };
      }
    } else if (response.statusCode == 401) {
      await clearSession();
      return {
        'success': false,
        'message': 'Sesi habis, silakan login kembali',
        'unauthorized': true,
      };
    }
    
    return {
      'success': false,
      'message': 'Gagal memuat data user'
    };
  } catch (e) {
    print('❌ Error getting user by id: $e');
    return {
      'success': false,
      'message': 'Error: $e'
    };
  }
}

  // ==========================================================================
  // CREATE USER - Untuk menambah user baru
  // ==========================================================================
  Future<Map<String, dynamic>> createUser(Map<String, dynamic> userData) async {
    try {
      if (!await isLoggedIn()) {
        return {
          'success': false,
          'message': 'Silakan login terlebih dahulu',
          'unauthorized': true,
        };
      }
      
      final headers = await _getHeaders();
      final uri = Uri.parse('$baseUrl/create_user.php');
      
      print('📡 POST Create User Request:');
      print('  URL: $uri');
      print('  Body: $userData');
      
      final response = await http.post(
        uri,
        headers: headers,
        body: json.encode(userData),
      ).timeout(const Duration(seconds: 30));
      
      print('📡 Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 401) {
        await clearSession();
        return {
          'success': false,
          'message': 'Sesi habis, silakan login kembali',
          'unauthorized': true,
        };
      }
      return {
        'success': false,
        'message': 'HTTP Error: ${response.statusCode}'
      };
    } catch (e) {
      print('Error creating user: $e');
      return {
        'success': false,
        'message': 'Error: $e'
      };
    }
  }

  // ==========================================================================
  // UPDATE USER - Untuk mengedit user
  // ==========================================================================
  Future<Map<String, dynamic>> updateUser(int id, Map<String, dynamic> userData) async {
    try {
      if (!await isLoggedIn()) {
        return {
          'success': false,
          'message': 'Silakan login terlebih dahulu',
          'unauthorized': true,
        };
      }
      
      final headers = await _getHeaders();
      final uri = Uri.parse('$baseUrl/update_user.php?id=$id');
      
      print('📡 POST Update User Request:');
      print('  URL: $uri');
      print('  Body: $userData');
      
      final response = await http.post(
        uri,
        headers: headers,
        body: json.encode(userData),
      ).timeout(const Duration(seconds: 30));
      
      print('📡 Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 401) {
        await clearSession();
        return {
          'success': false,
          'message': 'Sesi habis, silakan login kembali',
          'unauthorized': true,
        };
      }
      return {
        'success': false,
        'message': 'HTTP Error: ${response.statusCode}'
      };
    } catch (e) {
      print('Error updating user: $e');
      return {
        'success': false,
        'message': 'Error: $e'
      };
    }
  }

  // ==========================================================================
  // DELETE USER - Untuk menghapus user
  // ==========================================================================
  Future<Map<String, dynamic>> deleteUser(int id) async {
    try {
      if (!await isLoggedIn()) {
        return {
          'success': false,
          'message': 'Silakan login terlebih dahulu',
          'unauthorized': true,
        };
      }
      
      final headers = await _getHeaders();
      final uri = Uri.parse('$baseUrl/delete_user.php?id=$id');
      
      print('📡 DELETE User Request:');
      print('  URL: $uri');
      
      final response = await http.delete(
        uri,
        headers: headers,
      ).timeout(const Duration(seconds: 30));
      
      print('📡 Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 401) {
        await clearSession();
        return {
          'success': false,
          'message': 'Sesi habis, silakan login kembali',
          'unauthorized': true,
        };
      }
      return {
        'success': false,
        'message': 'HTTP Error: ${response.statusCode}'
      };
    } catch (e) {
      print('Error deleting user: $e');
      return {
        'success': false,
        'message': 'Error: $e'
      };
    }
  }

  // ==========================================================================
  // UPDATE USER STATUS - Untuk mengaktifkan/nonaktifkan user
  // ==========================================================================
  Future<Map<String, dynamic>> updateUserStatus(int id, bool isActive) async {
    try {
      if (!await isLoggedIn()) {
        return {
          'success': false,
          'message': 'Silakan login terlebih dahulu',
          'unauthorized': true,
        };
      }
      
      final headers = await _getHeaders();
      
      final uri = Uri.parse('$baseUrl/users.php?action=status&id=$id');
      
      print('📡 POST Update Status Request:');
      print('  URL: $uri');
      print('  Body: {"is_active": ${isActive ? 1 : 0}}');
      
      final response = await http.post(
        uri,
        headers: headers,
        body: json.encode({'is_active': isActive ? 1 : 0}),
      ).timeout(const Duration(seconds: 30));
      
      print('📡 Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 401) {
        await clearSession();
        return {
          'success': false,
          'message': 'Sesi habis, silakan login kembali',
          'unauthorized': true,
        };
      }
      return {
        'success': false,
        'message': 'HTTP Error: ${response.statusCode}'
      };
    } catch (e) {
      print('Error updating user status: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // ==========================================================================
  // RESET PASSWORD - Untuk mereset password user
  // ==========================================================================
  Future<Map<String, dynamic>> resetPassword(int id) async {
    try {
      if (!await isLoggedIn()) {
        return {
          'success': false,
          'message': 'Silakan login terlebih dahulu',
          'unauthorized': true,
        };
      }
      
      final headers = await _getHeaders();
      
      final uri = Uri.parse('$baseUrl/users.php?action=reset-password&id=$id');
      
      print('📡 POST Reset Password Request:');
      print('  URL: $uri');
      
      final response = await http.post(uri, headers: headers).timeout(
        const Duration(seconds: 30),
      );
      
      print('📡 Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 401) {
        await clearSession();
        return {
          'success': false,
          'message': 'Sesi habis, silakan login kembali',
          'unauthorized': true,
        };
      }
      return {
        'success': false,
        'message': 'HTTP Error: ${response.statusCode}'
      };
    } catch (e) {
      print('Error resetting password: $e');
      return {'success': false, 'message': e.toString()};
    }
  }
}