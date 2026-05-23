import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/dashboard_service.dart';
import '../../utils/date_formatter.dart';
import '../../widgets/window_resizer_shortcut.dart'; // Import window resizer shortcut

class WakepsekReportsScreen extends StatefulWidget {
  const WakepsekReportsScreen({super.key});

  @override
  State<WakepsekReportsScreen> createState() => _WakepsekReportsScreenState();
}

class _WakepsekReportsScreenState extends State<WakepsekReportsScreen> {
  late DashboardService _dashboardService;
  Map<String, dynamic>? _reportData;
  bool _isLoading = true;
  String? _error;
  
  String _selectedPeriod = 'month';
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _dashboardService = DashboardService(
      Provider.of<AuthService>(context, listen: false),
    );
    _setDefaultDates();
    _loadReport();
  }

  void _setDefaultDates() {
    final now = DateTime.now();
    _endDate = now;
    _startDate = DateTime(now.year, now.month - 1, now.day);
  }

  Future<void> _loadReport() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await _dashboardService.getReports(
        period: _selectedPeriod,
        startDate: _startDate,
        endDate: _endDate,
      );
      
      setState(() {
        _reportData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _exportReport(String format) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Mengekspor laporan sebagai $format...'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WindowResizerShortcut(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Laporan Wakil Kepala'),
          backgroundColor: const Color(0xFF0B4D8A),
          foregroundColor: Colors.white,
          actions: [
            // Tombol untuk membuka window resizer
            IconButton(
              icon: const Icon(Icons.aspect_ratio),
              onPressed: () => WindowResizerExtension.showResizerPanel(context),
              tooltip: 'Ubah Ukuran Window (F2)',
            ),
            IconButton(
              icon: const Icon(Icons.picture_as_pdf),
              onPressed: () => _exportReport('PDF'),
              tooltip: 'Ekspor PDF',
            ),
            IconButton(
              icon: const Icon(Icons.grid_on),
              onPressed: () => _exportReport('Excel'),
              tooltip: 'Ekspor Excel',
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadReport,
              tooltip: 'Refresh',
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 60,
                          color: Colors.red[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error: $_error',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadReport,
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Report Header
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6B48FF), Color(0xFF8A6CFF)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                'Laporan Kinerja',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Periode: ${DateFormatter.formatDate(_startDate!)} - ${DateFormatter.formatDate(_endDate!)}',
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Statistics Cards
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          childAspectRatio: 1.5,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          children: [
                            _buildStatCard(
                              'Total Pesan',
                              _reportData!['total_messages']?.toString() ?? '0',
                              Icons.message,
                              Colors.blue,
                            ),
                            _buildStatCard(
                              'Sudah Direview',
                              _reportData!['reviewed']?.toString() ?? '0',
                              Icons.check_circle,
                              Colors.green,
                            ),
                            _buildStatCard(
                              'Pending Review',
                              _reportData!['pending_review']?.toString() ?? '0',
                              Icons.pending_actions,
                              Colors.orange,
                            ),
                            _buildStatCard(
                              'Response Rate',
                              '${_reportData!['response_rate'] ?? 0}%',
                              Icons.trending_up,
                              Colors.purple,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}