// lib/screen/wakepsek/dashboard_screen.dart
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../../utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../utils/helpers.dart';
import '../../models/statistic_model.dart';
import '../../widgets/image_preview_dialog.dart';
import '../../widgets/attachment_grid.dart';
import '../../widgets/window_resizer_shortcut.dart';

// ============================================================================
// CUSTOM PAINTER FOR GRID LINES
// ============================================================================
class GridLinesPainter extends CustomPainter {
  final double yAxisMax;
  final double graphHeight;
  
  GridLinesPainter({
    required this.yAxisMax,
    required this.graphHeight,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[300]!
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;
    
    for (int i = 0; i <= yAxisMax.toInt(); i++) {
      final y = graphHeight - (i / yAxisMax) * graphHeight;
      if (y >= 0 && y <= graphHeight) {
        canvas.drawLine(
          Offset(0, y),
          Offset(size.width, y),
          paint,
        );
      }
    }
    
    final bottomLinePaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 1.5;
    canvas.drawLine(
      Offset(0, graphHeight),
      Offset(size.width, graphHeight),
      bottomLinePaint,
    );
    
    final verticalPaint = Paint()
      ..color = Colors.grey[200]!
      ..strokeWidth = 0.5;
    
    for (double x = 60; x < size.width; x += 120) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, graphHeight),
        verticalPaint,
      );
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

// ============================================================================
// CUSTOM PAINTER FOR MESSAGE TYPE GRID LINES
// ============================================================================
class MessageTypeGridPainter extends CustomPainter {
  final double yAxisMax;
  final double graphHeight;
  
  MessageTypeGridPainter({
    required this.yAxisMax,
    required this.graphHeight,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[300]!
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;
    
    for (int i = 0; i <= yAxisMax.toInt(); i++) {
      final y = graphHeight - (i / yAxisMax) * graphHeight;
      if (y >= 0 && y <= graphHeight) {
        canvas.drawLine(
          Offset(0, y),
          Offset(size.width, y),
          paint,
        );
      }
    }
    
    final bottomLinePaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 1.5;
    canvas.drawLine(
      Offset(0, graphHeight),
      Offset(size.width, graphHeight),
      bottomLinePaint,
    );
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

class WakepsekDashboardScreen extends StatefulWidget {
  const WakepsekDashboardScreen({super.key});

  @override
  State<WakepsekDashboardScreen> createState() => _WakepsekDashboardScreenState();
}

class _WakepsekDashboardScreenState extends State<WakepsekDashboardScreen> {
  int _selectedIndex = 0;
  bool _isLoading = true;
  String? _errorMessage;
  
  DashboardData? _dashboardData;
  List<MessageItem> _messages = [];
  List<GuruPerformance> _guruPerformances = [];
  List<MessageTypeStat> _messageTypeStats = [];
  List<GuruItem> _guruList = [];
  
  String _statusFilter = 'all';
  String _guruFilter = 'all';
  DateTime _dateFrom = DateTime.now().subtract(const Duration(days: 30));
  DateTime _dateTo = DateTime.now();
  String _searchQuery = '';
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalMessages = 0;
  
  String _userType = '';
  String _userName = '';
  
  final List<String> _titles = [
    'Dashboard Pimpinan',
    'Review Pesan',
    'Laporan & Statistik',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadDashboardData();
  }
  
  Future<void> _loadUserData() async {
    final userType = await AuthService.getUserType();
    final userName = await AuthService.getFullName();
    setState(() {
      _userType = userType ?? '';
      _userName = userName ?? 'Pimpinan';
    });
  }
  
  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final response = await ApiService.getWakepsekDashboard(
        status: _statusFilter,
        guruId: _guruFilter == 'all' ? null : _guruFilter,
        dateFrom: _dateFrom,
        dateTo: _dateTo,
        search: _searchQuery,
        page: _currentPage,
        perPage: 15,
        userType: _userType,
      );
      
      if (response['success'] == true && response['data'] != null) {
        setState(() {
          _dashboardData = DashboardData.fromJson(response['data']);
          _messages = (response['data']['messages'] as List?)
              ?.map((m) => MessageItem.fromJson(m))
              .toList() ?? [];
          _guruPerformances = (response['data']['guru_performances'] as List?)
              ?.map((g) => GuruPerformance.fromJson(g))
              .toList() ?? [];
          _messageTypeStats = (response['data']['message_type_stats'] as List?)
              ?.map((m) => MessageTypeStat.fromJson(m))
              .toList() ?? [];
          _guruList = (response['data']['guru_list'] as List?)
              ?.map((g) => GuruItem.fromJson(g))
              .toList() ?? [];
          _totalMessages = response['data']['total_messages'] ?? 0;
          _totalPages = response['data']['total_pages'] ?? 1;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response['message'] ?? 'Gagal memuat data';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }
  
  void _applyFilters() {
    _currentPage = 1;
    _loadDashboardData();
  }
  
  void _goToPage(int page) {
    if (page < 1 || page > _totalPages) return;
    setState(() {
      _currentPage = page;
    });
    _loadDashboardData();
  }
  
  @override
  Widget build(BuildContext context) {
    return WindowResizerShortcut(
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _titles[_selectedIndex],
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: const Color(0xFF0B4D8A),
          foregroundColor: Colors.white,
          elevation: 2,
          actions: [
            IconButton(
              icon: const Icon(Icons.aspect_ratio),
              onPressed: () => WindowResizerExtension.showResizerPanel(context),
              tooltip: 'Ubah Ukuran Window (F2)',
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadDashboardData,
              tooltip: 'Refresh',
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                final confirmed = await Helpers.showConfirmationDialog(
                  context,
                  title: 'Konfirmasi Logout',
                  message: 'Apakah Anda yakin ingin keluar?',
                  confirmText: 'Keluar',
                  cancelText: 'Batal',
                );
                if (confirmed) {
                  await AuthService.logout();
                  if (mounted) {
                    Navigator.pushReplacementNamed(context, '/login');
                  }
                }
              },
              tooltip: 'Logout',
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(_errorMessage!),
                        const SizedBox(height: 16),
                        ElevatedButton(onPressed: _loadDashboardData, child: const Text('Coba Lagi')),
                      ],
                    ),
                  )
                : _buildCurrentScreen(),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFF0B4D8A),
          unselectedItemColor: Colors.grey,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
            BottomNavigationBarItem(icon: Icon(Icons.rate_review), label: 'Review'),
            BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Laporan'),
          ],
          onTap: (index) => setState(() => _selectedIndex = index),
        ),
      ),
    );
  }
  
  Widget _buildCurrentScreen() {
    switch (_selectedIndex) {
      case 0:
        return _DashboardContent(
          userType: _userType,
          userName: _userName,
          dashboardData: _dashboardData,
          guruPerformances: _guruPerformances,
          messageTypeStats: _messageTypeStats,
          messages: _messages,
          totalMessages: _totalMessages,
          currentPage: _currentPage,
          totalPages: _totalPages,
          statusFilter: _statusFilter,
          guruFilter: _guruFilter,
          guruList: _guruList,
          dateFrom: _dateFrom,
          dateTo: _dateTo,
          searchQuery: _searchQuery,
          onRefresh: _loadDashboardData,
          onFilterChanged: (status, guru, dateFrom, dateTo, search) {
            setState(() {
              _statusFilter = status;
              _guruFilter = guru;
              _dateFrom = dateFrom;
              _dateTo = dateTo;
              _searchQuery = search;
            });
            _applyFilters();
          },
          onPageChanged: _goToPage,
          onExportExcel: _exportExcel,
          onExportPdf: _exportPdf,
          onSubmitReview: _submitReview,
        );
      case 1:
        return _ReviewContent(
          messages: _messages,
          totalMessages: _totalMessages,
          currentPage: _currentPage,
          totalPages: _totalPages,
          statusFilter: _statusFilter,
          guruFilter: _guruFilter,
          guruList: _guruList,
          dateFrom: _dateFrom,
          dateTo: _dateTo,
          searchQuery: _searchQuery,
          userType: _userType,
          onFilterChanged: (status, guru, dateFrom, dateTo, search) {
            setState(() {
              _statusFilter = status;
              _guruFilter = guru;
              _dateFrom = dateFrom;
              _dateTo = dateTo;
              _searchQuery = search;
            });
            _applyFilters();
          },
          onPageChanged: _goToPage,
          onRefresh: _loadDashboardData,
          onSubmitReview: _submitReview,
        );
      case 2:
        return _ReportsContent(
          dashboardData: _dashboardData,
          guruPerformances: _guruPerformances,
          messageTypeStats: _messageTypeStats,
          dateFrom: _dateFrom,
          dateTo: _dateTo,
          onExportExcel: _exportExcel,
          onExportPdf: _exportPdf,
        );
      default:
        return const SizedBox.shrink();
    }
  }
  
  Future<void> _submitReview(int messageId, String catatan) async {
    try {
      final response = await ApiService.submitReview(
        messageId: messageId,
        catatan: catatan,
        userType: _userType,
      );
      
      if (response['success'] == true) {
        if (mounted) {
          Helpers.showToast(context, 'Review berhasil disimpan');
          _loadDashboardData();
        }
      } else {
        if (mounted) {
          Helpers.showToast(context, response['message'] ?? 'Gagal menyimpan review');
        }
      }
    } catch (e) {
      if (mounted) {
        Helpers.showToast(context, 'Error: ${e.toString()}');
      }
    }
  }
  
