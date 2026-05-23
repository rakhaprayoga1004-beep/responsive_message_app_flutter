// lib/screens/guru/dashboard_guru_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/auth_service.dart';
import '../../providers/auth_provider.dart';
import '../../models/followup_models.dart';
import '../../widgets/message_detail_dialog.dart';
import '../../widgets/window_resizer_shortcut.dart';
import 'followup_screen.dart';
import '../../utils/environment.dart';

class DashboardGuruScreen extends StatefulWidget {
  const DashboardGuruScreen({super.key});

  @override
  State<DashboardGuruScreen> createState() => _DashboardGuruScreenState();
}

class _DashboardGuruScreenState extends State<DashboardGuruScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedTimeFilter = 'all';
  
  // Data dari followup API
  FollowupResponse? _followupResponse;
  List<FollowupMessage> _allMessages = [];
  
  // Data agregasi untuk dashboard berdasarkan filter waktu
  Map<String, dynamic> _aggregatedStats = {};
  List<Map<String, dynamic>> _statusDistribution = [];
  List<Map<String, dynamic>> _recentActivity = [];
  List<Map<String, dynamic>> _paginatedActivity = [];
  Map<String, dynamic> _reviewStats = {};
  
  // Pagination untuk recent activity
  int _activityCurrentPage = 1;
  int _activityTotalPages = 1;
  int _activityPerPage = 5;
  
  // Data untuk trend chart
  List<String> _chartLabels = [];
  List<double> _chartPendingData = [];
  List<double> _chartDibacaData = [];
  List<double> _chartDiprosesData = [];
  List<double> _chartDisetujuiData = [];
  List<double> _chartDitolakData = [];
  List<double> _chartSelesaiData = [];
  
  String _guruName = '';
  String _guruType = '';
  String _assignedType = '';
  String _dateRangeText = 'Semua Waktu';

  final List<String> _timeFilterOptions = ['all', '7days', '30days', '90days', 'year'];
  final Map<String, String> _timeFilterLabels = {
    'all': 'Semua Waktu',
    '7days': '7 Hari Terakhir',
    '30days': '30 Hari Terakhir',
    '90days': '90 Hari Terakhir',
    'year': '1 Tahun Terakhir',
  };

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadDashboardData();
  }

  Future<void> _loadUserData() async {
    try {
      final token = await AuthService.getToken();
      if (token != null && token.isNotEmpty) {
        final parts = token.split('.');
        if (parts.length > 1) {
          String payload = parts[1];
          while (payload.length % 4 != 0) {
            payload += '=';
          }
          final decoded = base64.decode(payload);
          final jsonString = utf8.decode(decoded);
          final payloadData = json.decode(jsonString);
          
          setState(() {
            _guruName = payloadData['nama_lengkap'] ?? payloadData['username'] ?? 'Guru';
            _guruType = payloadData['user_type'] ?? 'Guru_BK';
          });
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final uri = Uri.parse(
        '${Environment.baseUrl}/modules/guru/api/followup_api.php'
        '?status=all&priority=all&source=all&search=&page=1'
      );

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final followupResponse = FollowupResponse.fromJson(data);
          
          _allMessages = followupResponse.messages;
          
          _aggregateDataByTimeFilter();
          
          setState(() {
            _followupResponse = followupResponse;
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = data['message'] ?? 'Gagal memuat data dashboard';
            _isLoading = false;
          });
        }
      } else if (response.statusCode == 401) {
        throw Exception('Session expired. Please login again.');
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _aggregateDataByTimeFilter() {
    final now = DateTime.now();
    DateTime startDate;
    
    switch (_selectedTimeFilter) {
      case '7days':
        startDate = now.subtract(const Duration(days: 7));
        _dateRangeText = '${_formatDate(startDate)} - ${_formatDate(now)} (7 hari)';
        break;
      case '30days':
        startDate = now.subtract(const Duration(days: 30));
        _dateRangeText = '${_formatDate(startDate)} - ${_formatDate(now)} (30 hari)';
        break;
      case '90days':
        startDate = now.subtract(const Duration(days: 90));
        _dateRangeText = '${_formatDate(startDate)} - ${_formatDate(now)} (90 hari)';
        break;
      case 'year':
        startDate = now.subtract(const Duration(days: 365));
        _dateRangeText = '${_formatDate(startDate)} - ${_formatDate(now)} (1 tahun)';
        break;
      default:
        startDate = DateTime(1970);
        _dateRangeText = 'Data dari awal hingga ${_formatDate(now)}';
        break;
    }
    
    final filteredMessages = _allMessages.where((msg) {
      try {
        final msgDate = DateTime.parse(msg.createdAt);
        return msgDate.isAfter(startDate) || msgDate.isAtSameMomentAs(startDate);
      } catch (e) {
        return false;
      }
    }).toList();
    
    _calculateStats(filteredMessages);
    _calculateTrends(filteredMessages, startDate, now);
  }

  void _calculateStats(List<FollowupMessage> messages) {
    final total = messages.length;
    
    int pending = 0;
    int dibaca = 0;
    int diproses = 0;
    int disetujui = 0;
    int ditolak = 0;
    int selesai = 0;
    int totalResponses = 0;
    double totalResponseTime = 0;
    
    for (final msg in messages) {
      switch (msg.status) {
        case 'Pending': pending++; break;
        case 'Dibaca': dibaca++; break;
        case 'Diproses': diproses++; break;
        case 'Disetujui': disetujui++; break;
        case 'Ditolak': ditolak++; break;
        case 'Selesai': selesai++; break;
      }
      
      if (msg.hasResponse == 1 && msg.tanggalRespon != null) {
        totalResponses++;
        try {
          final created = DateTime.parse(msg.createdAt);
          final responded = DateTime.parse(msg.tanggalRespon!);
          totalResponseTime += responded.difference(created).inHours;
        } catch (e) {}
      }
    }
    
    final avgResponseTime = totalResponses > 0 ? totalResponseTime / totalResponses : 0;
    
    _aggregatedStats = {
      'total_assigned': total,
      'pending': pending,
      'dibaca': dibaca,
      'diproses': diproses,
      'disetujui': disetujui,
      'ditolak': ditolak,
      'selesai': selesai,
      'total_responses': totalResponses,
      'avg_response_time': avgResponseTime,
    };
    
    final totalNum = total > 0 ? total : 1;
    _statusDistribution = [
      {'status': 'Pending', 'count': pending, 'percentage': (pending / totalNum * 100).toStringAsFixed(1), 'color': Colors.orange, 'icon': Icons.access_time},
      {'status': 'Dibaca', 'count': dibaca, 'percentage': (dibaca / totalNum * 100).toStringAsFixed(1), 'color': Colors.cyan, 'icon': Icons.remove_red_eye},
      {'status': 'Diproses', 'count': diproses, 'percentage': (diproses / totalNum * 100).toStringAsFixed(1), 'color': Colors.blue, 'icon': Icons.settings},
      {'status': 'Disetujui', 'count': disetujui, 'percentage': (disetujui / totalNum * 100).toStringAsFixed(1), 'color': Colors.green, 'icon': Icons.check_circle},
      {'status': 'Ditolak', 'count': ditolak, 'percentage': (ditolak / totalNum * 100).toStringAsFixed(1), 'color': Colors.red, 'icon': Icons.cancel},
      {'status': 'Selesai', 'count': selesai, 'percentage': (selesai / totalNum * 100).toStringAsFixed(1), 'color': Colors.grey, 'icon': Icons.flag},
    ];
    
    _recentActivity = messages.map((msg) {
      return {
        'message_id': msg.id,
        'sender_name': msg.pengirimNama,
        'content': msg.isiPesan,
        'status': msg.status,
        'message_date': msg.createdAt,
        'response_date': msg.tanggalRespon,
        'has_response': msg.hasResponse,
        'is_external': msg.isExternal,
        'response_content': '',
      };
    }).toList();
    
    // Urutkan dari yang terbaru
    _recentActivity.sort((a, b) {
      final dateA = DateTime.tryParse(a['message_date'] ?? '');
      final dateB = DateTime.tryParse(b['message_date'] ?? '');
      if (dateA == null && dateB == null) return 0;
      if (dateA == null) return 1;
      if (dateB == null) return -1;
      return dateB.compareTo(dateA);
    });
    
    // Reset pagination saat data berubah
    _activityCurrentPage = 1;
    _updatePaginatedActivity();
    
    if (_followupResponse != null) {
      _reviewStats = {
        'total_responded': _followupResponse!.reviewStats.totalResponded,
        'reviewed_by_wakepsek': _followupResponse!.reviewStats.reviewedByWakepsek,
        'reviewed_by_kepsek': _followupResponse!.reviewStats.reviewedByKepsek,
        'pending_review': _followupResponse!.reviewStats.pendingReview,
      };
    }
  }
  
  void _updatePaginatedActivity() {
    int startIndex = (_activityCurrentPage - 1) * _activityPerPage;
    int endIndex = startIndex + _activityPerPage;
    if (endIndex > _recentActivity.length) endIndex = _recentActivity.length;
    
    setState(() {
      _paginatedActivity = _recentActivity.sublist(startIndex, endIndex);
      _activityTotalPages = (_recentActivity.length / _activityPerPage).ceil();
      if (_activityTotalPages == 0) _activityTotalPages = 1;
    });
  }
  
  void _goToActivityPage(int page) {
    if (page >= 1 && page <= _activityTotalPages) {
      setState(() {
        _activityCurrentPage = page;
      });
      _updatePaginatedActivity();
    }
  }

  void _calculateTrends(List<FollowupMessage> messages, DateTime startDate, DateTime endDate) {
    final Map<String, Map<String, int>> dailyStats = {};
    
    for (var date = startDate; date.isBefore(endDate) || date.isAtSameMomentAs(endDate); date = date.add(const Duration(days: 1))) {
      final dateKey = _formatDateKey(date);
      dailyStats[dateKey] = {
        'pending': 0, 'dibaca': 0, 'diproses': 0,
        'disetujui': 0, 'ditolak': 0, 'selesai': 0,
        'total': 0,
      };
    }
    
    for (final msg in messages) {
      try {
        final msgDate = DateTime.parse(msg.createdAt);
        final dateKey = _formatDateKey(msgDate);
        if (dailyStats.containsKey(dateKey)) {
          switch (msg.status) {
            case 'Pending':
              dailyStats[dateKey]!['pending'] = (dailyStats[dateKey]!['pending'] ?? 0) + 1;
              break;
            case 'Dibaca':
              dailyStats[dateKey]!['dibaca'] = (dailyStats[dateKey]!['dibaca'] ?? 0) + 1;
              break;
            case 'Diproses':
              dailyStats[dateKey]!['diproses'] = (dailyStats[dateKey]!['diproses'] ?? 0) + 1;
              break;
            case 'Disetujui':
              dailyStats[dateKey]!['disetujui'] = (dailyStats[dateKey]!['disetujui'] ?? 0) + 1;
              break;
            case 'Ditolak':
              dailyStats[dateKey]!['ditolak'] = (dailyStats[dateKey]!['ditolak'] ?? 0) + 1;
              break;
            case 'Selesai':
              dailyStats[dateKey]!['selesai'] = (dailyStats[dateKey]!['selesai'] ?? 0) + 1;
              break;
          }
          dailyStats[dateKey]!['total'] = (dailyStats[dateKey]!['total'] ?? 0) + 1;
        }
      } catch (e) {
        print('Error parsing date: $e');
      }
    }
    
    final filteredDates = dailyStats.keys.where((date) {
      return (dailyStats[date]!['total'] ?? 0) > 0;
    }).toList();
    
    filteredDates.sort();
    
    final maxDataPoints = 15;
    List<String> selectedDates = filteredDates;
    if (filteredDates.length > maxDataPoints) {
      final step = (filteredDates.length / maxDataPoints).ceil();
      selectedDates = [];
      for (int i = 0; i < filteredDates.length; i += step) {
        selectedDates.add(filteredDates[i]);
      }
    }
    
    if (selectedDates.isEmpty) {
      _chartLabels = ['Tidak Ada Data'];
      _chartPendingData = [0.0];
      _chartDibacaData = [0.0];
      _chartDiprosesData = [0.0];
      _chartDisetujuiData = [0.0];
      _chartDitolakData = [0.0];
      _chartSelesaiData = [0.0];
      return;
    }
    
    _chartLabels = [];
    _chartPendingData = [];
    _chartDibacaData = [];
    _chartDiprosesData = [];
    _chartDisetujuiData = [];
    _chartDitolakData = [];
    _chartSelesaiData = [];
    
    for (final date in selectedDates) {
      final stats = dailyStats[date]!;
      _chartLabels.add(_formatDateLabel(date));
      _chartPendingData.add((stats['pending'] ?? 0).toDouble());
      _chartDibacaData.add((stats['dibaca'] ?? 0).toDouble());
      _chartDiprosesData.add((stats['diproses'] ?? 0).toDouble());
      _chartDisetujuiData.add((stats['disetujui'] ?? 0).toDouble());
      _chartDitolakData.add((stats['ditolak'] ?? 0).toDouble());
      _chartSelesaiData.add((stats['selesai'] ?? 0).toDouble());
    }
  }

  String _formatDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatDateLabel(String dateKey) {
    try {
      final parts = dateKey.split('-');
      if (parts.length == 3) {
        return '${parts[2]}/${parts[1]}';
      }
      return dateKey;
    } catch (e) {
      return dateKey;
    }
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  void _changeTimeFilter(String? value) {
    if (value != null && value != _selectedTimeFilter) {
      setState(() {
        _selectedTimeFilter = value;
      });
      _loadDashboardData();
    }
  }

  void _navigateToFollowup() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const FollowupScreen()),
    );
  }

  String _formatNumber(dynamic value) {
    if (value == null) return '0';
    if (value is int) return value.toString();
    if (value is double) return value.toStringAsFixed(0);
    if (value is String) return value;
    return '0';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending': return Colors.orange;
      case 'Dibaca': return Colors.cyan;
      case 'Diproses': return Colors.blue;
      case 'Disetujui': return Colors.green;
      case 'Ditolak': return Colors.red;
      case 'Selesai': return Colors.grey;
      default: return Colors.grey;
    }
  }

  String _formatDateString(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    try {
      final date = DateTime.parse(dateStr);
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  void _showMessageDetailDialog(int messageId, FollowupMessage message) {
    showDialog(
      context: context,
      builder: (context) => MessageDetailDialog(
        messageId: messageId,
        initialData: {
          'id': message.id,
          'reference_number': message.referenceNumber,
          'tanggal_pesan': message.tanggalPesan,
          'isi_pesan': message.isiPesan,
          'status': message.status,
          'priority': message.priority,
          'created_at': message.createdAt,
          'tanggal_respon': message.tanggalRespon,
          'is_external': message.isExternal,
          'pengirim_nama_display': message.pengirimNama,
          'pengirim_tipe': message.pengirimTipe,
          'pengirim_email': message.pengirimEmail,
          'has_response': message.hasResponse,
        },
      ),
    );
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.logout, color: Colors.red, size: 28),
            SizedBox(width: 12),
            Text('Konfirmasi Logout'),
          ],
        ),
        content: const Text(
          'Apakah Anda yakin ingin keluar?\n\n'
          'Semua sesi Anda akan dihapus dan Anda perlu login kembali untuk mengakses aplikasi.',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      await AuthService.logout();
      
      if (mounted) {
        _allMessages = [];
        _aggregatedStats = {};
        _statusDistribution = [];
        _recentActivity = [];
        _reviewStats = {};
        _chartLabels = [];
        _chartPendingData = [];
        _chartDibacaData = [];
        _chartDiprosesData = [];
        _chartDisetujuiData = [];
        _chartDitolakData = [];
        _chartSelesaiData = [];
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Berhasil logout. Sampai jumpa kembali!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
        
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/login',
          (route) => false,
        );
      }
    } catch (e) {
      print('❌ Logout error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saat logout: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userType = authProvider.userType ?? 'Guru_BK';

    return WindowResizerShortcut(
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text(
            'Dashboard Analisis Pesan',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 1,
          actions: [
            IconButton(
              icon: const Icon(Icons.task, color: Colors.green),
              onPressed: _navigateToFollowup,
              tooltip: 'Follow-Up Pesan',
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadDashboardData,
              tooltip: 'Refresh',
            ),
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.red),
              onPressed: _logout,
              tooltip: 'Logout',
            ),
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.person, size: 16, color: Colors.blue),
                  const SizedBox(width: 4),
                  Text(
                    userType.replaceAll('_', ' '),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? _buildErrorWidget()
                : RefreshIndicator(
                    onRefresh: _loadDashboardData,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(),
                          const SizedBox(height: 16),
                          _buildTimeFilter(),
                          const SizedBox(height: 16),
                          if ((_aggregatedStats['total_assigned'] ?? 0) == 0)
                            _buildEmptyDataWidget()
                          else ...[
                            _buildKPICardsVertical(),
                            const SizedBox(height: 16),
                            _buildStatusCardsGrid(),
                            const SizedBox(height: 16),
                            _buildChartsSection(),
                            const SizedBox(height: 16),
                            _buildPerformanceTable(),
                            const SizedBox(height: 16),
                            _buildRecentActivity(),
                          ],
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0B4D8A), Color(0xFF1A73E8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.analytics, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dashboard Analisis Pesan',
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Menampilkan pesan yang direspons oleh $_guruName ($_guruType)',
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, size: 14, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      'Total: ${_formatNumber(_aggregatedStats['total_assigned'])} pesan',
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.reply_all, size: 14, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      'Direspons: ${_formatNumber(_aggregatedStats['total_responses'])}',
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // PERUBAHAN 1: Dropdownlist dipindahkan ke bawah tulisan "Rentang Waktu Analisis"
  Widget _buildTimeFilter() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Rentang Waktu Analisis:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            // Dropdown dipindahkan ke sini (di bawah tulisan)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedTimeFilter,
                  isExpanded: true,
                  items: _timeFilterOptions.map((filter) {
                    return DropdownMenuItem(
                      value: filter,
                      child: Text(_timeFilterLabels[filter] ?? filter),
                    );
                  }).toList(),
                  onChanged: _changeTimeFilter,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 16, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _dateRangeText,
                      style: const TextStyle(fontSize: 12, color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyDataWidget() {
    return Card(
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.info_outline, size: 48, color: Colors.orange),
            const SizedBox(height: 12),
            const Text(
              'Perhatian!',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Belum ada data untuk periode yang dipilih. Pastikan ada pesan yang masuk.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKPICardsVertical() {
    return Column(
      children: [
        _buildKPICard(
          title: 'Total Pesan',
          value: _formatNumber(_aggregatedStats['total_assigned']),
          icon: Icons.email,
          color: Colors.blue,
          subtitle: 'Semua pesan terkait',
        ),
        const SizedBox(height: 12),
        _buildKPICard(
          title: 'Rata Waktu Respons',
          value: '${(_aggregatedStats['avg_response_time'] ?? 0).toStringAsFixed(1)} jam',
          icon: Icons.access_time,
          color: Colors.orange,
          subtitle: 'Dari pesan diterima hingga direspons',
        ),
        const SizedBox(height: 12),
        _buildKPICard(
          title: 'Respon Diberikan',
          value: _formatNumber(_aggregatedStats['total_responses']),
          icon: Icons.reply_all,
          color: Colors.green,
          subtitle: 'Total respon yang telah diberikan',
        ),
      ],
    );
  }

  Widget _buildKPICard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
                Text(subtitle, style: const TextStyle(fontSize: 9, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Status Cards: 3 kolom 2 baris
  Widget _buildStatusCardsGrid() {
    final total = (_aggregatedStats['total_assigned'] ?? 1).toDouble();
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Status Pesan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            // 3 kolom 2 baris
            Column(
              children: [
                Row(
                  children: _statusDistribution.sublist(0, 3).map((status) {
                    return Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: (status['color'] as Color).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Icon(status['icon'] as IconData, size: 24, color: status['color'] as Color),
                            const SizedBox(height: 4),
                            Text(
                              _formatNumber(status['count']),
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: status['color'] as Color),
                            ),
                            Text(status['status'] as String, style: const TextStyle(fontSize: 10)),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
                Row(
                  children: _statusDistribution.sublist(3, 6).map((status) {
                    return Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: (status['color'] as Color).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Icon(status['icon'] as IconData, size: 24, color: status['color'] as Color),
                            const SizedBox(height: 4),
                            Text(
                              _formatNumber(status['count']),
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: status['color'] as Color),
                            ),
                            Text(status['status'] as String, style: const TextStyle(fontSize: 10)),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: ((_aggregatedStats['pending'] ?? 0) / total * 100).toInt(),
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        bottomLeft: Radius.circular(4),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: ((_aggregatedStats['dibaca'] ?? 0) / total * 100).toInt(),
                  child: Container(height: 8, color: Colors.cyan),
                ),
                Expanded(
                  flex: ((_aggregatedStats['diproses'] ?? 0) / total * 100).toInt(),
                  child: Container(height: 8, color: Colors.blue),
                ),
                Expanded(
                  flex: ((_aggregatedStats['disetujui'] ?? 0) / total * 100).toInt(),
                  child: Container(height: 8, color: Colors.green),
                ),
                Expanded(
                  flex: ((_aggregatedStats['ditolak'] ?? 0) / total * 100).toInt(),
                  child: Container(height: 8, color: Colors.red),
                ),
                Expanded(
                  flex: ((_aggregatedStats['selesai'] ?? 0) / total * 100).toInt(),
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.grey,
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(4),
                        bottomRight: Radius.circular(4),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartsSection() {
    return Column(
      children: [
        Center(
          child: SizedBox(
            width: 500,
            child: _buildDonutChart(),
          ),
        ),
        const SizedBox(height: 16),
        _buildBarChart(),
      ],
    );
  }

  // PERUBAHAN 2 & 3: Jarak antara tulisan dengan grafik donut dan jarak legend dengan grafik donut
  Widget _buildDonutChart() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Distribusi Status Pesan',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 4),
            const Text(
              'Semua 6 status pesan',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
            // Jarak 1 cm (sekitar 37.8 pixel) antara tulisan dengan grafik donut
            const SizedBox(height: 38),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: _buildPieChartSections(),
                  centerSpaceRadius: 40,
                  sectionsSpace: 2,
                ),
              ),
            ),
            // Jarak legend dengan grafik donut (1 cm)
            const SizedBox(height: 38),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: _statusDistribution.map((status) {
                final count = status['count'] as int;
                final percentage = status['percentage'] as String;
                final color = status['color'] as Color;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${status['status']} ($count, $percentage%)',
                      style: TextStyle(fontSize: 11, color: color),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildPieChartSections() {
    final colors = [
      Colors.orange,   // Pending
      Colors.cyan,     // Dibaca
      Colors.blue,     // Diproses
      Colors.green,    // Disetujui
      Colors.red,      // Ditolak
      Colors.grey,     // Selesai
    ];
    
    final values = [
      (_aggregatedStats['pending'] ?? 0).toDouble(),
      (_aggregatedStats['dibaca'] ?? 0).toDouble(),
      (_aggregatedStats['diproses'] ?? 0).toDouble(),
      (_aggregatedStats['disetujui'] ?? 0).toDouble(),
      (_aggregatedStats['ditolak'] ?? 0).toDouble(),
      (_aggregatedStats['selesai'] ?? 0).toDouble(),
    ];
    
    return List.generate(6, (index) {
      final value = values[index];
      if (value == 0) {
        return PieChartSectionData(
          value: 0.01,
          color: colors[index].withOpacity(0.3),
          radius: 80,
          showTitle: false,
        );
      }
      
      return PieChartSectionData(
        value: value,
        title: value > 0 ? '${value.toInt()}' : '',
        color: colors[index],
        radius: 80,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        showTitle: value > 0,
      );
    });
  }

  Widget _buildBarChart() {
    bool hasData = _chartLabels.isNotEmpty && 
                   _chartLabels.first != 'Tidak Ada Data' &&
                   (_chartPendingData.any((v) => v > 0) ||
                    _chartDisetujuiData.any((v) => v > 0) ||
                    _chartDitolakData.any((v) => v > 0));
    
    if (!hasData || _chartLabels.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: const Padding(
          padding: EdgeInsets.all(32),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bar_chart, size: 48, color: Colors.grey),
                SizedBox(height: 12),
                Text('Belum ada data trend', style: TextStyle(color: Colors.grey)),
                SizedBox(height: 4),
                Text('Pilih periode waktu yang berbeda', style: TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
        ),
      );
    }

    final allValues = <double>[];
    allValues.addAll(_chartPendingData);
    allValues.addAll(_chartDibacaData);
    allValues.addAll(_chartDiprosesData);
    allValues.addAll(_chartDisetujuiData);
    allValues.addAll(_chartDitolakData);
    allValues.addAll(_chartSelesaiData);
    
    final maxValue = allValues.isEmpty ? 5.0 : allValues.reduce((a, b) => a > b ? a : b);
    final yMax = maxValue > 0 ? maxValue + 1 : 5.0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Trend Pesan Berdasarkan Status',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 4),
            const Text(
              'Perkembangan 6 status pesan per periode',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 280,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: yMax,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        String status = '';
                        switch (rodIndex) {
                          case 0: status = 'Pending'; break;
                          case 1: status = 'Dibaca'; break;
                          case 2: status = 'Diproses'; break;
                          case 3: status = 'Disetujui'; break;
                          case 4: status = 'Ditolak'; break;
                          case 5: status = 'Selesai'; break;
                        }
                        return BarTooltipItem(
                          '$status\n${rod.toY.toInt()} pesan',
                          const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < _chartLabels.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Transform.rotate(
                                angle: -0.5,
                                child: Text(
                                  _chartLabels[index],
                                  style: const TextStyle(fontSize: 9),
                                ),
                              ),
                            );
                          }
                          return const Text('');
                        },
                        reservedSize: 50,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                        reservedSize: 30,
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(show: true),
                  borderData: FlBorderData(show: false),
                  barGroups: _buildBarGroups(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _buildLegendItem('Pending', Colors.orange),
                _buildLegendItem('Dibaca', Colors.cyan),
                _buildLegendItem('Diproses', Colors.blue),
                _buildLegendItem('Disetujui', Colors.green),
                _buildLegendItem('Ditolak', Colors.red),
                _buildLegendItem('Selesai', Colors.grey),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<BarChartGroupData> _buildBarGroups() {
    return List.generate(_chartLabels.length, (index) {
      return BarChartGroupData(
        x: index,
        barsSpace: 2,
        barRods: [
          BarChartRodData(
            toY: _chartPendingData[index],
            color: Colors.orange,
            width: 10,
            borderRadius: BorderRadius.circular(4),
          ),
          BarChartRodData(
            toY: _chartDibacaData[index],
            color: Colors.cyan,
            width: 10,
            borderRadius: BorderRadius.circular(4),
          ),
          BarChartRodData(
            toY: _chartDiprosesData[index],
            color: Colors.blue,
            width: 10,
            borderRadius: BorderRadius.circular(4),
          ),
          BarChartRodData(
            toY: _chartDisetujuiData[index],
            color: Colors.green,
            width: 10,
            borderRadius: BorderRadius.circular(4),
          ),
          BarChartRodData(
            toY: _chartDitolakData[index],
            color: Colors.red,
            width: 10,
            borderRadius: BorderRadius.circular(4),
          ),
          BarChartRodData(
            toY: _chartSelesaiData[index],
            color: Colors.grey,
            width: 10,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    });
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, color: color),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }

  Widget _buildPerformanceTable() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Performa Berdasarkan Status',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          const Divider(height: 0),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 20,
              headingRowColor: MaterialStateProperty.all(Colors.grey.shade100),
              columns: const [
                DataColumn(label: Text('Status Pesan', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Jumlah', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Persentase dari Total', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: _statusDistribution.map((status) {
                final color = status['color'] as Color;
                final count = status['count'] as int;
                final percentage = status['percentage'] as String;
                return DataRow(
                  cells: [
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(status['icon'] as IconData, size: 14, color: color),
                            const SizedBox(width: 4),
                            Text(status['status'], style: TextStyle(color: color, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                    DataCell(Text(count.toString(), style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataCell(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: (double.tryParse(percentage) ?? 0) / 100,
                              backgroundColor: Colors.grey.shade200,
                              color: color,
                              minHeight: 6,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text('$percentage% dari total', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // PERBAIKAN: Aktivitas Pesan Terbaru dengan pagination yang SELALU ditampilkan jika total > per page
Widget _buildRecentActivity() {
  if (_recentActivity.isEmpty) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.inbox, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              const Text('Belum ada aktivitas pesan terbaru', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  // Hitung ulang total halaman
  int totalPages = (_recentActivity.length / _activityPerPage).ceil();
  if (totalPages == 0) totalPages = 1;
  
  // Pastikan current page tidak melebihi total pages
  if (_activityCurrentPage > totalPages) {
    _activityCurrentPage = totalPages;
  }

  return Card(
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Aktivitas Pesan Terbaru',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  TextButton.icon(
                    onPressed: _navigateToFollowup,
                    icon: const Icon(Icons.arrow_forward, size: 16),
                    label: const Text('Lihat Semua'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Total pesan di bawah judul
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.email, size: 12, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      'Total: ${_recentActivity.length} pesan',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 0),
        
        // Daftar pesan yang dipaginasi
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _paginatedActivity.length,
          itemBuilder: (context, index) {
            final activity = _paginatedActivity[index];
            final statusColor = _getStatusColor(activity['status'] ?? 'Pending');
            final hasResponse = (activity['has_response'] as int?) == 1;
            
            return Column(
              children: [
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: statusColor.withOpacity(0.1),
                    child: Icon(Icons.email, color: statusColor, size: 20),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          activity['sender_name'] ?? 'Unknown',
                          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          activity['status'] ?? 'Pending',
                          style: TextStyle(fontSize: 10, color: statusColor),
                        ),
                      ),
                      if (activity['is_external'] == 1) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('External', style: TextStyle(fontSize: 8, color: Colors.orange)),
                        ),
                      ],
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activity['content'] ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 12, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            _formatDateString(activity['message_date']),
                            style: const TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                          if (hasResponse && activity['response_date'] != null) ...[
                            const SizedBox(width: 12),
                            Icon(Icons.reply, size: 12, color: Colors.green),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Direspon: ${_formatDateString(activity['response_date'])}',
                                style: const TextStyle(fontSize: 10, color: Colors.green),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                  isThreeLine: false,
                  trailing: IconButton(
                    icon: const Icon(Icons.visibility, size: 18, color: Colors.blue),
                    onPressed: () {
                      final followupMessage = FollowupMessage(
                        id: activity['message_id'] as int,
                        referenceNumber: '',
                        tanggalPesan: activity['message_date'] as String? ?? '',
                        isiPesan: activity['content'] as String? ?? '',
                        status: activity['status'] as String? ?? 'Pending',
                        priority: 'Medium',
                        createdAt: activity['message_date'] as String? ?? '',
                        tanggalRespon: activity['response_date'] as String?,
                        isExternal: (activity['is_external'] as int?) ?? 0,
                        pengirimNama: activity['sender_name'] as String? ?? 'Unknown',
                        pengirimTipe: (activity['is_external'] as int?) == 1 ? 'External' : 'Internal',
                        pengirimEmail: null,
                        attachmentCount: 0,
                        hasResponse: (activity['has_response'] as int?) ?? 0,
                        hoursRemaining: 0,
                        waktuStatus: 'Active',
                      );
                      _showMessageDetailDialog(activity['message_id'] as int, followupMessage);
                    },
                    tooltip: 'Lihat Detail',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ),
                if (index < _paginatedActivity.length - 1) const Divider(height: 1, indent: 72),
              ],
            );
          },
        ),
        
        // PAGINATION - SELALU DITAMPILKAN JIKA TOTAL DATA > ITEMS PER PAGE
        if (_recentActivity.length > _activityPerPage)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Column(
              children: [
                // Informasi range data yang ditampilkan
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Menampilkan ${(_activityCurrentPage - 1) * _activityPerPage + 1} - ${(_activityCurrentPage * _activityPerPage) > _recentActivity.length ? _recentActivity.length : (_activityCurrentPage * _activityPerPage)} dari ${_recentActivity.length} pesan',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ),
                // Tombol pagination
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Tombol First
                    IconButton(
                      icon: const Icon(Icons.first_page, size: 20),
                      onPressed: _activityCurrentPage > 1
                          ? () => _goToActivityPage(1)
                          : null,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Halaman pertama',
                    ),
                    const SizedBox(width: 8),
                    // Tombol Previous
                    IconButton(
                      icon: const Icon(Icons.chevron_left, size: 24),
                      onPressed: _activityCurrentPage > 1
                          ? () => _goToActivityPage(_activityCurrentPage - 1)
                          : null,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Halaman sebelumnya',
                    ),
                    const SizedBox(width: 12),
                    // Indikator halaman saat ini
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Text(
                        '$_activityCurrentPage / $totalPages',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.blue[700]),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Tombol Next
                    IconButton(
                      icon: const Icon(Icons.chevron_right, size: 24),
                      onPressed: _activityCurrentPage < totalPages
                          ? () => _goToActivityPage(_activityCurrentPage + 1)
                          : null,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Halaman berikutnya',
                    ),
                    const SizedBox(width: 8),
                    // Tombol Last
                    IconButton(
                      icon: const Icon(Icons.last_page, size: 20),
                      onPressed: _activityCurrentPage < totalPages
                          ? () => _goToActivityPage(totalPages)
                          : null,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Halaman terakhir',
                    ),
                  ],
                ),
                // Tombol untuk mengubah jumlah item per halaman (opsional)
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Tampilkan:', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    const SizedBox(width: 8),
                    _buildPerPageButton(5),
                    const SizedBox(width: 4),
                    _buildPerPageButton(10),
                    const SizedBox(width: 4),
                    _buildPerPageButton(20),
                  ],
                ),
              ],
            ),
          ),
      ],
    ),
  );
}

// Method tambahan untuk tombol pemilihan jumlah item per halaman
Widget _buildPerPageButton(int perPage) {
  final isSelected = _activityPerPage == perPage;
  return InkWell(
    onTap: () {
      setState(() {
        _activityPerPage = perPage;
        _activityCurrentPage = 1;
        _updatePaginatedActivity();
      });
    },
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(
        perPage.toString(),
        style: TextStyle(
          fontSize: 11,
          color: isSelected ? Colors.white : Colors.grey.shade600,
          fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
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
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(_errorMessage!),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadDashboardData,
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }
}