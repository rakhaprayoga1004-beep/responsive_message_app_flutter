// lib/screen/admin/dashboard_screen.dart - UPDATE FINAL dengan periode waktu lengkap (7H, 30H, 60H, 90H, 180H, 1TH, 2TH, 3TH)

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../services/auth_service.dart';
import '../../services/dashboard_service.dart';
import '../../models/dashboard_model.dart';
import '../../utils/helpers.dart';
import '../../utils/date_formatter.dart';
import '../../utils/constants.dart';
import '../../widgets/charts/message_volume_chart.dart';
import '../../widgets/charts/status_distribution_chart.dart';
import '../../widgets/charts/message_type_chart.dart';
import '../../widgets/charts/user_growth_chart.dart';
import '../../widgets/message_detail_dialog.dart';
import '../../widgets/window_resizer_shortcut.dart';
import 'user_management_screen.dart';
import 'manage_messages_screen.dart';
import 'message_types_screen.dart';
import 'audit_logs.dart';
import 'settings_screen.dart';
import 'reports_screen.dart';
import '../../utils/environment.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  late DashboardService _dashboardService;
  DashboardStats? _stats;
  bool _isLoading = true;
  String? _error;
  late TabController _tabController;
  
  // Periode untuk Volume Pesan (default 90 days sesuai permintaan)
  String _selectedMessagePeriod = '90days';
  List<DailyMessage> _volumeData = [];
  
  // Periode untuk Pertumbuhan Pengguna (default 180 days sesuai permintaan)
  String _selectedUserPeriod = '180days';
  List<UserGrowth> _userGrowthData = [];

  // State untuk pagination
  int _currentPage = 1;
  final int _itemsPerPage = 5;

  // Daftar periode yang tersedia untuk Volume Pesan
  final List<Map<String, String>> _messagePeriods = [
    {'value': '7days', 'label': '7H'},
    {'value': '30days', 'label': '30H'},
    {'value': '60days', 'label': '60H'},
    {'value': '90days', 'label': '90H'},
    {'value': '180days', 'label': '180H'},
    {'value': '1year', 'label': '1TH'},
    {'value': '2years', 'label': '2TH'},
    {'value': '3years', 'label': '3TH'},
  ];
  
  // Daftar periode yang tersedia untuk Pertumbuhan Pengguna
  final List<Map<String, String>> _userPeriods = [
    {'value': '7days', 'label': '7H'},
    {'value': '30days', 'label': '30H'},
    {'value': '60days', 'label': '60H'},
    {'value': '90days', 'label': '90H'},
    {'value': '180days', 'label': '180H'},
    {'value': '1year', 'label': '1TH'},
    {'value': '2years', 'label': '2TH'},
    {'value': '3years', 'label': '3TH'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _dashboardService = DashboardService();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDashboardData();
      _loadVolumeData(_selectedMessagePeriod);
      _loadUserGrowthData(_selectedUserPeriod);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _dashboardService.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
      _currentPage = 1;
    });

    try {
      final stats = await _dashboardService.getAdminDashboardStats();
      if (mounted) {
        setState(() {
          _stats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadVolumeData(String period) async {
  if (!mounted) return;
  try {
    print('🔄 Loading volume data for period: $period');
    final data = await _dashboardService.getMessageVolumeByPeriod(period);
    print('✅ Volume data received: ${data.length} items');
    if (mounted) {
      setState(() {
        _volumeData = data;
      });
    }
  } catch (e) {
    debugPrint('❌ Error loading volume data: $e');
    if (mounted) {
      setState(() {
        _volumeData = [];
      });
    }
  }
}

  Future<void> _loadUserGrowthData(String period) async {
  if (!mounted) return;
  try {
    print('🔄 Loading user growth data for period: $period');
    final data = await _dashboardService.getUserGrowthByPeriod(period);
    print('✅ User growth data received: ${data.length} items');
    if (mounted) {
      setState(() {
        _userGrowthData = data;
      });
    }
  } catch (e) {
    debugPrint('❌ Error loading user growth data: $e');
    if (mounted) {
      setState(() {
        _userGrowthData = [];
      });
    }
  }
}

  Future<void> _refreshDashboard() async {
    await _loadDashboardData();
    await _loadVolumeData(_selectedMessagePeriod);
    await _loadUserGrowthData(_selectedUserPeriod);
  }

  void _showExportModal() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ekspor Laporan Dashboard'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Pilih format ekspor laporan dashboard:'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _exportReport('pdf'),
                    icon: const Icon(Icons.picture_as_pdf, size: 18),
                    label: const Text('PDF', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red, padding: const EdgeInsets.symmetric(vertical: 10)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _exportReport('excel'),
                    icon: const Icon(Icons.grid_on, size: 18),
                    label: const Text('Excel', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 10)),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup')),
        ],
      ),
    );
  }

  void _exportReport(String format) {
    Navigator.pop(context);
    Helpers.showToast(context, 'Menyiapkan laporan $format...');
    Future.delayed(const Duration(seconds: 2), () {
      Helpers.showToast(context, 'Laporan berhasil diekspor sebagai $format');
    });
  }

  Future<void> _showMessageDetailDialog(int messageId) async {
    showDialog(
      context: context,
      builder: (context) => MessageDetailDialog(
        messageId: messageId,
        initialData: null,
      ),
    );
  }

  Future<Map<String, dynamic>?> _fetchMessageDetail(int messageId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final url = Uri.parse('${Environment.baseUrl}/modules/admin/api/get_message_detail.php?message_id=$messageId');
      print('📡 Loading message detail from: $url');
      
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
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['message'];
        }
      }
      return null;
    } catch (e) {
      print('❌ Error fetching message detail: $e');
      return null;
    }
  }

  Future<void> _logout() async {
    final confirmed = await Helpers.showConfirmationDialog(
      context,
      title: 'Konfirmasi Logout',
      message: 'Apakah Anda yakin ingin keluar?',
      confirmText: 'Keluar',
      cancelText: 'Batal',
      confirmColor: Colors.red,
    );
    
    if (confirmed) {
      await AuthService.logout();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  void _navigateToUserManagement() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const UserManagementScreen()),
    );
  }

  void _navigateToManageMessages() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ManageMessagesScreen()),
    );
  }

  void _navigateToMessageTypes() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MessageTypesScreen()),
    );
  }

  void _navigateToAuditLogs() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AuditLogs()),
    );
  }

  void _navigateToSettings() {
    Navigator.pushNamed(context, '/settings');
  }

  void _navigateToReports() {
    Navigator.pushNamed(context, '/reports');
  }

  void _showDeleteConfirmation(String messageId, String messageTitle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text('Apakah Anda yakin ingin menghapus pesan "$messageTitle"? Tindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteMessage(messageId);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteMessage(String messageId) async {
    try {
      final token = await AuthService.getToken();
      final uri = Uri.parse('${Environment.baseUrl}/api/messages/delete.php?id=$messageId');
      
      final response = await http.delete(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          Helpers.showToast(context, 'Pesan berhasil dihapus');
          _refreshDashboard();
        } else {
          Helpers.showToast(context, data['message'] ?? 'Gagal menghapus pesan', isError: true);
        }
      } else {
        Helpers.showToast(context, 'Server error: ${response.statusCode}', isError: true);
      }
    } catch (e) {
      Helpers.showToast(context, 'Error: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WindowResizerShortcut(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Dashboard Admin'),
          backgroundColor: const Color(0xFF0B4D8A),
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Dashboard', icon: Icon(Icons.dashboard)),
              Tab(text: 'Laporan', icon: Icon(Icons.analytics)),
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
              icon: const Icon(Icons.settings),
              onPressed: _navigateToSettings,
              tooltip: 'Pengaturan Sistem',
            ),
            IconButton(icon: const Icon(Icons.refresh), onPressed: _refreshDashboard, tooltip: 'Refresh'),
            IconButton(icon: const Icon(Icons.download), onPressed: _showExportModal, tooltip: 'Export'),
            IconButton(icon: const Icon(Icons.logout), onPressed: _logout, tooltip: 'Logout'),
          ],
        ),
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              FutureBuilder(
                future: AuthService.getFullName(),
                builder: (context, snapshot) {
                  final userName = snapshot.data ?? 'Admin';
                  return DrawerHeader(
                    decoration: const BoxDecoration(color: Color(0xFF0B4D8A)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          userName,
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text('Administrator', style: TextStyle(color: Colors.white70)),
                      ],
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.dashboard, color: Color(0xFF0B4D8A)),
                title: const Text('Dashboard'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.people, color: Color(0xFF0B4D8A)),
                title: const Text('Manajemen User'),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToUserManagement();
                },
              ),
              ListTile(
                leading: const Icon(Icons.message, color: Color(0xFF0B4D8A)),
                title: const Text('Manajemen Pesan'),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToManageMessages();
                },
              ),
              ListTile(
                leading: const Icon(Icons.category, color: Color(0xFF0B4D8A)),
                title: const Text('Jenis Pesan'),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToMessageTypes();
                },
              ),
              ListTile(
                leading: const Icon(Icons.history, color: Color(0xFF0B4D8A)),
                title: const Text('System Logs'),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToAuditLogs();
                },
              ),
              ListTile(
                leading: const Icon(Icons.analytics, color: Color(0xFF0B4D8A)),
                title: const Text('Laporan & Analitik'),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToReports();
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.settings, color: Color(0xFF0B4D8A)),
                title: const Text('Pengaturan Sistem'),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToSettings();
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Logout', style: TextStyle(color: Colors.red)),
                onTap: _logout,
              ),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
                        const SizedBox(height: 16),
                        Text('Error: $_error', textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(onPressed: _loadDashboardData, child: const Text('Coba Lagi')),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _refreshDashboard,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildDashboardTab(),
                        _buildReportsTab(),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildDashboardTab() {
    if (_stats == null) return const SizedBox();
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 12),
          _buildStatsCards(),
          const SizedBox(height: 16),
          _buildChartsRow(),
          const SizedBox(height: 16),
          _buildMessageVolumeChart(),
          const SizedBox(height: 16),
          _buildUserGrowthChart(),
          const SizedBox(height: 16),
          _buildRecentMessages(),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final now = DateTime.now();
    return FutureBuilder(
      future: AuthService.getFullName(),
      builder: (context, snapshot) {
        final userName = snapshot.data ?? 'Admin';
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF0B4D8A), Color(0xFF1A73E8)]),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Selamat datang,', style: const TextStyle(color: Colors.white70, fontSize: 9)),
                    Text(userName, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(
                      '${Helpers.getDayName(now.weekday)}, ${now.day} ${Helpers.getMonthName(now.month)} ${now.year}',
                      style: const TextStyle(color: Colors.white70, fontSize: 8)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(12)),
                child: const Text('Admin', style: TextStyle(color: Colors.white, fontSize: 8)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatsCards() {
    if (_stats == null) return const SizedBox();
    return Row(
      children: [
        Expanded(child: _buildStatCard('Total Pengguna', Helpers.formatNumber(_stats!.totalUsers), '${_stats!.newUsers30Days} baru', Icons.people, Colors.blue)),
        const SizedBox(width: 6),
        Expanded(child: _buildStatCard('Total Pesan', Helpers.formatNumber(_stats!.totalMessages), '${_stats!.pendingMessages} pending', Icons.message, Colors.green)),
        const SizedBox(width: 6),
        Expanded(child: _buildStatCard('Tertunda', Helpers.formatNumber(_stats!.pendingMessages), 'Perlu perhatian', Icons.access_time, Colors.orange)),
        const SizedBox(width: 6),
        Expanded(child: _buildStatCard('Expired', Helpers.formatNumber(_stats!.expiredMessages), 'Kadaluarsa', Icons.timer_off, Colors.red)),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, String subtitle, IconData icon, Color color) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6), side: BorderSide(color: Colors.grey.shade200, width: 0.5)),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: const TextStyle(fontSize: 7, color: Colors.grey)),
                  Text(
                    value,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(subtitle, style: TextStyle(fontSize: 6, color: Colors.grey[600]), overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
              child: Icon(icon, color: color, size: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartsRow() {
    if (_stats == null) return const SizedBox();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.grey.shade200, width: 0.5)),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.pie_chart, color: Color(0xFF0B4D8A), size: 11),
                      SizedBox(width: 4),
                      Text('Distribusi Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 8)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  StatusDistributionChart(data: _stats!.messageStatus),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.grey.shade200, width: 0.5)),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.bar_chart, color: Color(0xFF0B4D8A), size: 11),
                      SizedBox(width: 4),
                      Text('Performa Jenis', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 8)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (_stats!.messageTypeStats.isNotEmpty)
                    SizedBox(
                      height: 220,
                      child: MessageTypeChart(data: _stats!.messageTypeStats),
                    )
                  else
                    const Center(child: Text('Tidak ada data', style: TextStyle(fontSize: 7))),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // GRAFIK VOLUME PESAN - dengan periode lengkap (7H, 30H, 60H, 90H, 180H, 1TH, 2TH, 3TH)
  Widget _buildMessageVolumeChart() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade200, width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.show_chart, color: Color(0xFF0B4D8A), size: 11),
                    SizedBox(width: 4),
                    Text('Volume Pesan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 8)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 0),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<String>(
                    value: _selectedMessagePeriod,
                    underline: const SizedBox(),
                    icon: const Icon(Icons.arrow_drop_down, size: 14),
                    items: _messagePeriods.map((period) {
                      return DropdownMenuItem(
                        value: period['value'],
                        child: Text(period['label']!, style: const TextStyle(fontSize: 7)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedMessagePeriod = value;
                        });
                        _loadVolumeData(_selectedMessagePeriod);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (_volumeData.isNotEmpty)
              SizedBox(
                height: 160,
                child: MessageVolumeChart(data: _volumeData),
              )
            else
              Container(
                height: 160,
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.show_chart, size: 24, color: Colors.grey[300]),
                    const SizedBox(height: 4),
                    Text('Belum ada data', style: TextStyle(fontSize: 8, color: Colors.grey[500])),
                  ],
                ),
              ),
            const SizedBox(height: 2),
            Center(
              child: Text(
                'Menampilkan data ${_getPeriodLabel(_selectedMessagePeriod)} terakhir',
                style: TextStyle(fontSize: 7, color: Colors.grey[500]),
              ),
            ),
          ],
        ),
      ),
    );
  }