  Future<void> _exportExcel() async {
    try {
      await Helpers.showLoading(context, 'Menyiapkan laporan Excel...');
      final response = await ApiService.exportReport(
        format: 'excel',
        dateFrom: _dateFrom,
        dateTo: _dateTo,
        userType: _userType,
      );
      if (mounted) Helpers.hideLoading(context);
      if (response['success'] == true && response['data'] != null) {
        final fileName = 'Monitoring_Report_${DateFormat('yyyy-MM-dd').format(DateTime.now())}.xlsx';
        await Helpers.downloadFile(response['data'] as List<int>, fileName, context);
      } else {
        Helpers.showToast(context, response['message'] ?? 'Gagal mengekspor laporan', isError: true);
      }
    } catch (e) {
      if (mounted) Helpers.hideLoading(context);
      Helpers.showToast(context, 'Error: ${e.toString()}', isError: true);
    }
  }
  
  Future<void> _exportPdf() async {
    try {
      await Helpers.showLoading(context, 'Menyiapkan laporan PDF...');
      final response = await ApiService.exportReport(
        format: 'pdf',
        dateFrom: _dateFrom,
        dateTo: _dateTo,
        userType: _userType,
      );
      if (mounted) Helpers.hideLoading(context);
      if (response['success'] == true && response['data'] != null) {
        final fileName = 'Monitoring_Report_${DateFormat('yyyy-MM-dd').format(DateTime.now())}.pdf';
        await Helpers.downloadFile(response['data'] as List<int>, fileName, context);
      } else {
        Helpers.showToast(context, response['message'] ?? 'Gagal mengekspor laporan', isError: true);
      }
    } catch (e) {
      if (mounted) Helpers.hideLoading(context);
      Helpers.showToast(context, 'Error: ${e.toString()}', isError: true);
    }
  }
}

// ============================================================================
// DASHBOARD CONTENT
// ============================================================================
class _DashboardContent extends StatefulWidget {
  final String userType;
  final String userName;
  final DashboardData? dashboardData;
  final List<GuruPerformance> guruPerformances;
  final List<MessageTypeStat> messageTypeStats;
  final List<MessageItem> messages;
  final int totalMessages;
  final int currentPage;
  final int totalPages;
  final String statusFilter;
  final String guruFilter;
  final List<GuruItem> guruList;
  final DateTime dateFrom;
  final DateTime dateTo;
  final String searchQuery;
  final VoidCallback onRefresh;
  final Function(String, String, DateTime, DateTime, String) onFilterChanged;
  final Function(int) onPageChanged;
  final VoidCallback onExportExcel;
  final VoidCallback onExportPdf;
  final Function(int, String) onSubmitReview;
  
  const _DashboardContent({
    required this.userType,
    required this.userName,
    required this.dashboardData,
    required this.guruPerformances,
    required this.messageTypeStats,
    required this.messages,
    required this.totalMessages,
    required this.currentPage,
    required this.totalPages,
    required this.statusFilter,
    required this.guruFilter,
    required this.guruList,
    required this.dateFrom,
    required this.dateTo,
    required this.searchQuery,
    required this.onRefresh,
    required this.onFilterChanged,
    required this.onPageChanged,
    required this.onExportExcel,
    required this.onExportPdf,
    required this.onSubmitReview,
  });

