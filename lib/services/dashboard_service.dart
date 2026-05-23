// lib/services/dashboard_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/dashboard_model.dart';
import 'auth_service.dart';
import '../utils/environment.dart';

class DashboardService {
  static String get baseUrl => Environment.baseUrl;
  
  Future<DashboardStats> getAdminDashboardStats() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      // Path yang benar: api/admin/dashboard_stats.php
      final url = Uri.parse('$baseUrl/api/admin/dashboard_stats.php');
      print('📡 Fetching dashboard stats from: $url');
      
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 30));
      
      print('📡 Response status: ${response.statusCode}');
      print('📡 Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        print('📡 Parsed JSON: $jsonData');
        
        if (jsonData['success'] == true) {
          // Debug response_stats dari API
          if (jsonData['data'] != null && jsonData['data']['response_stats'] != null) {
            print('📊 response_stats from API: ${jsonData['data']['response_stats']}');
          }
          
          final stats = DashboardStats.fromJson(jsonData);
          print('📊 Total Users: ${stats.totalUsers}');
          print('📊 Total Messages: ${stats.totalMessages}');
          print('📊 Recent Messages Count: ${stats.recentMessages.length}');
          print('📊 ResponseStats after parsing: total=${stats.responseStats.totalMessages}, responded=${stats.responseStats.responded}, rate=${stats.responseStats.responseRate}');
          return stats;
        } else {
          print('❌ API Error: ${jsonData['message']}');
          return DashboardStats.empty();
        }
      } else {
        print('❌ HTTP Error: ${response.statusCode}');
        return DashboardStats.empty();
      }
    } catch (e) {
      print('❌ Exception fetching dashboard stats: $e');
      return DashboardStats.empty();
    }
  }
  
  Future<List<DailyMessage>> getMessageVolumeByPeriod(String period) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      // Path yang benar: api/admin/message_volume.php
      final url = Uri.parse('$baseUrl/api/admin/message_volume.php?period=$period');
      print('📡 Fetching message volume from: $url');
      
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 30));
      
      print('📡 Response status: ${response.statusCode}');
      print('📡 Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true) {
          final List<dynamic> data = jsonData['data'] ?? [];
          print('📡 Volume data count: ${data.length}');
          
          // Parse data dengan try-catch untuk debugging
          try {
            final result = data.map((item) {
              print('📡 Parsing item: $item');
              return DailyMessage.fromJson(item);
            }).toList();
            print('✅ Successfully parsed ${result.length} items');
            return result;
          } catch (e) {
            print('❌ Error parsing volume data: $e');
            return [];
          }
        } else {
          print('❌ Volume API error: ${jsonData['message']}');
          return [];
        }
      } else {
        print('❌ HTTP error: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ Error fetching message volume: $e');
      return [];
    }
  }

  // METHOD UNTUK PERTUMBUHAN PENGGUNA
  Future<List<UserGrowth>> getUserGrowthByPeriod(String period) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      // Path yang benar: api/admin/user_growth.php
      final url = Uri.parse('$baseUrl/api/admin/user_growth.php?period=$period');
      print('📡 Fetching user growth from: $url');
      
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 30));
      
      print('📡 Response status: ${response.statusCode}');
      print('📡 Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true) {
          final List<dynamic> data = jsonData['data'] ?? [];
          print('📡 User growth data count: ${data.length}');
          return data.map((item) => UserGrowth.fromJson(item)).toList();
        } else {
          print('❌ User growth API error: ${jsonData['message']}');
          return [];
        }
      } else {
        print('❌ HTTP error: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ Error fetching user growth: $e');
      return [];
    }
  }
  
  void dispose() {}
}