// GRAFIK PERTUMBUHAN PENGGUNA - dengan periode lengkap
Widget _buildUserGrowthChart() {
  // Gunakan _userGrowthData dari state, bukan dari _stats
  final userGrowthData = _userGrowthData;
  
  return Card(
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
      side: BorderSide(color: Colors.grey.shade200, width: 0.5),
    ),
    child: Padding(
      padding: const EdgeInsets.all(6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.people_outline, color: Color(0xFF0B4D8A), size: 11),
                  SizedBox(width: 4),
                  Text('Pertumbuhan Pengguna', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 8)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 0),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButton<String>(
                  value: _selectedUserPeriod,
                  underline: const SizedBox(),
                  icon: const Icon(Icons.arrow_drop_down, size: 14),
                  items: _userPeriods.map((period) {
                    return DropdownMenuItem(
                      value: period['value'],
                      child: Text(period['label']!, style: const TextStyle(fontSize: 7)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedUserPeriod = value;
                      });
                      _loadUserGrowthData(_selectedUserPeriod);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (userGrowthData.isNotEmpty)
            SizedBox(
              height: 160,
              child: UserGrowthChart(data: userGrowthData),
            )
          else
            Container(
              height: 160,
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 24, color: Colors.grey[300]),
                  const SizedBox(height: 4),
                  Text('Tidak ada data pertumbuhan pengguna', 
                       style: TextStyle(fontSize: 8, color: Colors.grey[500])),
                  const SizedBox(height: 4),
                  Text('Periode ${_getPeriodLabel(_selectedUserPeriod)}', 
                       style: TextStyle(fontSize: 7, color: Colors.grey[400])),
                ],
              ),
            ),
          const SizedBox(height: 2),
          Center(
            child: Text(
              'Menampilkan data ${_getPeriodLabel(_selectedUserPeriod)} terakhir',
              style: TextStyle(fontSize: 7, color: Colors.grey[500]),
            ),
          ),
        ],
      ),
    ),
  );
}

  String _getPeriodLabel(String period) {
    switch (period) {
      case '7days': return '7 hari';
      case '30days': return '30 hari';
      case '60days': return '60 hari';
      case '90days': return '90 hari';
      case '180days': return '180 hari';
      case '1year': return '1 tahun';
      case '2years': return '2 tahun';
      case '3years': return '3 tahun';
      default: return period;
    }
  }

  // Tabel Pesan Terbaru dengan pagination dan scrollbar horizontal
  Widget _buildRecentMessages() {
    if (_stats == null || _stats!.recentMessages.isEmpty) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.grey.shade200, width: 0.5),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.inbox, size: 32, color: Colors.grey[300]),
                const SizedBox(height: 4),
                Text('Belum ada pesan', style: TextStyle(fontSize: 9, color: Colors.grey[500])),
              ],
            ),
          ),
        ),
      );
    }

    final totalItems = _stats!.recentMessages.length;
    final totalPages = (totalItems / _itemsPerPage).ceil();
    final ScrollController _horizontalScrollController = ScrollController();

    return StatefulBuilder(
      builder: (context, setStatePagination) {
        final startIndex = (_currentPage - 1) * _itemsPerPage;
        final endIndex = startIndex + _itemsPerPage;
        final pageMessages = _stats!.recentMessages.sublist(
          startIndex,
          endIndex > totalItems ? totalItems : endIndex,
        );
        
        final displayStart = startIndex + 1;
        final displayEnd = endIndex > totalItems ? totalItems : endIndex;

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: Colors.grey.shade200, width: 0.5),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.history, color: Color(0xFF0B4D8A), size: 14),
                        const SizedBox(width: 4),
                        Text('Pesan Terbaru', 
                             style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
                        Container(
                          margin: const EdgeInsets.only(left: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0B4D8A),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('$totalItems', 
                                     style: const TextStyle(fontSize: 7, color: Colors.white)),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: _navigateToManageMessages,
                      style: TextButton.styleFrom(
                        minimumSize: Size.zero,
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      ),
                      child: const Text('Lihat Semua', style: TextStyle(fontSize: 8)),
                    ),
                  ],
                ),
                
                // Keterangan pagination
                Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Menampilkan $displayStart-$displayEnd dari $totalItems pesan',
                        style: TextStyle(fontSize: 9, color: Colors.grey[600]),
                      ),
                      if (totalPages > 1)
                        Text(
                          'Halaman $_currentPage dari $totalPages',
                          style: TextStyle(fontSize: 9, color: Colors.grey[500]),
                        ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 4),
                
                // Tabel dengan Scrollbar Horizontal
                RawScrollbar(
                  controller: _horizontalScrollController,
                  thumbVisibility: true,
                  trackVisibility: true,
                  interactive: true,
                  thickness: 8,
                  radius: const Radius.circular(6),
                  child: SingleChildScrollView(
                    controller: _horizontalScrollController,
                    scrollDirection: Axis.horizontal,
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: DataTable(
                      columnSpacing: 12,
                      headingRowColor: MaterialStateProperty.all(Colors.grey.shade50),
                      dataRowMinHeight: 48,
                      dataRowMaxHeight: 56,
                      columns: const [
                        DataColumn(label: SizedBox(width: 45, child: Text('#', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)))),
                        DataColumn(label: SizedBox(width: 130, child: Text('Pengirim', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)))),
                        DataColumn(label: SizedBox(width: 100, child: Text('Jenis', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)))),
                        DataColumn(label: SizedBox(width: 180, child: Text('Isi Pesan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)))),
                        DataColumn(label: SizedBox(width: 100, child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)))),
                        DataColumn(label: SizedBox(width: 110, child: Text('Waktu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)))),
                        DataColumn(label: SizedBox(width: 90, child: Text('Aksi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)))),
                      ],
                      rows: pageMessages.asMap().entries.map((entry) {
                        final index = startIndex + entry.key + 1;
                        final message = entry.value;
                        
                        return DataRow(
                          cells: [
                            DataCell(SizedBox(width: 45, child: Text('$index', style: const TextStyle(fontSize: 12)))),
                            DataCell(
                              SizedBox(
                                width: 130,
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 12,
                                      backgroundColor: Colors.blue.shade100,
                                      child: Text(
                                        Helpers.getInitials(message.namaLengkap ?? '?'),
                                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        message.namaLengkap ?? 'Unknown',
                                        style: const TextStyle(fontSize: 12),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(message.jenisPesan ?? '-', 
                                         style: const TextStyle(fontSize: 10)),
                              ),
                            ),
                            DataCell(
                              SizedBox(
                                width: 180,
                                child: Text(
                                  message.isiPesan.length > 40 
                                      ? '${message.isiPesan.substring(0, 40)}...' 
                                      : message.isiPesan,
                                  style: const TextStyle(fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Helpers.getStatusColor(message.status).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  message.status,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Helpers.getStatusColor(message.status),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                _formatDateTimeShort(message.createdAt),
                                style: const TextStyle(fontSize: 10),
                              ),
                            ),
                            DataCell(
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.visibility, size: 16, color: Colors.blue),
                                    onPressed: () => _showMessageDetailDialog(message.id),
                                    tooltip: 'Detail',
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                                    onPressed: () {
                                      _showDeleteConfirmation(
                                        message.id.toString(), 
                                        message.namaLengkap ?? 'Pesan'
                                      );
                                    },
                                    tooltip: 'Hapus',
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
                
                // Pagination
                if (totalPages > 1)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.first_page, size: 16),
                              onPressed: _currentPage > 1 ? () {
                                setStatePagination(() {
                                  _currentPage = 1;
                                });
                              } : null,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              tooltip: 'Halaman Pertama',
                            ),
                            IconButton(
                              icon: const Icon(Icons.chevron_left, size: 16),
                              onPressed: _currentPage > 1 ? () {
                                setStatePagination(() {
                                  _currentPage--;
                                });
                              } : null,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              tooltip: 'Halaman Sebelumnya',
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0B4D8A).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                '$_currentPage / $totalPages',
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF0B4D8A)),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.chevron_right, size: 16),
                              onPressed: _currentPage < totalPages ? () {
                                setStatePagination(() {
                                  _currentPage++;
                                });
                              } : null,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              tooltip: 'Halaman Selanjutnya',
                            ),
                            IconButton(
                              icon: const Icon(Icons.last_page, size: 16),
                              onPressed: _currentPage < totalPages ? () {
                                setStatePagination(() {
                                  _currentPage = totalPages;
                                });
                              } : null,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              tooltip: 'Halaman Terakhir',
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Menampilkan $displayStart-$displayEnd dari $totalItems pesan',
                            style: TextStyle(fontSize: 9, color: Colors.grey[600]),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDateTimeShort(DateTime date) {
    return '${date.day}/${date.month} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildReportsTab() {
    if (_stats == null) return const SizedBox();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton.icon(
                onPressed: () => _exportReport('pdf'),
                icon: const Icon(Icons.picture_as_pdf, size: 10),
                label: const Text('PDF', style: TextStyle(fontSize: 9)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3), minimumSize: const Size(0, 28)),
              ),
              const SizedBox(width: 4),
              ElevatedButton.icon(
                onPressed: () => _exportReport('excel'),
                icon: const Icon(Icons.grid_on, size: 10),
                label: const Text('Excel', style: TextStyle(fontSize: 9)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3), minimumSize: const Size(0, 28)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.grey.shade200, width: 0.5)),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.bar_chart, color: Color(0xFF0B4D8A), size: 11),
                      SizedBox(width: 4),
                      Text('Statistik Respons', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 8)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(child: _buildReportStatCard('Total', '${_stats!.responseStats.totalMessages}', Icons.message, Colors.blue)),
                      Expanded(child: _buildReportStatCard('Direspon', '${_stats!.responseStats.responded}', Icons.check_circle, Colors.green)),
                      Expanded(child: _buildReportStatCard('Rate', '${_stats!.responseStats.responseRate.toStringAsFixed(0)}%', Icons.percent, Colors.orange)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.grey.shade200, width: 0.5)),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.timeline, color: Color(0xFF0B4D8A), size: 11),
                      SizedBox(width: 4),
                      Text('Performa Jenis Pesan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 8)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (_stats!.messageTypeStats.isNotEmpty)
                    SizedBox(
                      height: 220,
                      child: MessageTypeChart(data: _stats!.messageTypeStats),
                    )
                  else
                    const Center(child: Text('Tidak ada data', style: TextStyle(fontSize: 7))),
                  const SizedBox(height: 4),
                  const Text('Total, Pending, Diproses, Disetujui, Ditolak', style: TextStyle(fontSize: 6, color: Colors.grey)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
      child: Column(
        children: [
          Icon(icon, color: color, size: 10),
          const SizedBox(height: 1),
          Text(value, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color)),
          Text(title, style: TextStyle(fontSize: 6, color: Colors.grey[600])),
        ],
      ),
    );
  }
}