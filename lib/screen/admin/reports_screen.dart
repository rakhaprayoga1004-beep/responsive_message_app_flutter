import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../services/auth_service.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../utils/date_formatter.dart';
import '../../widgets/window_resizer_shortcut.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic> _reportData = {};
  
  // Filter parameters
  String _reportType = 'messages';
  String _dateRange = 'last_30_days';
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  String _userTypeFilter = 'all';
  String _statusFilter = 'all';
  String _priorityFilter = 'all';
  String _messageTypeFilter = 'all';
  String _groupBy = 'day';
  
  // UI State
  int _selectedTabIndex = 1;
  late TabController _tabController;
  
  // Data untuk ditampilkan
  Map<String, dynamic> _summary = {};
  List<dynamic> _timeSeries = [];
  List<dynamic> _typeBreakdown = [];
  List<dynamic> _priorityDist = [];
  List<dynamic> _details = [];
  List<dynamic> _messageTypes = [];
  
  // Scroll controllers untuk scrollbar horizontal
  final ScrollController _typeBreakdownScrollController = ScrollController();
  final ScrollController _detailDataScrollController = ScrollController();
  final ScrollController _detailResponsScrollController = ScrollController();
  
  // Date picker controllers
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();

  final List<String> _dateRangeOptions = [
    'today', 'yesterday', 'this_week', 'last_week', 'this_month', 'last_30_days', 'custom'
  ];
  final Map<String, String> _dateRangeLabels = {
    'today': 'Hari Ini',
    'yesterday': 'Kemarin',
    'this_week': 'Minggu Ini',
    'last_week': 'Minggu Lalu',
    'this_month': 'Bulan Ini',
    'last_30_days': '30 Hari',
    'custom': 'Kustom',
  };
  
  final List<String> _userTypeOptions = ['all', 'Siswa', 'Orang_Tua', 'Guru', 'Admin', 'External'];
  final Map<String, String> _userTypeLabels = {
    'all': 'Semua',
    'Siswa': 'Siswa',
    'Orang_Tua': 'Orang Tua',
    'Guru': 'Guru',
    'Admin': 'Admin',
    'External': 'External',
  };
  
  final List<String> _statusOptions = [
    'all', 'Pending', 'Dibaca', 'Diproses', 'Disetujui', 'Ditolak', 'Selesai'
  ];
  final Map<String, String> _statusLabels = {
    'all': 'Semua',
    'Pending': 'Pending',
    'Dibaca': 'Dibaca',
    'Diproses': 'Diproses',
    'Disetujui': 'Disetujui',
    'Ditolak': 'Ditolak',
    'Selesai': 'Selesai',
  };
  
  final List<String> _priorityOptions = ['all', 'Low', 'Medium', 'High', 'Urgent'];
  final Map<String, String> _priorityLabels = {
    'all': 'Semua',
    'Low': 'Rendah',
    'Medium': 'Sedang',
    'High': 'Tinggi',
    'Urgent': 'Mendesak',
  };
  
  final List<String> _groupByOptions = ['day', 'week', 'month'];
  final Map<String, String> _groupByLabels = {
    'day': 'Harian',
    'week': 'Mingguan',
    'month': 'Bulanan',
  };

  // ============================================================
  // HELPER FUNCTIONS
  // ============================================================
  
  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      return parsed ?? 0.0;
    }
    return 0.0;
  }
  
  String _formatAvgResponse(dynamic value) {
    final avg = _parseDouble(value);
    return '${avg.toStringAsFixed(1)} jam';
  }
  
  int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);
    _tabController.index = 1;
    _selectedTabIndex = 1;
    _startDateController.text = DateFormatter.formatDateShort(_startDate);
    _endDateController.text = DateFormatter.formatDateShort(_endDate);
    _loadMessageTypes();
    _loadReportData();
  }
  
  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    _typeBreakdownScrollController.dispose();
    _detailDataScrollController.dispose();
    _detailResponsScrollController.dispose();
    super.dispose();
  }
  
  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      setState(() {
        _selectedTabIndex = _tabController.index;
        switch (_selectedTabIndex) {
          case 0:
            _reportType = 'dashboard';
            break;
          case 1:
            _reportType = 'messages';
            break;
          case 2:
            _reportType = 'responses';
            break;
        }
      });
      _loadReportData();
    }
  }

  Future<void> _loadMessageTypes() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return;
      
      final url = Uri.parse('${Constants.baseUrl}/api/message_types/list.php');
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            _messageTypes = data['data'] ?? data['types'] ?? [];
          });
        }
      }
    } catch (e) {
      print('Error loading message types: $e');
    }
  }

  Future<void> _loadReportData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Not authenticated - token tidak ditemukan');
      }

      final url = Uri.parse('${Constants.baseUrl}/modules/admin/api/reports.php')
          .replace(queryParameters: {
        'report_type': _reportType,
        'start_date': _startDate.toIso8601String().split('T')[0],
        'end_date': _endDate.toIso8601String().split('T')[0],
        'user_type': _userTypeFilter,
        'status': _statusFilter,
        'priority': _priorityFilter,
        'message_type': _messageTypeFilter,
        'group_by': _groupBy,
      });

      print('📡 Loading report from: $url');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 60));

      print('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            _reportData = data['data'] ?? {};
            _summary = _reportData['summary'] ?? {};
            _timeSeries = _reportData['time_series'] ?? [];
            _typeBreakdown = _reportData['type_breakdown'] ?? [];
            _priorityDist = _reportData['priority_distribution'] ?? [];
            _details = _reportData['details'] ?? [];
            _isLoading = false;
          });
          print('✅ Report loaded: summary=${_summary.length}, time_series=${_timeSeries.length}, details=${_details.length}');
        } else {
          setState(() {
            _error = data['message'] ?? 'Gagal memuat laporan';
            _isLoading = false;
          });
        }
      } else if (response.statusCode == 401) {
        throw Exception('Session expired. Please login again.');
      } else if (response.statusCode == 404) {
        setState(() {
          _error = 'Endpoint API tidak ditemukan (404). Pastikan file modules/admin/api/reports.php sudah dibuat.';
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Server error: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading report: $e');
      setState(() {
        _error = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  void _updateDateRange(String range) {
    final now = DateTime.now();
    DateTime start;
    DateTime end = now;
    
    switch (range) {
      case 'today':
        start = now;
        end = now;
        break;
      case 'yesterday':
        start = now.subtract(const Duration(days: 1));
        end = start;
        break;
      case 'this_week':
        final daysToMonday = now.weekday == DateTime.monday ? 0 : now.weekday - DateTime.monday;
        start = now.subtract(Duration(days: daysToMonday));
        break;
      case 'last_week':
        final daysToLastMonday = (now.weekday - DateTime.monday) + 7;
        start = now.subtract(Duration(days: daysToLastMonday));
        end = start.add(const Duration(days: 6));
        break;
      case 'this_month':
        start = DateTime(now.year, now.month, 1);
        break;
      case 'last_30_days':
        start = now.subtract(const Duration(days: 30));
        break;
      default:
        start = _startDate;
        end = _endDate;
    }
    
    setState(() {
      _dateRange = range;
      _startDate = start;
      _endDate = end;
      _startDateController.text = DateFormatter.formatDateShort(_startDate);
      _endDateController.text = DateFormatter.formatDateShort(_endDate);
    });
    _loadReportData();
  }
  
  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: _endDate,
    );
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
        _startDateController.text = DateFormatter.formatDateShort(_startDate);
        _dateRange = 'custom';
      });
      _loadReportData();
    }
  }
  
  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _endDate) {
      setState(() {
        _endDate = picked;
        _endDateController.text = DateFormatter.formatDateShort(_endDate);
        _dateRange = 'custom';
      });
      _loadReportData();
    }
  }

  void _applyFilters() {
    _loadReportData();
  }
  
  void _resetFilters() {
    setState(() {
      _userTypeFilter = 'all';
      _statusFilter = 'all';
      _priorityFilter = 'all';
      _messageTypeFilter = 'all';
      _groupBy = 'day';
    });
    _loadReportData();
  }

  Future<void> _exportReport(String format) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final url = Uri.parse('${Constants.baseUrl}/modules/admin/api/reports.php')
          .replace(queryParameters: {
        'export': format,
        'report_type': _reportType,
        'start_date': _startDate.toIso8601String().split('T')[0],
        'end_date': _endDate.toIso8601String().split('T')[0],
        'user_type': _userTypeFilter,
        'status': _statusFilter,
        'priority': _priorityFilter,
        'message_type': _messageTypeFilter,
        'group_by': _groupBy,
      });
      
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 60));
      
      if (response.statusCode == 200) {
        Helpers.showToast(context, 'Laporan berhasil diekspor sebagai $format');
      } else {
        Helpers.showToast(context, 'Gagal mengekspor laporan: ${response.statusCode}', isError: true);
      }
    } catch (e) {
      Helpers.showToast(context, 'Error: $e', isError: true);
    }
  }

  String _formatNumber(dynamic value) {
    if (value == null) return '0';
    if (value is int) return value.toString();
    if (value is double) return value.toStringAsFixed(0);
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) return parsed.toString();
      return value;
    }
    return '0';
  }

  String _formatDateTime(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    try {
      final parts = dateStr.split(' ');
      if (parts.length >= 2) {
        final dateParts = parts[0].split('-');
        if (dateParts.length == 3) {
          return '${dateParts[2]}/${dateParts[1]}/${dateParts[0]} ${parts[1]}';
        }
      }
      return dateStr;
    } catch (e) {
      return dateStr;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Disetujui': return Colors.green;
      case 'Ditolak': return Colors.red;
      case 'Selesai': return Colors.teal;
      case 'Pending': return Colors.orange;
      case 'Dibaca': return Colors.cyan;
      case 'Diproses': return Colors.blue;
      default: return Colors.grey;
    }
  }
  
  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'Urgent': return Colors.red;
      case 'High': return Colors.orange;
      case 'Medium': return Colors.blue;
      case 'Low': return Colors.green;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return WindowResizerShortcut(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Laporan & Analitik'),
          backgroundColor: const Color(0xFF0B4D8A),
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Dashboard', icon: Icon(Icons.dashboard)),
              Tab(text: 'Laporan Pesan', icon: Icon(Icons.receipt_long)),
              Tab(text: 'Laporan Respons', icon: Icon(Icons.reply_all)),
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
              onPressed: _loadReportData,
              tooltip: 'Refresh',
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildErrorWidget()
                : Column(
                    children: [
                      _buildFilterBar(),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: _buildReportContent(),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 130,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Rentang Waktu', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 4),
                        DropdownButtonFormField<String>(
                          value: _dateRange,
                          isExpanded: true,
                          isDense: true,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                            isDense: true,
                          ),
                          items: _dateRangeOptions.map((range) {
                            return DropdownMenuItem(
                              value: range,
                              child: Text(_dateRangeLabels[range] ?? range, style: const TextStyle(fontSize: 11)),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) _updateDateRange(value);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 120,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Tanggal Mulai', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 4),
                        InkWell(
                          onTap: _selectStartDate,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade400),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 12, color: Colors.grey),
                                const SizedBox(width: 4),
                                Expanded(child: Text(_startDateController.text, style: const TextStyle(fontSize: 11))),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 120,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Tanggal Selesai', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 4),
                        InkWell(
                          onTap: _selectEndDate,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade400),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 12, color: Colors.grey),
                                const SizedBox(width: 4),
                                Expanded(child: Text(_endDateController.text, style: const TextStyle(fontSize: 11))),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 56,
                    child: Center(
                      child: ElevatedButton(
                        onPressed: _applyFilters,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0B4D8A),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          minimumSize: const Size(0, 0),
                        ),
                        child: const Text('Terapkan', style: TextStyle(fontSize: 11)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          if (_reportType == 'messages')
            Container(
              margin: const EdgeInsets.only(top: 12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: IntrinsicHeight(
                  child: Row(
                    children: [
                      SizedBox(
                        width: 105,
                        child: DropdownButtonFormField<String>(
                          value: _userTypeFilter,
                          isExpanded: true,
                          isDense: true,
                          decoration: const InputDecoration(
                            labelText: 'Tipe User',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                            isDense: true,
                          ),
                          items: _userTypeOptions.map((type) {
                            return DropdownMenuItem(
                              value: type,
                              child: Text(_userTypeLabels[type] ?? type, style: const TextStyle(fontSize: 10)),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() => _userTypeFilter = value!);
                            _applyFilters();
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 95,
                        child: DropdownButtonFormField<String>(
                          value: _statusFilter,
                          isExpanded: true,
                          isDense: true,
                          decoration: const InputDecoration(
                            labelText: 'Status',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                            isDense: true,
                          ),
                          items: _statusOptions.map((status) {
                            return DropdownMenuItem(
                              value: status,
                              child: Text(_statusLabels[status] ?? status, style: const TextStyle(fontSize: 10)),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() => _statusFilter = value!);
                            _applyFilters();
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 95,
                        child: DropdownButtonFormField<String>(
                          value: _priorityFilter,
                          isExpanded: true,
                          isDense: true,
                          decoration: const InputDecoration(
                            labelText: 'Prioritas',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                            isDense: true,
                          ),
                          items: _priorityOptions.map((priority) {
                            return DropdownMenuItem(
                              value: priority,
                              child: Text(_priorityLabels[priority] ?? priority, style: const TextStyle(fontSize: 10)),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() => _priorityFilter = value!);
                            _applyFilters();
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 125,
                        child: DropdownButtonFormField<String>(
                          value: _messageTypeFilter,
                          isExpanded: true,
                          isDense: true,
                          decoration: const InputDecoration(
                            labelText: 'Jenis Pesan',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                            isDense: true,
                          ),
                          items: [
                            const DropdownMenuItem(value: 'all', child: Text('Semua', style: TextStyle(fontSize: 10))),
                            ..._messageTypes.map((type) {
                              return DropdownMenuItem(
                                value: type['id'].toString(),
                                child: Text(type['jenis_pesan'] ?? 'Unknown', style: const TextStyle(fontSize: 10)),
                              );
                            }).toList(),
                          ],
                          onChanged: (value) {
                            setState(() => _messageTypeFilter = value!);
                            _applyFilters();
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 95,
                        child: DropdownButtonFormField<String>(
                          value: _groupBy,
                          isExpanded: true,
                          isDense: true,
                          decoration: const InputDecoration(
                            labelText: 'Group By',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                            isDense: true,
                          ),
                          items: _groupByOptions.map((group) {
                            return DropdownMenuItem(
                              value: group,
                              child: Text(_groupByLabels[group] ?? group, style: const TextStyle(fontSize: 10)),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() => _groupBy = value!);
                            _applyFilters();
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: _resetFilters,
                        icon: const Icon(Icons.refresh, size: 12),
                        label: const Text('Reset', style: TextStyle(fontSize: 10)),
                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
                      ),
                      const SizedBox(width: 4),
                      PopupMenuButton<String>(
                        onSelected: _exportReport,
                        icon: const Icon(Icons.download, size: 16),
                        tooltip: 'Export',
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: 'csv', child: Row(
                            children: [Icon(Icons.file_copy, color: Colors.green, size: 14), SizedBox(width: 6), Text('CSV', style: TextStyle(fontSize: 11))],
                          )),
                          const PopupMenuItem(value: 'json', child: Row(
                            children: [Icon(Icons.code, color: Colors.blue, size: 14), SizedBox(width: 6), Text('JSON', style: TextStyle(fontSize: 11))],
                          )),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReportContent() {
    switch (_reportType) {
      case 'messages':
        return _buildMessagesReport();
      case 'responses':
        return _buildResponsesReport();
      default:
        return _buildDashboardReport();
    }
  }

  Widget _buildDashboardReport() {
    final todayStats = _reportData['today_stats'] ?? {};
    final weeklyTrend = _reportData['weekly_trend'] ?? [];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _buildStatCard('Pesan Hari Ini', _formatNumber(todayStats['today_messages']), Icons.email, Colors.blue)),
            Expanded(child: _buildStatCard('Pending Hari Ini', _formatNumber(todayStats['today_pending']), Icons.hourglass_empty, Colors.orange)),
            Expanded(child: _buildStatCard('Selesai Hari Ini', _formatNumber(todayStats['today_completed']), Icons.check_circle, Colors.green)),
          ],
        ),
        const SizedBox(height: 24),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tren 7 Hari Terakhir', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 16),
                if (weeklyTrend.isEmpty)
                  const Center(child: Text('Tidak ada data tren'))
                else
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columnSpacing: 20,
                      headingRowColor: MaterialStateProperty.all(Colors.grey.shade100),
                      columns: const [
                        DataColumn(label: Text('Tanggal')),
                        DataColumn(label: Text('Jumlah')),
                      ],
                      rows: weeklyTrend.map<DataRow>((item) {
                        return DataRow(cells: [
                          DataCell(Text(item['date'] ?? '-')),
                          DataCell(Text(_formatNumber(item['total']), textAlign: TextAlign.right)),
                        ]);
                      }).toList(),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMessagesReport() {
    int _toInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }
    
    int totalMessages = _toInt(_summary['total_messages']);
    int pendingCount = _toInt(_summary['pending']);
    int diprosesCount = _toInt(_summary['diproses']);
    int dibacaCount = _toInt(_summary['dibaca']);
    int disetujuiCount = _toInt(_summary['disetujui']);
    int ditolakCount = _toInt(_summary['ditolak']);
    int selesaiCount = _toInt(_summary['selesai']);
    
    int completedCount = disetujuiCount + selesaiCount;
    
    if (completedCount == 0 && _details.isNotEmpty) {
      completedCount = _details.where((item) {
        final status = item['status']?.toString() ?? '';
        return status == 'Disetujui' || status == 'Selesai';
      }).length;
    }
    
    if (completedCount == 0 && _timeSeries.isNotEmpty) {
      completedCount = _timeSeries.fold<int>(0, (sum, item) {
        return sum + _toInt(item['completed']);
      });
    }
    
    int pendingTotal = pendingCount + dibacaCount + diprosesCount;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _buildStatCard('Total Pesan', totalMessages.toString(), Icons.email, Colors.blue)),
            Expanded(child: _buildStatCard('Selesai', completedCount.toString(), Icons.check_circle, Colors.green)),
            Expanded(child: _buildStatCard('Pending', pendingTotal.toString(), Icons.hourglass_empty, Colors.orange)),
            Expanded(child: _buildStatCard('Ditolak', ditolakCount.toString(), Icons.cancel, Colors.red)),
          ],
        ),
        const SizedBox(height: 24),
        
        if (_timeSeries.isNotEmpty) ...[
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Data Time Series', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columnSpacing: 16,
                      headingRowColor: MaterialStateProperty.all(Colors.grey.shade100),
                      columns: const [
                        DataColumn(label: Text('Periode', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Total', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Selesai', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Pending', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Ditolak', style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      rows: _timeSeries.map<DataRow>((item) {
                        return DataRow(cells: [
                          DataCell(Text(item['period'] ?? '-', style: const TextStyle(fontSize: 12))),
                          DataCell(Text(_formatNumber(item['total']), style: const TextStyle(fontSize: 12), textAlign: TextAlign.right)),
                          DataCell(Text(_formatNumber(item['completed']), style: const TextStyle(fontSize: 12), textAlign: TextAlign.right)),
                          DataCell(Text(_formatNumber(item['pending']), style: const TextStyle(fontSize: 12), textAlign: TextAlign.right)),
                          DataCell(Text(_formatNumber(item['rejected']), style: const TextStyle(fontSize: 12), textAlign: TextAlign.right)),
                        ]);
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
        
        if (_typeBreakdown.isNotEmpty) ...[
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Statistik per Jenis Pesan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  Scrollbar(
                    controller: _typeBreakdownScrollController,
                    thumbVisibility: true,
                    trackVisibility: true,
                    interactive: true,
                    thickness: 10,
                    radius: const Radius.circular(8),
                    child: SingleChildScrollView(
                      controller: _typeBreakdownScrollController,
                      scrollDirection: Axis.horizontal,
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: DataTable(
                        columnSpacing: 20,
                        headingRowColor: MaterialStateProperty.all(Colors.grey.shade100),
                        columns: const [
                          DataColumn(label: Text('Jenis Pesan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          DataColumn(label: Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          DataColumn(label: Text('Disetujui', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          DataColumn(label: Text('Ditolak', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          DataColumn(label: Text('Pending', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                        ],
                        rows: _typeBreakdown.map<DataRow>((item) {
                          return DataRow(cells: [
                            DataCell(Text(item['jenis_pesan'] ?? '-', style: const TextStyle(fontSize: 12))),
                            DataCell(Text(_formatNumber(item['total']), style: const TextStyle(fontSize: 12), textAlign: TextAlign.right)),
                            DataCell(Text(_formatNumber(item['approved']), style: const TextStyle(fontSize: 12), textAlign: TextAlign.right)),
                            DataCell(Text(_formatNumber(item['rejected']), style: const TextStyle(fontSize: 12), textAlign: TextAlign.right)),
                            DataCell(Text(_formatNumber(item['pending']), style: const TextStyle(fontSize: 12), textAlign: TextAlign.right)),
                          ]);
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
        
        if (_priorityDist.isNotEmpty) ...[
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Distribusi Prioritas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columnSpacing: 30,
                      headingRowColor: MaterialStateProperty.all(Colors.grey.shade100),
                      columns: const [
                        DataColumn(label: Text('Prioritas', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Total', style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      rows: _priorityDist.map<DataRow>((item) {
                        final priority = item['priority'] ?? '-';
                        return DataRow(cells: [
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getPriorityColor(priority).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(priority, style: TextStyle(fontSize: 12, color: _getPriorityColor(priority))),
                            ),
                          ),
                          DataCell(Text(_formatNumber(item['total']), style: const TextStyle(fontSize: 12), textAlign: TextAlign.right)),
                        ]);
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
        
        // ==================== DETAIL DATA TABLE DENGAN SCROLLBAR HORIZONTAL ====================
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Detail Data (${_details.length} data)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    TextButton.icon(
                      onPressed: () => _exportReport('csv'),
                      icon: const Icon(Icons.download, size: 16),
                      label: const Text('Export CSV', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_details.isEmpty)
                  const Center(child: Text('Tidak ada data detail'))
                else
                  Scrollbar(
                    controller: _detailDataScrollController,
                    thumbVisibility: true,
                    trackVisibility: true,
                    interactive: true,
                    thickness: 10,
                    radius: const Radius.circular(8),
                    child: SingleChildScrollView(
                      controller: _detailDataScrollController,
                      scrollDirection: Axis.horizontal,
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: DataTable(
                        columnSpacing: 12,
                        headingRowColor: MaterialStateProperty.all(Colors.grey.shade100),
                        columns: const [
                          DataColumn(label: Text('ID', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                          DataColumn(label: Text('Ref', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                          DataColumn(label: Text('Tanggal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                          DataColumn(label: Text('Jenis', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                          DataColumn(label: Text('Pengirim', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                          DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                          DataColumn(label: Text('Prioritas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                          DataColumn(label: Text('Pesan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                          DataColumn(label: Text('Waktu Respons', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                        ],
                        rows: _details.map<DataRow>((item) {
                          final pengirimTipe = item['pengirim_tipe'] ?? '';
                          final isExternal = pengirimTipe == 'External' || item['is_external'] == 1;
                          final tipeDisplay = isExternal ? 'External' : (pengirimTipe.replaceAll('_', ' ') == 'Orang Tua' ? 'Orang Tua' : pengirimTipe);
                          
                          return DataRow(cells: [
                            DataCell(Text('${item['id'] ?? '-'}', style: const TextStyle(fontSize: 11))),
                            DataCell(Text(item['reference_number'] ?? '-', style: const TextStyle(fontSize: 11))),
                            DataCell(Text(_formatDateTime(item['tanggal_pesan']), style: const TextStyle(fontSize: 11))),
                            DataCell(Text(item['jenis_pesan'] ?? '-', style: const TextStyle(fontSize: 11))),
                            DataCell(
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item['pengirim_nama'] ?? '-', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
                                  if (tipeDisplay.isNotEmpty && tipeDisplay != '-')
                                    Text(tipeDisplay, style: const TextStyle(fontSize: 9, color: Colors.grey)),
                                ],
                              ),
                            ),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(item['status'] ?? '').withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(item['status'] ?? '-', style: TextStyle(fontSize: 10, color: _getStatusColor(item['status'] ?? ''))),
                              ),
                            ),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _getPriorityColor(item['priority'] ?? '').withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(item['priority'] ?? '-', style: TextStyle(fontSize: 10, color: _getPriorityColor(item['priority'] ?? ''))),
                              ),
                            ),
                            DataCell(SizedBox(width: 200, child: Text(item['isi_pesan_ringkas'] ?? '-', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11)))),
                            DataCell(
                              Text(item['response_time'] ?? '-', 
                                style: TextStyle(fontSize: 11, color: item['response_time'] != null && item['response_time'] != '-' ? Colors.green : Colors.grey)),
                            ),
                          ]);
                        }).toList(),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        
        if (_details.isEmpty && _timeSeries.isEmpty)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: Text('Tidak ada data untuk periode yang dipilih')),
          ),
      ],
    );
  }

  Widget _buildResponsesReport() {
    final summary = _reportData['summary'] ?? {};
    final statusStats = _reportData['status_stats'] ?? [];
    final details = _reportData['details'] ?? [];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _buildStatCard('Total Pesan', _formatNumber(summary['total_messages']), Icons.email, Colors.blue)),
            Expanded(child: _buildStatCard('Sudah Direspons', _formatNumber(summary['responded']), Icons.reply_all, Colors.green)),
            Expanded(child: _buildStatCard('Rata Respons', _formatAvgResponse(summary['avg_response_hours']), Icons.timer, Colors.orange)),
            Expanded(child: _buildStatCard('Terlambat', _formatNumber(summary['late_responses']), Icons.warning, Colors.red)),
          ],
        ),
        const SizedBox(height: 24),
        
        if (statusStats.isNotEmpty) ...[
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Statistik per Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columnSpacing: 20,
                      headingRowColor: MaterialStateProperty.all(Colors.grey.shade100),
                      columns: const [
                        DataColumn(label: Text('Status')),
                        DataColumn(label: Text('Total')),
                        DataColumn(label: Text('Direspons')),
                      ],
                      rows: statusStats.map<DataRow>((item) {
                        return DataRow(cells: [
                          DataCell(Text(item['status'] ?? '-')),
                          DataCell(Text(_formatNumber(item['total']), textAlign: TextAlign.right)),
                          DataCell(Text(_formatNumber(item['responded']), textAlign: TextAlign.right)),
                        ]);
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
        
        // ==================== DETAIL RESPONS TABLE DENGAN SCROLLBAR HORIZONTAL ====================
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Detail Respons (${details.length} data)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    TextButton.icon(
                      onPressed: () => _exportReport('csv'),
                      icon: const Icon(Icons.download, size: 16),
                      label: const Text('Export CSV', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (details.isEmpty)
                  const Center(child: Text('Tidak ada data respons'))
                else
                  Scrollbar(
                    controller: _detailResponsScrollController,
                    thumbVisibility: true,
                    trackVisibility: true,
                    interactive: true,
                    thickness: 10,
                    radius: const Radius.circular(8),
                    child: SingleChildScrollView(
                      controller: _detailResponsScrollController,
                      scrollDirection: Axis.horizontal,
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: DataTable(
                        columnSpacing: 12,
                        headingRowColor: MaterialStateProperty.all(Colors.grey.shade100),
                        columns: const [
                          DataColumn(label: Text('ID', style: TextStyle(fontSize: 11))),
                          DataColumn(label: Text('Ref', style: TextStyle(fontSize: 11))),
                          DataColumn(label: Text('Jenis', style: TextStyle(fontSize: 11))),
                          DataColumn(label: Text('Pengirim', style: TextStyle(fontSize: 11))),
                          DataColumn(label: Text('Tgl Pesan', style: TextStyle(fontSize: 11))),
                          DataColumn(label: Text('Tgl Respons', style: TextStyle(fontSize: 11))),
                          DataColumn(label: Text('Durasi', style: TextStyle(fontSize: 11))),
                          DataColumn(label: Text('Status', style: TextStyle(fontSize: 11))),
                        ],
                        rows: details.map<DataRow>((item) {
                          return DataRow(cells: [
                            DataCell(Text('${item['id'] ?? '-'}', style: const TextStyle(fontSize: 11))),
                            DataCell(Text(item['reference_number'] ?? '-', style: const TextStyle(fontSize: 11))),
                            DataCell(Text(item['jenis_pesan'] ?? '-', style: const TextStyle(fontSize: 11))),
                            DataCell(Text(item['pengirim'] ?? '-', style: const TextStyle(fontSize: 11))),
                            DataCell(Text(item['tanggal_pesan'] ?? '-', style: const TextStyle(fontSize: 11))),
                            DataCell(Text(item['tanggal_respon'] ?? '-', style: const TextStyle(fontSize: 11))),
                            DataCell(Text('${item['response_hours'] ?? 0} jam', style: const TextStyle(fontSize: 11))),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(item['status'] ?? '').withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(item['status'] ?? '-', style: TextStyle(fontSize: 10, color: _getStatusColor(item['status'] ?? ''))),
                              ),
                            ),
                          ]);
                        }).toList(),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.all(4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(_error!, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadReportData,
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }
}