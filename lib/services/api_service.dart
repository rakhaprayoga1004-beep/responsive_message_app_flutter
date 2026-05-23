// lib/services/api_service.dart - VERSI GABUNGAN LENGKAP (DIPERBAIKI)

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'auth_service.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cross_file/cross_file.dart';
import '../utils/environment.dart';

class ApiService {
  // ✅ Gunakan base URL dari Environment (konsisten)
  static String get baseUrl => Environment.baseUrl;
  
  // ✅ Tambahkan baseUrlApi untuk endpoint admin (seperti backup)
  static String get baseUrlApi => '$baseUrl/api';
  
  // Token cache
  static String? _cachedToken;
  static DateTime? _tokenExpiry;
  
  static Future<String?> getToken() async {
    if (_cachedToken != null && _tokenExpiry != null && DateTime.now().isBefore(_tokenExpiry!)) {
      return _cachedToken;
    }
    
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    
    if (token != null && token.isNotEmpty) {
      _cachedToken = token;
      _tokenExpiry = DateTime.now().add(const Duration(minutes: 55));
      print('🔑 Token cached (expires in 55 minutes)');
    }
    
    return token;
  }
  
  static void clearTokenCache() {
    _cachedToken = null;
    _tokenExpiry = null;
    print('🔑 Token cache cleared');
  }
  
  static Future<Map<String, String>> _getHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
  
  static Future<Map<String, dynamic>> _post(String endpoint, Map<String, dynamic> data) async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse(endpoint);
      
      final response = await http.post(
        url,
        headers: headers,
        body: json.encode(data),
      ).timeout(const Duration(seconds: 120));
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {'success': false, 'message': 'Server error: ${response.statusCode}'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }
  
  static Future<Map<String, dynamic>> _get(String endpoint) async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse(endpoint);
      
