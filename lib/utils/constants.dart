// lib/utils/constants.dart
import '../utils/environment.dart';

class Constants {
  // Base URL untuk backend PHP
  static String get baseUrl => Environment.baseUrl;
  
  // API endpoints - gunakan function
  static String apiUrl() => '$baseUrl/api';
  static String modulesUrl() => '$baseUrl/modules';
  static String adminApiUrl() => '${modulesUrl()}/admin/api';
  static String getUserApiUrl() => '${modulesUrl()}/user/api';
  static String getGuruApiUrl() => '${modulesUrl()}/guru/api';
  static String getWakepsekApiUrl() => '${modulesUrl()}/wakepsek/api';
  
  static const String SESSION_NAME = 'RMSESSID';
  static String get testUrl => '${apiUrl()}/test_connection1.php';
  
  // Database configuration
  static const String dbHost = 'localhost';
  static const int dbPort = 3307;
  static const String dbName = 'responsive_message_db';
  static const String dbUser = 'root';
  static const String dbPassword = '';
  
  static const String appName = 'SMKN 12 Jakarta - RMA';
  static const String appVersion = '1.0.0';
  
  // Shared Preferences Keys
  static const String prefAuthToken = 'auth_token';
  static const String prefIsLoggedIn = 'is_logged_in';
  static const String prefUserId = 'user_id';
  static const String prefUserName = 'user_name';
  static const String prefUserType = 'user_type';
  static const String prefSessionId = 'session_id';
  
  // User types
  static const List<String> userTypes = [
    'Admin', 'Guru', 'Guru_BK', 'Guru_Humas', 'Guru_Kurikulum',
    'Guru_Kesiswaan', 'Guru_Sarana', 'Siswa', 'Orang_Tua',
    'Kepala_Sekolah', 'Wakil_Kepala',
  ];
  
  // Status Filters
  static const List<String> statusFilters = [
    'all', 'pending', 'completed', 'Pending', 'Dibaca',
    'Diproses', 'Disetujui', 'Ditolak', 'Selesai'
  ];
  
  // Priority Filters
  static const List<String> priorityFilters = ['all', 'Low', 'Medium', 'High', 'Urgent'];
  
  // Pagination
  static const int defaultPageSize = 20;
}