// lib/screen/admin/analytics_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../main.dart'; // Import untuk WindowResizerShortcut
import '../utils/environment.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() {
    print('✅ AnalyticsScreen created! - Navigasi berhasil ke halaman Analitik Dashboard');
    return _AnalyticsScreenState();
  }
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final String _apiUrl = '${Environment.baseUrl}/api';
  
  bool _isLoading = true;
  String? _errorMsg;
  
  // Date range
  String _selectedPreset = 'last30days';
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  
  // Analytics data
  Map<String, dynamic> _overview = {};
  List<dynamic> _statusStats = [];
  List<dynamic> _priorityStats = [];
  Map<String, dynamic> _dailyTrends = {};
  List<dynamic> _responseTimeDist = [];
  List<dynamic> _messageTypes = [];
  List<dynamic> _teacherPerformance = [];
  List<dynamic> _userGrowth = [];
  Map<String, dynamic> _externalSenders = {};
  Map<String, dynamic> _slaCompliance = {};
  
  final List<Map<String, dynamic>> _presets = [
    {'label': 'Today', 'value': 'today', 'days': 0},
    {'label': 'Yesterday', 'value': 'yesterday', 'days': 1},
    {'label': '7 Days', 'value': 'last7days', 'days': 7},
    {'label': '30 Days', 'value': 'last30days', 'days': 30},
    {'label': '90 Days', 'value': 'last90days', 'days': 90},
    {'label': 'This Month', 'value': 'thisMonth', 'days': null},
    {'label': 'Last Month', 'value': 'lastMonth', 'days': null},
    {'label': 'This Year', 'value': 'thisYear', 'days': null},
  ];
  
  @override
  void initState() {
    super.initState();
    print('📊 AnalyticsScreen initState - Memuat data analitik...');
    _loadAnalytics();
  }
  
  Future<String?> _getAuthCookie() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('session_id') ?? prefs.getString('RMSESSID');
  }
  
  // Helper function to safely convert to double
  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }
  
  // Helper function to safely convert to int
  int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }
  
  Future<void> _loadAnalytics() async {
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });
    
    final cookie = await _getAuthCookie();
    final url = Uri.parse('$_apiUrl/analytics.php?action=all&preset=$_selectedPreset');
    
    print('📡 Memuat data analitik dari: $url');
    
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (cookie != null) 'Cookie': 'RMSESSID=$cookie',
        },
      );
      
      print('📡 Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final overviewData = data['data']['overview'] ?? {};
          setState(() {
            _overview = {
              'total_messages': _toInt(overviewData['total_messages']),
              'resolved_messages': _toInt(overviewData['resolved_messages']),
              'avg_response_time': _toDouble(overviewData['avg_response_time']),
              'external_senders': _toInt(overviewData['external_senders']),
              'external_messages': _toInt(overviewData['external_messages']),
              'trend_percentage': _toDouble(overviewData['trend_percentage']),
              'trend_direction': overviewData['trend_direction'] ?? 'up',
            };
            
            _statusStats = (data['data']['status_stats'] ?? []).map((stat) {
              return {
                'status': stat['status'],
                'total': _toInt(stat['total']),
                'percentage': _toDouble(stat['percentage']),
                'color': stat['color'] ?? '#6c757d'
              };
            }).toList();
            
            _priorityStats = (data['data']['priority_stats'] ?? []).map((stat) {
              return {
                'priority': stat['priority'],
                'total': _toInt(stat['total']),
                'percentage': _toDouble(stat['percentage']),
                'color': stat['color'] ?? '#6c757d'
              };
            }).toList();
            
            final dailyData = data['data']['daily_trends'] ?? {};
            _dailyTrends = {
              'daily': (dailyData['daily'] ?? []).map((item) {
                return {
                  'date': item['date'],
                  'total_messages': _toInt(item['total_messages']),
                  'external_messages': _toInt(item['external_messages']),
                };
              }).toList(),
              'moving_avg': (dailyData['moving_avg'] ?? []).map((val) => _toDouble(val)).toList(),
            };
            
            _responseTimeDist = (data['data']['response_time'] ?? []).map((item) {
              return {
                'response_range': item['response_range'],
                'total': _toInt(item['total']),
                'percentage': _toDouble(item['percentage']),
              };
            }).toList();
            
            _messageTypes = (data['data']['message_types'] ?? []).map((type) {
              return {
                'jenis_pesan': type['jenis_pesan'],
                'total': _toInt(type['total']),
                'external_count': _toInt(type['external_count']),
                'resolved_count': _toInt(type['resolved_count']),
                'avg_response_time': _toDouble(type['avg_response_time']),
              };
            }).toList();
            
            _teacherPerformance = (data['data']['teacher_performance'] ?? []).map((teacher) {
              return {
                'nama_lengkap': teacher['nama_lengkap'],
                'messages_handled': _toInt(teacher['messages_handled']),
                'responses_given': _toInt(teacher['responses_given']),
                'avg_response_time': _toDouble(teacher['avg_response_time']),
                'resolved_messages': _toInt(teacher['resolved_messages']),
                'sla_compliance': _toDouble(teacher['sla_compliance']),
              };
            }).toList();
            
            _userGrowth = (data['data']['user_growth'] ?? []).map((item) {
              return {
                'date': item['date'],
                'new_users': _toInt(item['new_users']),
                'new_teachers': _toInt(item['new_teachers']),
                'new_students': _toInt(item['new_students']),
              };
            }).toList();
            
            final externalData = data['data']['external_senders'] ?? {};
            _externalSenders = {
              'total_senders': _toInt(externalData['total_senders']),
              'total_messages': _toInt(externalData['total_messages']),
              'avg_response_time': _toDouble(externalData['avg_response_time']),
              'resolved_messages': _toInt(externalData['resolved_messages']),
              'message_types_used': _toInt(externalData['message_types_used']),
            };
            
            final slaData = data['data']['sla_compliance'] ?? {};
            _slaCompliance = {
              'total_resolved': _toInt(slaData['total_resolved']),
              'within_sla': _toInt(slaData['within_sla']),
              'compliance_rate': _toDouble(slaData['compliance_rate']),
              'avg_overdue_hours': _toDouble(slaData['avg_overdue_hours']),
              'responders_count': _toInt(slaData['responders_count']),
            };
            
            _isLoading = false;
          });
          print('✅ Data analitik berhasil dimuat');
        } else {
          setState(() {
            _errorMsg = data['message'] ?? 'Gagal memuat data';
            _isLoading = false;
          });
          print('❌ Gagal memuat data: ${data['message']}');
        }
      } else {
        setState(() {
          _errorMsg = 'Gagal terhubung ke server';
          _isLoading = false;
        });
        print('❌ Gagal terhubung ke server, status code: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _errorMsg = 'Error: $e';
        _isLoading = false;
      });
      print('❌ Error loading analytics: $e');
    }
  }
  
  Future<void> _loadWithDateRange() async {
    setState(() {
      _selectedPreset = 'custom';
      _isLoading = true;
    });
    
    final cookie = await _getAuthCookie();
    final url = Uri.parse(
      '$_apiUrl/analytics.php?action=all&start_date=${_startDate.toIso8601String().split('T')[0]}&end_date=${_endDate.toIso8601String().split('T')[0]}'
    );
    
    print('📡 Memuat data dengan custom date range: $url');
    
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (cookie != null) 'Cookie': 'RMSESSID=$cookie',
        },
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final overviewData = data['data']['overview'] ?? {};
          setState(() {
            _overview = {
              'total_messages': _toInt(overviewData['total_messages']),
              'resolved_messages': _toInt(overviewData['resolved_messages']),
              'avg_response_time': _toDouble(overviewData['avg_response_time']),
              'external_senders': _toInt(overviewData['external_senders']),
              'external_messages': _toInt(overviewData['external_messages']),
              'trend_percentage': _toDouble(overviewData['trend_percentage']),
              'trend_direction': overviewData['trend_direction'] ?? 'up',
            };
            
            _statusStats = (data['data']['status_stats'] ?? []).map((stat) {
              return {
                'status': stat['status'],
                'total': _toInt(stat['total']),
                'percentage': _toDouble(stat['percentage']),
                'color': stat['color'] ?? '#6c757d'
              };
            }).toList();
            
            _priorityStats = (data['data']['priority_stats'] ?? []).map((stat) {
              return {
                'priority': stat['priority'],
                'total': _toInt(stat['total']),
                'percentage': _toDouble(stat['percentage']),
                'color': stat['color'] ?? '#6c757d'
              };
            }).toList();
            
            final dailyData = data['data']['daily_trends'] ?? {};
            _dailyTrends = {
              'daily': (dailyData['daily'] ?? []).map((item) {
                return {
                  'date': item['date'],
                  'total_messages': _toInt(item['total_messages']),
                  'external_messages': _toInt(item['external_messages']),
                };
              }).toList(),
              'moving_avg': (dailyData['moving_avg'] ?? []).map((val) => _toDouble(val)).toList(),
            };
            
            _responseTimeDist = (data['data']['response_time'] ?? []).map((item) {
              return {
                'response_range': item['response_range'],
                'total': _toInt(item['total']),
                'percentage': _toDouble(item['percentage']),
              };
            }).toList();
            
            _messageTypes = (data['data']['message_types'] ?? []).map((type) {
              return {
                'jenis_pesan': type['jenis_pesan'],
                'total': _toInt(type['total']),
                'external_count': _toInt(type['external_count']),
                'resolved_count': _toInt(type['resolved_count']),
                'avg_response_time': _toDouble(type['avg_response_time']),
              };
            }).toList();
            
            _teacherPerformance = (data['data']['teacher_performance'] ?? []).map((teacher) {
              return {
                'nama_lengkap': teacher['nama_lengkap'],
                'messages_handled': _toInt(teacher['messages_handled']),
                'responses_given': _toInt(teacher['responses_given']),
                'avg_response_time': _toDouble(teacher['avg_response_time']),
                'resolved_messages': _toInt(teacher['resolved_messages']),
                'sla_compliance': _toDouble(teacher['sla_compliance']),
              };
            }).toList();
            
            _userGrowth = (data['data']['user_growth'] ?? []).map((item) {
              return {
                'date': item['date'],
                'new_users': _toInt(item['new_users']),
                'new_teachers': _toInt(item['new_teachers']),
                'new_students': _toInt(item['new_students']),
              };
            }).toList();
            
            final externalData = data['data']['external_senders'] ?? {};
            _externalSenders = {
              'total_senders': _toInt(externalData['total_senders']),
              'total_messages': _toInt(externalData['total_messages']),
              'avg_response_time': _toDouble(externalData['avg_response_time']),
              'resolved_messages': _toInt(externalData['resolved_messages']),
              'message_types_used': _toInt(externalData['message_types_used']),
            };
            
            final slaData = data['data']['sla_compliance'] ?? {};
            _slaCompliance = {
              'total_resolved': _toInt(slaData['total_resolved']),
              'within_sla': _toInt(slaData['within_sla']),
              'compliance_rate': _toDouble(slaData['compliance_rate']),
              'avg_overdue_hours': _toDouble(slaData['avg_overdue_hours']),
              'responders_count': _toInt(slaData['responders_count']),
            };
            
            _isLoading = false;
          });
          print('✅ Data dengan custom date range berhasil dimuat');
        } else {
          setState(() {
            _errorMsg = data['message'] ?? 'Gagal memuat data';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _errorMsg = 'Error: $e';
        _isLoading = false;
      });
      print('❌ Error loading analytics with date range: $e');
    }
  }
  
  void _selectPreset(String preset) {
    print('📅 Memilih preset: $preset');
    setState(() {
      _selectedPreset = preset;
    });
    _loadAnalytics();
  }
  
  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );
    
    if (picked != null) {
      print('📅 Custom date range dipilih: ${picked.start} - ${picked.end}');
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadWithDateRange();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    print('🏗️ Membangun UI AnalyticsScreen');
    // Membungkus dengan WindowResizerShortcut
    return WindowResizerShortcut(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Analitik Dashboard'),
          backgroundColor: const Color(0xFF0B4D8A),
          actions: [
            IconButton(
              icon: const Icon(Icons.aspect_ratio),
              onPressed: () => WindowResizerExtension.showResizerPanel(context),
              tooltip: 'Ubah Ukuran Window (F2)',
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadAnalytics,
              tooltip: 'Refresh',
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: SpinKitFadingCircle(color: Color(0xFF0B4D8A), size: 50))
            : _errorMsg != null
                ? _buildErrorWidget()
                : RefreshIndicator(
                    onRefresh: _loadAnalytics,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDateRangeSelector(),
                          const SizedBox(height: 20),
                          _buildKPICards(),
                          const SizedBox(height: 24),
                          _buildDailyTrendsChart(),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(child: _buildStatusChart()),
                              const SizedBox(width: 16),
                              Expanded(child: _buildPriorityChart()),
                            ],
                          ),
                          const SizedBox(height: 24),
                          _buildResponseTimeChart(),
                          const SizedBox(height: 24),
                          _buildMessageTypesTable(),
                          const SizedBox(height: 24),
                          _buildTeacherPerformanceTable(),
                          const SizedBox(height: 24),
                          _buildExternalSendersCard(),
                        ],
                      ),
                    ),
                  ),
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
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(_errorMsg!, textAlign: TextAlign.center),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadAnalytics,
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDateRangeSelector() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _presets.map((preset) {
                  final isSelected = _selectedPreset == preset['value'];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: FilterChip(
                      label: Text(preset['label']),
                      selected: isSelected,
                      onSelected: (_) => _selectPreset(preset['value']),
                      backgroundColor: Colors.grey[200],
                      selectedColor: const Color(0xFF0B4D8A).withOpacity(0.2),
                      labelStyle: TextStyle(
                        color: isSelected ? const Color(0xFF0B4D8A) : Colors.black87,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _selectDateRange,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.calendar_today, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      '${DateFormat('dd/MM/yyyy').format(_startDate)} - ${DateFormat('dd/MM/yyyy').format(_endDate)}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildKPICards() {
    // Konversi semua data dengan helper functions
    int totalMessages = _toInt(_overview['total_messages']);
    int resolvedMessages = _toInt(_overview['resolved_messages']);
    double avgResponseTime = _toDouble(_overview['avg_response_time']);
    int externalSenders = _toInt(_overview['external_senders']);
    int externalMessages = _toInt(_overview['external_messages']);
    double trendPercentage = _toDouble(_overview['trend_percentage']);
    String trendDirection = _overview['trend_direction'] ?? 'up';
    
    int slaTotalResolved = _toInt(_slaCompliance['total_resolved']);
    int slaWithinSla = _toInt(_slaCompliance['within_sla']);
    double slaComplianceRate = _toDouble(_slaCompliance['compliance_rate']);
    int respondersCount = _toInt(_slaCompliance['responders_count']);
    
    // Hitung resolution rate dengan aman
    double resolutionRate = 0;
    if (totalMessages > 0) {
      resolutionRate = (resolvedMessages / totalMessages * 100);
      resolutionRate = double.parse(resolutionRate.toStringAsFixed(1));
    }
    
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.8,
      children: [
        _buildKPICard(
          'Total Pesan',
          totalMessages.toString(),
          Icons.email,
          Colors.blue,
          trendPercentage,
          trendDirection,
        ),
        _buildKPICard(
          'Terselesaikan',
          resolvedMessages.toString(),
          Icons.check_circle,
          Colors.green,
          null,
          null,
          subtitle: '$resolutionRate% dari total',
        ),
        _buildKPICard(
          'Rata-rata Respons',
          '${avgResponseTime.toStringAsFixed(1)}h',
          Icons.timer,
          Colors.orange,
          null,
          null,
        ),
        _buildKPICard(
          'Eksternal',
          externalSenders.toString(),
          Icons.public,
          Colors.purple,
          null,
          null,
          subtitle: '$externalMessages pesan',
        ),
        _buildKPICard(
          'SLA Compliance',
          '${slaComplianceRate.toStringAsFixed(1)}%',
          Icons.verified,
          Colors.teal,
          null,
          null,
          subtitle: '$slaWithinSla/$slaTotalResolved',
        ),
        _buildKPICard(
          'Guru Aktif',
          respondersCount.toString(),
          Icons.people,
          Colors.indigo,
          null,
          null,
        ),
      ],
    );
  }
  
  Widget _buildKPICard(
    String title,
    String value,
    IconData icon,
    Color color,
    dynamic trend,
    String? trendDirection, {
    String? subtitle,
  }) {
    // Konversi trend ke double dengan aman
    double? trendValue;
    if (trend != null) {
      if (trend is double) {
        trendValue = trend;
      } else if (trend is int) {
        trendValue = trend.toDouble();
      } else if (trend is String) {
        trendValue = double.tryParse(trend);
      }
    }
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                if (trendValue != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: (trendDirection == 'up' ? Colors.green : Colors.red).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          trendDirection == 'up' ? Icons.arrow_upward : Icons.arrow_downward,
                          size: 12,
                          color: trendDirection == 'up' ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${trendValue.abs().toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: trendDirection == 'up' ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            if (subtitle != null)
              Text(
                subtitle,
                style: TextStyle(fontSize: 10, color: Colors.grey[500]),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDailyTrendsChart() {
    final dailyData = _dailyTrends['daily'] ?? [];
    if (dailyData.isEmpty) {
      return _buildEmptyChart('Belum ada data harian');
    }
    
    final labels = dailyData.map((e) {
      final date = DateTime.parse(e['date']);
      return DateFormat('dd/MM').format(date);
    }).toList();
    
    final messages = dailyData.map<int>((e) => _toInt(e['total_messages'])).toList();
    final external = dailyData.map<int>((e) => _toInt(e['external_messages'])).toList();
    final movingAvg = (_dailyTrends['moving_avg'] ?? []).map<double>((val) => _toDouble(val)).toList();
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tren Pesan Harian',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < labels.length) {
                            return Text(labels[index], style: const TextStyle(fontSize: 10));
                          }
                          return const Text('');
                        },
                        reservedSize: 30,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                    ),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: List.generate(messages.length, (i) => FlSpot(i.toDouble(), messages[i].toDouble())),
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 2,
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(show: true, color: Colors.blue.withOpacity(0.1)),
                    ),
                    LineChartBarData(
                      spots: List.generate(external.length, (i) => FlSpot(i.toDouble(), external[i].toDouble())),
                      isCurved: true,
                      color: Colors.orange,
                      barWidth: 2,
                      dotData: FlDotData(show: false),
                    ),
                    if (movingAvg.isNotEmpty)
                      LineChartBarData(
                        spots: List.generate(movingAvg.length, (i) => FlSpot(i.toDouble(), movingAvg[i].toDouble())),
                        isCurved: true,
                        color: Colors.red,
                        barWidth: 2,
                        dashArray: [5, 5],
                        dotData: FlDotData(show: false),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              children: [
                _buildLegend('Total Pesan', Colors.blue),
                _buildLegend('Eksternal', Colors.orange),
                if (movingAvg.isNotEmpty) _buildLegend('Moving Average (7d)', Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildLegend(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, color: color),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10)),
      ],
    );
  }
  
  Widget _buildStatusChart() {
    if (_statusStats.isEmpty) {
      return _buildEmptyChart('Tidak ada data status');
    }
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Status Pesan',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: _statusStats.map((stat) {
                    return PieChartSectionData(
                      value: _toDouble(stat['total']),
                      title: '${_toDouble(stat['percentage']).toStringAsFixed(1)}%',
                      color: _hexToColor(stat['color'] ?? '#6c757d'),
                      radius: 60,
                      titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                    );
                  }).toList(),
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _statusStats.map((stat) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _hexToColor(stat['color'] ?? '#6c757d').withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${stat['status']}: ${_toInt(stat['total'])}',
                    style: TextStyle(fontSize: 10, color: _hexToColor(stat['color'] ?? '#6c757d')),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPriorityChart() {
    if (_priorityStats.isEmpty) {
      return _buildEmptyChart('Tidak ada data prioritas');
    }
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Prioritas Pesan',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: _priorityStats.map((stat) {
                    return PieChartSectionData(
                      value: _toDouble(stat['total']),
                      title: '${_toDouble(stat['percentage']).toStringAsFixed(1)}%',
                      color: _hexToColor(stat['color'] ?? '#6c757d'),
                      radius: 60,
                      titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                    );
                  }).toList(),
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _priorityStats.map((stat) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _hexToColor(stat['color'] ?? '#6c757d').withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${stat['priority']}: ${_toInt(stat['total'])}',
                    style: TextStyle(fontSize: 10, color: _hexToColor(stat['color'] ?? '#6c757d')),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildResponseTimeChart() {
    if (_responseTimeDist.isEmpty) {
      return _buildEmptyChart('Tidak ada data waktu respons');
    }
    
    final maxValue = _responseTimeDist.map<double>((e) => _toDouble(e['total'])).reduce((a, b) => a > b ? a : b);
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Distribusi Waktu Respons',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxValue + 5,
                  barGroups: _responseTimeDist.asMap().entries.map((entry) {
                    final index = entry.key;
                    final data = entry.value;
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: _toDouble(data['total']),
                          color: Colors.blue,
                          width: 30,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    );
                  }).toList(),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < _responseTimeDist.length) {
                            return Text(
                              _responseTimeDist[index]['response_range'] ?? '',
                              style: const TextStyle(fontSize: 10),
                              overflow: TextOverflow.ellipsis,
                            );
                          }
                          return const Text('');
                        },
                        reservedSize: 50,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                    ),
                  ),
                  gridData: FlGridData(show: true),
                  borderData: FlBorderData(show: true),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMessageTypesTable() {
  if (_messageTypes.isEmpty) {
    return const SizedBox();
  }
  
  return Card(
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Statistik per Jenis Pesan',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Scrollbar(
            thumbVisibility: true,
            trackVisibility: true,
            interactive: true,
            thickness: 10,
            radius: const Radius.circular(8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const AlwaysScrollableScrollPhysics(),
              child: DataTable(
                columnSpacing: 12,
                headingRowColor: WidgetStateProperty.resolveWith(
                  (states) => Colors.grey[100],
                ),
                columns: const [
                  DataColumn(label: Text('Jenis Pesan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  DataColumn(label: Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  DataColumn(label: Text('Eksternal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  DataColumn(label: Text('Terselesaikan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  DataColumn(label: Text('Rata-rata', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                ],
                rows: _messageTypes.map((type) {
                  return DataRow(cells: [
                    DataCell(Text(type['jenis_pesan'] ?? '-', maxLines: 1, overflow: TextOverflow.ellipsis)),
                    DataCell(Text((_toInt(type['total'])).toString())),
                    DataCell(Text((_toInt(type['external_count'])).toString())),
                    DataCell(Text((_toInt(type['resolved_count'])).toString())),
                    DataCell(Text(type['avg_response_time'] != null ? '${_toDouble(type['avg_response_time'])}h' : '-')),
                  ]);
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
  
  Widget _buildTeacherPerformanceTable() {
    if (_teacherPerformance.isEmpty) {
      return const SizedBox();
    }
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Performa Guru Terbaik',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 12,
                columns: const [
                  DataColumn(label: Text('No', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Nama Guru', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Pesan', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Respons', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Rata-rata', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Selesai', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('SLA', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
                rows: _teacherPerformance.asMap().entries.map((entry) {
                  final index = entry.key;
                  final teacher = entry.value;
                  return DataRow(cells: [
                    DataCell(Text((index + 1).toString())),
                    DataCell(Text(teacher['nama_lengkap'] ?? '-', maxLines: 1, overflow: TextOverflow.ellipsis)),
                    DataCell(Text((_toInt(teacher['messages_handled'])).toString())),
                    DataCell(Text((_toInt(teacher['responses_given'])).toString())),
                    DataCell(Text('${_toDouble(teacher['avg_response_time'])}h')),
                    DataCell(Text((_toInt(teacher['resolved_messages'])).toString())),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getSLAColor(_toDouble(teacher['sla_compliance'])).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_toDouble(teacher['sla_compliance']).toStringAsFixed(1)}%',
                          style: TextStyle(color: _getSLAColor(_toDouble(teacher['sla_compliance'])), fontSize: 12),
                        ),
                      ),
                    ),
                  ]);
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildExternalSendersCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ringkasan Pengirim Eksternal',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildExternalStat(
                    'Total Sender',
                    _toInt(_externalSenders['total_senders']).toString(),
                    Icons.people,
                    Colors.purple,
                  ),
                ),
                Expanded(
                  child: _buildExternalStat(
                    'Total Pesan',
                    _toInt(_externalSenders['total_messages']).toString(),
                    Icons.email,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildExternalStat(
                    'Rata-rata Respons',
                    '${_toDouble(_externalSenders['avg_response_time']).toStringAsFixed(1)}h',
                    Icons.timer,
                    Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildExternalStat(
                    'Terselesaikan',
                    _toInt(_externalSenders['resolved_messages']).toString(),
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildExternalStat(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
          ),
          Text(title, style: TextStyle(fontSize: 10, color: Colors.grey[600]), textAlign: TextAlign.center),
        ],
      ),
    );
  }
  
  Widget _buildEmptyChart(String message) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.bar_chart, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 8),
              Text(message, style: TextStyle(color: Colors.grey[600])),
            ],
          ),
        ),
      ),
    );
  }
  
  Color _hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex';
    }
    return Color(int.parse(hex, radix: 16));
  }
  
  Color _getSLAColor(double percentage) {
    if (percentage >= 90) return Colors.green;
    if (percentage >= 70) return Colors.orange;
    return Colors.red;
  }
}