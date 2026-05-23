// lib/screens/guru/message_detail_screen.dart
import 'package:flutter/material.dart';
import '../../services/followup_service.dart';
import '../../widgets/window_resizer_shortcut.dart'; // Import window resizer shortcut

class MessageDetailScreen extends StatefulWidget {
  final int messageId;
  
  const MessageDetailScreen({super.key, required this.messageId});

  @override
  State<MessageDetailScreen> createState() => _MessageDetailScreenState();
}

class _MessageDetailScreenState extends State<MessageDetailScreen> {
  late final FollowupService _service;
  
  Map<String, dynamic>? _message;
  List<Map<String, dynamic>> _attachments = [];
  List<Map<String, dynamic>> _responses = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _service = FollowupService();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _service.getMessageDetail(widget.messageId);
      
      if (mounted) {
        setState(() {
          _message = data['message'];
          _attachments = List<Map<String, dynamic>>.from(data['attachments'] ?? []);
          _responses = List<Map<String, dynamic>>.from(data['responses'] ?? []);
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending': return Colors.orange;
      case 'Dibaca': return Colors.blue;
      case 'Diproses': return Colors.cyan;
      case 'Disetujui': return Colors.green;
      case 'Ditolak': return Colors.red;
      case 'Selesai': return Colors.teal;
      default: return Colors.grey;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'Low': return Colors.green;
      case 'Medium': return Colors.orange;
      case 'High': return Colors.deepOrange;
      case 'Urgent': return Colors.red;
      default: return Colors.grey;
    }
  }

  String _getPriorityText(String priority) {
    switch (priority?.toLowerCase()) {
      case 'urgent': return 'Urgent';
      case 'high': return 'Tinggi';
      case 'medium': return 'Sedang';
      case 'low': return 'Rendah';
      default: return 'Normal';
    }
  }

  String _getUserTypeDisplay(String userType) {
    switch (userType) {
      case 'Admin': return 'Administrator';
      case 'Kepala_Sekolah': return 'Kepala Sekolah';
      case 'Wakil_Kepala': return 'Wakil Kepala Sekolah';
      case 'Guru_BK': return 'Guru BK';
      case 'Guru_Humas': return 'Guru Humas';
      case 'Guru_Kurikulum': return 'Guru Kurikulum';
      case 'Guru_Kesiswaan': return 'Guru Kesiswaan';
      case 'Guru_Sarana': return 'Guru Sarana';
      case 'Guru': return 'Guru';
      default: return userType ?? 'User';
    }
  }

  int _getResponseLevel(String userType) {
    if (userType == 'Admin' || userType == 'Guru_BK' || userType == 'Guru_Humas' || 
        userType == 'Guru_Kurikulum' || userType == 'Guru_Kesiswaan' || 
        userType == 'Guru_Sarana' || userType == 'Guru') {
      return 1;
    } else if (userType == 'Wakil_Kepala') {
      return 2;
    } else if (userType == 'Kepala_Sekolah') {
      return 3;
    }
    return 0;
  }

  void _showImagePreview(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.9),
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
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WindowResizerShortcut(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Detail Pesan'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 1,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadDetail,
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? _buildErrorWidget()
                : _buildDetailContent(),
      ),
    );
  }

  Widget _buildDetailContent() {
    if (_message == null) {
      return const Center(child: Text('Pesan tidak ditemukan'));
    }

    final msg = _message!;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      msg['reference_number'] ?? 'Pesan #${msg['id']}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'ID: ${msg['id']}',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildInfoChip('Status: ${msg['status'] ?? 'Pending'}', _getStatusColor(msg['status'] ?? 'Pending')),
                    const SizedBox(width: 8),
                    _buildInfoChip('Prioritas: ${_getPriorityText(msg['priority'])}', _getPriorityColor(msg['priority'])),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 14, color: Colors.white70),
                    const SizedBox(width: 4),
                    Text(
                      'Dikirim: ${msg['tanggal_pesan'] ?? msg['created_at'] ?? '-'}',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Pengirim Card
          _buildInfoCard(
            title: 'Informasi Pengirim',
            icon: Icons.person,
            iconColor: Colors.blue,
            children: [
              _buildInfoRow('Nama', msg['pengirim_nama_display'] ?? msg['pengirim_nama'] ?? '-'),
              _buildInfoRow('Tipe', msg['pengirim_tipe'] ?? '-'),
              _buildInfoRow('Identitas', msg['nomor_identitas'] ?? msg['reference_number'] ?? '-'),
              if (msg['pengirim_email'] != null && msg['pengirim_email'].toString().isNotEmpty)
                _buildInfoRow('Email', msg['pengirim_email']),
              if (msg['pengirim_phone'] != null && msg['pengirim_phone'].toString().isNotEmpty)
                _buildInfoRow('No. HP', msg['pengirim_phone']),
            ],
          ),
          const SizedBox(height: 16),
          
          // Isi Pesan Card
          _buildInfoCard(
            title: 'Isi Pesan',
            icon: Icons.message,
            iconColor: Colors.green,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  msg['isi_pesan'] ?? 'Tidak ada isi pesan',
                  style: const TextStyle(fontSize: 14, height: 1.5),
                ),
              ),
            ],
          ),
          
          // Lampiran Gambar
          if (_attachments.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildInfoCard(
              title: 'Lampiran (${_attachments.length})',
              icon: Icons.attach_file,
              iconColor: Colors.purple,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _attachments.map((attachment) {
                    final imageUrl = attachment['filepath'] ?? '';
                    final isImage = attachment['filetype']?.toLowerCase() ?? '';
                    final isImageFile = isImage.contains('image') || 
                        ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'].contains(isImage);
                    
                    if (isImageFile && imageUrl.isNotEmpty) {
                      return GestureDetector(
                        onTap: () => _showImagePreview(imageUrl),
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
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
                                      child: const Icon(Icons.broken_image, size: 40, color: Colors.grey),
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
                              ],
                            ),
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  }).toList(),
                ),
              ],
            ),
          ],
          
          // Respon Card
          if (msg['has_response'] == true || _responses.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildInfoCard(
              title: 'Respon Guru',
              icon: Icons.reply_all,
              iconColor: Colors.orange,
              children: [
                _buildInfoRow('Guru Responder', msg['responder_name'] ?? '-'),
                _buildInfoRow('Status Respon', msg['response_status'] ?? msg['status'] ?? '-'),
                _buildInfoRow('Waktu Respon', msg['tanggal_respon'] ?? '-'),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Catatan Respon:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(msg['last_response'] ?? 'Tidak ada catatan'),
                    ],
                  ),
                ),
              ],
            ),
          ],
          
          // Riwayat Respons Berjenjang
          if (_responses.isNotEmpty && _responses.length > 1) ...[
            const SizedBox(height: 16),
            _buildInfoCard(
              title: 'Riwayat Respons Berjenjang',
              icon: Icons.history,
              iconColor: Colors.teal,
              children: [
                ..._responses.asMap().entries.map((entry) {
                  final index = entry.key;
                  final response = entry.value;
                  final level = _getResponseLevel(response['user_type']);
                  final isLast = index == _responses.length - 1;
                  
                  return Column(
                    children: [
                      _buildResponseItem(response, level, index + 1),
                      if (!isLast) ...[
                        const SizedBox(height: 8),
                        Container(
                          height: 20,
                          width: 2,
                          color: Colors.grey[300],
                          margin: const EdgeInsets.only(left: 20),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ],
                  );
                }).toList(),
              ],
            ),
          ],
          
          // Review Card
          if (msg['review_id'] != null) ...[
            const SizedBox(height: 16),
            _buildInfoCard(
              title: 'Review ${msg['reviewer_type'] ?? 'Pimpinan'}',
              icon: msg['reviewer_type'] == 'Kepala_Sekolah' ? Icons.verified : Icons.assignment,
              iconColor: msg['reviewer_type'] == 'Kepala_Sekolah' ? Colors.amber : Colors.teal,
              children: [
                _buildInfoRow('Reviewer', msg['reviewer_nama'] ?? '-'),
                _buildInfoRow('Tanggal Review', msg['review_date'] ?? '-'),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Catatan Review:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(msg['review_catatan'] ?? 'Tidak ada catatan'),
                    ],
                  ),
                ),
              ],
            ),
          ],
          
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildResponseItem(Map<String, dynamic> response, int level, int number) {
    Color getLevelColor(int level) {
      switch (level) {
        case 1: return Colors.blue;
        case 2: return Colors.orange;
        case 3: return Colors.purple;
        default: return Colors.grey;
      }
    }

    String getLevelText(int level) {
      switch (level) {
        case 1: return 'Level 1 - Guru/Admin';
        case 2: return 'Level 2 - Wakil Kepala Sekolah';
        case 3: return 'Level 3 - Kepala Sekolah';
        default: return 'Unknown';
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: getLevelColor(level).withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: getLevelColor(level).withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: getLevelColor(level),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      number.toString(),
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        response['responder_nama'] ?? 'Unknown',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Text(
                        getLevelText(level),
                        style: TextStyle(fontSize: 10, color: getLevelColor(level)),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: getLevelColor(level).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getUserTypeDisplay(response['user_type']),
                    style: TextStyle(fontSize: 10, color: getLevelColor(level), fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    response['catatan_respon'] ?? 'Tidak ada catatan',
                    style: const TextStyle(fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 12, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(
                        response['created_at'] ?? '-',
                        style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
          ),
          const Divider(height: 0),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w500),
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
            onPressed: _loadDetail,
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }
}