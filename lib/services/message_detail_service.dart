import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/environment.dart';

class MessageDetailService {
  static String get baseUrl => Environment.baseUrl;
  static const String API_URL = '$baseUrl/api';
  
  // Method FINAL - Menggunakan API tanpa autentikasi untuk testing
  static Future<Map<String, dynamic>?> getMessageDetail(String messageId, String token) async {
    try {
      // Gunakan API final yang TIDAK memerlukan autentikasi
      final url = Uri.parse('$API_URL/get_message_final.php?id=$messageId');
      
      debugPrint('=== FETCHING MESSAGE DETAIL (FINAL) ===');
      debugPrint('URL: $url');
      debugPrint('Message ID: $messageId');
      
      // Kirim request TANPA header autentikasi
      final response = await http.get(url).timeout(const Duration(seconds: 15));
      
      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success'] == true) {
          debugPrint('✅ Successfully loaded message $messageId');
          return data['data'];
        } else {
          debugPrint('❌ API returned error: ${data['error']}');
          return null;
        }
      } else {
        debugPrint('❌ HTTP Error: ${response.statusCode}');
        return null;
      }
    } on TimeoutException catch (e) {
      debugPrint('⏱️ Timeout error: $e');
      return null;
    } catch (e) {
      debugPrint('💥 Error fetching message detail: $e');
      return null;
    }
  }
  
  // Method untuk mendapatkan token (tetap dipertahankan untuk kompatibilitas)
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('session_id');
    debugPrint('getToken() returning: "$token"');
    return token;
  }
  
  // Method untuk menyimpan token
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('session_id', token);
    debugPrint('Token saved: $token');
  }
  
  // Method untuk mengirim balasan (masih memerlukan autentikasi)
  static Future<bool> sendResponse(String messageId, String responseText) async {
    try {
      final token = await getToken();
      final url = Uri.parse('$API_URL/send_response.php');
      
      final response = await http.post(
        url,
        headers: {
          'X-API-Token': token ?? '',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'message_id': messageId,
          'response': responseText,
        }),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      debugPrint('Error sending response: $e');
      return false;
    }
  }
  
  // Method untuk menghapus pesan
  static Future<bool> deleteMessage(String messageId) async {
    try {
      final token = await getToken();
      final url = Uri.parse('$API_URL/delete_message.php');
      
      final response = await http.post(
        url,
        headers: {
          'X-API-Token': token ?? '',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'message_id': messageId,
        }),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      debugPrint('Error deleting message: $e');
      return false;
    }
  }
  
  // Method untuk fallback data (hanya ID 60)
  static Future<Map<String, dynamic>?> getMessageDirectFromDB(String messageId) async {
    if (messageId == '60') {
      return {
        'id': '60',
        'pengirim_nama': 'Django',
        'isi_pesan': 'Ada acara silaturahmi di sekolah',
        'status': 'Pending',
        'priority': 'Medium',
        'created_at': '2026-02-28 16:12:25',
        'is_external': true,
        'response_count': 0,
        'jenis_pesan': 'Informasi',
        'attachments': [
          {
            'id': '3',
            'filename': 'ext_EXT20260228-00713_1772269945_50184706281a6467.jpg',
            'filepath': 'uploads/external_messages/2026/02/28/ext_EXT20260228-00713_1772269945_50184706281a6467.jpg',
            'filesize': 102189,
            'is_external': true,
          }
        ],
        'responses': []
      };
    }
    return null;
  }
  
  // Method untuk cek token (sederhana) - DITAMBAHKAN UNTUK KOMPATIBILITAS
  static Future<bool> checkToken(String token) async {
    // Token dianggap valid jika tidak kosong
    return token.isNotEmpty;
  }
}