      final response = await http.get(
        url,
        headers: headers,
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('❌ GET failed: ${response.statusCode} - $endpoint');
        return {'success': false, 'message': 'Server error: ${response.statusCode}'};
      }
    } catch (e) {
      print('❌ GET error: $e - $endpoint');
      return {'success': false, 'message': 'Error: $e'};
    }
  }
  
  // ============================================================
  // AUTHENTICATION
  // ============================================================
  
  static Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final url = Uri.parse('$baseUrl/api/login_flutter.php');
      print('📍 Login URL: $url');
      
      final response = await http.post(
        url,
        body: {
          'username': username,
          'password': password,
        },
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
      ).timeout(const Duration(seconds: 30));
      
      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        
        if (data['success'] == true && data['user'] != null) {
          final userData = data['user'];
          
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_token', userData['token']);
          await prefs.setInt('user_id', userData['id']);
          await prefs.setString('username', userData['username']);
          await prefs.setString('nama_lengkap', userData['nama_lengkap'] ?? userData['username']);
          await prefs.setString('user_type', userData['user_type']);
          await prefs.setString('email', userData['email'] ?? '');
          await prefs.setString('phone_number', userData['phone_number'] ?? '');
          await prefs.setString('avatar', userData['avatar'] ?? 'default-avatar.png');
          await prefs.setString('privilege_level', userData['privilege_level'] ?? '');
          await prefs.setBool('is_logged_in', true);
          
          clearTokenCache();
          return {'success': true, 'user': userData};
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
  
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('is_logged_in') ?? false;
  }
  
  static Future<String?> getUserType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_type');
  }
  
  static Future<String?> getFullName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('nama_lengkap');
  }
  
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    clearTokenCache();
    print('✅ User logged out');
  }
  
  static Future<Map<String, dynamic>?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('is_logged_in') ?? false) {
      return {
        'id': prefs.getInt('user_id'),
        'username': prefs.getString('username'),
        'nama_lengkap': prefs.getString('nama_lengkap'),
        'user_type': prefs.getString('user_type'),
        'email': prefs.getString('email'),
        'phone_number': prefs.getString('phone_number'),
        'avatar': prefs.getString('avatar'),
        'privilege_level': prefs.getString('privilege_level'),
        'token': prefs.getString('auth_token'),
      };
    }
    return null;
  }
  
  // ============================================================
  // PUBLIC ENDPOINTS
  // ============================================================
  
  static Future<Map<String, dynamic>> getPublicMessageTypes() async {
    try {
      final url = Uri.parse('$baseUrl/api/message_types/public_list.php');
      print('📡 Fetching message types from: $url');
      
      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded['success'] == true) {
          return {'success': true, 'data': decoded['data']};
        } else {
          return {'success': false, 'message': decoded['message'] ?? 'Gagal memuat data'};
        }
      } else {
        return {'success': false, 'message': 'HTTP ${response.statusCode}'};
      }
    } catch (e) {
      print('❌ API Error: $e');
      return {'success': false, 'message': 'Error: $e', 'data': null};
    }
  }
  
  static Future<Map<String, dynamic>> trackMessage(String reference) async {
    try {
      final url = Uri.parse('$baseUrl/api/track_message.php');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'tracking_reference': reference, 'track_message': '1'},
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        if (response.body.trim().startsWith('<')) {
          return {'success': false, 'message': 'Layanan sedang sibuk, silakan coba lagi'};
        }
        final decoded = jsonDecode(response.body);
        return decoded;
      } else {
        return {'success': false, 'message': 'HTTP ${response.statusCode}'};
      }
    } catch (e) {
      print('❌ Track message error: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }
  
  static Future<Map<String, dynamic>> sendExternalMessage({
    required String nama,
    String? email,
    String? phone,
    required String identitas,
    required int jenisPesanId,
    required String prioritas,
    required String isiPesan,
    List<XFile>? files,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/api/send_external_message.php');
      var request = http.MultipartRequest('POST', uri);
      
      request.fields['nama_pengirim'] = nama;
      if (email != null && email.isNotEmpty) request.fields['email_pengirim'] = email;
      if (phone != null && phone.isNotEmpty) request.fields['nomor_hp'] = phone;
      request.fields['identitas'] = identitas;
      request.fields['jenis_pesan_id'] = jenisPesanId.toString();
      request.fields['prioritas'] = prioritas;
      request.fields['isi_pesan'] = isiPesan;
      request.fields['submit_external_message'] = '1';
      request.fields['form_unique_id'] = DateTime.now().millisecondsSinceEpoch.toString();
      
      if (files != null && files.isNotEmpty) {
        for (var file in files) {
          final fileBytes = await file.readAsBytes();
          final multipartFile = http.MultipartFile.fromBytes(
            'attachments[]',
            fileBytes,
            filename: file.name,
          );
          request.files.add(multipartFile);
        }
      }
      
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final decoded = json.decode(responseBody);
      
      if (response.statusCode == 200 && decoded['success'] == true) {
        return {'success': true, 'data': decoded['data']};
      } else {
        return {'success': false, 'message': decoded['message'] ?? 'Gagal mengirim pesan'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }
  
  // ============================================================
  // SETTINGS & NOTIFICATIONS
  // ============================================================
  
  static Future<Map<String, dynamic>> getGeneralSettings() async {
    return _get('$baseUrlApi/admin/settings.php?action=general');
  }
  
  static Future<Map<String, dynamic>> updateGeneralSettings(Map<String, dynamic> settings) async {
    return _post('$baseUrlApi/admin/settings.php', {
      'action': 'update_general',
      'settings': settings,
    });
  }
  
  static Future<Map<String, dynamic>> getMessageTypes() async {
    return _get('$baseUrlApi/admin/settings.php?action=message_types');
  }
  
  static Future<Map<String, dynamic>> addMessageType(Map<String, dynamic> data) async {
    return _post('$baseUrlApi/admin/settings.php', {
      'action': 'add_message_type',
      ...data,
    });
  }
  
  static Future<Map<String, dynamic>> editMessageType(int id, Map<String, dynamic> data) async {
    return _post('$baseUrlApi/admin/settings.php', {
      'action': 'edit_message_type',
      'id': id,
      ...data,
    });
  }
  
  static Future<Map<String, dynamic>> deleteMessageType(int id) async {
    return _post('$baseUrlApi/admin/settings.php', {
      'action': 'delete_message_type',
      'id': id,
    });
  }
  
  static Future<Map<String, dynamic>> getTemplates() async {
    return _get('$baseUrlApi/admin/settings.php?action=templates');
  }
  
  static Future<Map<String, dynamic>> addTemplate(Map<String, dynamic> data) async {
    return _post('$baseUrlApi/admin/settings.php', {
      'action': 'add_template',
      ...data,
    });
  }
  
  static Future<Map<String, dynamic>> editTemplate(int id, Map<String, dynamic> data) async {
    return _post('$baseUrlApi/admin/settings.php', {
      'action': 'edit_template',
      'id': id,
      ...data,
    });
  }
  
  static Future<Map<String, dynamic>> deleteTemplate(int id) async {
    return _post('$baseUrlApi/admin/settings.php', {
      'action': 'delete_template',
      'id': id,
    });
  }
  
  static Future<Map<String, dynamic>> getUsers() async {
    return _get('$baseUrlApi/admin/settings.php?action=users');
  }
  
  static Future<Map<String, dynamic>> updateUserStatus(int userId, bool isActive) async {
    return _post('$baseUrlApi/admin/settings.php', {
      'action': 'update_user_status',
      'user_id': userId,
      'is_active': isActive ? 1 : 0,
    });
  }
  
  static Future<Map<String, dynamic>> resetUserPassword(int userId) async {
    return _post('$baseUrlApi/admin/settings.php', {
      'action': 'reset_user_password',
      'user_id': userId,
    });
  }
  
  static Future<Map<String, dynamic>> getAuditLogs() async {
    return _get('$baseUrlApi/admin/settings.php?action=audit');
  }
  
  static Future<Map<String, dynamic>> clearOldLogs(int days) async {
    return _post('$baseUrlApi/admin/settings.php', {
      'action': 'clear_logs',
      'days': days,
    });
  }
  
  static Future<Map<String, dynamic>> getSystemInfo() async {
    return _get('$baseUrlApi/admin/settings.php?action=system_info');
  }
  
  static Future<Map<String, dynamic>> getNotificationsConfig() async {
    return _get('$baseUrlApi/admin/settings.php?action=notifications');
  }
  
  static Future<Map<String, dynamic>> updateMailerSendConfig(Map<String, dynamic> config) async {
    return _post('$baseUrlApi/admin/settings.php', {
      'action': 'update_mailersend',
      ...config,
    });
  }
  
  static Future<Map<String, dynamic>> updateFonnteConfig(Map<String, dynamic> config) async {
    return _post('$baseUrlApi/admin/settings.php', {
      'action': 'update_fonnte',
      ...config,
    });
  }
  
  static Future<Map<String, dynamic>> testMailerSendConnection(Map<String, dynamic> config) async {
    return _post('$baseUrlApi/admin/settings.php', {
      'action': 'test_mailersend_connection',
      ...config,
    });
  }
  
  static Future<Map<String, dynamic>> testFonnteConnection(Map<String, dynamic> config) async {
    return _post('$baseUrlApi/admin/settings.php', {
      'action': 'test_fonnte_connection',
      ...config,
    });
  }
  
  static Future<Map<String, dynamic>> sendTestEmail(Map<String, dynamic> config) async {
    return _post('$baseUrlApi/admin/settings.php', {
      'action': 'send_test_email',
      ...config,
    });
  }
  
  static Future<Map<String, dynamic>> sendTestWhatsApp(Map<String, dynamic> config) async {
    return _post('$baseUrlApi/admin/settings.php', {
      'action': 'send_test_whatsapp',
      ...config,
    });
  }
  
  // ============================================================
  // BACKUP & RESTORE
  // ============================================================
  
  static Future<Map<String, dynamic>> getBackupFiles() async {
    try {
      final url = Uri.parse('${Constants.baseUrl}/modules/admin/api/get_backups_no_auth.php');
      print('📡 Fetching backup files from: $url');
      
      final response = await http.get(url).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        return {'success': false, 'message': 'Server error: ${response.statusCode}'};
      }
    } catch (e) {
      print('❌ Get backup files error: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }
  
  static Future<Map<String, dynamic>> createBackup() async {
    try {
      final url = Uri.parse('${Constants.baseUrl}/modules/admin/api/create_backup_full.php');
      print('📡 Creating FULL backup via: $url');
      
      final response = await http.post(url).timeout(const Duration(seconds: 120));
      
      if (response.statusCode == 200) {
        String responseBody = response.body.trim();
        final jsonStart = responseBody.indexOf('{');
        if (jsonStart >= 0) {
          responseBody = responseBody.substring(jsonStart);
        }
        final data = json.decode(responseBody);
        return data;
      } else {
        return {'success': false, 'message': 'HTTP ${response.statusCode}: Gagal membuat backup'};
      }
    } catch (e) {
      print('❌ Create backup error: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }
  
  static Future<Map<String, dynamic>> deleteBackup(String filename) async {
    return _post('$baseUrlApi/admin/backup_handler.php', {
      'action': 'delete_backup',
      'filename': filename,
    });
  }
  
  static Future<Map<String, dynamic>> restoreDatabase(File file) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'Token tidak ditemukan'};
      }
      
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrlApi/admin/backup_handler.php'),
      );
      
      request.headers['Authorization'] = 'Bearer $token';
      request.fields['action'] = 'restore_database';
      request.files.add(await http.MultipartFile.fromPath('backup_file', file.path));
      
      final streamedResponse = await request.send().timeout(const Duration(seconds: 300));
      final responseBody = await streamedResponse.stream.bytesToString();
      final data = json.decode(responseBody);
      
      return data;
    } catch (e) {
      print('❌ Restore database error: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }
  
  static Future<Map<String, dynamic>> downloadBackup(String filename) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'Token tidak ditemukan'};
      }
      
      final response = await http.get(
        Uri.parse('$baseUrlApi/admin/download_backup.php?file=${Uri.encodeComponent(filename)}'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 120));
      
      if (response.statusCode == 200) {
        final saveFile = File('${Directory.current.path}/$filename');
        await saveFile.writeAsBytes(response.bodyBytes);
        
        return {
          'success': true,
          'file_path': saveFile.path,
          'message': 'File berhasil diunduh',
        };
      } else {
        return {'success': false, 'message': 'Gagal mengunduh file'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }
  
  // ============================================================
  // ADMIN ENDPOINTS (Dashboard, dll)
  // ============================================================
  
  static Future<Map<String, dynamic>> getAdminDashboardStats() async {
    return _get('$baseUrlApi/admin/dashboard_stats.php');
  }
  
  static Future<Map<String, dynamic>> getAdminMessageVolume({int days = 7}) async {
    return _get('$baseUrlApi/admin/message_volume.php?days=$days');
  }
  
  static Future<Map<String, dynamic>> getMessageDetail(int messageId) async {
    return _get('$baseUrlApi/admin/get_message_detail.php?message_id=$messageId');
  }
  
  // ============================================================
  // EXPORT/IMPORT CONFIG
  // ============================================================
  
  static Future<Map<String, dynamic>> exportConfig() async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrlApi/admin/settings.php'),
        headers: headers,
        body: json.encode({'action': 'export_config'}),
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {'success': false, 'message': 'Server error: ${response.statusCode}'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }
  
  static Future<Map<String, dynamic>> importConfig(File file) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'Token tidak ditemukan'};
      }
      
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrlApi/admin/settings.php'),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.fields['action'] = 'import_config';
      request.files.add(await http.MultipartFile.fromPath('config_file', file.path));
      
      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final data = json.decode(responseData);
      
      return data;
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }
  
  // ============================================================
  // WAKEPSEK/KEPSEK ENDPOINTS (DIPERBAIKI)
  // ============================================================
  
  static Future<Map<String, dynamic>> getWakepsekDashboard({
    required String userType,
    String status = 'all',
    String search = '',
    int page = 1,
    int perPage = 15,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? guruId,
  }) async {
    final token = await getToken();
    
    final queryParams = {
      'user_type': userType,
      'status': status,
      'search': search,
      'page': page.toString(),
      'per_page': perPage.toString(),
    };
    
    if (guruId != null && guruId.isNotEmpty && guruId != 'all') {
      queryParams['guru_id'] = guruId;
    }
    
    if (dateFrom != null) {
      queryParams['date_from'] = dateFrom.toIso8601String().split('T')[0];
    }
    if (dateTo != null) {
      queryParams['date_to'] = dateTo.toIso8601String().split('T')[0];
    }
    
    // ✅ PERBAIKAN: Gunakan $baseUrl (bukan $baseUrlApi) karena sudah include /api
    final url = Uri.parse('$baseUrl/api/wakepsek/dashboard.php').replace(queryParameters: queryParams);
    print('📡 Wakepsek Dashboard URL: $url');
    
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 30));
      
      print('📡 Response status: ${response.statusCode}');
      print('📡 Response body preview: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}');
      
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded['success'] == true) {
          return {'success': true, 'data': decoded['data']};
        } else {
          return {'success': false, 'message': decoded['message'] ?? 'Unknown error'};
        }
      } else {
        return {'success': false, 'message': 'HTTP ${response.statusCode}'};
      }
    } catch (e) {
      print('❌ Wakepsek Dashboard error: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }
  
  static Future<Map<String, dynamic>> submitReview({
    required int messageId,
    required String catatan,
    required String userType,
  }) async {
    final token = await getToken();
    // ✅ Perbaiki URL
    final url = Uri.parse('$baseUrl/api/wakepsek/submit_review.php');
    print('📡 Submit Review URL: $url');
    
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'message_id': messageId,
          'catatan': catatan,
          'user_type': userType,
        }),
      ).timeout(const Duration(seconds: 30));
      
      print('📡 Response status: ${response.statusCode}');
      print('📡 Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return {'success': decoded['success'] ?? false, 'message': decoded['message'] ?? ''};
      } else {
        return {'success': false, 'message': 'HTTP ${response.statusCode}'};
      }
    } catch (e) {
      print('❌ Submit review error: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }
  
  static Future<Map<String, dynamic>> exportReport({
    required String format,
    required DateTime dateFrom,
    required DateTime dateTo,
    required String userType,
  }) async {
    final queryParams = {
      'export': format,
      'date_from': dateFrom.toIso8601String().split('T')[0],
      'date_to': dateTo.toIso8601String().split('T')[0],
      'user_type': userType,
    };
    
    final queryString = queryParams.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
    
    final token = await getToken();
    // ✅ Perbaiki URL
    final url = Uri.parse('$baseUrl/api/wakepsek/export_report.php?$queryString');
    print('📡 Export Report URL: $url');
    
    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      
      print('📡 Export response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        return {'success': true, 'data': response.bodyBytes};
      } else {
        final decoded = jsonDecode(response.body);
        return {'success': false, 'message': decoded['message'] ?? 'Gagal mengekspor'};
      }
    } catch (e) {
      print('❌ Export report error: $e');
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }
  
  // ============================================================
  // MESSAGE ATTACHMENTS
  // ============================================================
  
  static Future<Map<String, dynamic>> getMessageAttachments(int messageId) async {
    return _get('$baseUrlApi/messages/get_attachments.php?message_id=$messageId');
  }
}