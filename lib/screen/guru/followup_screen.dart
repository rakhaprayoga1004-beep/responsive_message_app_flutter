// lib/screen/guru/followup_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../../models/followup_models.dart';
import '../../services/followup_service.dart';
import '../../services/auth_service.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/message_detail_dialog.dart';
import '../../widgets/window_resizer_shortcut.dart';
import '../../utils/constants.dart';
import 'dashboard_guru_screen.dart';

class FollowupScreen extends StatefulWidget {
  const FollowupScreen({super.key});

  @override
  State<FollowupScreen> createState() => _FollowupScreenState();
}

class _FollowupScreenState extends State<FollowupScreen> {
  late final FollowupService _service;
  
  String _selectedStatus = 'all';
  String _selectedPriority = 'all';
  String _selectedSource = 'all';
  String _searchQuery = '';
  int _currentPage = 1;
  
  FollowupResponse? _response;
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _errorMessage;

  final List<String> _statusOptions = [
    'all', 'pending', 'Pending', 'Dibaca', 'Diproses', 'Disetujui', 'Ditolak', 'Selesai'
  ];
  
  final List<String> _priorityOptions = ['all', 'Low', 'Medium', 'High', 'Urgent'];
  final List<String> _sourceOptions = ['all', 'internal', 'external'];