  @override
  State<_DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<_DashboardContent> {
  late TextEditingController _searchController;
  String _tempStatusFilter = 'all';
  String _tempGuruFilter = 'all';
  DateTime? _tempDateFrom;
  DateTime? _tempDateTo;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.searchQuery);
    _tempStatusFilter = widget.statusFilter;
    _tempGuruFilter = widget.guruFilter;
    _tempDateFrom = widget.dateFrom;
    _tempDateTo = widget.dateTo;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    widget.onFilterChanged(
      _tempStatusFilter,
      _tempGuruFilter,
      _tempDateFrom!,
      _tempDateTo!,
      _searchController.text,
    );
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateBottom) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(child: SizedBox(width: 40, height: 4, child: DecoratedBox(decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.all(Radius.circular(2)))))),
                  const SizedBox(height: 16),
                  const Text('Filter Pesan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  const Text('Status Review', style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'all', label: Text('Semua')),
                      ButtonSegment(value: 'pending', label: Text('Menunggu')),
                      ButtonSegment(value: 'reviewed', label: Text('Direview')),
                    ],
                    selected: {_tempStatusFilter},
                    onSelectionChanged: (Set<String> selection) {
                      setStateBottom(() => _tempStatusFilter = selection.first);
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text('Guru Responder', style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _tempGuruFilter,
                    items: [
                      const DropdownMenuItem(value: 'all', child: Text('Semua Guru')),
                      ...widget.guruList.map((guru) => DropdownMenuItem(value: guru.id.toString(), child: Text(guru.namaLengkap))),
                    ],
                    onChanged: (value) => setStateBottom(() => _tempGuruFilter = value!),
                    decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                  ),
                  const SizedBox(height: 16),
                  const Text('Rentang Tanggal', style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final date = await showDatePicker(context: context, initialDate: _tempDateFrom!, firstDate: DateTime(2020), lastDate: DateTime.now());
                            if (date != null) setStateBottom(() => _tempDateFrom = date);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(8)),
                            child: Row(children: [const Icon(Icons.calendar_today, size: 16), const SizedBox(width: 8), Text(DateFormat('dd/MM/yyyy').format(_tempDateFrom!))]),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text('-'),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final date = await showDatePicker(context: context, initialDate: _tempDateTo!, firstDate: DateTime(2020), lastDate: DateTime.now());
                            if (date != null) setStateBottom(() => _tempDateTo = date);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(8)),
                            child: Row(children: [const Icon(Icons.calendar_today, size: 16), const SizedBox(width: 8), Text(DateFormat('dd/MM/yyyy').format(_tempDateTo!))]),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setStateBottom(() {
                              _tempStatusFilter = 'all';
                              _tempGuruFilter = 'all';
                              _tempDateFrom = DateTime.now().subtract(const Duration(days: 30));
                              _tempDateTo = DateTime.now();
                              _searchController.clear();
                            });
                          },
                          child: const Text('Reset'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () { _applyFilters(); Navigator.pop(context); },
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0B4D8A), foregroundColor: Colors.white),
                          child: const Text('Terapkan'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final stats = widget.dashboardData?.stats ?? Statistics.empty();
    final guruStats = widget.dashboardData?.guruStats ?? GuruStatistics.empty();
    
    return RefreshIndicator(
      onRefresh: () async => widget.onRefresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 20),
            _buildStatsCards(stats, guruStats),
            const SizedBox(height: 20),
            _buildPerformanceChart(context, guruStats),
            const SizedBox(height: 20),
            _buildMessageTypeChart(context),
            const SizedBox(height: 20),
            _buildFilterBar(),
            const SizedBox(height: 12),
            _buildMessagesList(),
            if (widget.totalPages > 1) _buildPagination(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final displayUserType = widget.userType == 'Kepala_Sekolah' ? 'Kepala Sekolah' : 'Wakil Kepala Sekolah';
    final formattedDate = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(DateTime.now());
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF0B4D8A), Color(0xFF1A73E8)]), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          CircleAvatar(radius: 30, backgroundColor: Colors.white, child: Text(Helpers.getInitials(widget.userName), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0B4D8A)))),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Selamat datang,', style: TextStyle(color: Colors.white70, fontSize: 12)),
                Text(widget.userName, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                Text(displayUserType, style: TextStyle(color: Colors.white70, fontSize: 12)),
                Text(formattedDate, style: TextStyle(color: Colors.white54, fontSize: 11)),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: widget.onRefresh),
              Row(
                children: [
                  IconButton(icon: const Icon(Icons.table_chart, color: Colors.white, size: 20), onPressed: widget.onExportExcel),
                  IconButton(icon: const Icon(Icons.picture_as_pdf, color: Colors.white, size: 20), onPressed: widget.onExportPdf),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards(Statistics stats, GuruStatistics guruStats) {
    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _buildSmallStatCard(
                          'Direspon Guru', 
                          stats.totalResponded.toString(), 
                          Icons.check_circle, 
                          Colors.blue
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: _buildSmallStatCard(
                          'Menunggu Review', 
                          stats.pendingReview.toString(), 
                          Icons.pending_actions, 
                          Colors.orange
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _buildSmallStatCard(
                          'Sudah Direview', 
                          stats.reviewed.toString(), 
                          Icons.verified, 
                          Colors.green
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: _buildSmallStatCard(
                          'Rata-rata Respon', 
                          '${stats.avgResponseTime} jam', 
                          Icons.speed, 
                          Colors.purple
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.blue[50], 
            borderRadius: BorderRadius.circular(8)
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.people, size: 20, color: Colors.blue[700]),
                  const SizedBox(width: 8),
                  Text(
                    'Total Guru Aktif:', 
                    style: TextStyle(
                      fontSize: 13, 
                      fontWeight: FontWeight.w500, 
                      color: Colors.blue[700]
                    ),
                  ),
                ],
              ),
              Text(
                '${guruStats.totalActiveGuru} Guru', 
                style: TextStyle(
                  fontSize: 16, 
                  fontWeight: FontWeight.bold, 
                  color: Colors.blue[700]
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSmallStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        constraints: const BoxConstraints(
          minHeight: 120,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, size: 36, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
                height: 1.2,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
                height: 1.2,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceChart(BuildContext context, GuruStatistics guruStats) {
  final guruDataList = widget.guruPerformances;
  
  if (guruDataList.isEmpty) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.bar_chart, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text('Belum ada data kinerja guru', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            ],
          ),
        ),
      ),
    );
  }
  
  int maxTotalPesan = guruDataList.fold<int>(0, (max, g) => g.totalMessages > max ? g.totalMessages : max);
  double yAxisMax = (maxTotalPesan * 1.2).ceilToDouble();
  if (yAxisMax < 5) yAxisMax = 5;
  
  return Card(
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF0B4D8A).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.bar_chart, color: Color(0xFF0B4D8A), size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Komparasi Kinerja Guru Responder',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${DateFormat('dd MMM yyyy').format(widget.dateFrom)} - ${DateFormat('dd MMM yyyy').format(widget.dateTo)}',
                      style: TextStyle(fontSize: 9, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Statistik ringkasan
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        guruStats.totalRespondedAll.toString(),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                      const Text('Total Direspon', style: TextStyle(fontSize: 9)),
                    ],
                  ),
                ),
                Container(width: 1, height: 25, color: Colors.grey[300]),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '${guruStats.avgResponseAll.toStringAsFixed(1)} jam',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange),
                      ),
                      const Text('Rata-rata Waktu', style: TextStyle(fontSize: 9)),
                    ],
                  ),
                ),
                Container(width: 1, height: 25, color: Colors.grey[300]),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '${guruStats.completionRate.toStringAsFixed(0)}%',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.purple),
                      ),
                      const Text('Tingkat Penyelesaian', style: TextStyle(fontSize: 9)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Grafik batang dengan scroll horizontal - DIPERKECIL UKURANNYA
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: guruDataList.asMap().entries.map((entry) {
                final guru = entry.value;
                
                final totalHeight = (guru.totalMessages / yAxisMax) * 160;
                final respondedHeight = (guru.respondedMessages / yAxisMax) * 160;
                final pendingHeight = (guru.pendingMessages / yAxisMax) * 160;
                final expiredHeight = (guru.expiredMessages / yAxisMax) * 160;
                
                return Container(
                  width: 85, // Dikurangi dari 110 menjadi 85
                  margin: const EdgeInsets.only(right: 12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // 4 batang vertikal berdampingan - DIPERKECIL
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Total Pesan
                          Column(
                            children: [
                              Container(
                                width: 15, // Dikurangi dari 20 menjadi 15
                                height: totalHeight,
                                decoration: BoxDecoration(
                                  color: Colors.grey,
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                                ),
                                child: totalHeight > 20
                                    ? Center(
                                        child: Transform.rotate(
                                          angle: -1.57,
                                          child: Text(
                                            '${guru.totalMessages}',
                                            style: const TextStyle(fontSize: 7, color: Colors.white, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      )
                                    : null,
                              ),
                              const SizedBox(height: 2),
                              const Text('Tot', style: TextStyle(fontSize: 7)),
                            ],
                          ),
                          const SizedBox(width: 3),
                          // Direspon
                          Column(
                            children: [
                              Container(
                                width: 15,
                                height: respondedHeight,
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                                ),
                                child: respondedHeight > 20
                                    ? Center(
                                        child: Transform.rotate(
                                          angle: -1.57,
                                          child: Text(
                                            '${guru.respondedMessages}',
                                            style: const TextStyle(fontSize: 7, color: Colors.white, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      )
                                    : null,
                              ),
                              const SizedBox(height: 2),
                              const Text('Rsp', style: TextStyle(fontSize: 7)),
                            ],
                          ),
                          const SizedBox(width: 3),
                          // Pending
                          Column(
                            children: [
                              Container(
                                width: 15,
                                height: pendingHeight,
                                decoration: BoxDecoration(
                                  color: Colors.orange,
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                                ),
                                child: pendingHeight > 20
                                    ? Center(
                                        child: Transform.rotate(
                                          angle: -1.57,
                                          child: Text(
                                            '${guru.pendingMessages}',
                                            style: const TextStyle(fontSize: 7, color: Colors.white, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      )
                                    : null,
                              ),
                              const SizedBox(height: 2),
                              const Text('Pnd', style: TextStyle(fontSize: 7)),
                            ],
                          ),
                          const SizedBox(width: 3),
                          // Expired
                          Column(
                            children: [
                              Container(
                                width: 15,
                                height: expiredHeight,
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                                ),
                                child: expiredHeight > 20
                                    ? Center(
                                        child: Transform.rotate(
                                          angle: -1.57,
                                          child: Text(
                                            '${guru.expiredMessages}',
                                            style: const TextStyle(fontSize: 7, color: Colors.white, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      )
                                    : null,
                              ),
                              const SizedBox(height: 2),
                              const Text('Exp', style: TextStyle(fontSize: 7)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Label guru di bawah sumbu X - DIPERKECIL
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Column(
                          children: [
                            Text(
                              guru.namaLengkap.length > 8 ? '${guru.namaLengkap.substring(0, 6)}..' : guru.namaLengkap,
                              style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 1),
                            Text(
                              '${guru.respondedMessages}/${guru.totalMessages}',
                              style: const TextStyle(fontSize: 7, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Legend - DIPERKECIL
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 6,
            children: [
              _buildLegendDot('Total', Colors.grey),
              _buildLegendDot('Direspon', Colors.green),
              _buildLegendDot('Pending', Colors.orange),
              _buildLegendDot('Expired', Colors.red),
            ],
          ),
          
          const SizedBox(height: 6),
          
          // Informasi scroll
          Center(
            child: Text(
              'Geser ke kanan/kiri untuk melihat semua guru',
              style: TextStyle(fontSize: 9, color: Colors.grey[500]),
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildLegendItemStatic(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildGuruStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
      child: Column(
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildDistribusiItem(String label, int value, Color color) {
    return Column(
      children: [
        Text(value.toString(), style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey), textAlign: TextAlign.center),
      ],
    );
  }

  Widget _buildMessageTypeChart(BuildContext context) {
  if (widget.messageTypeStats.isEmpty) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.pie_chart, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text('Belum ada data jenis pesan', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            ],
          ),
        ),
      ),
    );
  }
  
  final messageTypeList = widget.messageTypeStats;
  int maxTotalPesan = messageTypeList.fold<int>(0, (max, t) => t.totalMessages > max ? t.totalMessages : max);
  double yAxisMax = (maxTotalPesan * 1.2).ceilToDouble();
  if (yAxisMax < 5) yAxisMax = 5;
  
  return Card(
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.pie_chart, color: Colors.green, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Komparasi Jenis Pesan',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Total vs Direspon per jenis pesan',
                      style: TextStyle(fontSize: 9, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Grafik batang dengan scroll horizontal - DIPERKECIL
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: messageTypeList.asMap().entries.map((entry) {
                final type = entry.value;
                
                final totalHeight = (type.totalMessages / yAxisMax) * 160;
                final respondedHeight = (type.respondedMessages / yAxisMax) * 160;
                
                return Container(
                  width: 130, // Dikurangi dari 160 menjadi 130
                  margin: const EdgeInsets.only(right: 12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // 2 batang berdampingan
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Batang Total Pesan
                          Expanded(
                            child: Column(
                              children: [
                                Container(
                                  height: totalHeight,
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                                  ),
                                  child: totalHeight > 25
                                      ? Center(
                                          child: Transform.rotate(
                                            angle: -1.57,
                                            child: Text(
                                              '${type.totalMessages}',
                                              style: const TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        )
                                      : null,
                                ),
                                const SizedBox(height: 3),
                                const Text('Total', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Batang Direspon
                          Expanded(
                            child: Column(
                              children: [
                                Container(
                                  height: respondedHeight,
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                                  ),
                                  child: respondedHeight > 25
                                      ? Center(
                                          child: Transform.rotate(
                                            angle: -1.57,
                                            child: Text(
                                              '${type.respondedMessages}',
                                              style: const TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        )
                                      : null,
                                ),
                                const SizedBox(height: 3),
                                const Text('Direspon', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Label jenis pesan - DIPERKECIL
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Column(
                          children: [
                            Text(
                              type.jenisPesan.length > 20 ? '${type.jenisPesan.substring(0, 17)}..' : type.jenisPesan,
                              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (type.responderType != null) ...[
                              const SizedBox(height: 3),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: Colors.blue[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  type.responderType!.replaceAll('Guru_', ''),
                                  style: const TextStyle(fontSize: 7),
                                ),
                              ),
                            ],
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: type.totalMessages > 0
                                    ? (type.respondedMessages / type.totalMessages >= 0.8
                                        ? Colors.green[100]
                                        : type.respondedMessages / type.totalMessages >= 0.5
                                            ? Colors.orange[100]
                                            : Colors.red[100])
                                    : Colors.grey[100],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${type.totalMessages > 0 ? (type.respondedMessages / type.totalMessages * 100).round() : 0}%',
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w600,
                                  color: type.totalMessages > 0
                                      ? (type.respondedMessages / type.totalMessages >= 0.8
                                          ? Colors.green[700]
                                          : type.respondedMessages / type.totalMessages >= 0.5
                                              ? Colors.orange[700]
                                              : Colors.red[700])
                                      : Colors.grey[600],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Legend - DIPERKECIL
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 16,
            runSpacing: 6,
            children: [
              _buildLegendDot('Total Pesan', Colors.blue),
              _buildLegendDot('Direspon', Colors.green),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Ringkasan statistik - DIPERKECIL
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    Text(
                      '${messageTypeList.length}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
                    ),
                    const Text('Jenis Pesan', style: TextStyle(fontSize: 9)),
                  ],
                ),
                Container(width: 1, height: 30, color: Colors.grey[300]),
                Column(
                  children: [
                    Text(
                      '${messageTypeList.fold<int>(0, (sum, t) => sum + t.totalMessages)}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                    const Text('Total Pesan', style: TextStyle(fontSize: 9)),
                  ],
                ),
                Container(width: 1, height: 30, color: Colors.grey[300]),
                Column(
                  children: [
                    Text(
                      '${messageTypeList.fold<int>(0, (sum, t) => sum + t.respondedMessages)}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange),
                    ),
                    const Text('Total Direspon', style: TextStyle(fontSize: 9)),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 6),
          
          // Informasi scroll
          Center(
            child: Text(
              'Geser ke kanan/kiri untuk melihat semua jenis pesan',
              style: TextStyle(fontSize: 9, color: Colors.grey[500]),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildLegendDot(String label, Color color) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      ),
      const SizedBox(width: 5),
      Text(
        label,
        style: const TextStyle(fontSize: 10),
      ),
    ],
  );
}

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.grey[50],
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari pesan, pengirim, atau guru...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty ? IconButton(icon: const Icon(Icons.clear), onPressed: () { _searchController.clear(); _applyFilters(); }) : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onSubmitted: (_) => _applyFilters(),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
            child: IconButton(icon: const Icon(Icons.filter_list), onPressed: _showFilterDialog, tooltip: 'Filter'),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
            child: IconButton(icon: const Icon(Icons.refresh), onPressed: widget.onRefresh, tooltip: 'Refresh'),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    if (widget.messages.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text('Tidak ada data', style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 8),
              Text(
                widget.userType == 'Kepala_Sekolah'
                    ? 'Tidak ada pesan yang telah direspons guru atau wakil kepala sekolah pada periode ini.'
                    : 'Tidak ada pesan yang telah direspons guru pada periode ini.',
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Text('Daftar Pesan yang Direspon Guru (${widget.totalMessages})', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey)),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: widget.messages.length,
          itemBuilder: (context, index) {
            final msg = widget.messages[index];
            final isReviewed = widget.userType == 'Kepala_Sekolah' ? msg.kepsekReviewId != null : msg.reviewId != null;
            
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ExpansionTile(
                leading: CircleAvatar(
                  backgroundColor: isReviewed ? Colors.green : Colors.orange,
                  radius: 16,
                  child: Text('${index + 1}', style: const TextStyle(color: Colors.white, fontSize: 11)),
                ),
                title: Text(msg.pengirimNamaDisplay, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(msg.messageType ?? 'Pesan', style: const TextStyle(fontSize: 11)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (msg.attachmentCount > 0) Icon(Icons.attach_file, size: 10, color: Colors.grey[600]),
                        if (msg.attachmentCount > 0) Text(' ${msg.attachmentCount} file', style: TextStyle(fontSize: 9, color: Colors.grey[600])),
                        const Spacer(),
                        Text(DateFormat('dd/MM/yyyy HH:mm').format(msg.createdAt), style: TextStyle(fontSize: 9, color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
                trailing: isReviewed ? const Icon(Icons.check_circle, color: Colors.green, size: 18) : const Icon(Icons.pending, color: Colors.orange, size: 18),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.blue[200]!)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [const Icon(Icons.message, size: 14, color: Colors.blue), const SizedBox(width: 6), Text('Pesan Asli', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.blue[800])), const Spacer(), Text(DateFormat('dd/MM/yyyy HH:mm').format(msg.createdAt), style: TextStyle(fontSize: 9, color: Colors.grey))]),
                              const SizedBox(height: 6),
                              Text(msg.isiPesan, style: const TextStyle(fontSize: 12)),
                              const SizedBox(height: 6),
                              Row(children: [Icon(Icons.person, size: 12, color: Colors.grey[600]), const SizedBox(width: 4), Text(msg.pengirimNamaDisplay, style: const TextStyle(fontSize: 10)), const SizedBox(width: 8), Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(4)), child: Text(msg.pengirimTipe?.replaceAll('_', ' ') ?? '-', style: const TextStyle(fontSize: 9)))]),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (msg.guruResponse != null)
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.green[200]!)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [const Icon(Icons.school, size: 14, color: Colors.green), const SizedBox(width: 6), Text('Respon Guru', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.green[800])), const Spacer(), if (msg.guruResponseDate != null) Text(DateFormat('dd/MM/yyyy HH:mm').format(msg.guruResponseDate!), style: TextStyle(fontSize: 9, color: Colors.grey))]),
                                const SizedBox(height: 6),
                                Text(msg.guruResponse!, style: const TextStyle(fontSize: 12)),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(Icons.person, size: 12, color: Colors.grey[600]),
                                    const SizedBox(width: 4),
                                    Text(msg.guruResponderNama ?? '-', style: const TextStyle(fontSize: 10)),
                                    const SizedBox(width: 8),
                                    Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.green[100], borderRadius: BorderRadius.circular(4)), child: Text(msg.guruResponderType?.replaceAll('Guru_', '') ?? '-', style: const TextStyle(fontSize: 9))),
                                    const Spacer(),
                                    Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: msg.guruResponseStatus == 'Disetujui' ? Colors.green[100] : Colors.orange[100], borderRadius: BorderRadius.circular(4)), child: Text(msg.guruResponseStatus ?? 'Pending', style: TextStyle(fontSize: 9, color: msg.guruResponseStatus == 'Disetujui' ? Colors.green[800] : Colors.orange[800]))),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            if (widget.userType == 'Wakil_Kepala' && msg.reviewId == null && msg.guruResponse != null)
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _showReviewDialog(context, msg),
                                  icon: const Icon(Icons.check, size: 16),
                                  label: const Text('Beri Review', style: TextStyle(fontSize: 11)),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 8)),
                                ),
                              ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _showDetailDialog(context, msg),
                                icon: const Icon(Icons.visibility, size: 16),
                                label: const Text('Lihat Detail', style: TextStyle(fontSize: 11)),
                                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 8)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPagination() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(color: Colors.grey[50], border: Border(top: BorderSide(color: Colors.grey[200]!))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(icon: const Icon(Icons.chevron_left), onPressed: widget.currentPage > 1 ? () => widget.onPageChanged(widget.currentPage - 1) : null),
          Text('Halaman ${widget.currentPage} dari ${widget.totalPages}'),
          IconButton(icon: const Icon(Icons.chevron_right), onPressed: widget.currentPage < widget.totalPages ? () => widget.onPageChanged(widget.currentPage + 1) : null),
        ],
      ),
    );
  }

  void _showReviewDialog(BuildContext context, MessageItem msg) {
    final TextEditingController catatanController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(children: [Icon(widget.userType == 'Kepala_Sekolah' ? Icons.emoji_events : Icons.verified_user, color: Colors.green), const SizedBox(width: 8), Text(widget.userType == 'Kepala_Sekolah' ? 'Review Kepala Sekolah' : 'Review Wakil Kepala Sekolah')]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Pesan dari:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                  Text(msg.pengirimNamaDisplay, style: const TextStyle(fontSize: 12)),
                  const SizedBox(height: 8),
                  const Text('Isi Pesan:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                  Text(msg.isiPesan, style: const TextStyle(fontSize: 12), maxLines: 3, overflow: TextOverflow.ellipsis),
                  if (msg.guruResponse != null) ...[
                    const SizedBox(height: 8),
                    const Text('Respon Guru:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                    Text(msg.guruResponse!, style: const TextStyle(fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('Catatan Review', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(controller: catatanController, maxLines: 4, decoration: const InputDecoration(hintText: 'Tulis catatan review Anda di sini...', border: OutlineInputBorder())),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () { if (catatanController.text.trim().isNotEmpty) { widget.onSubmitReview(msg.id, catatanController.text.trim()); Navigator.pop(context); } },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            child: const Text('Simpan Review'),
          ),
        ],
      ),
    );
  }

  void _showDetailDialog(BuildContext context, MessageItem msg) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detail Pesan'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Pengirim', msg.pengirimNamaDisplay),
              _buildDetailRow('Tipe Pengirim', msg.pengirimTipe?.replaceAll('_', ' ') ?? '-'),
              _buildDetailRow('Jenis Pesan', msg.messageType ?? '-'),
              _buildDetailRow('Waktu Kirim', DateFormat('dd/MM/yyyy HH:mm:ss').format(msg.createdAt)),
              _buildDetailRow('Status', msg.status ?? 'Pending'),
              const Divider(),
              const Text('Isi Pesan:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Container(padding: const EdgeInsets.all(8), color: Colors.grey[100], child: Text(msg.isiPesan)),
              if (msg.guruResponse != null) ...[
                const Divider(),
                const Text('Respon Guru:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                _buildDetailRow('Guru Responder', msg.guruResponderNama ?? '-'),
                _buildDetailRow('Status Respon', msg.guruResponseStatus ?? '-'),
                if (msg.guruResponseDate != null) _buildDetailRow('Waktu Respon', DateFormat('dd/MM/yyyy HH:mm:ss').format(msg.guruResponseDate!)),
                const SizedBox(height: 4),
                Container(padding: const EdgeInsets.all(8), color: Colors.green[50], child: Text(msg.guruResponse!)),
              ],
            ],
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup'))],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [SizedBox(width: 100, child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11))), Expanded(child: Text(value, style: const TextStyle(fontSize: 11)))]),
    );
  }
}

// ============================================================================
// REVIEW CONTENT
// ============================================================================
class _ReviewContent extends StatefulWidget {
  final List<MessageItem> messages;
  final int totalMessages;
  final int currentPage;
  final int totalPages;
  final String statusFilter;
  final String guruFilter;
  final List<GuruItem> guruList;
  final DateTime dateFrom;
  final DateTime dateTo;
  final String searchQuery;
  final String userType;
  final Function(String, String, DateTime, DateTime, String) onFilterChanged;
  final Function(int) onPageChanged;
  final VoidCallback onRefresh;
  final Function(int, String) onSubmitReview;
  
  const _ReviewContent({
    required this.messages,
    required this.totalMessages,
    required this.currentPage,
    required this.totalPages,
    required this.statusFilter,
    required this.guruFilter,
    required this.guruList,
    required this.dateFrom,
    required this.dateTo,
    required this.searchQuery,
    required this.userType,
    required this.onFilterChanged,
    required this.onPageChanged,
    required this.onRefresh,
    required this.onSubmitReview,
  });

  @override
  State<_ReviewContent> createState() => _ReviewContentState();
}

class _ReviewContentState extends State<_ReviewContent> {
  late TextEditingController _searchController;
  String _tempStatusFilter = 'all';
  String _tempGuruFilter = 'all';
  DateTime? _tempDateFrom;
  DateTime? _tempDateTo;
  
  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.searchQuery);
    _tempStatusFilter = widget.statusFilter;
    _tempGuruFilter = widget.guruFilter;
    _tempDateFrom = widget.dateFrom;
    _tempDateTo = widget.dateTo;
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  void _applyFilters() {
    widget.onFilterChanged(_tempStatusFilter, _tempGuruFilter, _tempDateFrom!, _tempDateTo!, _searchController.text);
  }
  
  @override
  Widget build(BuildContext context) {
    return WindowResizerShortcut(
      child: RefreshIndicator(
        onRefresh: () async => widget.onRefresh(),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.grey[50],
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Cari pesan, pengirim, atau guru...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchController.text.isNotEmpty ? IconButton(icon: const Icon(Icons.clear), onPressed: () { _searchController.clear(); _applyFilters(); }) : null,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onSubmitted: (_) => _applyFilters(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)), child: IconButton(icon: const Icon(Icons.filter_list), onPressed: _showFilterDialog, tooltip: 'Filter')),
                  const SizedBox(width: 8),
                  Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)), child: IconButton(icon: const Icon(Icons.refresh), onPressed: widget.onRefresh, tooltip: 'Refresh')),
                ],
              ),
            ),
            Expanded(
              child: widget.messages.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text('Tidak ada data', style: TextStyle(color: Colors.grey[600])),
                          const SizedBox(height: 8),
                          Text(
                            widget.userType == 'Kepala_Sekolah'
                                ? 'Tidak ada pesan yang telah direspons guru atau wakil kepala sekolah pada periode ini.'
                                : 'Tidak ada pesan yang telah direspons guru pada periode ini.',
                            style: TextStyle(color: Colors.grey[500], fontSize: 12),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: widget.messages.length,
                      itemBuilder: (context, index) {
                        final msg = widget.messages[index];
                        final isReviewed = widget.userType == 'Kepala_Sekolah' ? msg.kepsekReviewId != null : msg.reviewId != null;
                        final hasWakepsekReview = msg.wakepsekReviewId != null;
                        
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          color: widget.userType == 'Kepala_Sekolah' && msg.kepsekReviewId != null ? Colors.green[50] : widget.userType == 'Kepala_Sekolah' && hasWakepsekReview ? Colors.blue[50] : null,
                          child: ExpansionTile(
                            leading: CircleAvatar(backgroundColor: isReviewed ? Colors.green : Colors.orange, child: Text('${(widget.currentPage - 1) * 15 + index + 1}', style: const TextStyle(color: Colors.white, fontSize: 12))),
                            title: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(msg.messageType ?? 'Pesan', style: const TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text('Dari: ${msg.pengirimNamaDisplay}', style: const TextStyle(fontSize: 12)),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Guru: ${msg.guruResponderNama ?? '-'}', style: const TextStyle(fontSize: 11)),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    if (msg.attachmentCount > 0) Icon(Icons.attach_file, size: 12, color: Colors.grey[600]),
                                    if (msg.attachmentCount > 0) Text(' ${msg.attachmentCount} file', style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                                    const Spacer(),
                                    Text(DateFormat('dd/MM/yyyy HH:mm').format(msg.createdAt), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                  ],
                                ),
                              ],
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (isReviewed) const Icon(Icons.check_circle, color: Colors.green, size: 20)
                                else if (widget.userType == 'Kepala_Sekolah' && hasWakepsekReview) const Icon(Icons.pending, color: Colors.orange, size: 20)
                                else const Icon(Icons.pending, color: Colors.grey, size: 20),
                                const SizedBox(height: 4),
                                Text(isReviewed ? 'Direview' : 'Menunggu', style: const TextStyle(fontSize: 9)),
                              ],
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.blue[200]!)),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(children: [const Icon(Icons.message, size: 16, color: Colors.blue), const SizedBox(width: 8), Text('Pesan Asli', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue[800])), const Spacer(), Text(DateFormat('dd/MM/yyyy HH:mm').format(msg.createdAt), style: const TextStyle(fontSize: 10, color: Colors.grey))]),
                                          const SizedBox(height: 8),
                                          Text(msg.isiPesan),
                                          const SizedBox(height: 8),
                                          Row(children: [Icon(Icons.person, size: 12, color: Colors.grey[600]), const SizedBox(width: 4), Text(msg.pengirimNamaDisplay, style: const TextStyle(fontSize: 11)), const SizedBox(width: 8), Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(4)), child: Text(msg.pengirimTipe?.replaceAll('_', ' ') ?? '-', style: const TextStyle(fontSize: 10)))]),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    if (msg.guruResponse != null)
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.green[200]!)),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(children: [const Icon(Icons.school, size: 16, color: Colors.green), const SizedBox(width: 8), Text('Respon Guru', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green[800])), const Spacer(), if (msg.guruResponseDate != null) Text(DateFormat('dd/MM/yyyy HH:mm').format(msg.guruResponseDate!), style: const TextStyle(fontSize: 10, color: Colors.grey))]),
                                            const SizedBox(height: 8),
                                            Text(msg.guruResponse!),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                Icon(Icons.person, size: 12, color: Colors.grey[600]),
                                                const SizedBox(width: 4),
                                                Text(msg.guruResponderNama ?? '-', style: const TextStyle(fontSize: 11)),
                                                const SizedBox(width: 8),
                                                Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.green[100], borderRadius: BorderRadius.circular(4)), child: Text(msg.guruResponderType?.replaceAll('Guru_', '') ?? '-', style: const TextStyle(fontSize: 10))),
                                                const Spacer(),
                                                Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: msg.guruResponseStatus == 'Disetujui' ? Colors.green[100] : Colors.orange[100], borderRadius: BorderRadius.circular(4)), child: Text(msg.guruResponseStatus ?? 'Pending', style: TextStyle(fontSize: 10, color: msg.guruResponseStatus == 'Disetujui' ? Colors.green[800] : Colors.orange[800]))),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    const SizedBox(height: 12),
                                    if (widget.userType == 'Kepala_Sekolah' && msg.wakepsekReviewCatatan != null)
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(color: Colors.purple[50], borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.purple[200]!)),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(children: [const Icon(Icons.verified_user, size: 16, color: Colors.purple), const SizedBox(width: 8), Text('Review Wakil Kepala Sekolah', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple[800])), const Spacer(), if (msg.wakepsekReviewDate != null) Text(DateFormat('dd/MM/yyyy HH:mm').format(msg.wakepsekReviewDate!), style: const TextStyle(fontSize: 10, color: Colors.grey))]),
                                            const SizedBox(height: 8),
                                            Text(msg.wakepsekReviewCatatan!),
                                            const SizedBox(height: 8),
                                            Row(children: [Icon(Icons.person, size: 12, color: Colors.grey[600]), const SizedBox(width: 4), Text(msg.wakepsekReviewerNama ?? 'Wakil Kepala Sekolah', style: const TextStyle(fontSize: 11))]),
                                          ],
                                        ),
                                      ),
                                    const SizedBox(height: 12),
                                    if (msg.attachmentCount > 0)
                                      AttachmentGrid(
                                        messageId: msg.id,
                                        onPreviewImage: (url, name) => showDialog(context: context, builder: (context) => ImagePreviewDialog(imageUrl: url, imageName: name)),
                                      ),
                                    Row(
                                      children: [
                                        if (widget.userType == 'Wakil_Kepala' && msg.reviewId == null && msg.guruResponse != null)
                                          Expanded(child: ElevatedButton.icon(onPressed: () => _showReviewDialog(context, msg), icon: const Icon(Icons.check), label: const Text('Beri Review'), style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white))),
                                        if (widget.userType == 'Kepala_Sekolah' && msg.kepsekReviewId == null && (msg.guruResponse != null || msg.wakepsekReviewId != null))
                                          Expanded(child: ElevatedButton.icon(onPressed: () => _showReviewDialog(context, msg), icon: const Icon(Icons.check), label: const Text('Review Kepsek'), style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white))),
                                        if ((widget.userType == 'Wakil_Kepala' && msg.reviewId != null) || (widget.userType == 'Kepala_Sekolah' && msg.kepsekReviewId != null))
                                          Expanded(child: OutlinedButton.icon(onPressed: () => _showDetailDialog(context, msg), icon: const Icon(Icons.info), label: const Text('Detail'))),
                                        const SizedBox(width: 8),
                                        Expanded(child: OutlinedButton.icon(onPressed: () => _showFullDetailDialog(context, msg), icon: const Icon(Icons.visibility), label: const Text('Lihat Lengkap'))),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            if (widget.totalPages > 1)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(color: Colors.grey[50], border: Border(top: BorderSide(color: Colors.grey[200]!))),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(icon: const Icon(Icons.chevron_left), onPressed: widget.currentPage > 1 ? () => widget.onPageChanged(widget.currentPage - 1) : null),
                    Text('Halaman ${widget.currentPage} dari ${widget.totalPages}'),
                    IconButton(icon: const Icon(Icons.chevron_right), onPressed: widget.currentPage < widget.totalPages ? () => widget.onPageChanged(widget.currentPage + 1) : null),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateBottom) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(child: SizedBox(width: 40, height: 4, child: DecoratedBox(decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.all(Radius.circular(2)))))),
                  const SizedBox(height: 16),
                  const Text('Filter Pesan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  const Text('Status Review', style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: const [ButtonSegment(value: 'all', label: Text('Semua')), ButtonSegment(value: 'pending', label: Text('Menunggu')), ButtonSegment(value: 'reviewed', label: Text('Direview'))],
                    selected: {_tempStatusFilter},
                    onSelectionChanged: (Set<String> selection) => setStateBottom(() => _tempStatusFilter = selection.first),
                  ),
                  const SizedBox(height: 16),
                  const Text('Guru Responder', style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _tempGuruFilter,
                    items: [const DropdownMenuItem(value: 'all', child: Text('Semua Guru')), ...widget.guruList.map((guru) => DropdownMenuItem(value: guru.id.toString(), child: Text(guru.namaLengkap)))],
                    onChanged: (value) => setStateBottom(() => _tempGuruFilter = value!),
                    decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                  ),
                  const SizedBox(height: 16),
                  const Text('Rentang Tanggal', style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: InkWell(onTap: () async { final date = await showDatePicker(context: context, initialDate: _tempDateFrom!, firstDate: DateTime(2020), lastDate: DateTime.now()); if (date != null) setStateBottom(() => _tempDateFrom = date); }, child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12), decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(8)), child: Row(children: [const Icon(Icons.calendar_today, size: 16), const SizedBox(width: 8), Text(DateFormat('dd/MM/yyyy').format(_tempDateFrom!))])))),
                      const SizedBox(width: 12),
                      const Text('-'),
                      const SizedBox(width: 12),
                      Expanded(child: InkWell(onTap: () async { final date = await showDatePicker(context: context, initialDate: _tempDateTo!, firstDate: DateTime(2020), lastDate: DateTime.now()); if (date != null) setStateBottom(() => _tempDateTo = date); }, child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12), decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(8)), child: Row(children: [const Icon(Icons.calendar_today, size: 16), const SizedBox(width: 8), Text(DateFormat('dd/MM/yyyy').format(_tempDateTo!))])))),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(child: OutlinedButton(onPressed: () { setStateBottom(() { _tempStatusFilter = 'all'; _tempGuruFilter = 'all'; _tempDateFrom = DateTime.now().subtract(const Duration(days: 30)); _tempDateTo = DateTime.now(); _searchController.clear(); }); }, child: const Text('Reset'))),
                      const SizedBox(width: 12),
                      Expanded(child: ElevatedButton(onPressed: () { _applyFilters(); Navigator.pop(context); }, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0B4D8A), foregroundColor: Colors.white), child: const Text('Terapkan'))),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showReviewDialog(BuildContext context, MessageItem msg) {
    final TextEditingController catatanController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(children: [Icon(widget.userType == 'Kepala_Sekolah' ? Icons.emoji_events : Icons.verified_user, color: Colors.green), const SizedBox(width: 8), Text(widget.userType == 'Kepala_Sekolah' ? 'Review Kepala Sekolah' : 'Review Wakil Kepala Sekolah')]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Pesan dari:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(msg.pengirimNamaDisplay),
                  const SizedBox(height: 8),
                  const Text('Isi Pesan:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(msg.isiPesan, maxLines: 3, overflow: TextOverflow.ellipsis),
                  if (msg.guruResponse != null) ...[
                    const SizedBox(height: 8),
                    const Text('Respon Guru:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(msg.guruResponse!, maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                  if (widget.userType == 'Kepala_Sekolah' && msg.wakepsekReviewCatatan != null) ...[
                    const SizedBox(height: 8),
                    const Text('Review Wakepsek:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(msg.wakepsekReviewCatatan!, maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('Catatan Review', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(controller: catatanController, maxLines: 4, decoration: const InputDecoration(hintText: 'Tulis catatan review Anda di sini...', border: OutlineInputBorder())),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(onPressed: () { if (catatanController.text.trim().isNotEmpty) { widget.onSubmitReview(msg.id, catatanController.text.trim()); Navigator.pop(context); } }, style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white), child: const Text('Simpan Review')),
        ],
      ),
    );
  }

  void _showDetailDialog(BuildContext context, MessageItem msg) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detail Review'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (msg.reviewCatatan != null || msg.kepsekReviewCatatan != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [Icon(Icons.person, size: 16, color: Colors.grey[600]), const SizedBox(width: 8), Text(msg.reviewerNama ?? msg.kepsekReviewerNama ?? 'Pimpinan', style: const TextStyle(fontWeight: FontWeight.bold)), const Spacer(), if (msg.reviewDate != null) Text(DateFormat('dd/MM/yyyy HH:mm').format(msg.reviewDate!), style: const TextStyle(fontSize: 11, color: Colors.grey))]),
                    const SizedBox(height: 8),
                    Text(msg.reviewCatatan ?? msg.kepsekReviewCatatan ?? ''),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            const Text('Detail Pesan:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Pengirim: ${msg.pengirimNamaDisplay}'),
            Text('Guru Responder: ${msg.guruResponderNama ?? '-'}'),
            Text('Status Respon: ${msg.guruResponseStatus ?? '-'}'),
            if (msg.guruResponseDate != null) Text('Waktu Respon: ${DateFormat('dd/MM/yyyy HH:mm').format(msg.guruResponseDate!)}'),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup'))],
      ),
    );
  }

  void _showFullDetailDialog(BuildContext context, MessageItem msg) {
  // State untuk tracking loading gambar
  final Map<String, bool> imageLoadingStates = {};
  final Map<String, Uint8List?> imageDataCache = {};
  
  showDialog(
    context: context,
    builder: (context) => Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: double.maxFinite,
        constraints: const BoxConstraints(maxWidth: 700, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF0B4D8A),
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      msg.messageType ?? 'Detail Pesan',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            
            // Body dengan scroll
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailSection('Informasi Dasar', [
                      _buildDetailRow('Pengirim', msg.pengirimNamaDisplay),
                      _buildDetailRow('Tipe Pengirim', msg.pengirimTipe?.replaceAll('_', ' ') ?? '-'),
                      _buildDetailRow('Jenis Pesan', msg.messageType ?? '-'),
                      _buildDetailRow('Waktu Kirim', DateFormat('dd/MM/yyyy HH:mm:ss').format(msg.createdAt)),
                      _buildDetailRow('Status', msg.status ?? 'Pending'),
                    ]),
                    const SizedBox(height: 16),
                    
                    _buildDetailSection('Isi Pesan', [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(msg.isiPesan, style: const TextStyle(fontSize: 13)),
                      ),
                    ]),
                    const SizedBox(height: 16),
                    
                    if (msg.guruResponse != null)
                      _buildDetailSection('Respon Guru', [
                        _buildDetailRow('Guru Responder', msg.guruResponderNama ?? '-'),
                        _buildDetailRow('Tipe Guru', msg.guruResponderType?.replaceAll('Guru_', '') ?? '-'),
                        _buildDetailRow('Status Respon', msg.guruResponseStatus ?? '-'),
                        if (msg.guruResponseDate != null) 
                          _buildDetailRow('Waktu Respon', DateFormat('dd/MM/yyyy HH:mm:ss').format(msg.guruResponseDate!)),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(msg.guruResponse!, style: const TextStyle(fontSize: 13)),
                        ),
                      ]),
                    const SizedBox(height: 16),
                    
                    if (msg.wakepsekReviewCatatan != null)
                      _buildDetailSection('Review Wakil Kepala Sekolah', [
                        _buildDetailRow('Reviewer', msg.wakepsekReviewerNama ?? 'Wakil Kepala Sekolah'),
                        if (msg.wakepsekReviewDate != null)
                          _buildDetailRow('Waktu Review', DateFormat('dd/MM/yyyy HH:mm:ss').format(msg.wakepsekReviewDate!)),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.purple[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(msg.wakepsekReviewCatatan!, style: const TextStyle(fontSize: 13)),
                        ),
                      ]),
                    const SizedBox(height: 16),
                    
                    if (msg.kepsekReviewCatatan != null)
                      _buildDetailSection('Review Kepala Sekolah', [
                        _buildDetailRow('Reviewer', msg.kepsekReviewerNama ?? 'Kepala Sekolah'),
                        if (msg.kepsekReviewDate != null)
                          _buildDetailRow('Waktu Review', DateFormat('dd/MM/yyyy HH:mm:ss').format(msg.kepsekReviewDate!)),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(msg.kepsekReviewCatatan!, style: const TextStyle(fontSize: 13)),
                        ),
                      ]),
                    const SizedBox(height: 16),
                    
                    // THUMBNAIL GAMBAR - Tampilkan sebagai grid gambar yang bisa diklik
                    if (msg.attachmentCount > 0)
                      _buildAttachmentSection(msg.id),
                  ],
                ),
              ),
            ),
            
            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Tutup'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// Method untuk menampilkan section lampiran dengan thumbnail - DIPERBAIKI
