// lib/screen/admin/logs_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../widgets/window_resizer_shortcut.dart';
import '../utils/environment.dart';

// ==================== API SERVICE ====================
class LogsApiService {
  static String get baseUrl => '${Environment.baseUrl}/api';
  
  static String? authToken;
  static int? userId;
  static String? userType;
  
  static Future<void> loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      authToken = prefs.getString('auth_token');
      userId = prefs.getInt('user_id');
      userType = prefs.getString('user_type');
      print('✅ User data loaded - userId: $userId, userType: $userType');
    } catch (e) {
      print('❌ Error loading user data: $e');
      userId = 1;
      userType = 'Admin';
    }
  }
  
  static Future<Map<String, dynamic>> _request(
    String endpoint, {
    String method = 'GET',
    Map<String, dynamic>? body,
  }) async {
    final url = Uri.parse('$baseUrl/$endpoint');
    print('📡 API Request: $method $url');
    
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'X-Requested-With': 'XMLHttpRequest',
    };
    
    await loadUserData();
    
    final prefs = await SharedPreferences.getInstance();
    String? sessionId = prefs.getString('session_id');
    if (sessionId == null || sessionId.isEmpty) {
      sessionId = prefs.getString('RMSESSID');
    }
    if (sessionId == null || sessionId.isEmpty) {
      sessionId = prefs.getString('PHPSESSID');
    }
    
    if (sessionId != null && sessionId.isNotEmpty) {
      headers['Cookie'] = 'RMSESSID=$sessionId; PHPSESSID=$sessionId';
    }
    
    if (authToken != null) {
      headers['Authorization'] = 'Bearer $authToken';
    }
    
    try {
      http.Response response;
      if (method == 'GET') {
        response = await http.get(url, headers: headers).timeout(
          const Duration(seconds: 30),
          onTimeout: () => throw Exception('Connection timeout'),
        );
      } else if (method == 'POST') {
        response = await http.post(
          url, 
          headers: headers, 
          body: jsonEncode(body)
        ).timeout(
          const Duration(seconds: 30),
          onTimeout: () => throw Exception('Connection timeout'),
        );
      } else if (method == 'PUT') {
        response = await http.put(
          url, 
          headers: headers, 
          body: jsonEncode(body)
        ).timeout(
          const Duration(seconds: 30),
          onTimeout: () => throw Exception('Connection timeout'),
        );
      } else if (method == 'DELETE') {
        response = await http.delete(url, headers: headers).timeout(
          const Duration(seconds: 30),
          onTimeout: () => throw Exception('Connection timeout'),
        );
      } else {
        throw Exception('Unsupported method: $method');
      }
      
      print('📡 API Response Status: ${response.statusCode}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        print('✅ API Response Success');
        return data;
      } else if (response.statusCode == 401) {
        throw Exception('Session expired. Please login again.');
      } else if (response.statusCode == 403) {
        throw Exception('Access forbidden. Please check your permissions.');
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ API Error: $e');
      rethrow;
    }
  }
  
  static Future<Map<String, dynamic>> getLogs({
    required String logType,
    required String startDate,
    required String endDate,
    required String actionType,
    required int userId,
    required String search,
    required int page,
    required int limit,
  }) async {
    print('📊 Getting logs with params: type=$logType, page=$page');
    try {
      final queryParams = {
        'type': logType,
        'start_date': startDate,
        'end_date': endDate,
        'action': actionType,
        'user_id': userId.toString(),
        'search': search,
        'page': page.toString(),
        'limit': limit.toString(),
      };
      
      final queryString = queryParams.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');
      
      final data = await _request('logs.php?$queryString');
      return data;
    } catch (e) {
      print('❌ Error getting logs: $e');
      rethrow;
    }
  }
  
  static Future<Map<String, dynamic>> getStats() async {
    print('📊 Getting stats...');
    try {
      final data = await _request('logs/stats.php');
      return data;
    } catch (e) {
      print('❌ Error getting stats: $e');
      return {
        'success': false,
        'stats': {
          'total_logs': 0,
          'unique_users': 0,
          'unique_actions': 0,
          'last_24h': 0,
          'modifications': 0,
          'failed_logins': 0,
        }
      };
    }
  }
  
  static Future<Map<String, dynamic>> clearOldLogs(int days) async {
    try {
      final data = await _request(
        'logs.php',
        method: 'POST',
        body: {
          'action': 'clear_old_logs',
          'days': days,
        },
      );
      return data;
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
  
  static Future<Map<String, dynamic>> deleteLog(int logId) async {
    try {
      final data = await _request(
        'logs.php',
        method: 'POST',
        body: {
          'action': 'delete_log',
          'log_id': logId,
        },
      );
      return data;
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
  
  static Future<String> exportLogs({
    required String format,
    required String logType,
    required String startDate,
    required String endDate,
    required String actionType,
    required int userId,
    required String search,
  }) async {
    final queryParams = {
      'export': format,
      'type': logType,
      'start_date': startDate,
      'end_date': endDate,
      'action': actionType,
      'user_id': userId.toString(),
      'search': search,
    };
    
    final queryString = queryParams.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');
    
    return '$baseUrl/logs.php?$queryString';
  }
}

// ==================== MODEL CLASSES ====================
class LogEntry {
  final int id;
  final DateTime createdAt;
  final String? userName;
  final String? userType;
  final String actionType;
  final String? tableName;
  final int? recordId;
  final String? description;
  final String? ipAddress;
  final String? userAgent;
  final int? hoursAgo;

  LogEntry({
    required this.id,
    required this.createdAt,
    this.userName,
    this.userType,
    required this.actionType,
    this.tableName,
    this.recordId,
    this.description,
    this.ipAddress,
    this.userAgent,
    this.hoursAgo,
  });

  factory LogEntry.fromJson(Map<String, dynamic> json) {
    return LogEntry(
      id: json['id'] ?? 0,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      userName: json['user_name'],
      userType: json['user_type'],
      actionType: json['action_type'] ?? 'UNKNOWN',
      tableName: json['table_name'],
      recordId: json['record_id'],
      description: json['new_value'],
      ipAddress: json['ip_address'],
      userAgent: json['user_agent'],
      hoursAgo: json['hours_ago'],
    );
  }
  
  Color getActionColor() {
    switch (actionType) {
      case 'CREATE':
        return Colors.green;
      case 'UPDATE':
        return Colors.orange;
      case 'DELETE':
        return Colors.red;
      case 'LOGIN':
        return Colors.blue;
      case 'LOGOUT':
        return Colors.grey;
      case 'LOGIN_FAILED':
        return Colors.red;
      case 'BACKUP':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
  
  Color getActionBgColor() {
    return getActionColor().withOpacity(0.1);
  }
}

class LogStats {
  final int totalLogs;
  final int uniqueUsers;
  final int uniqueActions;
  final int last24h;
  final int modifications;
  final int failedLogins;
  final DateTime? oldestLog;
  final DateTime? newestLog;

  LogStats({
    required this.totalLogs,
    required this.uniqueUsers,
    required this.uniqueActions,
    required this.last24h,
    required this.modifications,
    required this.failedLogins,
    this.oldestLog,
    this.newestLog,
  });

  factory LogStats.fromJson(Map<String, dynamic> json) {
    return LogStats(
      totalLogs: json['total_logs'] ?? 0,
      uniqueUsers: json['unique_users'] ?? 0,
      uniqueActions: json['unique_actions'] ?? 0,
      last24h: json['last_24h'] ?? 0,
      modifications: json['modifications'] ?? 0,
      failedLogins: json['failed_logins'] ?? 0,
      oldestLog: json['oldest_log'] != null ? DateTime.parse(json['oldest_log']) : null,
      newestLog: json['newest_log'] != null ? DateTime.parse(json['newest_log']) : null,
    );
  }
}

class DailyActivity {
  final DateTime date;
  final int total;
  final int creates;
  final int updates;
  final int deletes;
  final int logins;
  final int failed;

  DailyActivity({
    required this.date,
    required this.total,
    required this.creates,
    required this.updates,
    required this.deletes,
    required this.logins,
    required this.failed,
  });

  factory DailyActivity.fromJson(Map<String, dynamic> json) {
    return DailyActivity(
      date: DateTime.parse(json['date']),
      total: json['total'] ?? 0,
      creates: json['creates'] ?? 0,
      updates: json['updates'] ?? 0,
      deletes: json['deletes'] ?? 0,
      logins: json['logins'] ?? 0,
      failed: json['failed'] ?? 0,
    );
  }
}

class ActionDistribution {
  final String actionType;
  final int total;
  final double percentage;

  ActionDistribution({
    required this.actionType,
    required this.total,
    required this.percentage,
  });

  factory ActionDistribution.fromJson(Map<String, dynamic> json) {
    return ActionDistribution(
      actionType: json['action_type'] ?? '',
      total: json['total'] ?? 0,
      percentage: json['percentage']?.toDouble() ?? 0.0,
    );
  }
  
  Color getColor() {
    switch (actionType) {
      case 'CREATE':
        return Colors.green;
      case 'UPDATE':
        return Colors.orange;
      case 'DELETE':
        return Colors.red;
      case 'LOGIN':
        return Colors.blue;
      case 'LOGOUT':
        return Colors.grey;
      case 'LOGIN_FAILED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

class TopUser {
  final int id;
  final String namaLengkap;
  final String userType;
  final int activityCount;
  final DateTime lastActivity;

  TopUser({
    required this.id,
    required this.namaLengkap,
    required this.userType,
    required this.activityCount,
    required this.lastActivity,
  });

  factory TopUser.fromJson(Map<String, dynamic> json) {
    return TopUser(
      id: json['id'] ?? 0,
      namaLengkap: json['nama_lengkap'] ?? '',
      userType: json['user_type'] ?? '',
      activityCount: json['activity_count'] ?? 0,
      lastActivity: DateTime.parse(json['last_activity'] ?? DateTime.now().toIso8601String()),
    );
  }
  
  Color getUserTypeColor() {
    switch (userType) {
      case 'Admin':
        return Colors.red;
      case 'Siswa':
        return Colors.green;
      case 'Guru':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}

// ==================== MAIN SCREEN ====================
class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key});

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> with SingleTickerProviderStateMixin {
  String _logType = 'audit';
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();
  String _actionType = 'all';
  int _selectedUserId = 0;
  String _search = '';
  int _currentPage = 1;
  final int _limit = 50;
  bool _isExporting = false;
  
  List<LogEntry> _logs = [];
  LogStats? _stats;
  List<DailyActivity> _dailyActivity = [];
  List<ActionDistribution> _actionDistribution = [];
  List<TopUser> _topUsers = [];
  List<Map<String, dynamic>> _userList = [];
  
  bool _isLoading = true;
  String? _error;
  int _totalLogs = 0;
  int _totalPages = 0;
  
  late TabController _tabController;
  Timer? _debounceTimer;
  
  // Scroll controller untuk log list
  final ScrollController _logListScrollController = ScrollController();
  
  @override
  void initState() {
    super.initState();
    print('═══════════════════════════════════════════════════════');
    print('🔵 LOGS SCREEN INITIALIZATION STARTED');
    print('═══════════════════════════════════════════════════════');
    
    try {
      _tabController = TabController(length: 3, vsync: this);
      _tabController.addListener(_onTabChanged);
      
      print('✅ TabController initialized');
      
      _loadData();
      _loadUserList();
      
      print('✅ initState completed successfully');
    } catch (e, stacktrace) {
      print('❌ ERROR in initState: $e');
      print('Stacktrace: $stacktrace');
      setState(() {
        _error = 'Initialization error: $e';
        _isLoading = false;
      });
    }
  }
  
  @override
  void dispose() {
    print('🔴 Disposing LogsScreen');
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _debounceTimer?.cancel();
    _logListScrollController.dispose();
    super.dispose();
  }
  
  void _onTabChanged() {
    print('🔄 Tab changed to index: ${_tabController.index}');
    setState(() {
      switch (_tabController.index) {
        case 0:
          _logType = 'audit';
          break;
        case 1:
          _logType = 'security';
          break;
        case 2:
          _logType = 'errors';
          break;
      }
      _currentPage = 1;
    });
    _loadData();
  }
  
  Future<void> _loadUserList() async {
    print('👥 Loading user list...');
    try {
      setState(() {
        _userList = [
          {'id': 1, 'nama_lengkap': 'Administrator Sistem', 'user_type': 'Admin'},
          {'id': 2, 'nama_lengkap': 'Budi Santoso', 'user_type': 'Guru'},
          {'id': 3, 'nama_lengkap': 'Siti Aisyah', 'user_type': 'Guru_BK'},
          {'id': 8, 'nama_lengkap': 'Joko Widodo', 'user_type': 'Wakil_Kepala'},
          {'id': 9, 'nama_lengkap': 'Sri Mulyani', 'user_type': 'Kepala_Sekolah'},
        ];
      });
      print('✅ User list loaded: ${_userList.length} users');
    } catch (e) {
      print('❌ Error loading user list: $e');
    }
  }
  
  Future<void> _loadData() async {
    print('🔄 Loading data...');
    print('   - Log Type: $_logType');
    print('   - Date Range: ${DateFormat('yyyy-MM-dd').format(_startDate)} to ${DateFormat('yyyy-MM-dd').format(_endDate)}');
    print('   - Action: $_actionType');
    print('   - User ID: $_selectedUserId');
    print('   - Search: $_search');
    print('   - Page: $_currentPage');
    
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      await LogsApiService.loadUserData();
      print('✅ User data loaded from SharedPreferences');
      
      print('📡 Calling API getLogs...');
      final result = await LogsApiService.getLogs(
        logType: _logType,
        startDate: DateFormat('yyyy-MM-dd').format(_startDate),
        endDate: DateFormat('yyyy-MM-dd').format(_endDate),
        actionType: _actionType,
        userId: _selectedUserId,
        search: _search,
        page: _currentPage,
        limit: _limit,
      );
      
      print('📊 API Result: ${result['success']}');
      
      if (result['success'] == true) {
        final logsData = result['data'] ?? [];
        _logs = logsData.map((log) => LogEntry.fromJson(log)).toList();
        _totalLogs = result['total'] ?? 0;
        _totalPages = result['total_pages'] ?? 0;
        print('✅ Loaded ${_logs.length} logs (Total: $_totalLogs, Pages: $_totalPages)');
      } else {
        print('⚠️ API returned success=false');
        _logs = [];
        _totalLogs = 0;
        _totalPages = 0;
      }
      
      print('📡 Calling API getStats...');
      final statsResult = await LogsApiService.getStats();
      
      if (statsResult['success'] == true) {
        _stats = LogStats.fromJson(statsResult['stats'] ?? {});
        _dailyActivity = (statsResult['daily_activity'] ?? [])
            .map((item) => DailyActivity.fromJson(item))
            .toList();
        _actionDistribution = (statsResult['action_distribution'] ?? [])
            .map((item) => ActionDistribution.fromJson(item))
            .toList();
        _topUsers = (statsResult['top_users'] ?? [])
            .map((user) => TopUser.fromJson(user))
            .toList();
        print('✅ Stats loaded: Total Logs=${_stats?.totalLogs}, Users=${_stats?.uniqueUsers}');
      } else {
        print('⚠️ Stats API returned success=false, using defaults');
      }
      
      setState(() {
        _isLoading = false;
      });
      print('✅ Data loading completed');
      
    } catch (e) {
      print('❌ ERROR loading data: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }
  
  Future<void> _refreshData() async {
    print('🔄 Manual refresh triggered');
    await _loadData();
  }
  
  void _onSearchChanged(String value) {
    _search = value;
    _currentPage = 1;
    print('🔍 Search changed: "$value"');
    
    if (_debounceTimer?.isActive ?? false) {
      _debounceTimer?.cancel();
    }
    
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      print('🔍 Debounced search: loading data...');
      _loadData();
    });
  }
  
  Future<void> _showClearLogsDialog() async {
    final days = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bersihkan Log Lama'),
        content: const Text('Pilih periode log yang akan dihapus:'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, 30),
            child: const Text('30 Hari'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, 90),
            child: const Text('90 Hari'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, 180),
            child: const Text('180 Hari'),
          ),
        ],
      ),
    );
    
    if (days != null) {
      await _clearOldLogs(days);
    }
  }
  
  Future<void> _clearOldLogs(int days) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus Log'),
        content: Text('Apakah Anda yakin ingin menghapus log lebih dari $days hari?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      setState(() {
        _isLoading = true;
      });
      
      final result = await LogsApiService.clearOldLogs(days);
      if (result['success'] == true) {
        _loadData();
        _showSnackBar('Berhasil membersihkan log', Colors.green);
      } else {
        _showSnackBar('Gagal membersihkan log', Colors.red);
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _deleteLog(int logId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: const Text('Apakah Anda yakin ingin menghapus log ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      final result = await LogsApiService.deleteLog(logId);
      if (result['success'] == true) {
        _loadData();
        _showSnackBar('Log berhasil dihapus', Colors.green);
      } else {
        _showSnackBar('Gagal menghapus log', Colors.red);
      }
    }
  }
  
  Future<void> _exportLogs(String format) async {
    setState(() {
      _isExporting = true;
    });
    
    try {
      final url = await LogsApiService.exportLogs(
        format: format,
        logType: _logType,
        startDate: DateFormat('yyyy-MM-dd').format(_startDate),
        endDate: DateFormat('yyyy-MM-dd').format(_endDate),
        actionType: _actionType,
        userId: _selectedUserId,
        search: _search,
      );
      
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        _showSnackBar('Memulai ekspor $format...', Colors.blue);
      } else {
        _showSnackBar('Tidak dapat membuka URL ekspor', Colors.red);
      }
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}', Colors.red);
    } finally {
      setState(() {
        _isExporting = false;
      });
    }
  }
  
  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
  
  void _showLogDetail(LogEntry log) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Detail Log Entry',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    children: [
                      _buildDetailRow('ID', log.id.toString()),
                      _buildDetailRow('Timestamp', DateFormat('dd/MM/yyyy HH:mm:ss').format(log.createdAt)),
                      _buildDetailRow('User', log.userName ?? 'System'),
                      _buildDetailRow('User Type', log.userType ?? 'System'),
                      _buildDetailRow('Action', log.actionType),
                      _buildDetailRow('Table', log.tableName ?? '-'),
                      _buildDetailRow('Record ID', log.recordId?.toString() ?? '-'),
                      _buildDetailRow('Description', log.description ?? '-'),
                      _buildDetailRow('IP Address', log.ipAddress ?? '-'),
                      _buildDetailRow('User Agent', log.userAgent ?? '-', isMultiLine: true),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildDetailRow(String label, String value, {bool isMultiLine = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: isMultiLine
                ? Text(value, style: const TextStyle(fontSize: 12))
                : Text(value, style: const TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
  
  IconData _getActionIcon(String actionType) {
    switch (actionType) {
      case 'CREATE':
        return Icons.add_circle;
      case 'UPDATE':
        return Icons.edit;
      case 'DELETE':
        return Icons.delete;
      case 'LOGIN':
        return Icons.login;
      case 'LOGOUT':
        return Icons.logout;
      case 'LOGIN_FAILED':
        return Icons.warning;
      case 'BACKUP':
        return Icons.backup;
      default:
        return Icons.info;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    print('═══════════════════════════════════════════════════════');
    print('🟢 LOGS SCREEN BUILD METHOD CALLED');
    print('   - isLoading: $_isLoading');
    print('   - error: $_error');
    print('   - logs count: ${_logs.length}');
    print('   - stats: ${_stats != null}');
    print('═══════════════════════════════════════════════════════');
    
    try {
      final result = WindowResizerShortcut(
        child: Scaffold(
          appBar: AppBar(
            title: const Text('System Logs'),
            backgroundColor: const Color(0xFF0B4D8A),
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Audit Trail', icon: Icon(Icons.history)),
                Tab(text: 'Security Logs', icon: Icon(Icons.security)),
                Tab(text: 'Error Logs', icon: Icon(Icons.error)),
              ],
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicatorColor: Colors.white,
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.aspect_ratio),
                onPressed: () => WindowResizerExtension.showResizerPanel(context),
                tooltip: 'Ubah Ukuran Window (F2)',
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _refreshData,
                tooltip: 'Refresh',
              ),
              PopupMenuButton<String>(
                icon: _isExporting 
                    ? const SizedBox(
                        width: 20, 
                        height: 20, 
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                      )
                    : const Icon(Icons.download),
                tooltip: 'Export',
                onSelected: (value) => _exportLogs(value),
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'csv', child: Row(
                    children: [Icon(Icons.grid_on, color: Colors.green), SizedBox(width: 8), Text('CSV')],
                  )),
                  const PopupMenuItem(value: 'excel', child: Row(
                    children: [Icon(Icons.table_chart, color: Colors.green), SizedBox(width: 8), Text('Excel')],
                  )),
                  const PopupMenuItem(value: 'pdf', child: Row(
                    children: [Icon(Icons.picture_as_pdf, color: Colors.red), SizedBox(width: 8), Text('PDF')],
                  )),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.delete_sweep),
                onPressed: () => _showClearLogsDialog(),
                tooltip: 'Clean Up Logs',
              ),
            ],
          ),
          body: _isLoading
              ? const Center(child: SpinKitFadingCircle(color: Color(0xFF0B4D8A), size: 50))
              : _error != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              _error!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadData,
                            child: const Text('Coba Lagi'),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Kembali ke Dashboard'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _refreshData,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Column(
                          children: [
                            _buildFilterSection(),
                            if (_stats != null && _logType == 'audit')
                              _buildStatsCards(),
                            _buildLogsTable(),
                            if (_totalPages > 1 && _logType == 'audit')
                              _buildPagination(),
                            if (_logType == 'audit')
                              _buildInsightsSection(),
                          ],
                        ),
                      ),
                    ),
        ),
      );
      
      print('✅ Build method completed successfully');
      return result;
      
    } catch (e, stacktrace) {
      print('❌ ERROR in build method: $e');
      print('Stacktrace: $stacktrace');
      return Scaffold(
        appBar: AppBar(
          title: const Text('Error'),
          backgroundColor: Colors.red,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Error: $e',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Kembali ke Dashboard'),
              ),
            ],
          ),
        ),
      );
    }
  }
  
  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Cari...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: _onSearchChanged,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _loadData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0B4D8A),
                  minimumSize: const Size(80, 56),
                ),
                child: const Text('Filter'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildDateFilter(),
                const SizedBox(width: 8),
                _buildActionFilter(),
                const SizedBox(width: 8),
                _buildUserFilter(),
                const SizedBox(width: 8),
                _buildQuickDateButtons(),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildQuickDateButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.today, size: 18),
          const SizedBox(width: 8),
          _buildQuickDateButton('Hari Ini', DateTime.now(), DateTime.now()),
          const VerticalDivider(),
          _buildQuickDateButton('7 Hari', 
              DateTime.now().subtract(const Duration(days: 7)), DateTime.now()),
          const VerticalDivider(),
          _buildQuickDateButton('30 Hari', 
              DateTime.now().subtract(const Duration(days: 30)), DateTime.now()),
        ],
      ),
    );
  }
  
  Widget _buildQuickDateButton(String label, DateTime start, DateTime end) {
    return InkWell(
      onTap: () {
        setState(() {
          _startDate = start;
          _endDate = end;
        });
        _loadData();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ),
    );
  }
  
  Widget _buildDateFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.date_range, size: 18),
          const SizedBox(width: 8),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _startDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (picked != null) {
                setState(() {
                  _startDate = picked;
                });
                _loadData();
              }
            },
            child: Text(DateFormat('dd/MM/yyyy').format(_startDate)),
          ),
          const Text(' - '),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _endDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (picked != null) {
                setState(() {
                  _endDate = picked;
                });
                _loadData();
              }
            },
            child: Text(DateFormat('dd/MM/yyyy').format(_endDate)),
          ),
        ],
      ),
    );
  }
  
  Widget _buildActionFilter() {
    final actions = ['all', 'CREATE', 'UPDATE', 'DELETE', 'LOGIN', 'LOGOUT', 'LOGIN_FAILED'];
    final actionLabels = {
      'all': 'Semua Aksi',
      'CREATE': 'CREATE',
      'UPDATE': 'UPDATE',
      'DELETE': 'DELETE',
      'LOGIN': 'LOGIN',
      'LOGOUT': 'LOGOUT',
      'LOGIN_FAILED': 'LOGIN FAILED',
    };
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButton<String>(
        value: _actionType,
        underline: const SizedBox(),
        icon: const Icon(Icons.arrow_drop_down),
        items: actions.map((action) {
          return DropdownMenuItem(
            value: action,
            child: Text(actionLabels[action] ?? action),
          );
        }).toList(),
        onChanged: (value) {
          if (value != null) {
            setState(() {
              _actionType = value;
              _currentPage = 1;
            });
            _loadData();
          }
        },
      ),
    );
  }
  
  Widget _buildUserFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButton<int>(
        value: _selectedUserId,
        underline: const SizedBox(),
        icon: const Icon(Icons.person),
        items: [
          const DropdownMenuItem(value: 0, child: Text('Semua User')),
          ..._userList.map((user) {
            return DropdownMenuItem(
              value: user['id'],
              child: Text(user['nama_lengkap']),
            );
          }).toList(),
        ],
        onChanged: (value) {
          if (value != null) {
            setState(() {
              _selectedUserId = value;
              _currentPage = 1;
            });
            _loadData();
          }
        },
      ),
    );
  }
  
  Widget _buildStatsCards() {
    if (_stats == null) return const SizedBox();
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 6,
        childAspectRatio: 1.5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        children: [
          _buildStatCard('Total Logs', _stats!.totalLogs.toString(), Icons.database, Colors.blue),
          _buildStatCard('Active Users', _stats!.uniqueUsers.toString(), Icons.people, Colors.green),
          _buildStatCard('Modifications', _stats!.modifications.toString(), Icons.edit, Colors.orange),
          _buildStatCard('Security', _stats!.failedLogins.toString(), Icons.shield, Colors.red),
          _buildStatCard('Today', _stats!.last24h.toString(), Icons.today, Colors.purple),
          _buildStatCard('Actions', _stats!.uniqueActions.toString(), Icons.category, Colors.teal),
        ],
      ),
    );
  }
  
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
            ),
            Text(
              title,
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  // ==================== LOGS TABLE DENGAN SCROLLBAR HORIZONTAL ====================
  Widget _buildLogsTable() {
    if (_logs.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inbox, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('Tidak ada log yang ditemukan'),
              SizedBox(height: 8),
              Text(
                'Coba ubah filter atau rentang tanggal',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }
    
    return Scrollbar(
      controller: _logListScrollController,
      thumbVisibility: true,
      trackVisibility: true,
      interactive: true,
      thickness: 10,
      radius: const Radius.circular(8),
      child: SingleChildScrollView(
        controller: _logListScrollController,
        scrollDirection: Axis.horizontal,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: MediaQuery.of(context).size.width - 32,
          ),
          child: DataTable(
            columnSpacing: 16,
            headingRowColor: WidgetStateProperty.resolveWith(
              (states) => Colors.grey[100],
            ),
            columns: const [
              DataColumn(label: Text('Waktu', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('User', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Aksi', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Deskripsi', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('IP', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Detail', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
            rows: _logs.map((log) => DataRow(
              cells: [
                DataCell(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('dd/MM/yyyy').format(log.createdAt),
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                      ),
                      Text(
                        DateFormat('HH:mm:ss').format(log.createdAt),
                        style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                DataCell(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        log.userName ?? 'System',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        log.userType ?? 'System',
                        style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: log.getActionBgColor(),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      log.actionType,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: log.getActionColor(),
                      ),
                    ),
                  ),
                ),
                DataCell(
                  SizedBox(
                    width: 250,
                    child: Text(
                      log.description ?? '-',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    log.ipAddress ?? '-',
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
                DataCell(
                  IconButton(
                    icon: const Icon(Icons.visibility, size: 18),
                    onPressed: () => _showLogDetail(log),
                    tooltip: 'Lihat Detail',
                  ),
                ),
              ],
            )).toList(),
          ),
        ),
      ),
    );
  }
  
  Widget _buildPagination() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _currentPage > 1
                ? () {
                    setState(() {
                      _currentPage--;
                    });
                    _loadData();
                  }
                : null,
          ),
          Text(
            'Halaman $_currentPage dari $_totalPages',
            style: const TextStyle(fontSize: 14),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _currentPage < _totalPages
                ? () {
                    setState(() {
                      _currentPage++;
                    });
                    _loadData();
                  }
                : null,
          ),
        ],
      ),
    );
  }
  
  Widget _buildInsightsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📊 Insights & Analytics',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (_topUsers.isNotEmpty) ...[
            const Text(
              'Top Active Users',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ..._topUsers.take(5).map((user) => _buildTopUserTile(user)),
            const SizedBox(height: 16),
          ],
          if (_actionDistribution.isNotEmpty) ...[
            const Text(
              'Action Distribution',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ..._actionDistribution.map((action) => _buildActionDistributionTile(action)),
          ],
        ],
      ),
    );
  }
  
  Widget _buildTopUserTile(TopUser user) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: user.getUserTypeColor().withOpacity(0.1),
            child: Text(
              user.namaLengkap[0].toUpperCase(),
              style: TextStyle(color: user.getUserTypeColor()),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.namaLengkap,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  user.userType,
                  style: TextStyle(fontSize: 12, color: user.getUserTypeColor()),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${user.activityCount} aktivitas',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                DateFormat('dd/MM/yyyy').format(user.lastActivity),
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildActionDistributionTile(ActionDistribution action) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: action.getColor(),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  action.actionType,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              Text(
                '${action.total} (${action.percentage.toStringAsFixed(1)}%)',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: action.percentage / 100,
            backgroundColor: Colors.grey[200],
            color: action.getColor(),
            minHeight: 6,
          ),
        ],
      ),
    );
  }
}