  @override
  void initState() {
    super.initState();
    _service = FollowupService();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _service.getFollowupMessages(
        status: _selectedStatus,
        priority: _selectedPriority,
        source: _selectedSource,
        search: _searchQuery,
        page: _currentPage,
      );
      
      if (mounted) {
        setState(() {
          _response = response;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshData() async {
    if (_isRefreshing) return;
    
    setState(() => _isRefreshing = true);
    await _loadMessages();
    if (mounted) {
      setState(() => _isRefreshing = false);
    }
  }

  void _applyFilters() {
    setState(() {
      _currentPage = 1;
    });
    _loadMessages();
  }

  void _showMessage(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _navigateToDashboard() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const DashboardGuruScreen(),
      ),
    );
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
        _response = null;
        _isLoading = false;
        
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

  Future<String> _getAttachmentUrl(int messageId, FollowupMessage message) async {
    try {
      final token = await AuthService.getToken();
      
      final apiUrl = Uri.parse('${Constants.baseUrl}/modules/guru/api/get_attachments.php?message_id=$messageId');
      print('📸 Getting attachment URL for message $messageId');
      
      final response = await http.get(
        apiUrl,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['attachments'] != null && data['attachments'].isNotEmpty) {
          final imageUrl = data['attachments'][0]['full_url'] ?? '';
          print('📸 Attachment URL found: $imageUrl');
          return imageUrl;
        }
      }
    } catch (e) {
      print('Error getting attachment URL: $e');
    }
    
    final createdAt = message.createdAt;
    final isExternal = message.isExternalMessage;
    final referenceNumber = message.referenceNumber;
    
    String year = '', month = '', day = '';
    if (createdAt.isNotEmpty) {
      try {
        final date = DateTime.parse(createdAt);
        year = date.year.toString();
        month = date.month.toString().padLeft(2, '0');
        day = date.day.toString().padLeft(2, '0');
      } catch (e) {}
    }
    
    final folder = isExternal ? 'external_messages' : 'messages';
    final baseName = referenceNumber.isNotEmpty 
        ? referenceNumber.replaceAll('-', '_') 
        : 'MSG_$messageId';
    
    final fallbackUrl = '${Constants.baseUrl}/uploads/$folder/$year/$month/$day/${baseName}_1.jpg';
    print('📸 Using fallback URL: $fallbackUrl');
    return fallbackUrl;
  }

  Future<List<Map<String, dynamic>>> _getAttachmentsList(int messageId) async {
    try {
      final token = await AuthService.getToken();
      
      final apiUrl = Uri.parse('${Constants.baseUrl}/modules/guru/api/get_attachments.php?message_id=$messageId');
      final response = await http.get(
        apiUrl,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['attachments'] != null) {
          return List<Map<String, dynamic>>.from(data['attachments']);
        }
      }
    } catch (e) {
      print('Error getting attachments list: $e');
    }
    
    return [];
  }

  Future<void> _showAttachmentsPreview(int messageId, int attachmentCount) async {
    if (attachmentCount == 0) {
      _showMessage('Tidak ada lampiran', Colors.orange);
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) => FutureBuilder<List<Map<String, dynamic>>>(
        future: _getAttachmentsList(messageId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Dialog(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),
            );
          }
          
          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return Dialog(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text('Gagal memuat lampiran'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Tutup'),
                    ),
                  ],
                ),
              ),
            );
          }
          
          final attachments = snapshot.data!;
          
          return Dialog(
            insetPadding: const EdgeInsets.all(16),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.8,
              height: MediaQuery.of(context).size.height * 0.7,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Colors.purple,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.attach_file, color: Colors.white),
                        const SizedBox(width: 12),
                        const Text(
                          'Lampiran',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${attachments.length} file',
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1,
                      ),
                      itemCount: attachments.length,
                      itemBuilder: (context, index) {
                        final att = attachments[index];
                        final imageUrl = att['full_url'] ?? '';
                        final fileName = att['original_name'] ?? att['filename'] ?? 'Lampiran';
                        final fileSize = att['filesize_formatted'] ?? '';
                        
                        return GestureDetector(
                          onTap: () => _showFullImagePreview(imageUrl, fileName),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.network(
                                    imageUrl,
                                    fit: BoxFit.cover,
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Container(
                                        color: Colors.grey[200],
                                        child: const Center(
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        ),
                                      );
                                    },
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.grey[200],
                                        child: const Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.broken_image, size: 40, color: Colors.grey),
                                            SizedBox(height: 4),
                                            Text('Gambar error', style: TextStyle(fontSize: 10)),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                  Positioned(
                                    bottom: 4,
                                    right: 4,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.6),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Icon(
                                        Icons.zoom_in,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  if (fileSize.isNotEmpty)
                                    Positioned(
                                      top: 4,
                                      left: 4,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.6),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          fileSize,
                                          style: const TextStyle(color: Colors.white, fontSize: 8),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showFullImagePreview(String imageUrl, String fileName) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.95),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.broken_image, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('Gambar tidak dapat dimuat', style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              Positioned(
                top: 16,
                right: 16,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 32),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      fileName,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _quickAction(int messageId, String action) async {
    final isApprove = action == 'approve';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isApprove ? 'Setujui Pesan' : 'Tolak Pesan'),
        content: Text(isApprove 
            ? 'Apakah Anda yakin ingin menyetujui pesan ini?' 
            : 'Apakah Anda yakin ingin menolak pesan ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), 
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isApprove ? Colors.green : Colors.red,
            ),
            child: Text(isApprove ? 'Setujui' : 'Tolak'),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;
    
    setState(() => _isLoading = true);
    
    try {
      await _service.quickAction(messageId, action == 'approve' ? 'quick_approve' : 'quick_reject');
      _showMessage(isApprove ? 'Pesan disetujui' : 'Pesan ditolak', Colors.green);
      await _loadMessages();
    } catch (e) {
      _showMessage('Error: $e', Colors.red);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteMessage(int messageId, String senderName) async {
    bool confirmed = false;
    String reason = '';
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
              SizedBox(width: 8),
              Text('Hapus Pesan'),
            ],
          ),
          content: SizedBox(
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Anda akan menghapus pesan dari:'),
                const SizedBox(height: 4),
                Text(senderName, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                const SizedBox(height: 16),
                const Text('Alasan Penghapusan:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  onChanged: (value) => setStateDialog(() => reason = value),
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Contoh: Pesan mengandung kata-kata tidak sopan, spam, dll.',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Checkbox(
                      value: confirmed,
                      onChanged: (value) => setStateDialog(() => confirmed = value ?? false),
                    ),
                    const Expanded(
                      child: Text('Saya yakin ingin menghapus pesan ini dan memahami bahwa tindakan ini tidak dapat dibatalkan.'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
            ElevatedButton(
              onPressed: confirmed && reason.isNotEmpty 
                  ? () => Navigator.pop(context, true) 
                  : null,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Hapus Permanen'),
            ),
          ],
        ),
      ),
    );
    
    if (result != true) return;
    
    setState(() => _isLoading = true);
    
    try {
      await _service.deleteMessage(messageId, reason);
      _showMessage('Pesan berhasil dihapus', Colors.green);
      await _loadMessages();
    } catch (e) {
      _showMessage('Error: $e', Colors.red);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
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
            'Follow-Up Pesan',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 1,
          actions: [
            IconButton(
              icon: const Icon(Icons.aspect_ratio),
              onPressed: () => WindowResizerExtension.showResizerPanel(context),
              tooltip: 'Ubah Ukuran Window (F2)',
            ),
            IconButton(
              icon: const Icon(Icons.analytics, color: Colors.blue),
              onPressed: _navigateToDashboard,
              tooltip: 'Dashboard Analisis Pesan',
            ),
            if (_isRefreshing)
              const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _refreshData,
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
        body: RefreshIndicator(
          onRefresh: _refreshData,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
                  ? _buildErrorWidget()
                  : _response == null
                      ? _buildEmptyWidget()
                      : _buildMessagesTab(),
        ),
      ),
    );
  }

  Widget _buildMessagesTab() {
    return Column(
      children: [
        _buildFilterSection(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refreshData,
            child: ListView(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                _buildStatsCards(),
                const SizedBox(height: 16),
                
                if (_response != null && _response!.reviewStats.totalResponded > 0)
                  _buildReviewStatsCard(),
                
                const SizedBox(height: 16),
                
                if (_response != null && _response!.templates.isNotEmpty) 
                  _buildTemplatesSection(),
                
                const SizedBox(height: 16),
                
                _buildMessagesTable(),
                
                const SizedBox(height: 16),
                
                _buildPagination(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewStatsCard() {
    final review = _response!.reviewStats;
    
    if (review.totalResponded == 0) return const SizedBox();
    
    final pendingReview = review.pendingReview;
    final reviewedByWakepsek = review.reviewedByWakepsek;
    final reviewedByKepsek = review.reviewedByKepsek;
    final totalReviewed = review.totalReviewed;
    final totalResponded = review.totalResponded;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.analytics, size: 20, color: Colors.blue),
              const SizedBox(width: 8),
              const Text(
                'Status Review Pimpinan',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Total pesan direspons dipindahkan ke bawah judul
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Total: $totalResponded Pesan Direspon',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(height: 16),
          
          _buildProgressBar(
            'Menunggu Review Pimpinan',
            pendingReview,
            totalResponded,
            Colors.orange,
          ),
          const SizedBox(height: 12),
          _buildProgressBar(
            'Sudah Direview Wakil Kepala',
            reviewedByWakepsek,
            totalResponded,
            Colors.blue,
          ),
          const SizedBox(height: 12),
          _buildProgressBar(
            'Sudah Direview Kepala Sekolah',
            reviewedByKepsek,
            totalResponded,
            Colors.green,
          ),
          const SizedBox(height: 16),
          
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 1,
                child: SizedBox(
                  height: 150,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: const Size(120, 120),
                        painter: DonutChartPainter(
                          pendingReview: pendingReview,
                          reviewedByWakepsek: reviewedByWakepsek,
                          reviewedByKepsek: reviewedByKepsek,
                          total: totalResponded,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$totalReviewed',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          const Text(
                            'Total Sudah\nDireview',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLegendItem('Menunggu', pendingReview, Colors.orange),
                    const SizedBox(height: 8),
                    _buildLegendItem('Wakil Kepala', reviewedByWakepsek, Colors.blue),
                    const SizedBox(height: 8),
                    _buildLegendItem('Kepala Sekolah', reviewedByKepsek, Colors.green),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, int value, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
        ),
        Text(
          '$value',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar(String label, int value, int total, Color color) {
    final percentage = total > 0 ? (value / total) * 100 : 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12)),
            Text(
              '$value pesan (${percentage.toStringAsFixed(0)}%)',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: color),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: Colors.grey.shade200,
            color: color,
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _buildMessagesTable() {
    if (_response == null || _response!.messages.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.inbox, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 12),
                Text('Tidak ada pesan', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                const SizedBox(height: 8),
                Text('Ubah filter untuk melihat pesan lain', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              ],
            ),
          ),
        ),
      );
    }
    
    final messages = _response!.messages;
    final ScrollController _horizontalScrollController = ScrollController();
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          // Scrollbar horizontal
          Scrollbar(
            controller: _horizontalScrollController,
            thumbVisibility: true,
            trackVisibility: true,
            interactive: true,
            thickness: 10,
            radius: const Radius.circular(8),
            child: SingleChildScrollView(
              controller: _horizontalScrollController,
              scrollDirection: Axis.horizontal,
              physics: const AlwaysScrollableScrollPhysics(),
              child: DataTable(
                dataRowMinHeight: 70.0,
                dataRowMaxHeight: 90.0,
                columnSpacing: 12,
                headingRowColor: MaterialStateProperty.all(Colors.grey.shade100),
                columns: const [
                  DataColumn(label: Text('#', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                  DataColumn(label: Text('Pengirim', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                  DataColumn(label: Text('Isi Pesan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                  DataColumn(label: Text('Lampiran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                  DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                  DataColumn(label: Text('Review Pimpinan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                  DataColumn(label: Text('Prioritas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                  DataColumn(label: Text('Sisa Waktu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                  DataColumn(label: Text('Aksi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                ],
                rows: messages.asMap().entries.map((entry) {
                  final index = entry.key + 1;
                  final message = entry.value;
                  final isExternal = message.isExternalMessage;
                  final hasResponse = message.isResponded;
                  final hasAttachments = message.hasAttachments;
                  
                  return DataRow(
                    cells: [
                      DataCell(Text('$index', style: const TextStyle(fontSize: 11))),
                      
                      DataCell(
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Text(
                                  message.pengirimNama,
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                                ),
                                if (isExternal) ...[
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
                            Text(
                              message.referenceNumber,
                              style: const TextStyle(fontSize: 10, color: Colors.grey),
                            ),
                            Text(
                              message.tanggalPesan,
                              style: const TextStyle(fontSize: 10, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      
                      DataCell(
                        SizedBox(
                          width: 200,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                message.isiPesan,
                                style: const TextStyle(fontSize: 11),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (hasResponse)
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade100,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Text(
                                    'Sudah direspons',
                                    style: TextStyle(fontSize: 9, color: Colors.green),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      
                      DataCell(
                        hasAttachments
                            ? GestureDetector(
                                onTap: () => _showAttachmentsPreview(message.id, message.attachmentCount),
                                child: Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey.shade300),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: FutureBuilder<String>(
                                      future: _getAttachmentUrl(message.id, message),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState == ConnectionState.waiting) {
                                          return Container(
                                            color: Colors.grey[200],
                                            child: const Center(
                                              child: SizedBox(
                                                width: 20,
                                                height: 20,
                                                child: CircularProgressIndicator(strokeWidth: 2),
                                              ),
                                            ),
                                          );
                                        }
                                        
                                        if (snapshot.hasData && snapshot.data != null && snapshot.data!.isNotEmpty) {
                                          return Image.network(
                                            snapshot.data!,
                                            fit: BoxFit.cover,
                                            loadingBuilder: (context, child, loadingProgress) {
                                              if (loadingProgress == null) return child;
                                              return Container(
                                                color: Colors.grey[200],
                                                child: const Center(
                                                  child: SizedBox(
                                                    width: 20,
                                                    height: 20,
                                                    child: CircularProgressIndicator(strokeWidth: 2),
                                                  ),
                                                ),
                                              );
                                            },
                                            errorBuilder: (context, error, stackTrace) {
                                              return Container(
                                                color: Colors.grey[200],
                                                child: const Icon(Icons.broken_image, size: 24, color: Colors.grey),
                                              );
                                            },
                                          );
                                        }
                                        
                                        return Container(
                                          color: Colors.grey[200],
                                          child: const Icon(Icons.image, size: 24, color: Colors.grey),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              )
                            : const Text('-', style: TextStyle(fontSize: 11)),
                      ),
                      
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: message.statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            message.status,
                            style: TextStyle(fontSize: 10, color: message.statusColor),
                          ),
                        ),
                      ),
                      
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: message.isExpired 
                                ? Colors.red.shade100 
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            message.isExpired ? 'Expired' : 'Menunggu',
                            style: TextStyle(
                              fontSize: 10,
                              color: message.isExpired ? Colors.red : Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: message.priorityColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            message.priority,
                            style: TextStyle(fontSize: 10, color: message.priorityColor),
                          ),
                        ),
                      ),
                      
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: message.isExpired 
                                ? Colors.red.shade100 
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            message.isExpired 
                                ? 'Expired' 
                                : '${message.hoursRemaining} jam',
                            style: TextStyle(
                              fontSize: 10,
                              color: message.isExpired ? Colors.red : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                      
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.visibility, size: 18, color: Colors.blue),
                              onPressed: () {
                                _showMessageDetailDialog(message.id, message);
                              },
                              tooltip: 'Lihat Detail',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            const SizedBox(width: 4),
                            
                            if (hasAttachments)
                              IconButton(
                                icon: const Icon(Icons.image, size: 18, color: Colors.purple),
                                onPressed: () => _showAttachmentsPreview(message.id, message.attachmentCount),
                                tooltip: 'Lihat Lampiran (${message.attachmentCount} file)',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            
                            IconButton(
                              icon: Icon(hasResponse ? Icons.edit : Icons.reply, size: 18),
                              onPressed: () {
                                if (hasResponse) {
                                  _showMessage('Fitur edit respons sedang dalam pengembangan', Colors.orange);
                                } else {
                                  _showMessage('Fitur respons sedang dalam pengembangan', Colors.orange);
                                }
                              },
                              tooltip: hasResponse ? 'Edit Respons' : 'Beri Respons',
                              color: hasResponse ? Colors.orange : Colors.green,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            const SizedBox(width: 4),
                            
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                              onPressed: () => _deleteMessage(message.id, message.pengirimNama),
                              tooltip: 'Hapus Pesan',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            const SizedBox(width: 4),
                            
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert, size: 18),
                              onSelected: (value) async {
                                if (value == 'approve') {
                                  await _quickAction(message.id, 'approve');
                                } else if (value == 'reject') {
                                  await _quickAction(message.id, 'reject');
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'approve', 
                                  child: Row(
                                    children: [
                                      Icon(Icons.check_circle, color: Colors.green, size: 18), 
                                      SizedBox(width: 8), 
                                      Text('Setujui Cepat')
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'reject', 
                                  child: Row(
                                    children: [
                                      Icon(Icons.cancel, color: Colors.red, size: 18), 
                                      SizedBox(width: 8), 
                                      Text('Tolak Cepat')
                                    ],
                                  ),
                                ),
                              ],
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
        ],
      ),
    );
  }

  Widget _buildPagination() {
    if (_response == null || _response!.totalPages <= 1) return const SizedBox();
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: _currentPage > 1 ? () {
            setState(() => _currentPage--);
            _loadMessages();
          } : null,
        ),
        Text('Halaman $_currentPage dari ${_response!.totalPages}', style: const TextStyle(fontSize: 12)),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: _currentPage < _response!.totalPages ? () {
            setState(() => _currentPage++);
            _loadMessages();
          } : null,
        ),
      ],
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildFilterDropdown(
                  label: 'STATUS',
                  value: _selectedStatus,
                  items: _statusOptions,
                  onChanged: (value) {
                    setState(() => _selectedStatus = value!);
                    _applyFilters();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFilterDropdown(
                  label: 'PRIORITAS',
                  value: _selectedPriority,
                  items: _priorityOptions,
                  onChanged: (value) {
                    setState(() => _selectedPriority = value!);
                    _applyFilters();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFilterDropdown(
                  label: 'SUMBER',
                  value: _selectedSource,
                  items: _sourceOptions,
                  onChanged: (value) {
                    setState(() => _selectedSource = value!);
                    _applyFilters();
                  },
                  displayMapper: (value) {
                    switch (value) {
                      case 'internal': return 'Internal';
                      case 'external': return 'External';
                      default: return 'Semua Sumber';
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Cari nama, email, isi pesan...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              setState(() {
                                _searchQuery = '';
                                _applyFilters();
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  ),
                  onChanged: (value) {
                    _searchQuery = value;
                  },
                  onSubmitted: (value) {
                    _applyFilters();
                  },
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _applyFilters,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                ),
                child: const Text('Filter'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
    String Function(String)? displayMapper,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey),
        ),
        const SizedBox(height: 4),
        Container(
          constraints: const BoxConstraints(maxHeight: 40),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              isDense: true,
              items: items.map((item) {
                String display = displayMapper?.call(item) ?? item;
                if (item == 'pending' && label == 'STATUS') display = 'Pending & Diproses';
                if (item == 'all' && label == 'STATUS') display = 'Semua Status';
                if (item == 'all' && label == 'PRIORITAS') display = 'Semua Prioritas';
                return DropdownMenuItem(
                  value: item,
                  child: Text(display, style: const TextStyle(fontSize: 12)),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCards() {
    final stats = _response!.stats;
    // Stat cards: 3 kolom 2 baris
    final List<StatItem> allStats = [
      StatItem('Total Pesan', stats.totalAssigned, Icons.email, Colors.blue),
      StatItem('Pending', stats.totalPending, Icons.hourglass_empty, Colors.orange),
      StatItem('Diproses', stats.diproses, Icons.settings, Colors.cyan),
      StatItem('Selesai', stats.totalCompleted, Icons.check_circle, Colors.green),
      StatItem('Ditolak', stats.ditolak, Icons.cancel, Colors.red),
      StatItem('Lampiran', stats.withAttachments, Icons.attach_file, Colors.purple),
    ];
    
    return Column(
      children: [
        // Baris 1 (3 kolom pertama)
        Row(
          children: allStats.sublist(0, 3).map((stat) {
            return _buildStatCard(stat.title, stat.value, stat.icon, stat.color);
          }).toList(),
        ),
        const SizedBox(height: 8),
        // Baris 2 (3 kolom berikutnya)
        Row(
          children: allStats.sublist(3, 6).map((stat) {
            return _buildStatCard(stat.title, stat.value, stat.icon, stat.color);
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, int value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(12),
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
        child: Column(
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: 4),
            Text(
              value.toString(),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 10, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplatesSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Template Respons Cepat',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          // Template dalam 1 kolom (ListView vertical)
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _response!.templates.length,
            itemBuilder: (context, index) {
              final template = _response!.templates[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.copy, size: 16, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            template.name,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            template.content,
                            style: const TextStyle(fontSize: 10, color: Colors.grey),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 16, color: Colors.grey),
                      onPressed: () {
                        _showMessage('Template "${template.name}" disalin ke clipboard', Colors.green);
                      },
                      tooltip: 'Salin template',
                    ),
                  ],
                ),
              );
            },
          ),
        ],
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
            onPressed: _loadMessages,
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inbox, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('Tidak ada pesan', style: TextStyle(fontSize: 16)),
          const SizedBox(height: 8),
          Text(
            _selectedStatus != 'all'
                ? 'Tidak ada pesan dengan status $_selectedStatus'
                : 'Belum ada pesan masuk untuk Anda',
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class StatItem {
  final String title;
  final int value;
  final IconData icon;
  final Color color;
  
  StatItem(this.title, this.value, this.icon, this.color);
}

class DonutChartPainter extends CustomPainter {
  final int pendingReview;
  final int reviewedByWakepsek;
  final int reviewedByKepsek;
  final int total;

  DonutChartPainter({
    required this.pendingReview,
    required this.reviewedByWakepsek,
    required this.reviewedByKepsek,
    required this.total,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (total == 0) return;
    
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round;
    
    double startAngle = -90 * (3.14159 / 180);
    
    final pendingPercentage = pendingReview / total;
    final wakepsekPercentage = reviewedByWakepsek / total;
    final kepsekPercentage = reviewedByKepsek / total;
    
    if (pendingReview > 0) {
      final sweepAngle = 360 * pendingPercentage * (3.14159 / 180);
      paint.color = Colors.orange;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
      startAngle += sweepAngle;
    }
    
    if (reviewedByWakepsek > 0) {
      final sweepAngle = 360 * wakepsekPercentage * (3.14159 / 180);
      paint.color = Colors.blue;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
      startAngle += sweepAngle;
    }
    
    if (reviewedByKepsek > 0) {
      final sweepAngle = 360 * kepsekPercentage * (3.14159 / 180);
      paint.color = Colors.green;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}