Widget _buildAttachmentSection(int messageId) {
  // Cari message berdasarkan ID untuk mendapatkan attachmentCount
  final message = widget.messages.firstWhere(
    (m) => m.id == messageId,
    orElse: () => widget.messages.first,
  );
  
  // Jika tidak ada attachment, jangan tampilkan section
  if (message.attachmentCount == null || message.attachmentCount == 0) {
    return const SizedBox.shrink();
  }
  
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          const Icon(Icons.attach_file, size: 16, color: Colors.blue),
          const SizedBox(width: 8),
          const Text(
            'Lampiran',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0B4D8A)),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.blue[100],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${message.attachmentCount} file',
              style: TextStyle(fontSize: 10, color: Colors.blue[700]),
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      
      // Grid thumbnail gambar
      FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchAttachments(messageId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: SizedBox(
                  width: 30,
                  height: 30,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }
          
          if (snapshot.hasError) {
            print('❌ Error loading attachments: ${snapshot.error}');
            return Center(
              child: Column(
                children: [
                  Icon(Icons.error_outline, color: Colors.red[300], size: 40),
                  const SizedBox(height: 8),
                  Text('Gagal memuat lampiran', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                ],
              ),
            );
          }
          
          final attachments = snapshot.data ?? [];
          if (attachments.isEmpty) {
            return Center(
              child: Column(
                children: [
                  Icon(Icons.image_not_supported, color: Colors.grey[400], size: 40),
                  const SizedBox(height: 8),
                  Text('Tidak ada lampiran', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                ],
              ),
            );
          }
          
          // Filter hanya file gambar
          final imageAttachments = attachments.where((att) {
            final fileName = att['file_name']?.toString().toLowerCase() ?? '';
            return fileName.endsWith('.jpg') || 
                   fileName.endsWith('.jpeg') || 
                   fileName.endsWith('.png') || 
                   fileName.endsWith('.gif') ||
                   fileName.endsWith('.webp');
          }).toList();
          
          if (imageAttachments.isEmpty) {
            return Center(
              child: Column(
                children: [
                  Icon(Icons.description, color: Colors.grey[400], size: 40),
                  const SizedBox(height: 8),
                  Text('Tidak ada lampiran gambar', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                ],
              ),
            );
          }
          
          // Tampilkan informasi jumlah gambar yang ditemukan
          print('📡 Displaying ${imageAttachments.length} images');
          for (var att in imageAttachments) {
            print('   - ${att['file_name']} -> ${att['full_url']}');
          }
          
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.0,
            ),
            itemCount: imageAttachments.length,
            itemBuilder: (context, index) {
              final attachment = imageAttachments[index];
              final fileUrl = attachment['full_url'] ?? attachment['file_url'] ?? '';
              final fileName = attachment['file_name'] ?? 'Image ${index + 1}';
              
              print('📡 Building thumbnail $index: $fileUrl');
              
              return GestureDetector(
                onTap: () => _showFullImageDialog(context, fileUrl, fileName),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: FutureBuilder<Uint8List?>(
                      future: _loadImageThumbnail(fileUrl),
                      builder: (context, imageSnapshot) {
                        if (imageSnapshot.connectionState == ConnectionState.waiting) {
                          return Container(
                            color: Colors.grey[200],
                            child: const Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                          );
                        }
                        
                        if (imageSnapshot.hasData && imageSnapshot.data != null) {
                          return Image.memory(
                            imageSnapshot.data!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          );
                        }
                        
                        // Tampilkan placeholder jika gambar gagal dimuat
                        return Container(
                          color: Colors.grey[200],
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.broken_image, color: Colors.grey[400], size: 32),
                              const SizedBox(height: 4),
                              Text(
                                fileName.length > 15 ? '${fileName.substring(0, 12)}...' : fileName,
                                style: TextStyle(fontSize: 9, color: Colors.grey[600]),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    ],
  );
}


// Method untuk mengambil daftar lampiran dari API
Future<List<Map<String, dynamic>>> _fetchAttachments(int messageId) async {
  try {
    final token = await AuthService.getToken();
    if (token == null) return [];
    
    final url = Uri.parse('${Constants.baseUrl}/modules/admin/api/get_message_detail.php?message_id=$messageId');
    print('📡 Fetching message detail from: $url');
    
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 30));
    
    print('📡 Response status: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      if (data['success'] == true && data['message'] != null) {
        final message = data['message'];
        final List<dynamic> attachments = message['attachments'] as List? ?? [];
        
        if (attachments.isNotEmpty) {
          final List<Map<String, dynamic>> result = [];
          
          for (var att in attachments) {
            if (att is Map<String, dynamic>) {
              // Ambil filepath dari response
              String filepath = att['filepath']?.toString() ?? '';
              String filename = att['filename']?.toString() ?? '';
              
              // Jika filepath kosong, gunakan filename
              if (filepath.isEmpty && filename.isNotEmpty) {
                filepath = filename;
              }
              
              // Build URL lengkap
              String fullUrl = '';
              
              // Jika filepath sudah dimulai dengan http, gunakan langsung
              if (filepath.startsWith('http')) {
                fullUrl = filepath;
              } 
              // Jika filepath dimulai dengan uploads/, tambahkan base URL
              else if (filepath.startsWith('uploads/')) {
                fullUrl = '${Constants.baseUrl}/$filepath';
              }
              // Jika hanya nama file, coba cari di folder messages
              else if (filepath.isNotEmpty && !filepath.contains('/')) {
                fullUrl = '${Constants.baseUrl}/uploads/messages/$filepath';
              }
              // Fallback
              else {
                fullUrl = '${Constants.baseUrl}/uploads/messages/$filename';
              }
              
              print('📡 Processing attachment:');
              print('   - filepath: $filepath');
              print('   - filename: $filename');
              print('   - fullUrl: $fullUrl');
              
              result.add({
                'file_name': filename.isNotEmpty ? filename : filepath.split('/').last,
                'file_path': filepath,
                'file_url': fullUrl,
                'full_url': fullUrl,
              });
            }
          }
          return result;
        }
      }
    }
    return [];
  } catch (e) {
    print('❌ Error fetching attachments: $e');
    return [];
  }
}


// Method untuk mencoba endpoint attachment khusus
Future<List<Map<String, dynamic>>> _fetchAttachmentsFromEndpoint(int messageId) async {
  try {
    final token = await AuthService.getToken();
    if (token == null) return [];
    
    // Coba berbagai kemungkinan endpoint
    final endpoints = [
      '${Constants.baseUrl}/api/get_attachments.php?message_id=$messageId',
      '${Constants.baseUrl}/api/attachments.php?message_id=$messageId',
      '${Constants.baseUrl}/api/messages/attachments.php?message_id=$messageId',
    ];
    
    for (final endpoint in endpoints) {
      print('📡 Trying endpoint: $endpoint');
      final response = await http.get(
        Uri.parse(endpoint),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> attachments = data['attachments'] as List? ?? [];
          if (attachments.isNotEmpty) {
            final List<Map<String, dynamic>> result = [];
            for (var att in attachments) {
              if (att is Map<String, dynamic>) {
                final fileName = att['file_name']?.toString() ?? '';
                result.add({
                  'file_name': fileName,
                  'file_path': att['file_path']?.toString() ?? '',
                  'file_url': '${Constants.baseUrl}/uploads/messages/$fileName',
                  'full_url': '${Constants.baseUrl}/uploads/messages/$fileName',
                });
              }
            }
            return result;
          }
        }
      }
    }
    return [];
  } catch (e) {
    print('❌ Error in attachment endpoint: $e');
    return [];
  }
}

// Fallback method untuk mengambil lampiran
Future<List<Map<String, dynamic>>> _fetchAttachmentsFallback(int messageId) async {
  try {
    final token = await AuthService.getToken();
    if (token == null) return [];
    
    // Coba endpoint alternatif
    final url = Uri.parse('${Constants.baseUrl}/api/get_attachments.php?message_id=$messageId');
    print('📡 Fallback: Fetching from $url');
    
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    ).timeout(const Duration(seconds: 30));
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        final List<dynamic> attachmentsDynamic = data['attachments'] as List? ?? [];
        
        // Konversi ke List<Map<String, dynamic>>
        final List<Map<String, dynamic>> attachments = [];
        for (var att in attachmentsDynamic) {
          if (att is Map<String, dynamic>) {
            final filePath = att['file_path']?.toString() ?? '';
            final fileName = att['file_name']?.toString() ?? '';
            
            String fileUrl = '';
            if (fileName.contains('external_messages')) {
              fileUrl = '${Constants.baseUrl}/uploads/external_messages/$fileName';
            } else {
              fileUrl = '${Constants.baseUrl}/uploads/messages/$fileName';
            }
            
            attachments.add({
              'file_name': fileName,
              'file_path': filePath,
              'file_url': fileUrl,
            });
          }
        }
        return attachments;
      }
    }
    return [];
  } catch (e) {
    print('❌ Fallback error: $e');
    return [];
  }
}

