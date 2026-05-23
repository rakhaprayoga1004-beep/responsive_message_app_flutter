import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/followup_models.dart';
import 'auth_service.dart';
import '../utils/environment.dart';

class FollowupService {
  static String get baseUrl => Environment.baseUrl;
  
  Future<FollowupResponse> getFollowupMessages({
    String status = 'pending',
    String priority = 'all',
    String source = 'all',
    String search = '',
    int page = 1,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final uri = Uri.parse(
        '$baseUrl/modules/guru/api/followup_api.php'
        '?status=$status&priority=$priority&source=$source&search=$search&page=$page'
      );

      print('📡 Followup API URL: $uri');
      print('📡 Authorization Header: Bearer ${token.substring(0, token.length > 20 ? 20 : token.length)}...');

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('📡 Followup API Response Status: ${response.statusCode}');
      print('📡 Followup API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return FollowupResponse.fromJson(data);
      } else if (response.statusCode == 401) {
        throw Exception('Session expired. Please login again.');
      } else {
        throw Exception('Failed to load followup messages: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error loading followup messages: $e');
      throw Exception('Error loading followup messages: $e');
    }
  }

  Future<Map<String, dynamic>> getMessageDetail(int messageId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final uri = Uri.parse(
        '$baseUrl/modules/guru/ajax/get_message_detail.php?message_id=$messageId'
      );

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 401) {
        throw Exception('Session expired. Please login again.');
      } else {
        throw Exception('Failed to load message detail: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error loading message detail: $e');
      throw Exception('Error loading message detail: $e');
    }
  }

  Future<Map<String, dynamic>> getMessageAttachments(int messageId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final uri = Uri.parse(
        '$baseUrl/modules/guru/ajax/get_message_attachments.php?message_id=$messageId'
      );

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 401) {
        throw Exception('Session expired. Please login again.');
      } else {
        throw Exception('Failed to load attachments: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error loading attachments: $e');
      throw Exception('Error loading attachments: $e');
    }
  }

  Future<Map<String, dynamic>> quickAction(int messageId, String action) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final uri = Uri.parse('$baseUrl/modules/guru/api/followup_api.php');
      
      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'action': action,
          'message_id': messageId,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return {'success': true, 'message': data['message'] ?? 'Success'};
        } else {
          throw Exception(data['message'] ?? 'Quick action failed');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Session expired. Please login again.');
      } else {
        throw Exception('Quick action failed: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error quick action: $e');
      throw Exception('Error quick action: $e');
    }
  }

  Future<Map<String, dynamic>> deleteMessage(int messageId, String reason) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      if (reason.trim().isEmpty) {
        throw Exception('Alasan penghapusan harus diisi');
      }

      final uri = Uri.parse('$baseUrl/modules/guru/api/followup_api.php');
      
      print('🗑️ Deleting message ID: $messageId');
      print('📝 Delete reason: $reason');
      
      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'action': 'delete_message',
          'message_id': messageId,
          'delete_reason': reason,
          'confirm_delete': 'yes',
        }),
      ).timeout(const Duration(seconds: 30));

      print('🗑️ Delete response status: ${response.statusCode}');
      print('🗑️ Delete response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return {'success': true, 'message': data['message'] ?? 'Pesan berhasil dihapus'};
        } else {
          throw Exception(data['message'] ?? 'Gagal menghapus pesan');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Session expired. Please login again.');
      } else if (response.statusCode == 403) {
        throw Exception('Anda tidak memiliki izin untuk menghapus pesan ini');
      } else {
        throw Exception('Failed to delete message: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error deleting message: $e');
      throw Exception('Error deleting message: $e');
    }
  }

  Future<Map<String, dynamic>> sendResponse({
    required int messageId,
    required String status,
    required String catatan,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      if (catatan.trim().isEmpty) {
        throw Exception('Catatan respons tidak boleh kosong');
      }

      final uri = Uri.parse('$baseUrl/modules/guru/api/followup_api.php');
      
      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'action': 'send_response',
          'message_id': messageId,
          'status': status,
          'catatan': catatan,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return {'success': true, 'message': data['message'] ?? 'Respons berhasil dikirim'};
        } else {
          throw Exception(data['message'] ?? 'Gagal mengirim respons');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Session expired. Please login again.');
      } else {
        throw Exception('Failed to send response: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error sending response: $e');
      throw Exception('Error sending response: $e');
    }
  }
}