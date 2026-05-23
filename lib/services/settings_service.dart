import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/settings_models.dart';
import '../utils/api_constants.dart';
import 'package:flutter/foundation.dart';

class SettingsService {
  final String baseUrl = ApiConstants.baseUrl;
  
  Future<String?> _getSessionId() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionId = prefs.getString('session_id');
    if (kDebugMode) {
      print('🔑 Getting session ID: $sessionId');
    }
    return sessionId;
  }

  // Headers dengan cookie
  Future<Map<String, String>> _getHeaders() async {
    final sessionId = await _getSessionId();
    
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    if (sessionId != null && sessionId.isNotEmpty) {
      // Gunakan nama session yang sama dengan config.php (SESSION_NAME)
      headers['Cookie'] = '${ApiConstants.sessionName}=$sessionId';
      if (kDebugMode) {
        print('🔑 Using session: ${ApiConstants.sessionName}=$sessionId');
      }
    } else {
      if (kDebugMode) {
        print('⚠️ No session ID found!');
      }
    }
    
    return headers;
  }
  
  // ============================================
  // GENERAL SETTINGS
  // ============================================
  
  Future<GeneralSettings> getGeneralSettings() async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse('$baseUrl${ApiConstants.settingsGeneral}');
      
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return GeneralSettings.fromJson(data['data']);
      } else {
        throw Exception('Failed to load general settings: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting general settings: $e');
    }
  }

  Future<bool> updateGeneralSettings(GeneralSettings settings) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl${ApiConstants.settingsGeneral}'),
        headers: headers,
        body: json.encode(settings.toJson()),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      } else {
        throw Exception('Failed to update general settings: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating general settings: $e');
    }
  }

  // ============================================
  // MESSAGE TYPES
  // ============================================

  Future<List<MessageType>> getMessageTypes() async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse('$baseUrl${ApiConstants.settingsMessageTypes}');
      
      if (kDebugMode) {
        print('========== API REQUEST ==========');
        print('URL: $url');
        print('Method: GET');
      }
      
      final response = await http.get(url, headers: headers);

      if (kDebugMode) {
        print('Status Code: ${response.statusCode}');
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success'] != true) {
          throw Exception(data['message'] ?? 'API error');
        }
        
        final List<dynamic> types = data['data'];
        final result = types.map((json) => MessageType.fromJson(json)).toList();
        
        if (kDebugMode) {
          print('✅ Loaded ${result.length} message types');
        }
        
        return result;
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized - Please login first');
      } else {
        throw Exception('Failed to load message types: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting message types: $e');
      }
      rethrow;
    }
  }

  Future<MessageType> createMessageType(MessageType type) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl${ApiConstants.settingsMessageTypes}'),
        headers: headers,
        body: json.encode(type.toJson()),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);
        return MessageType.fromJson(data['data']);
      } else {
        throw Exception('Failed to create message type: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating message type: $e');
    }
  }

  Future<MessageType> updateMessageType(int id, MessageType type) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl${ApiConstants.settingsMessageTypes}?id=$id'),
        headers: headers,
        body: json.encode(type.toJson()),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return MessageType.fromJson(data['data']);
      } else {
        throw Exception('Failed to update message type: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating message type: $e');
    }
  }

  Future<bool> deleteMessageType(int id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl${ApiConstants.settingsMessageTypes}?id=$id'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      } else {
        throw Exception('Failed to delete message type: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting message type: $e');
    }
  }

  // ============================================
  // RESPONSE TEMPLATES
  // ============================================

  Future<List<ResponseTemplate>> getResponseTemplates() async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse('$baseUrl${ApiConstants.settingsTemplates}');
      
      if (kDebugMode) {
        print('========== API REQUEST ==========');
        print('URL: $url');
        print('Method: GET');
      }
      
      final response = await http.get(url, headers: headers);

      if (kDebugMode) {
        print('Status Code: ${response.statusCode}');
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success'] != true) {
          throw Exception(data['message'] ?? 'API error');
        }
        
        final List<dynamic> templatesData = data['data'];
        final result = templatesData.map((json) => ResponseTemplate.fromJson(json)).toList();
        
        if (kDebugMode) {
          print('✅ Loaded ${result.length} templates');
        }
        
        return result;
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized - Please login first');
      } else {
        throw Exception('Failed to load templates: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting templates: $e');
      }
      rethrow;
    }
  }

  Future<ResponseTemplate> createTemplate(ResponseTemplate template) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl${ApiConstants.settingsTemplates}'),
        headers: headers,
        body: json.encode({
          'name': template.name,
          'content': template.content,
          'category': template.category,
          'default_status': template.defaultStatus,
          'guru_type': template.guruType,
          'is_active': template.isActive ? 1 : 0,
        }),
      );

      if (kDebugMode) {
        print('Create Template Response Status: ${response.statusCode}');
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['success'] != true) {
          throw Exception(data['message'] ?? 'Failed to create template');
        }
        return ResponseTemplate.fromJson(data['data']);
      } else {
        throw Exception('Failed to create template: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating template: $e');
    }
  }

  Future<ResponseTemplate> updateTemplate(int id, ResponseTemplate template) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl${ApiConstants.settingsTemplates}?id=$id'),
        headers: headers,
        body: json.encode(template.toJson()),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ResponseTemplate.fromJson(data['data']);
      } else {
        throw Exception('Failed to update template: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating template: $e');
    }
  }

  Future<bool> deleteTemplate(int id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl${ApiConstants.settingsTemplates}?id=$id'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      } else {
        throw Exception('Failed to delete template: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting template: $e');
    }
  }

  // ============================================
  // USER MANAGEMENT
  // ============================================
  
  Future<List<User>> getUsers() async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse('$baseUrl${ApiConstants.settingsUsers}');
      
      if (kDebugMode) {
        print('📡 Fetching users from: $url');
      }
      
      final response = await http.get(url, headers: headers);

      if (kDebugMode) {
        print('📡 Response status: ${response.statusCode}');
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> users = data['data'];
        return users.map((json) => User.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load users: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting users: $e');
      }
      throw Exception('Error getting users: $e');
    }
  }

  Future<bool> updateUserStatus(int userId, bool isActive) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl${ApiConstants.userStatus}&id=$userId'),
        headers: headers,
        body: json.encode({'is_active': isActive}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      } else {
        throw Exception('Failed to update user status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating user status: $e');
    }
  }

  Future<bool> resetUserPassword(int userId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl${ApiConstants.userResetPassword}&id=$userId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      } else {
        throw Exception('Failed to reset password: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error resetting password: $e');
    }
  }

  // ============================================
  // NOTIFICATIONS (MailerSend & Fonnte)
  // ============================================
  
  Future<MailerSendConfig> getMailerSendConfig() async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse('$baseUrl${ApiConstants.settingsMailerSend}');
      
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return MailerSendConfig.fromJson(data['data']);
      } else {
        throw Exception('Failed to load MailerSend config: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting MailerSend config: $e');
    }
  }

  Future<bool> updateMailerSendConfig(MailerSendConfig config) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl${ApiConstants.settingsMailerSend}'),
        headers: headers,
        body: json.encode(config.toJson()),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      } else {
        throw Exception('Failed to update MailerSend config: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating MailerSend config: $e');
    }
  }

  Future<FonnteConfig> getFonnteConfig() async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse('$baseUrl${ApiConstants.settingsFonnte}');
      
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return FonnteConfig.fromJson(data['data']);
      } else {
        throw Exception('Failed to load Fonnte config: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting Fonnte config: $e');
    }
  }

  Future<bool> updateFonnteConfig(FonnteConfig config) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl${ApiConstants.settingsFonnte}'),
        headers: headers,
        body: json.encode(config.toJson()),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      } else {
        throw Exception('Failed to update Fonnte config: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating Fonnte config: $e');
    }
  }

  // ============================================
  // TEST NOTIFICATIONS
  // ============================================
  
  Future<TestResult> testMailerSendConnection(MailerSendConfig config) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl${ApiConstants.testMailerSend}'),
        headers: headers,
        body: json.encode(config.toJson()),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return TestResult.fromJson(data);
      } else {
        throw Exception('Failed to test MailerSend: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error testing MailerSend: $e');
    }
  }

  Future<TestResult> sendTestEmail(String email, MailerSendConfig config) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl${ApiConstants.testEmail}'),
        headers: headers,
        body: json.encode({
          'email': email,
          'config': config.toJson(),
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return TestResult.fromJson(data);
      } else {
        throw Exception('Failed to send test email: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error sending test email: $e');
    }
  }

  Future<TestResult> testFonnteConnection(FonnteConfig config) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl${ApiConstants.testFonnte}'),
        headers: headers,
        body: json.encode(config.toJson()),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return TestResult.fromJson(data);
      } else {
        throw Exception('Failed to test Fonnte: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error testing Fonnte: $e');
    }
  }

  Future<TestResult> sendTestWhatsApp(String phone, FonnteConfig config) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl${ApiConstants.testWhatsApp}'),
        headers: headers,
        body: json.encode({
          'phone': phone,
          'config': config.toJson(),
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return TestResult.fromJson(data);
      } else {
        throw Exception('Failed to send test WhatsApp: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error sending test WhatsApp: $e');
    }
  }

  // ============================================
  // SYSTEM & AUDIT
  // ============================================
  
  Future<SystemStats> getSystemStats() async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse('$baseUrl${ApiConstants.settingsSystemStats}');
      
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return SystemStats.fromJson(data['data']);
      } else {
        throw Exception('Failed to load system stats: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting system stats: $e');
    }
  }

  Future<List<AuditLog>> getAuditLogs({int limit = 50}) async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse('$baseUrl${ApiConstants.settingsAuditLogs}?limit=$limit');
      
      if (kDebugMode) {
        print('📡 Fetching audit logs from: $url');
      }
      
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> logs = data['data'];
        return logs.map((json) => AuditLog.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load audit logs: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting audit logs: $e');
    }
  }

  Future<bool> clearOldLogs(int days) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl${ApiConstants.clearLogs}'),
        headers: headers,
        body: json.encode({'days': days}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      } else {
        throw Exception('Failed to clear logs: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error clearing logs: $e');
    }
  }

  // ============================================
  // BACKUP & RESTORE
  // ============================================
  
  Future<BackupResult> createBackup() async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl${ApiConstants.backupCreate}'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return BackupResult.fromJson(data);
      } else {
        throw Exception('Failed to create backup: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating backup: $e');
    }
  }

  Future<List<BackupFile>> getBackupFiles() async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse('$baseUrl${ApiConstants.backupList}');
      
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> files = data['data'];
        return files.map((json) => BackupFile.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load backup files: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting backup files: $e');
    }
  }

  Future<BackupResult> restoreBackup(String filePath) async {
    try {
      final headers = await _getHeaders();
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl${ApiConstants.backupRestore}'),
      );
      request.headers.addAll(headers);
      request.files.add(await http.MultipartFile.fromPath('backup_file', filePath));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return BackupResult.fromJson(data);
      } else {
        throw Exception('Failed to restore backup: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error restoring backup: $e');
    }
  }

  Future<bool> deleteBackupFile(String filename) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl${ApiConstants.backupDelete}'),
        headers: headers,
        body: json.encode({'filename': filename}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      } else {
        throw Exception('Failed to delete backup: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting backup: $e');
    }
  }

  // ============================================
  // EXPORT & IMPORT
  // ============================================
  
  Future<String> exportConfig() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl${ApiConstants.exportConfig}'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return json.encode(data['data']);
      } else {
        throw Exception('Failed to export config: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error exporting config: $e');
    }
  }

  Future<bool> importConfig(String configJson) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl${ApiConstants.importConfig}'),
        headers: headers,
        body: configJson,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      } else {
        throw Exception('Failed to import config: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error importing config: $e');
    }
  }

  // ============================================
  // TOTAL USER STATS (INDEPENDENT - FOR "SEMUA" COUNTER)
  // ============================================
  
  /// Get TOTAL user statistics from database (without any filter)
  /// This is for the "Semua" counter - completely independent
  Future<Map<String, dynamic>> getTotalUserStats() async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse('$baseUrl/api/total_users_stats.php');
      
      if (kDebugMode) {
        print('📡 Fetching TOTAL user stats from: $url');
        print('   🔥 This is INDEPENDENT endpoint for "Semua" counter');
      }
      
      final response = await http.get(url, headers: headers);
      
      if (kDebugMode) {
        print('📡 Response status: ${response.statusCode}');
      }
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          if (kDebugMode) {
            print('✅ Total user stats loaded successfully');
            print('   Total All Users: ${data['data']['total_all_users']}');
            print('   Stats by type: ${data['data']['stats_by_type']}');
          }
          return {
            'success': true,
            'total_all_users': data['data']['total_all_users'],
            'stats_by_type': data['data']['stats_by_type'],
          };
        }
      }
      return {'success': false};
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting total user stats: $e');
      }
      return {'success': false};
    }
  }
}