// Method untuk load gambar thumbnail
Future<Uint8List?> _loadImageThumbnail(String imageUrl) async {
  try {
    print('📡 Loading image from URL: $imageUrl');
    
    if (imageUrl.isEmpty) {
      print('❌ Image URL is empty');
      return null;
    }
    
    // Parse URL
    final Uri url = Uri.parse(imageUrl);
    print('📡 Parsed URL: $url');
    
    final response = await http.get(url);
    print('📡 HTTP status: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      print('✅ Image loaded successfully: ${response.bodyBytes.length} bytes');
      return response.bodyBytes;
    } else {
      print('❌ Failed to load image: ${response.statusCode}');
      return null;
    }
  } catch (e) {
    print('❌ Error loading image: $e');
    return null;
  }
}


// Method untuk menampilkan dialog gambar fullscreen - DIPERBAIKI
void _showFullImageDialog(BuildContext context, String imageUrl, String imageName) {
  print('📡 Showing full image dialog for: $imageUrl');
  
  showDialog(
    context: context,
    builder: (context) => Dialog(
      insetPadding: const EdgeInsets.all(8),
      backgroundColor: Colors.black87,
      child: Container(
        width: double.maxFinite,
        constraints: const BoxConstraints(maxWidth: 800, maxHeight: 600),
        child: Stack(
          children: [
            // Image
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: FutureBuilder<Uint8List?>(
                  future: _loadImageThumbnail(imageUrl),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox(
                        width: 200,
                        height: 200,
                        child: Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      );
                    }
                    
                    if (snapshot.hasData && snapshot.data != null) {
                      return Image.memory(
                        snapshot.data!,
                        fit: BoxFit.contain,
                        width: double.infinity,
                        height: double.infinity,
                      );
                    }
                    
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.broken_image, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'Gagal memuat gambar',
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          imageName,
                          style: TextStyle(color: Colors.grey[500], fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            
            // Close button
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            
            // Image name
            Positioned(
              bottom: 8,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                color: Colors.black54,
                child: Text(
                  imageName,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0B4D8A))),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [SizedBox(width: 100, child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12))), Expanded(child: Text(value, style: const TextStyle(fontSize: 12)))]),
    );
  }
}

