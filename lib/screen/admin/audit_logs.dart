// lib/screen/admin/audit_logs.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import '../../services/auth_service.dart';
import '../../utils/helpers.dart';
import '../../widgets/window_resizer_shortcut.dart';
import '../../utils/environment.dart';

class AuditLogs extends StatefulWidget {
  const AuditLogs({super.key});

  @override
  State<AuditLogs> createState() => _AuditLogsState();
}

class _AuditLogsState extends State<AuditLogs> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _logs = [];
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _actionDistribution = [];
  List<Map<String, dynamic>> _topUsers = [];
  List<Map<String, dynamic>> _userList = [];
  List<Map<String, dynamic>> _dailyActivity = [];
  
  bool _isLoading = true;
  String? _error;
  
  // Filters
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 365));
  DateTime _endDate = DateTime.now();
  String _selectedAction = 'all';
  int _selectedUserId = 0;
  String _searchQuery = '';
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalLogs = 0;
  
  // Stats dari logs yang dihitung (KESELURUHAN DATABASE)
  int _calculatedTotalLogs = 0;
  int _calculatedActiveUsers = 0;
  int _calculatedModifications = 0;
  int _calculatedFailedLogins = 0;
  int _calculatedTotalActivities = 0;
  
  final TextEditingController _daysController = TextEditingController(text: '90');
  
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  final ScrollController _tableBodyScrollController = ScrollController();
  final ScrollController _statsScrollController = ScrollController(); // Untuk scrollbar horizontal stats cards
  
  final List<String> _actionTypes = [
    'all', 'CREATE', 'UPDATE', 'DELETE', 'LOGIN', 'LOGOUT', 'LOGIN_FAILED', 'BACKUP', 'CLEANUP', 'REGISTER'
  ];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    _tableBodyScrollController.dispose();
    _statsScrollController.dispose();
    _daysController.dispose();
    super.dispose();
  }
  
  // ==================== FUNGSI UNTUK MENGHITUNG STATS DARI API ====================
  void _calculateStatsFromApi() {
    print('═══════════════════════════════════════════════════════');
    print('📊 MEMULAI PERHITUNGAN STATS DARI DATA API');
    print('📊 _totalLogs (total database): $_totalLogs');
    print('📊 _topUsers.length: ${_topUsers.length}');
    print('📊 _actionDistribution.length: ${_actionDistribution.length}');
    print('═══════════════════════════════════════════════════════');
    
    // ==================== TOTAL LOGS ====================
    int totalLogs = _totalLogs;
    print('✅ Total Logs (dari API): $totalLogs');
    
    // ==================== ACTIVE USERS ====================
    int activeUsers = _topUsers.length;
    print('✅ Active Users (dari API _topUsers): $activeUsers');
    
    // ==================== MODIFICATIONS ====================
    int modificationCount = 0;
    Map<String, int> actionTotalCount = {};
    
    for (var action in _actionDistribution) {
      String actionType = action['action_type'] ?? '';
      int total = action['total'] ?? 0;
      actionTotalCount[actionType] = total;
      
      if (actionType == 'CREATE' || actionType == 'UPDATE' || actionType == 'DELETE') {
        modificationCount += total;
      }
    }
    print('✅ Modifications (CREATE/UPDATE/DELETE dari API): $modificationCount');
    print('   Detail per action type (keseluruhan):');
    actionTotalCount.forEach((action, count) {
      print('      $action: $count');
    });
    
    // ==================== FAILED LOGINS ====================
    int failedLoginsCount = 0;
    for (var action in _actionDistribution) {
      String actionType = action['action_type'] ?? '';
      int total = action['total'] ?? 0;
      if (actionType == 'LOGIN_FAILED') {
        failedLoginsCount += total;
      }
    }
    print('✅ Failed Logins: $failedLoginsCount');
    
    print('═══════════════════════════════════════════════════════');
    print('📊 HASIL AKHIR PERHITUNGAN (KESELURUHAN DATABASE):');
    print('   - Total Logs: $totalLogs');
    print('   - Active Users: $activeUsers');
    print('   - Modifications: $modificationCount');
    print('   - Failed Logins: $failedLoginsCount');
    print('═══════════════════════════════════════════════════════');
    
    // Gunakan setState dengan nilai yang sudah dihitung
    setState(() {
      _calculatedTotalLogs = totalLogs;
      _calculatedActiveUsers = activeUsers;
      _calculatedModifications = modificationCount;
      _calculatedFailedLogins = failedLoginsCount;
      _calculatedTotalActivities = totalLogs;
    });
    
    // Debug setelah setState
    print('🔍 AFTER SETSTATE - _calculatedTotalLogs: $_calculatedTotalLogs');
    print('🔍 AFTER SETSTATE - _calculatedActiveUsers: $_calculatedActiveUsers');
    print('🔍 AFTER SETSTATE - _calculatedModifications: $_calculatedModifications');
    print('═══════════════════════════════════════════════════════');
  }
  
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final token = await AuthService.getToken();
      
      if (token == null) {
        setState(() {
          _error = 'Token tidak ditemukan. Silakan login kembali.';
          _isLoading = false;
        });
        return;
      }
      
      final queryParams = {
        'start_date': _startDate.toIso8601String().split('T')[0],
        'end_date': _endDate.toIso8601String().split('T')[0],
        'action': _selectedAction,
        'user_id': _selectedUserId.toString(),
        'search': _searchQuery,
        'page': _currentPage.toString(),
      };
      
      final uri = Uri.parse('${Environment.baseUrl}/api/admin/logs.php')
            .replace(queryParameters: queryParams);
      
      print('═══════════════════════════════════════════════════════');
      print('📡 MEMANGGIL API: $uri');
      print('═══════════════════════════════════════════════════════');
      
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 30));
      
      print('📡 Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('📡 Response success: ${data['success']}');
        
        if (data['success'] == true) {
          final logsData = data['data']['logs'] ?? [];
          
          print('📊 Jumlah logs dari database: ${logsData.length}');
          
          if (logsData.isNotEmpty) {
            print('📊 Contoh data log pertama:');
            print('   - id: ${logsData[0]['id']}');
            print('   - user_id: ${logsData[0]['user_id']}');
            print('   - user_name: ${logsData[0]['user_name']}');
            print('   - action_type: ${logsData[0]['action_type']}');
            print('   - created_at: ${logsData[0]['created_at']}');
          }
          
          setState(() {
            _logs = List<Map<String, dynamic>>.from(logsData);
            _stats = data['data']['stats'] ?? {};
            _actionDistribution = List<Map<String, dynamic>>.from(data['data']['action_distribution'] ?? []);
            _topUsers = List<Map<String, dynamic>>.from(data['data']['top_users'] ?? []);
            _userList = List<Map<String, dynamic>>.from(data['data']['user_list'] ?? []);
            _dailyActivity = List<Map<String, dynamic>>.from(data['data']['daily_activity'] ?? []);
            _totalLogs = data['data']['pagination']['total'] ?? 0;
            _totalPages = data['data']['pagination']['total_pages'] ?? 1;
            _isLoading = false;
          });
          
          // Hitung stats dari data API (KESELURUHAN)
          Future.microtask(() {
            _calculateStatsFromApi();
          });
          
        } else {
          print('❌ API error: ${data['message']}');
          setState(() {
            _error = data['message'] ?? 'Gagal memuat data';
            _isLoading = false;
          });
        }
      } else {
        print('❌ HTTP error: ${response.statusCode}');
        setState(() {
          _error = 'Server error: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Exception: $e');
      setState(() {
        _error = 'Error: $e';
        _isLoading = false;
      });
    }
  }
  
  Future<void> _deleteLog(int logId) async {
    final confirmed = await Helpers.showConfirmationDialog(
      context,
      title: 'Konfirmasi Hapus',
      message: 'Apakah Anda yakin ingin menghapus log ini?',
      confirmText: 'Hapus',
      cancelText: 'Batal',
      confirmColor: Colors.red,
    );
    
    if (!confirmed) return;
    
    try {
      final token = await AuthService.getToken();
      final response = await http.delete(
	    Uri.parse('${Environment.baseUrl}/api/admin/logs.php?id=$logId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          Helpers.showToast(context, 'Log berhasil dihapus');
          _loadData();
        } else {
          Helpers.showToast(context, data['message'] ?? 'Gagal menghapus', isError: true);
        }
      }
    } catch (e) {
      Helpers.showToast(context, 'Error: $e', isError: true);
    }
  }
  
  Future<void> _showLogDetail(Map<String, dynamic> log) async {
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
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _getActionColor(log['action_type']).contains('success')
                            ? Colors.green.withOpacity(0.1)
                            : (_getActionColor(log['action_type']).contains('warning')
                                ? Colors.orange.withOpacity(0.1)
                                : (_getActionColor(log['action_type']).contains('danger')
                                    ? Colors.red.withOpacity(0.1)
                                    : Colors.blue.withOpacity(0.1))),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.info_outline,
                        color: _getActionColor(log['action_type']).contains('success')
                            ? Colors.green
                            : (_getActionColor(log['action_type']).contains('warning')
                                ? Colors.orange
                                : (_getActionColor(log['action_type']).contains('danger')
                                    ? Colors.red
                                    : Colors.blue)),
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Detail Log Entry',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Text(
                            'ID: #${log['id']}',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    children: [
                      _buildDetailRow('Timestamp', _formatDateTime(log['created_at'])),
                      _buildDetailRow('User ID', log['user_id']?.toString() ?? '-'),
                      _buildDetailRow('User Name', log['user_name'] ?? 'System'),
                      _buildDetailRow('User Type', log['user_type'] ?? 'System'),
                      _buildDetailRow('Action', _getActionDisplay(log['action_type'])),
                      _buildDetailRow('Table', log['table_name'] ?? '-'),
                      _buildDetailRow('Record ID', log['record_id']?.toString() ?? '-'),
                      _buildDetailRow('Description', log['new_value'] ?? '-', isMultiLine: true),
                      _buildDetailRow('IP Address', log['ip_address'] ?? '-'),
                      _buildDetailRow('User Agent', log['user_agent'] ?? '-', isMultiLine: true),
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
  
  Future<void> _clearOldLogs() async {
    _daysController.text = '90';
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bersihkan Log Lama'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Hapus log lebih dari berapa hari?'),
            const SizedBox(height: 16),
            TextField(
              controller: _daysController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Hari',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Log yang lebih lama dari jumlah hari yang ditentukan akan dihapus permanen.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tindakan ini tidak dapat dibatalkan!',
              style: TextStyle(fontSize: 12, color: Colors.red),
            ),
          ],
        ),
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
    
    if (confirmed != true) return;
    
    final days = int.tryParse(_daysController.text) ?? 90;
    if (days < 1 || days > 365) {
      Helpers.showToast(context, 'Jumlah hari harus antara 1-365', isError: true);
      return;
    }
    
    try {
      final token = await AuthService.getToken();
      final response = await http.post(
        Uri.parse('${Environment.baseUrl}/api/admin/logs.php'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'action': 'clear_old_logs',
          'days': days,
        }),
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          Helpers.showToast(context, data['message'] ?? 'Log berhasil dibersihkan');
          _loadData();
        } else {
          Helpers.showToast(context, data['message'] ?? 'Gagal membersihkan log', isError: true);
        }
      }
    } catch (e) {
      Helpers.showToast(context, 'Error: $e', isError: true);
    }
  }
  
  String _getActionColor(String action) {
    switch (action) {
      case 'CREATE': return 'success';
      case 'UPDATE': return 'warning';
      case 'DELETE': return 'danger';
      case 'LOGIN': return 'info';
      case 'LOGOUT': return 'secondary';
      case 'LOGIN_FAILED': return 'danger';
      case 'BACKUP': return 'primary';
      case 'CLEANUP': return 'secondary';
      case 'REGISTER': return 'info';
      default: return 'secondary';
    }
  }
  
  String _getActionDisplay(String action) {
    switch (action) {
      case 'CREATE': return 'CREATE';
      case 'UPDATE': return 'UPDATE';
      case 'DELETE': return 'DELETE';
      case 'LOGIN': return 'LOGIN';
      case 'LOGOUT': return 'LOGOUT';
      case 'LOGIN_FAILED': return 'LOGIN FAILED';
      case 'BACKUP': return 'BACKUP';
      case 'CLEANUP': return 'CLEANUP';
      case 'REGISTER': return 'REGISTER';
      default: return action;
    }
  }
  
  String _formatDateTime(String? dateTimeString) {
    if (dateTimeString == null) return '-';
    try {
      final date = DateTime.parse(dateTimeString);
      return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTimeString;
    }
  }
  
  String _formatDate(String? dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}';
    } catch (e) {
      return dateString;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return WindowResizerShortcut(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Logs & Audit Trail'),
          backgroundColor: const Color(0xFF0B4D8A),
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Audit Trail', icon: Icon(Icons.history)),
              Tab(text: 'Analytics', icon: Icon(Icons.bar_chart)),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.aspect_ratio),
              onPressed: () => WindowResizerExtension.showResizerPanel(context),
              tooltip: 'Ubah Ukuran Window (F2)',
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadData,
              tooltip: 'Refresh',
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'clear_old') {
                  _clearOldLogs();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'clear_old',
                  child: Row(
                    children: [
                      Icon(Icons.cleaning_services, size: 20, color: Colors.orange),
                      SizedBox(width: 8),
                      Text('Bersihkan Log Lama'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildAuditTab(),
            _buildAnalyticsTab(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAuditTab() {
    return Column(
      children: [
        // Filter Bar
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                InkWell(
                  onTap: () async {
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
                    );
                    if (picked != null) {
                      setState(() {
                        _startDate = picked.start;
                        _endDate = picked.end;
                      });
                      _loadData();
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          '${_startDate.day}/${_startDate.month}/${_startDate.year} - ${_endDate.day}/${_endDate.month}/${_endDate.year}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<String>(
                    value: _selectedAction,
                    underline: const SizedBox(),
                    icon: const Icon(Icons.arrow_drop_down),
                    items: _actionTypes.map((action) {
                      return DropdownMenuItem<String>(
                        value: action,
                        child: Text(action == 'all' ? 'Semua Aksi' : _getActionDisplay(action)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedAction = value);
                        _currentPage = 1;
                        _loadData();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<int>(
                    value: _selectedUserId,
                    underline: const SizedBox(),
                    icon: const Icon(Icons.person),
                    items: <DropdownMenuItem<int>>[
                      const DropdownMenuItem<int>(value: 0, child: Text('Semua User')),
                      ..._userList.map((user) {
                        return DropdownMenuItem<int>(
                          value: user['id'],
                          child: Text(user['nama_lengkap'] ?? 'Unknown'),
                        );
                      }).toList(),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedUserId = value);
                        _currentPage = 1;
                        _loadData();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 200,
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Cari...',
                      prefixIcon: const Icon(Icons.search, size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      isDense: true,
                    ),
                    onSubmitted: (value) {
                      _searchQuery = value;
                      _currentPage = 1;
                      _loadData();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        // Scrollable Content
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
                          const SizedBox(height: 16),
                          Text(_error!),
                          const SizedBox(height: 16),
                          ElevatedButton(onPressed: _loadData, child: const Text('Coba Lagi')),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      controller: _scrollController,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        children: [
                          // Daily Activity Chart
                          if (_dailyActivity.isNotEmpty) ...[
                            Container(
                              margin: const EdgeInsets.all(12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.timeline, size: 20, color: Color(0xFF0B4D8A)),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Daily Activity Trends',
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                      ),
                                      const Spacer(),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade100,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          '${_dailyActivity.length} hari',
                                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    height: 220,
                                    child: LineChart(
                                      LineChartData(
                                        gridData: FlGridData(
                                          show: true,
                                          drawVerticalLine: false,
                                          horizontalInterval: _getMaxTotal() / 5,
                                        ),
                                        titlesData: FlTitlesData(
                                          leftTitles: AxisTitles(
                                            sideTitles: SideTitles(
                                              showTitles: true,
                                              reservedSize: 40,
                                              interval: _getMaxTotal() / 5,
                                              getTitlesWidget: (value, meta) {
                                                return Text(
                                                  value.toInt().toString(),
                                                  style: const TextStyle(fontSize: 10),
                                                );
                                              },
                                            ),
                                          ),
                                          bottomTitles: AxisTitles(
                                            sideTitles: SideTitles(
                                              showTitles: true,
                                              reservedSize: 40,
                                              getTitlesWidget: (value, meta) {
                                                final index = value.toInt();
                                                if (index >= 0 && index < _dailyActivity.length) {
                                                  return Padding(
                                                    padding: const EdgeInsets.only(top: 8),
                                                    child: Transform.rotate(
                                                      angle: -0.3,
                                                      child: Text(
                                                        _formatDate(_dailyActivity[index]['date']),
                                                        style: const TextStyle(fontSize: 9),
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                  );
                                                }
                                                return const Text('');
                                              },
                                            ),
                                          ),
                                          rightTitles: const AxisTitles(
                                            sideTitles: SideTitles(showTitles: false),
                                          ),
                                          topTitles: const AxisTitles(
                                            sideTitles: SideTitles(showTitles: false),
                                          ),
                                        ),
                                        borderData: FlBorderData(
                                          show: true,
                                          border: Border.all(color: Colors.grey.shade300),
                                        ),
                                        lineBarsData: [
                                          LineChartBarData(
                                            spots: _generateSpots('total'),
                                            isCurved: true,
                                            color: Colors.blue,
                                            barWidth: 3,
                                            isStrokeCapRound: true,
                                            dotData: const FlDotData(show: true),
                                            belowBarData: BarAreaData(
                                              show: true,
                                              color: Colors.blue.withOpacity(0.1),
                                            ),
                                          ),
                                        ],
                                        lineTouchData: LineTouchData(
                                          touchTooltipData: LineTouchTooltipData(
                                            getTooltipItems: (touchedSpots) {
                                              return touchedSpots.map((touchedSpot) {
                                                final index = touchedSpot.x.toInt();
                                                final date = _dailyActivity[index]['date'] ?? '';
                                                return LineTooltipItem(
                                                  '$date\nTotal: ${touchedSpot.y.toInt()} aktivitas',
                                                  const TextStyle(color: Colors.white, fontSize: 11),
                                                );
                                              }).toList();
                                            },
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  // SUMMARY STATS
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Expanded(child: _buildSummaryStat('Total Aktivitas', '$_calculatedTotalLogs', Icons.show_chart, Colors.blue)),
                                      const SizedBox(width: 8),
                                      Expanded(child: _buildSummaryStat('Rata-rata/Hari', _dailyActivity.isNotEmpty ? (_dailyActivity.fold<double>(0, (sum, item) => sum + (item['total'] as int? ?? 0)) / _dailyActivity.length).toStringAsFixed(1) : '0', Icons.trending_up, Colors.green)),
                                      const SizedBox(width: 8),
                                      Expanded(child: _buildSummaryStat('Hari Tertinggi', _dailyActivity.isNotEmpty ? _dailyActivity.map((e) => e['total'] as int? ?? 0).reduce((a, b) => a > b ? a : b).toString() : '0', Icons.arrow_upward, Colors.orange)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                          
                          // ==================== STATS CARDS DENGAN SCROLLBAR HORIZONTAL ====================
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Scrollbar(
                              controller: _statsScrollController,
                              thumbVisibility: true,
                              trackVisibility: true,
                              interactive: true,
                              thickness: 10,
                              radius: const Radius.circular(8),
                              child: SingleChildScrollView(
                                controller: _statsScrollController,
                                scrollDirection: Axis.horizontal,
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 170,
                                      child: _buildStatCard(
                                        'Total Logs',
                                        '$_calculatedTotalLogs',
                                        Icons.storage,
                                        Colors.blue,
                                        'Total data di database',
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    SizedBox(
                                      width: 170,
                                      child: _buildStatCard(
                                        'Active Users',
                                        '$_calculatedActiveUsers',
                                        Icons.people,
                                        Colors.green,
                                        'Total user yang melakukan aktivitas',
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    SizedBox(
                                      width: 170,
                                      child: _buildStatCard(
                                        'Modifications',
                                        '$_calculatedModifications',
                                        Icons.edit,
                                        Colors.orange,
                                        'Create/Update/Delete',
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    SizedBox(
                                      width: 170,
                                      child: _buildStatCard(
                                        'Security',
                                        '$_calculatedFailedLogins',
                                        Icons.security,
                                        Colors.red,
                                        'Failed login attempts',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          
                          // Logs Table
                          _logs.isEmpty
                              ? Container(
                                  padding: const EdgeInsets.all(32),
                                  child: Center(
                                    child: Column(
                                      children: [
                                        Icon(Icons.inbox, size: 60, color: Colors.grey),
                                        const SizedBox(height: 16),
                                        Text(
                                          'Tidak ada log ditemukan',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(color: Colors.grey),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Total log di database: $_calculatedTotalLogs',
                                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                        ),
                                        const SizedBox(height: 16),
                                        TextButton.icon(
                                          onPressed: () {
                                            setState(() {
                                              _startDate = DateTime(2026, 2, 1);
                                              _endDate = DateTime.now();
                                            });
                                            _loadData();
                                          },
                                          icon: const Icon(Icons.calendar_today, size: 16),
                                          label: const Text('Lihat Log Februari 2026'),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.1),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        physics: const NeverScrollableScrollPhysics(),
                                        child: Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade50,
                                            borderRadius: const BorderRadius.only(
                                              topLeft: Radius.circular(12),
                                              topRight: Radius.circular(12),
                                            ),
                                            border: Border(
                                              bottom: BorderSide(color: Colors.grey.shade200),
                                            ),
                                          ),
                                          child: Row(
                                            children: const [
                                              SizedBox(width: 160, child: Text('Timestamp', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                              SizedBox(width: 150, child: Text('User', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                              SizedBox(width: 100, child: Text('Action', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                              SizedBox(width: 120, child: Text('Table', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                              SizedBox(width: 80, child: Text('Record', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.center)),
                                              SizedBox(width: 250, child: Text('Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                              SizedBox(width: 130, child: Text('IP Address', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                              SizedBox(width: 120, child: Text('Aksi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.center)),
                                            ],
                                          ),
                                        ),
                                      ),
                                      Scrollbar(
                                        controller: _tableBodyScrollController,
                                        thumbVisibility: true,
                                        trackVisibility: true,
                                        interactive: true,
                                        thickness: 10,
                                        radius: const Radius.circular(8),
                                        child: SingleChildScrollView(
                                          controller: _tableBodyScrollController,
                                          scrollDirection: Axis.horizontal,
                                          physics: const AlwaysScrollableScrollPhysics(),
                                          child: Column(
                                            children: _logs.map((log) {
                                              return Container(
                                                padding: const EdgeInsets.all(12),
                                                decoration: BoxDecoration(
                                                  border: Border(
                                                    bottom: BorderSide(color: Colors.grey.shade100),
                                                  ),
                                                ),
                                                child: Row(
                                                  children: [
                                                    SizedBox(width: 160, child: Text(_formatDateTime(log['created_at']), style: const TextStyle(fontSize: 11))),
                                                    SizedBox(width: 150, child: Text(log['user_name'] ?? 'System', style: const TextStyle(fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis)),
                                                    SizedBox(width: 100, child: Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: _getActionColor(log['action_type']).contains('success') ? Colors.green.withOpacity(0.1) : (_getActionColor(log['action_type']).contains('warning') ? Colors.orange.withOpacity(0.1) : (_getActionColor(log['action_type']).contains('danger') ? Colors.red.withOpacity(0.1) : Colors.blue.withOpacity(0.1))),
                                                        borderRadius: BorderRadius.circular(12),
                                                      ),
                                                      child: Center(child: Text(_getActionDisplay(log['action_type']), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _getActionColor(log['action_type']).contains('success') ? Colors.green : (_getActionColor(log['action_type']).contains('warning') ? Colors.orange : (_getActionColor(log['action_type']).contains('danger') ? Colors.red : Colors.blue))))),
                                                    )),
                                                    SizedBox(width: 120, child: Text(log['table_name'] ?? '-', style: const TextStyle(fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                                    SizedBox(width: 80, child: Center(child: (log['record_id'] ?? 0) > 0 ? Chip(label: Text('#${log['record_id']}'), materialTapTargetSize: MaterialTapTargetSize.shrinkWrap) : const Text('-'))),
                                                    SizedBox(width: 250, child: Text((log['new_value']?.length ?? 0) > 60 ? '${log['new_value']?.substring(0, 60)}...' : (log['new_value'] ?? '-'), style: const TextStyle(fontSize: 11), maxLines: 2, overflow: TextOverflow.ellipsis)),
                                                    SizedBox(width: 130, child: Text(log['ip_address'] ?? '-', style: const TextStyle(fontSize: 11))),
                                                    SizedBox(width: 120, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                                      IconButton(icon: const Icon(Icons.visibility, size: 18, color: Colors.blue), onPressed: () => _showLogDetail(log), tooltip: 'Lihat Detail', padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 32)),
                                                      const SizedBox(width: 4),
                                                      IconButton(icon: const Icon(Icons.delete, size: 18, color: Colors.red), onPressed: () => _deleteLog(log['id']), tooltip: 'Hapus Log', padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 32)),
                                                    ])),
                                                  ],
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                          
                          // Pagination
                          if (_totalPages > 1)
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                              margin: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Wrap(
                                alignment: WrapAlignment.center,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 16,
                                children: [
                                  Text('Menampilkan ${_logs.length} dari $_calculatedTotalLogs log', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                  Row(mainAxisSize: MainAxisSize.min, children: [
                                    IconButton(icon: const Icon(Icons.first_page, size: 20), onPressed: _currentPage > 1 ? () { setState(() { _currentPage = 1; _loadData(); }); } : null, tooltip: 'Halaman Pertama', padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 40)),
                                    IconButton(icon: const Icon(Icons.chevron_left, size: 20), onPressed: _currentPage > 1 ? () { setState(() { _currentPage--; _loadData(); }); } : null, tooltip: 'Halaman Sebelumnya', padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 40)),
                                    Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: const Color(0xFF0B4D8A).withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Text('$_currentPage / $_totalPages', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0B4D8A)))),
                                    IconButton(icon: const Icon(Icons.chevron_right, size: 20), onPressed: _currentPage < _totalPages ? () { setState(() { _currentPage++; _loadData(); }); } : null, tooltip: 'Halaman Selanjutnya', padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 40)),
                                    IconButton(icon: const Icon(Icons.last_page, size: 20), onPressed: _currentPage < _totalPages ? () { setState(() { _currentPage = _totalPages; _loadData(); }); } : null, tooltip: 'Halaman Terakhir', padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 40)),
                                  ]),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
        ),
      ],
    );
  }
  
  Widget _buildAnalyticsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Distribusi Aksi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  ..._actionDistribution.map((action) {
                    double percentage = 0.0;
                    final percentageValue = action['percentage'];
                    if (percentageValue is num) {
                      percentage = percentageValue.toDouble();
                    } else if (percentageValue is String) {
                      percentage = double.tryParse(percentageValue) ?? 0.0;
                    }
                    
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(child: Text(_getActionDisplay(action['action_type'] ?? '-'), style: const TextStyle(fontSize: 12))),
                              Text('${action['total']} (${percentage.toStringAsFixed(1)}%)', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: percentage / 100,
                            backgroundColor: Colors.grey[200],
                            color: _getActionColor(action['action_type'] ?? '').contains('success') ? Colors.green : (_getActionColor(action['action_type'] ?? '').contains('warning') ? Colors.orange : (_getActionColor(action['action_type'] ?? '').contains('danger') ? Colors.red : Colors.blue)),
                            minHeight: 6,
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('User Paling Aktif', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ..._topUsers.asMap().entries.map((entry) {
                    final index = entry.key + 1;
                    final user = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          SizedBox(width: 30, child: Text('#$index', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(user['nama_lengkap'] ?? 'Unknown', style: const TextStyle(fontSize: 12)),
                                Text(user['user_type'] ?? '-', style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                              ],
                            ),
                          ),
                          Chip(label: Text('${user['activity_count']}'), backgroundColor: Colors.blue.withOpacity(0.1), materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatCard(String title, String value, IconData icon, Color color, String subtitle) {
    print('📊 _buildStatCard - $title: $value');
    
    final displayValue = value.isEmpty ? '0' : value;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const Spacer(),
                Text(
                  displayValue,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSummaryStat(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Column(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
          Text(title, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }
  
  List<FlSpot> _generateSpots(String type) {
    final spots = <FlSpot>[];
    for (int i = 0; i < _dailyActivity.length; i++) {
      final item = _dailyActivity[i];
      double value = 0;
      if (type == 'total') {
        value = (item['total'] as num?)?.toDouble() ?? 0;
      } else if (type == 'creates') {
        value = (item['creates'] as num?)?.toDouble() ?? 0;
      } else if (type == 'updates') {
        value = (item['updates'] as num?)?.toDouble() ?? 0;
      } else if (type == 'deletes') {
        value = (item['deletes'] as num?)?.toDouble() ?? 0;
      }
      spots.add(FlSpot(i.toDouble(), value));
    }
    return spots;
  }
  
  double _getMaxTotal() {
    if (_dailyActivity.isEmpty) return 10;
    double max = 0;
    for (var item in _dailyActivity) {
      final total = (item['total'] as num?)?.toDouble() ?? 0;
      if (total > max) max = total;
    }
    return max > 0 ? max + 2 : 10;
  }
}