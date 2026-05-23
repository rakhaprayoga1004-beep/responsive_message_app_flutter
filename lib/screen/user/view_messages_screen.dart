// lib/screen/user/view_messages_screen.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../services/auth_service.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../widgets/window_resizer_shortcut.dart'; // Import window resizer shortcut

class ViewMessagesScreen extends StatefulWidget {
  const ViewMessagesScreen({super.key});

  @override
  State<ViewMessagesScreen> createState() => _ViewMessagesScreenState();
}

class _ViewMessagesScreenState extends State<ViewMessagesScreen> {
  List<Map<String, dynamic>> _messages = [];
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _timeline = [];
  List<Map<String, dynamic>> _messageTypes = [];
  List<Map<String, dynamic>> _templates = [];
  
  // Chart data
  List<String> _chartDates = [];
  List<int> _chartCounts = [];
  int _statusPending = 0;
  int _statusDiproses = 0;
  int _statusSelesai = 0;
  int _statusDitolak = 0;
  
  // Timeline pagination
  int _timelineCurrentPage = 1;
  int _timelineTotalPages = 1;
  int _timelinePerPage = 10;
  List<Map<String, dynamic>> _paginatedTimeline = [];
  
  bool _isLoading = true;
  bool _isLoadingDetail = false;
  String? _errorMessage;
  
  // Filter
  String _selectedStatus = 'all';
  String _selectedType = 'all';
  String _selectedPriority = 'all';
  String _searchQuery = '';
  String _dateFrom = '';
  String _dateTo = '';
  String _sortBy = 'created_at';
  String _sortOrder = 'DESC';
  int _currentPage = 1;
  int _totalPages = 1;
  int _perPage = 10;
  int _totalMessages = 0;
  
  // Selected messages for bulk action
  Set<int> _selectedMessageIds = {};
  
