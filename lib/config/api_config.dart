// lib/config/api_config.dart
import '../utils/environment.dart';

class ApiConfig {
  static String get baseUrl => Environment.baseUrl;
  
  // API Endpoints
  static const String login = '/api/login_final.php';
  static const String logout = '/api/logout.php';
  static const String checkSession = '/api/check_session.php';
  
  // Admin endpoints
  static const String adminDashboard = '/api/admin/dashboard_stats.php';
  static const String getUsers = '/api/admin/get_users.php';
  static const String saveUser = '/api/admin/save_user.php';
  static const String deleteUser = '/api/admin/delete_user.php';
  static const String getMessageTypes = '/api/admin/get_message_types.php';
  static const String getLogs = '/api/admin/get_logs.php';
  
  // Timeouts
  static const int connectionTimeout = 30000;
  static const int receiveTimeout = 30000;
}