import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/message_model.dart';
import 'auth_service.dart';
import '../utils/environment.dart';

class MessageService {
  static String get baseUrl => Environment.baseUrl;
  
  static Future<DashboardStats> getDashboardStats(String timeFilter) async {
    try {
      final token = await AuthService.getToken();
      final url = Uri.parse('$baseUrl/api/admin/dashboard_stats.php?token=$token');
      
      final response = await http.get(url).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return DashboardStats.fromJson(data['stats'] ?? data);
        }
      }
      
      return DashboardStats(
        totalAssigned: 0,
        pending: 0,
        dibaca: 0,
        diproses: 0,
        disetujui: 0,
        ditolak: 0,
        selesai: 0,
        avgResponseTime: 0,
      );
    } catch (e) {
      print('Error getting dashboard stats: $e');
      return DashboardStats(
        totalAssigned: 0,
        pending: 0,
        dibaca: 0,
        diproses: 0,
        disetujui: 0,
        ditolak: 0,
        selesai: 0,
        avgResponseTime: 0,
      );
    }
  }
  
  static Future<List<RecentActivity>> getRecentActivities() async {
    try {
      final token = await AuthService.getToken();
      final url = Uri.parse('$baseUrl/api/admin/recent_activities.php?token=$token');
      
      final response = await http.get(url).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['activities'] != null) {
          final List<dynamic> activitiesJson = data['activities'];
          return activitiesJson.map((json) => RecentActivity.fromJson(json)).toList();
        }
      }
      
      return [];
    } catch (e) {
      print('Error getting recent activities: $e');
      return [];
    }
  }
}