  // Modal
  Map<String, dynamic>? _selectedMessage;
  List<Map<String, dynamic>> _attachments = [];

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadTemplates();
  }
  
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      await _loadMessages();
      await _loadMessageTypes();
      await _loadStats();
      await _loadTimeline();
    } catch (e) {
      print('❌ Error loading data: $e');
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _loadMessages() async {
    try {
      final token = await AuthService.getToken();
      
      if (token == null) {
        throw Exception('Token tidak ditemukan');
      }
      
      final queryParams = {
        'status': _selectedStatus,
        'type': _selectedType,
        'priority': _selectedPriority,
        'search': _searchQuery,
        'date_from': _dateFrom,
        'date_to': _dateTo,
        'sort_by': _sortBy,
        'sort_order': _sortOrder,
        'page': _currentPage.toString(),
        'per_page': _perPage.toString(),
        'token': token,
      };
      
      final uri = Uri.parse('${Constants.baseUrl}/modules/user/api/get_user_messages.php')
          .replace(queryParameters: queryParams);
      
      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            _messages = List<Map<String, dynamic>>.from(data['messages'] ?? []);
            _totalMessages = data['total'] ?? 0;
            _totalPages = data['total_pages'] ?? 1;
          });
          print('✅ Loaded ${_messages.length} messages');
        } else {
          throw Exception(data['message'] ?? 'Gagal memuat pesan');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error loading messages: $e');
      rethrow;
    }
  }
  
  Future<void> _loadStats() async {
    try {
      if (_messages.isNotEmpty) {
        int total = _messages.length;
        int pending = 0;
        int diproses = 0;
        int selesai = 0;
        int ditolak = 0;
        int responded = 0;
        double totalResponseHours = 0;
        
        for (var msg in _messages) {
          final status = msg['status'] ?? '';
          if (status == 'Pending') {
            pending++;
          } else if (status == 'Dibaca' || status == 'Diproses') {
            diproses++;
          } else if (status == 'Disetujui' || status == 'Selesai') {
            selesai++;
          } else if (status == 'Ditolak') {
            ditolak++;
          }
          
          if (msg['responder_id'] != null && msg['responder_id'] > 0) {
            responded++;
            // Hitung waktu respons jika ada
            if (msg['created_at'] != null && msg['tanggal_respon'] != null) {
              try {
                final created = DateTime.parse(msg['created_at']);
                final respondedAt = DateTime.parse(msg['tanggal_respon']);
                final hours = respondedAt.difference(created).inHours;
                totalResponseHours += hours;
              } catch (e) {}
            }
          }
        }
        
        // Hitung chart data (7 hari terakhir)
        List<String> dates = [];
        List<int> counts = [];
        for (int i = 6; i >= 0; i--) {
          final date = DateTime.now().subtract(Duration(days: i));
          dates.add('${date.day} ${_getMonthName(date.month)}');
          
          int count = 0;
          for (var msg in _messages) {
            final msgDate = DateTime.tryParse(msg['created_at'] ?? '');
            if (msgDate != null && 
                msgDate.year == date.year && 
                msgDate.month == date.month && 
                msgDate.day == date.day) {
              count++;
            }
          }
          counts.add(count);
        }
        
        final responseRate = total > 0 ? (responded / total * 100).round() : 0;
        final last7Days = counts.isNotEmpty ? counts.reduce((a, b) => a + b) : 0;
        final avgResponseHours = responded > 0 ? (totalResponseHours / responded).round() : 0;
        
        setState(() {
          _stats = {
            'total': total,
            'pending': pending,
            'diproses': diproses,
            'selesai': selesai,
            'ditolak': ditolak,
            'responded_count': responded,
            'response_rate': responseRate,
            'last_7_days': last7Days,
            'avg_response_hours': avgResponseHours,
          };
          _chartDates = dates;
          _chartCounts = counts;
          _statusPending = pending;
          _statusDiproses = diproses;
          _statusSelesai = selesai;
          _statusDitolak = ditolak;
        });
      }
    } catch (e) {
      print('❌ Error loading stats: $e');
    }
  }
  
  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    return months[month - 1];
  }
  
  Future<void> _loadTimeline() async {
    try {
      List<Map<String, dynamic>> timeline = [];
      for (var msg in _messages) {
        final activityDate = DateTime.tryParse(msg['tanggal_respon'] ?? msg['created_at'] ?? '');
        
        timeline.add({
          'id': msg['id'],
          'isi_pesan': msg['isi_pesan'],
          'jenis_pesan': msg['jenis_pesan'],
          'activity_type': msg['responder_id'] != null && msg['responder_id'] > 0 ? 'responded' : 'sent',
          'activity_date': msg['tanggal_respon'] ?? msg['created_at'],
          'activity_date_obj': activityDate,
          'activity_date_formatted': _formatDateIndonesian(msg['tanggal_respon'] ?? msg['created_at']),
          'responder_nama': msg['responder_nama'],
          'status': msg['status'],
          'reference_number': msg['reference_number'],
        });
      }
      
      // Urutkan berdasarkan tanggal terbaru
      timeline.sort((a, b) {
        final dateA = a['activity_date_obj'] as DateTime?;
        final dateB = b['activity_date_obj'] as DateTime?;
        if (dateA == null && dateB == null) return 0;
        if (dateA == null) return 1;
        if (dateB == null) return -1;
        return dateB.compareTo(dateA);
      });
      
      setState(() {
        _timeline = timeline;
        _updatePaginatedTimeline();
      });
    } catch (e) {
      print('❌ Error loading timeline: $e');
    }
  }
  
  void _updatePaginatedTimeline() {
    int startIndex = (_timelineCurrentPage - 1) * _timelinePerPage;
    int endIndex = startIndex + _timelinePerPage;
    if (endIndex > _timeline.length) endIndex = _timeline.length;
    
    setState(() {
      _paginatedTimeline = _timeline.sublist(startIndex, endIndex);
      _timelineTotalPages = (_timeline.length / _timelinePerPage).ceil();
      if (_timelineTotalPages == 0) _timelineTotalPages = 1;
    });
  }
  
  void _goToTimelinePage(int page) {
    if (page >= 1 && page <= _timelineTotalPages) {
      setState(() {
        _timelineCurrentPage = page;
      });
      _updatePaginatedTimeline();
    }
  }
  
  void _viewMessageFromTimeline(int messageId) {
    _viewMessageDetail(messageId);
  }
  
  Future<void> _loadMessageTypes() async {
    try {
      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/modules/user/api/get_message_types.php'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            _messageTypes = List<Map<String, dynamic>>.from(data['data'] ?? []);
          });
        }
      }
    } catch (e) {
      print('❌ Error loading message types: $e');
    }
  }
  
  Future<void> _loadTemplates() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return;
      
      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/modules/user/api/get_response_templates.php')
            .replace(queryParameters: {'token': token}),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 15));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            _templates = List<Map<String, dynamic>>.from(data['templates'] ?? []);
          });
        }
      }
    } catch (e) {
      print('❌ Error loading templates: $e');
    }
  }
  
  Future<void> _viewMessageDetail(int messageId) async {
    setState(() {
      _isLoadingDetail = true;
      _selectedMessage = null;
      _attachments = [];
    });
    
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('Token tidak ditemukan');
      
      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/modules/user/api/get_message_detail.php?message_id=$messageId&token=$token'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 20));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            _selectedMessage = data['message'];
            _attachments = List<Map<String, dynamic>>.from(data['attachments'] ?? []);
            _isLoadingDetail = false;
          });
          
          if (mounted) {
            _showMessageDetailDialog();
          }
        } else {
          throw Exception(data['message'] ?? 'Gagal memuat detail pesan');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isLoadingDetail = false;
      });
      if (mounted) {
        Helpers.showToast(context, 'Error: $e');
      }
    }
  }
  
  Future<void> _viewAttachments(int messageId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('Token tidak ditemukan');
      
      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/modules/user/api/get_message_attachments.php?message_id=$messageId&token=$token'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 20));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final attachments = List<Map<String, dynamic>>.from(data['attachments'] ?? []);
          if (mounted) {
            _showAttachmentsDialog(attachments);
          }
        } else {
          throw Exception(data['error'] ?? 'Gagal memuat lampiran');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        Helpers.showToast(context, 'Error: $e');
      }
    }
  }
  
  void _showMessageDetailDialog() {
    if (_selectedMessage == null) return;
    
    final message = _selectedMessage!;
    final hasAttachments = _attachments.isNotEmpty;
    
    // Ambil data pengirim dengan prioritas dari response API
    final senderName = message['pengirim_nama_lengkap'] ?? message['pengirim_nama'] ?? '-';
    final senderType = message['pengirim_tipe'] ?? message['user_type'] ?? '-';
    final senderEmail = message['pengirim_email'] ?? message['email'] ?? '-';
    final senderPhone = message['pengirim_phone'] ?? message['phone_number'] ?? '-';
    final senderNisNip = message['pengirim_nis_nip'] ?? '-';
    final senderKelas = message['pengirim_kelas'] ?? '-';
    final senderJurusan = message['pengirim_jurusan'] ?? '-';
    final senderMataPelajaran = message['pengirim_mata_pelajaran'] ?? '-';
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          constraints: const BoxConstraints(maxWidth: 800, maxHeight: 700),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color(0xFF0B4D8A),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.email, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            message['reference_number'] ?? 'Pesan',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'ID: ${message['id']}',
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status dan Prioritas
                      Row(
                        children: [
                          _buildStatusBadge(message['status'] ?? 'Pending'),
                          const SizedBox(width: 12),
                          _buildPriorityBadge(message['priority'] ?? 'Medium'),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      // Informasi Pengirim (Lengkap dari tabel users)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.person, size: 18, color: Colors.blue),
                                const SizedBox(width: 8),
                                const Text(
                                  'Informasi Pengirim',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 20),
                            _buildDetailRow('Nama Lengkap', senderName),
                            _buildDetailRow('Tipe Pengirim', _getUserTypeDisplay(senderType)),
                            _buildDetailRow('Email', senderEmail),
                            _buildDetailRow('No. HP', senderPhone),
                            _buildDetailRow('NIS/NIP', senderNisNip),
                            // Tampilkan Kelas/Jurusan hanya untuk siswa
                            if (senderType == 'Siswa' || senderType == 'Student') ...[
                              if (senderKelas != '-' && senderKelas.isNotEmpty)
                                _buildDetailRow('Kelas', senderKelas),
                              if (senderJurusan != '-' && senderJurusan.isNotEmpty)
                                _buildDetailRow('Jurusan', senderJurusan),
                            ],
                            // Tampilkan Mata Pelajaran hanya untuk guru
                            if (senderType == 'Guru' || senderType.toString().contains('Guru')) ...[
                              if (senderMataPelajaran != '-' && senderMataPelajaran.isNotEmpty)
                                _buildDetailRow('Mata Pelajaran', senderMataPelajaran),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Informasi Pesan
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.info, size: 18, color: Colors.grey),
                                const SizedBox(width: 8),
                                const Text(
                                  'Informasi Pesan',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 20),
                            _buildDetailRow('Jenis Pesan', message['jenis_pesan'] ?? '-'),
                            _buildDetailRow('Tanggal Kirim', _formatDate(message['created_at'])),
                            if (message['tanggal_respon'] != null)
                              _buildDetailRow('Tanggal Respons', _formatDate(message['tanggal_respon'])),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Isi Pesan
                      const Text(
                        'Isi Pesan',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          message['isi_pesan'] ?? '-',
                          style: const TextStyle(height: 1.5),
                        ),
                      ),
                      
                      // Respon Guru dengan Status Respons
                      if (message['responder_id'] != null && message['responder_id'] > 0) ...[
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.reply, size: 18, color: Colors.green),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Respons Guru',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Colors.green,
                                    ),
                                  ),
                                  const Spacer(),
                                  // Status Respons Badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(message['status'] ?? 'Pending').withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'Status: ${message['status'] ?? 'Pending'}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: _getStatusColor(message['status'] ?? 'Pending'),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 20),
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: Colors.green.shade100,
                                    child: Text(
                                      (message['responder_nama'] ?? 'A')[0].toUpperCase(),
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          message['responder_nama'] ?? 'Admin',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                        Text(
                                          _getUserTypeDisplay(message['responder_type']),
                                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    _formatDate(message['tanggal_respon']),
                                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  message['last_response'] ?? message['catatan_respon'] ?? 'Tidak ada respons',
                                  style: const TextStyle(height: 1.4),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      
                      // Attachments
                      if (hasAttachments) ...[
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            const Icon(Icons.attach_file, size: 18),
                            const SizedBox(width: 8),
                            const Text(
                              'Lampiran',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const Spacer(),
                            TextButton.icon(
                              onPressed: () => _viewAttachments(message['id']),
                              icon: const Icon(Icons.image, size: 16),
                              label: Text('Lihat Semua (${_attachments.length})'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 100,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _attachments.length > 3 ? 3 : _attachments.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 8),
                            itemBuilder: (context, index) {
                              final att = _attachments[index];
                              final imageUrl = '${Constants.baseUrl}/${att['filepath']}';
                              return GestureDetector(
                                onTap: () => _showImagePreview(imageUrl, att['filename']),
                                child: Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey.shade300),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      imageUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        color: Colors.grey.shade200,
                                        child: const Icon(Icons.broken_image, size: 32),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              
              // Footer
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.grey.shade200)),
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

  // Helper method untuk mendapatkan warna status
  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange;
      case 'Dibaca':
        return Colors.blue;
      case 'Diproses':
        return Colors.cyan;
      case 'Disetujui':
      case 'Selesai':
        return Colors.green;
      case 'Ditolak':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Helper method untuk menampilkan tipe pengirim dengan format yang lebih baik
  String _getUserTypeDisplay(String? userType) {
    if (userType == null) return 'Pengguna';
    
    switch (userType) {
      case 'Siswa':
      case 'Student':
        return 'Siswa';
      case 'Guru':
        return 'Guru';
      case 'Guru_BK':
        return 'Guru BK';
      case 'Guru_Humas':
        return 'Guru Humas';
      case 'Guru_Kurikulum':
        return 'Guru Kurikulum';
      case 'Guru_Kesiswaan':
        return 'Guru Kesiswaan';
      case 'Guru_Sarana':
        return 'Guru Sarana Prasarana';
      case 'Orang_Tua':
      case 'Parent':
        return 'Orang Tua/Wali';
      case 'Admin':
        return 'Administrator';
      case 'Kepala_Sekolah':
        return 'Kepala Sekolah';
      case 'Wakil_Kepala':
        return 'Wakil Kepala Sekolah';
      default:
        return userType.replaceAll('_', ' ');
    }
  }
  
  void _showAttachmentsDialog(List<Map<String, dynamic>> attachments) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 500),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFF0B4D8A),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.image, color: Colors.white),
                    const SizedBox(width: 12),
                    const Text(
                      'Lampiran Gambar',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Text(
                      '${attachments.length} file',
                      style: const TextStyle(color: Colors.white70),
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
                    final imageUrl = '${Constants.baseUrl}/${att['filepath']}';
                    final fileName = att['filename'] ?? 'image.jpg';
                    final fileSize = att['filesize'] ?? 0;
                    
                    return GestureDetector(
                      onTap: () => _showImagePreview(imageUrl, fileName),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: Colors.grey.shade200,
                                  child: const Icon(Icons.broken_image, size: 32),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 4,
                              right: 4,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Icon(Icons.zoom_in, size: 16, color: Colors.white),
                              ),
                            ),
                            if (fileSize > 0)
                              Positioned(
                                top: 4,
                                left: 4,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    _formatFileSize(fileSize),
                                    style: const TextStyle(color: Colors.white, fontSize: 10),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _showImagePreview(String imageUrl, String fileName) {
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
                    errorBuilder: (_, __, ___) => const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.broken_image, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('Gambar tidak dapat dimuat', style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
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
                      style: const TextStyle(color: Colors.white),
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
  
  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'Pending':
        color = Colors.orange;
        break;
      case 'Dibaca':
        color = Colors.blue;
        break;
      case 'Diproses':
        color = Colors.cyan;
        break;
      case 'Disetujui':
      case 'Selesai':
        color = Colors.green;
        break;
      case 'Ditolak':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(status, style: TextStyle(color: color, fontSize: 12)),
    );
  }
  
  Widget _buildPriorityBadge(String priority) {
    Color color;
    switch (priority) {
      case 'Low':
        color = Colors.green;
        break;
      case 'Medium':
        color = Colors.orange;
        break;
      case 'High':
        color = Colors.red;
        break;
      case 'Urgent':
        color = Colors.purple;
        break;
      default:
        color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(priority, style: TextStyle(color: color, fontSize: 12)),
    );
  }
  
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ),
          Expanded(
            child: Text(': $value', style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }
  
  String _formatDate(String? dateString) {
    if (dateString == null) return '-';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }
  
  String _formatDateIndonesian(String? dateString) {
    if (dateString == null) return '-';
    try {
      final date = DateTime.parse(dateString);
      const months = ['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (e) {
      return dateString;
    }
  }
  
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1048576).toStringAsFixed(1)} MB';
  }
  
  void _applyFilters() {
    setState(() {
      _currentPage = 1;
    });
    _loadMessages();
  }
  
  void _resetFilters() {
    setState(() {
      _selectedStatus = 'all';
      _selectedType = 'all';
      _selectedPriority = 'all';
      _searchQuery = '';
      _dateFrom = '';
      _dateTo = '';
      _sortBy = 'created_at';
      _sortOrder = 'DESC';
      _currentPage = 1;
    });
    _loadMessages();
  }
  
  @override
  Widget build(BuildContext context) {
    return WindowResizerShortcut(
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text('Pesan Saya'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 1,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadData,
              tooltip: 'Refresh',
            ),
            IconButton(
              icon: const Icon(Icons.send),
              onPressed: () => Navigator.pushReplacementNamed(context, '/send-message'),
              tooltip: 'Pesan Baru',
            ),
            IconButton(
              icon: const Icon(Icons.aspect_ratio),
              onPressed: () => WindowResizerExtension.showResizerPanel(context),
              tooltip: 'Ubah Ukuran Window (F2)',
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? _buildErrorWidget()
                : RefreshIndicator(
                    onRefresh: _loadData,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildStatsCards(),
                          const SizedBox(height: 16),
                          _buildChartsSection(),
                          const SizedBox(height: 16),
                          _buildResponseRateCard(),
                          const SizedBox(height: 16),
                          if (_templates.isNotEmpty) _buildTemplatesSection(),
                          const SizedBox(height: 16),
                          _buildFilterSection(),
                          const SizedBox(height: 16),
                          _buildMessagesTable(),
                          const SizedBox(height: 16),
                          _buildPagination(),
                          if (_timeline.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            _buildTimelineSection(),
                          ],
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }
  
  Widget _buildStatsCards() {
    return Row(
      children: [
        _buildStatCard('Total', _stats['total'] ?? 0, Icons.email, Colors.blue),
        _buildStatCard('Pending', _stats['pending'] ?? 0, Icons.hourglass_empty, Colors.orange),
        _buildStatCard('Diproses', _stats['diproses'] ?? 0, Icons.settings, Colors.cyan),
        _buildStatCard('Selesai', _stats['selesai'] ?? 0, Icons.check_circle, Colors.green),
        _buildStatCard('Ditolak', _stats['ditolak'] ?? 0, Icons.cancel, Colors.red),
      ],
    );
  }
  
  Widget _buildStatCard(String title, int value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: 4),
            Text(value.toString(), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            Text(title, style: const TextStyle(fontSize: 10, color: Colors.grey), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
  
  Widget _buildChartsSection() {
  return Column(
    mainAxisSize: MainAxisSize.min, // Penting! Agar tidak memaksa tinggi berlebih
    children: [
      // Grafik Aktivitas 7 Hari Terakhir
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Aktivitas 7 Hari Terakhir',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildActivityChart(), // Tidak perlu Container dengan height fixed
          ],
        ),
      ),
      const SizedBox(height: 16),
      // Grafik Distribusi Status
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Donut chart
            Expanded(
              flex: 1,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Distribusi Status',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: _buildSimpleDonutChart(),
                  ),
                ],
              ),
            ),
            // Legend
            Expanded(
              flex: 1,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLegendItem('Pending', _statusPending, Colors.orange),
                  const SizedBox(height: 6),
                  _buildLegendItem('Diproses', _statusDiproses, Colors.cyan),
                  const SizedBox(height: 6),
                  _buildLegendItem('Selesai', _statusSelesai, Colors.green),
                  const SizedBox(height: 6),
                  _buildLegendItem('Ditolak', _statusDitolak, Colors.red),
                ],
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
  
  Widget _buildActivityChart() {
  if (_chartDates.isEmpty || _chartCounts.isEmpty) {
    return const Center(child: Text('Belum ada data', style: TextStyle(fontSize: 12)));
  }
  
  // Cari nilai maksimum untuk skala sumbu Y
  double maxCount = _chartCounts.reduce((a, b) => a > b ? a : b).toDouble();
  if (maxCount == 0) maxCount = 1;
  
  // Tentukan nilai sumbu Y yang DINAMIS
  List<int> yValues = [];
  int maxInt = maxCount.ceil();
  
  if (maxInt <= 5) {
    for (int i = 0; i <= maxInt; i++) yValues.add(i);
  } else if (maxInt <= 10) {
    for (int i = 0; i <= maxInt; i += 2) yValues.add(i);
    if (!yValues.contains(maxInt)) yValues.add(maxInt);
  } else if (maxInt <= 20) {
    for (int i = 0; i <= maxInt; i += 5) yValues.add(i);
  } else if (maxInt <= 50) {
    for (int i = 0; i <= maxInt; i += 10) yValues.add(i);
  } else {
    for (int i = 0; i <= maxInt; i += 20) yValues.add(i);
  }
  
  if (!yValues.contains(maxInt)) yValues.add(maxInt);
  
  final ScrollController _scrollController = ScrollController();
  final double barWidth = 55.0;
  final double chartHeight = 200.0;
  final double totalChartWidth = _chartDates.length * barWidth;
  
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      // Container utama dengan Row yang memiliki sumbu Y tetap di kiri
      Container(
        height: chartHeight + 80,
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sumbu Y - TETAP (tidak ikut scroll)
            Container(
              width: 45,
              height: chartHeight,
              color: Colors.white,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: yValues.reversed.map((value) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      value.toString(),
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  );
                }).toList(),
              ),
            ),
            // Area chart - BISA DI-SCROLL (sumbu X dan bar bergerak)
            Expanded(
              child: ListView(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                children: [
                  Container(
                    width: totalChartWidth,
                    height: chartHeight + 60,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Garis bantu horizontal
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          height: chartHeight,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: yValues.map((value) {
                              return Container(
                                height: 1,
                                color: Colors.grey.shade300,
                              );
                            }).toList(),
                          ),
                        ),
                        // Bar chart
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 40,
                          height: chartHeight,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: List.generate(_chartDates.length, (index) {
                              final count = _chartCounts[index];
                              final height = (count / maxCount) * chartHeight;
                              return SizedBox(
                                width: barWidth,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    if (count > 0)
                                      Text(
                                        count.toString(),
                                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
                                      ),
                                    const SizedBox(height: 4),
                                    Container(
                                      width: 35,
                                      height: height,
                                      decoration: BoxDecoration(
                                        color: Colors.blue,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ),
                        ),
                        // Label sumbu X - INI YANG AKAN BERGERAK SAAT SCROLL
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 10,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: List.generate(_chartDates.length, (index) {
                              return SizedBox(
                                width: barWidth,
                                child: Text(
                                  _chartDates[index],
                                  style: const TextStyle(fontSize: 9),
                                  textAlign: TextAlign.center,
                                ),
                              );
                            }),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 8),
      // Tombol scroll kiri/kanan
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: IconButton(
                icon: const Icon(Icons.chevron_left, size: 20),
                onPressed: () {
                  _scrollController.animateTo(
                    _scrollController.offset - 150,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                tooltip: 'Geser ke kiri',
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  Icon(Icons.swipe, size: 14, color: Colors.grey),
                  SizedBox(width: 4),
                  Text(
                    'Geser grafik ke kanan/kiri',
                    style: TextStyle(fontSize: 10, color: Colors.grey, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: IconButton(
                icon: const Icon(Icons.chevron_right, size: 20),
                onPressed: () {
                  _scrollController.animateTo(
                    _scrollController.offset + 150,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                tooltip: 'Geser ke kanan',
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
  
  Widget _buildSimpleDonutChart() {
  final total = _statusPending + _statusDiproses + _statusSelesai + _statusDitolak;
  if (total == 0) {
    return const Center(child: Text('Belum ada data', style: TextStyle(fontSize: 12)));
  }
  
  return CustomPaint(
    painter: _SimplePieChartPainter(
      pending: _statusPending,
      diproses: _statusDiproses,
      selesai: _statusSelesai,
      ditolak: _statusDitolak,
      total: total,
    ),
  );
}

  
  Widget _buildLegendItem(String label, int value, Color color) {
  return Row(
    children: [
      Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 8),
      Text(
        label,
        style: const TextStyle(fontSize: 11),
      ),
      const SizedBox(width: 6),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          value.toString(),
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
        ),
      ),
    ],
  );
}
  
  Widget _buildResponseRateCard() {
    final responseRate = _stats['response_rate'] ?? 0;
    final respondedCount = _stats['responded_count'] ?? 0;
    final total = _stats['total'] ?? 0;
    final last7Days = _stats['last_7_days'] ?? 0;
    final avgResponseHours = _stats['avg_response_hours'] ?? 0;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Respons Rate Chart
          Expanded(
            flex: 1,
            child: Column(
              children: [
                const Text('Respons Rate', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey.shade200,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Progress circle
                      SizedBox(
                        width: 80,
                        height: 80,
                        child: CircularProgressIndicator(
                          value: responseRate / 100,
                          strokeWidth: 8,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                        ),
                      ),
                      Container(
                        width: 60,
                        height: 60,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '$responseRate%',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Stats
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      const Text('Rata-rata Waktu Respons', 
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 4),
                      Text('$avgResponseHours jam',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      const Text('Pesan Direspons', 
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 4),
                      Text('$respondedCount / $total',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      const Text('Aktivitas 7 Hari', 
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 4),
                      Text('$last7Days pesan',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTemplatesSection() {
    if (_templates.isEmpty) return const SizedBox();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '⚡ Template Cepat',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          // ListView dengan 1 kolom
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _templates.length,
            itemBuilder: (context, index) {
              final template = _templates[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.bolt, size: 16, color: Colors.orange),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            template['name'] ?? 'Template',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy, size: 16, color: Colors.blue),
                          onPressed: () {
                            Helpers.showToast(context, 'Template "${template['name']}" disalin');
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      template['content'] ?? '',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        template['category'] ?? 'Umum',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.blue.shade700,
                        ),
                      ),
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
  
  Widget _buildTimelineSection() {
    if (_timeline.isEmpty) return const SizedBox();
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.history, size: 20, color: Color(0xFF0B4D8A)),
                const SizedBox(width: 8),
                const Text('Aktivitas Terbaru', 
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const Spacer(),
                Text('${_timeline.length} aktivitas', 
                    style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 12),
            
            // Timeline List
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _paginatedTimeline.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final activity = _paginatedTimeline[index];
                final isSent = activity['activity_type'] == 'sent';
                final status = activity['status'] ?? '';
                final isRejected = status == 'Ditolak';
                
                return InkWell(
                  onTap: () => _viewMessageFromTimeline(activity['id']),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isSent ? Colors.blue.shade100 : (isRejected ? Colors.red.shade100 : Colors.green.shade100),
                      child: Icon(
                        isSent ? Icons.send : (isRejected ? Icons.cancel : Icons.reply),
                        size: 16,
                        color: isSent ? Colors.blue : (isRejected ? Colors.red : Colors.green),
                      ),
                    ),
                    title: Text(
                      isSent ? 'Pesan dikirim' : (isRejected ? 'Pesan ditolak' : 'Direspons'),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activity['jenis_pesan'] ?? '',
                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          activity['isi_pesan'] ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          activity['activity_date_formatted'] ?? _formatDateIndonesian(activity['activity_date']),
                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                        if (!isSent && activity['responder_nama'] != null)
                          Text(
                            'by ${activity['responder_nama']}',
                            style: const TextStyle(fontSize: 9, color: Colors.grey),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
            
            // Pagination
            if (_timelineTotalPages > 1)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left, size: 20),
                      onPressed: _timelineCurrentPage > 1
                          ? () => _goToTimelinePage(_timelineCurrentPage - 1)
                          : null,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '$_timelineCurrentPage / $_timelineTotalPages',
                        style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right, size: 20),
                      onPressed: _timelineCurrentPage < _timelineTotalPages
                          ? () => _goToTimelinePage(_timelineCurrentPage + 1)
                          : null,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildFilterDropdown(
                  label: 'STATUS',
                  value: _selectedStatus,
                  items: const ['all', 'Pending', 'Dibaca', 'Diproses', 'Disetujui', 'Ditolak', 'Selesai'],
                  onChanged: (value) => setState(() => _selectedStatus = value!),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFilterDropdown(
                  label: 'JENIS',
                  value: _selectedType,
                  items: [{'id': 'all', 'name': 'Semua Jenis'}, ..._messageTypes.map((t) => {'id': t['id'].toString(), 'name': t['jenis_pesan']})],
                  onChanged: (value) => setState(() => _selectedType = value!),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFilterDropdown(
                  label: 'PRIORITAS',
                  value: _selectedPriority,
                  items: const ['all', 'Low', 'Medium', 'High', 'Urgent'],
                  onChanged: (value) => setState(() => _selectedPriority = value!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Cari pesan...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  ),
                  onChanged: (value) => _searchQuery = value,
                  onSubmitted: (_) => _applyFilters(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Dari tanggal',
                    prefixIcon: const Icon(Icons.calendar_today, size: 16),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  controller: TextEditingController(text: _dateFrom),
                  readOnly: true,
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() => _dateFrom = date.toIso8601String().split('T').first);
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Sampai tanggal',
                    prefixIcon: const Icon(Icons.calendar_today, size: 16),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  controller: TextEditingController(text: _dateTo),
                  readOnly: true,
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() => _dateTo = date.toIso8601String().split('T').first);
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _applyFilters,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0B4D8A),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                ),
                child: const Text('Filter'),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: _resetFilters,
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                child: const Text('Reset'),
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
    required List<dynamic> items,
    required Function(String) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey)),
        const SizedBox(height: 4),
        Container(
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
              items: items.map<DropdownMenuItem<String>>((item) {
                String display;
                String itemValue;
                if (item is Map) {
                  display = item['name'];
                  itemValue = item['id'].toString();
                } else {
                  display = item.toString();
                  itemValue = item.toString();
                  if (item == 'all') display = 'Semua';
                  if (item == 'all' && label == 'STATUS') display = 'Semua Status';
                }
                return DropdownMenuItem(value: itemValue, child: Text(display, style: const TextStyle(fontSize: 12)));
              }).toList(),
              onChanged: (value) => onChanged(value!),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildMessagesTable() {
    if (_messages.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(Icons.inbox, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 12),
              Text('Tidak ada pesan', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
              const SizedBox(height: 8),
              Text('Kirim pesan baru untuk memulai', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => Navigator.pushReplacementNamed(context, '/send-message'),
                icon: const Icon(Icons.add),
                label: const Text('Kirim Pesan'),
              ),
            ],
          ),
        ),
      );
    }
    
    // Scroll controller untuk horizontal scroll
    final ScrollController _horizontalScrollController = ScrollController();
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          // Scrollbar Horizontal
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
                dataRowMinHeight: 60,
                dataRowMaxHeight: 80,
                columnSpacing: 12,
                headingRowColor: MaterialStateProperty.all(Colors.grey.shade100),
                columns: const [
                  DataColumn(label: Text('#', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                  DataColumn(label: Text('Referensi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                  DataColumn(label: Text('Jenis', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                  DataColumn(label: Text('Isi Pesan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                  DataColumn(label: Text('Lamp', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                  DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                  DataColumn(label: Text('Prioritas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                  DataColumn(label: Text('Tanggal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                  DataColumn(label: Text('Respons', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                  DataColumn(label: Text('Aksi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                ],
                rows: _messages.asMap().entries.map((entry) {
                  final index = entry.key + 1 + ((_currentPage - 1) * _perPage);
                  final message = entry.value;
                  final hasResponse = message['responder_id'] != null && message['responder_id'] > 0;
                  final hasAttachments = (message['attachment_count'] ?? 0) > 0;
                  
                  return DataRow(
                    cells: [
                      DataCell(Text('$index', style: const TextStyle(fontSize: 11))),
                      DataCell(
                        Text(
                          message['reference_number'] ?? 'REF-${message['id']}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                        ),
                      ),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            message['jenis_pesan'] ?? '-',
                            style: const TextStyle(fontSize: 10, color: Colors.blue),
                          ),
                        ),
                      ),
                      DataCell(
                        SizedBox(
                          width: 200,
                          child: Text(
                            message['isi_pesan'] ?? '-',
                            style: const TextStyle(fontSize: 11),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      DataCell(
                        hasAttachments
                            ? IconButton(
                                icon: const Icon(Icons.attach_file, size: 18, color: Colors.purple),
                                onPressed: () => _viewAttachments(message['id']),
                                tooltip: '${message['attachment_count']} lampiran',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              )
                            : const Text('-', style: TextStyle(fontSize: 11)),
                      ),
                      DataCell(_buildStatusBadge(message['status'] ?? 'Pending')),
                      DataCell(_buildPriorityBadge(message['priority'] ?? 'Medium')),
                      DataCell(
                        Text(
                          _formatDate(message['created_at']),
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                      DataCell(
                        hasResponse
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    message['responder_nama'] ?? 'Admin',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                                  ),
                                  Text(
                                    _formatDate(message['tanggal_respon']),
                                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                                  ),
                                ],
                              )
                            : Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text('Belum', style: TextStyle(fontSize: 10, color: Colors.grey)),
                              ),
                      ),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.visibility, size: 18, color: Colors.blue),
                              onPressed: () => _viewMessageDetail(message['id']),
                              tooltip: 'Lihat Detail',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            const SizedBox(width: 4),
                            if (hasAttachments)
                              IconButton(
                                icon: const Icon(Icons.image, size: 18, color: Colors.purple),
                                onPressed: () => _viewAttachments(message['id']),
                                tooltip: 'Lihat Lampiran',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
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
    if (_totalPages <= 1) return const SizedBox();
    
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
        Text('Halaman $_currentPage dari $_totalPages', style: const TextStyle(fontSize: 12)),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: _currentPage < _totalPages ? () {
            setState(() => _currentPage++);
            _loadMessages();
          } : null,
        ),
      ],
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
          ElevatedButton(onPressed: _loadData, child: const Text('Coba Lagi')),
        ],
      ),
    );
  }
}

// Simple Pie Chart Painter
class _SimplePieChartPainter extends CustomPainter {
  final int pending;
  final int diproses;
  final int selesai;
  final int ditolak;
  final int total;

  _SimplePieChartPainter({
    required this.pending,
    required this.diproses,
    required this.selesai,
    required this.ditolak,
    required this.total,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (total == 0) return;
    
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final paint = Paint()..style = PaintingStyle.fill;
    
    double startAngle = -90.0;
    final totalValue = total.toDouble();
    
    // Pending
    if (pending > 0) {
      final sweepAngle = 360.0 * (pending / totalValue);
      paint.color = Colors.orange;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle * 3.14159 / 180,
        sweepAngle * 3.14159 / 180,
        true,
        paint,
      );
      startAngle += sweepAngle;
    }
    
    // Diproses
    if (diproses > 0) {
      final sweepAngle = 360.0 * (diproses / totalValue);
      paint.color = Colors.cyan;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle * 3.14159 / 180,
        sweepAngle * 3.14159 / 180,
        true,
        paint,
      );
      startAngle += sweepAngle;
    }
    
    // Selesai
    if (selesai > 0) {
      final sweepAngle = 360.0 * (selesai / totalValue);
      paint.color = Colors.green;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle * 3.14159 / 180,
        sweepAngle * 3.14159 / 180,
        true,
        paint,
      );
      startAngle += sweepAngle;
    }
    
    // Ditolak
    if (ditolak > 0) {
      final sweepAngle = 360.0 * (ditolak / totalValue);
      paint.color = Colors.red;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle * 3.14159 / 180,
        sweepAngle * 3.14159 / 180,
        true,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}