// ============================================================================
// REPORTS CONTENT
// ============================================================================
class _ReportsContent extends StatelessWidget {
  final DashboardData? dashboardData;
  final List<GuruPerformance> guruPerformances;
  final List<MessageTypeStat> messageTypeStats;
  final DateTime dateFrom;
  final DateTime dateTo;
  final VoidCallback onExportExcel;
  final VoidCallback onExportPdf;
  
  const _ReportsContent({
    required this.dashboardData,
    required this.guruPerformances,
    required this.messageTypeStats,
    required this.dateFrom,
    required this.dateTo,
    required this.onExportExcel,
    required this.onExportPdf,
  });

  @override
  Widget build(BuildContext context) {
    final stats = dashboardData?.stats ?? Statistics.empty();
    final guruStats = dashboardData?.guruStats ?? GuruStatistics.empty();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFF0B4D8A).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, color: Color(0xFF0B4D8A)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Periode Laporan', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Text('${DateFormat('dd MMMM yyyy', 'id_ID').format(dateFrom)} - ${DateFormat('dd MMMM yyyy', 'id_ID').format(dateTo)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Row(
                  children: [
                    _buildExportButton(context, icon: Icons.table_chart, label: 'Excel', color: Colors.green, onTap: onExportExcel),
                    const SizedBox(width: 8),
                    _buildExportButton(context, icon: Icons.picture_as_pdf, label: 'PDF', color: Colors.red, onTap: onExportPdf),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          
          const Text('Ringkasan Statistik', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              int crossAxisCount = constraints.maxWidth > 800 ? 2 : 1;
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 2.5,
                children: [
                  _buildReportCard('Total Pesan Direspon', stats.totalResponded.toString(), Icons.check_circle, Colors.blue, 'Pesan yang sudah direspons'),
                  _buildReportCard('Menunggu Review', stats.pendingReview.toString(), Icons.pending, Colors.orange, 'Perlu perhatian'),
                  _buildReportCard('Sudah Direview', stats.reviewed.toString(), Icons.verified, Colors.green, 'Telah di-approve'),
                  _buildReportCard('Rata-rata Respon', '${stats.avgResponseTime} jam', Icons.speed, Colors.purple, 'Tercepat: ${stats.fastestResponder}'),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          
          if (guruPerformances.isNotEmpty) ...[
            const Text('Detail Kinerja Guru', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Card(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 16,
                  columns: const [DataColumn(label: Text('No')), DataColumn(label: Text('Nama Guru')), DataColumn(label: Text('Tipe')), DataColumn(label: Text('Total')), DataColumn(label: Text('Direspon')), DataColumn(label: Text('Pending')), DataColumn(label: Text('Expired')), DataColumn(label: Text('Rata-rata'))],
                  rows: guruPerformances.asMap().entries.map((entry) {
                    final index = entry.key;
                    final guru = entry.value;
                    return DataRow(cells: [
                      DataCell(Text('${index + 1}')),
                      DataCell(Text(guru.namaLengkap)),
                      DataCell(Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: Colors.blue[100], borderRadius: BorderRadius.circular(4)), child: Text(guru.userType.replaceAll('Guru_', ''), style: const TextStyle(fontSize: 11)))),
                      DataCell(Text(guru.totalMessages.toString())),
                      DataCell(Text(guru.respondedMessages.toString(), style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold))),
                      DataCell(Text(guru.pendingMessages.toString())),
                      DataCell(Text(guru.expiredMessages.toString())),
                      DataCell(guru.avgResponseHours > 0 ? Text('${guru.avgResponseHours.toStringAsFixed(1)} jam') : const Text('-')),
                    ]);
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
          
          if (messageTypeStats.isNotEmpty) ...[
            const Text('Detail Jenis Pesan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Card(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 16,
                  columns: const [DataColumn(label: Text('No')), DataColumn(label: Text('Jenis Pesan')), DataColumn(label: Text('Responder')), DataColumn(label: Text('Total')), DataColumn(label: Text('Direspon')), DataColumn(label: Text('Pending')), DataColumn(label: Text('Expired')), DataColumn(label: Text('Tingkat'))],
                  rows: messageTypeStats.asMap().entries.map((entry) {
                    final index = entry.key;
                    final type = entry.value;
                    final responseRate = type.totalMessages > 0 ? (type.respondedMessages / type.totalMessages * 100).round() : 0;
                    return DataRow(cells: [
                      DataCell(Text('${index + 1}')),
                      DataCell(SizedBox(width: 150, child: Text(type.jenisPesan, maxLines: 2, overflow: TextOverflow.ellipsis))),
                      DataCell(type.responderType != null ? Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: Colors.blue[100], borderRadius: BorderRadius.circular(4)), child: Text(type.responderType!.replaceAll('Guru_', ''), style: const TextStyle(fontSize: 11))) : const Text('-')),
                      DataCell(Text(type.totalMessages.toString())),
                      DataCell(Text(type.respondedMessages.toString(), style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold))),
                      DataCell(Text(type.pendingMessages.toString())),
                      DataCell(Text(type.expiredMessages.toString())),
                      DataCell(Row(children: [SizedBox(width: 60, child: LinearProgressIndicator(value: responseRate / 100, backgroundColor: Colors.grey[300], color: responseRate >= 80 ? Colors.green : responseRate >= 50 ? Colors.orange : Colors.red, minHeight: 6, borderRadius: BorderRadius.circular(3))), const SizedBox(width: 8), Text('$responseRate%')])),
                    ]);
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
          
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.grey[600], size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text('Laporan ini dapat diekspor dalam format Excel atau PDF. Data yang ditampilkan berdasarkan periode filter yang dipilih.', style: TextStyle(color: Colors.grey[600], fontSize: 12))),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildReportCard(String title, String value, IconData icon, Color color, String subtitle) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: color),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
            if (subtitle.isNotEmpty) Text(subtitle, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
  
  Widget _buildExportButton(BuildContext context, {required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
    );
  }
}