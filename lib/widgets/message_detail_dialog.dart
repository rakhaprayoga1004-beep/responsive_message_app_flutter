// lib/widgets/message_detail_dialog.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/auth_service.dart';
import '../utils/constants.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MessageDetailDialog extends StatefulWidget {
  final int messageId;
  final Map<String, dynamic>? initialData;

  const MessageDetailDialog({
    super.key,
    required this.messageId,
    this.initialData,
  });

  @override
  State<MessageDetailDialog> createState() => _MessageDetailDialogState();
}

class _MessageDetailDialogState extends State<MessageDetailDialog> {
  Map<String, dynamic>? _messageDetail;
  List<Map<String, dynamic>> _attachments = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCompleteData();
  }

  Future<void> _loadCompleteData() async {
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
      
      await _loadMessageDetail(token);
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMessageDetail(String token) async {
    try {
      final url = Uri.parse('${Constants.baseUrl}/modules/guru/api/get_message_detail.php?message_id=${widget.messageId}');
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
        if (data['success'] == true && data['message'] != null) {
          setState(() {
            _messageDetail = data['message'];
            _attachments = List<Map<String, dynamic>>.from(data['message']['attachments'] ?? []);
          });
          print('✅ Message detail loaded successfully');
          print('   - has_response: ${_messageDetail?['has_response']}');
          print('   - response_status: ${_messageDetail?['response_status']}');
          print('   - has_review: ${_messageDetail?['has_review']}');
          print('   - reviewer_type: ${_messageDetail?['reviewer_type']}');
        } else {
          setState(() {
            _error = data['message'] ?? 'Gagal memuat detail pesan';
          });
        }
      } else if (response.statusCode == 401) {
        setState(() {
          _error = 'Session expired. Silakan login kembali.';
        });
      } else {
        setState(() {
          _error = 'Server error: ${response.statusCode}';
        });
      }
    } catch (e) {
      print('❌ Error loading message detail: $e');
      setState(() {
        _error = 'Error: $e';
      });
    }
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
                    headers: const {
                      'Cache-Control': 'no-cache',
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      print('❌ Preview error: $error');
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
    switch (priority?.toLowerCase()) {
      case 'urgent': return Colors.red;
      case 'high': return Colors.orange;
      case 'medium': return Colors.blue;
      case 'low': return Colors.green;
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

  String _formatDate(dynamic date) {
    if (date == null) return '-';
    if (date is String) {
      try {
        final parsed = DateTime.parse(date);
        return '${parsed.day}/${parsed.month}/${parsed.year} ${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}';
      } catch (e) {
        return date;
      }
    }
    return date.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? _buildErrorWidget()
                      : _buildDetailContent(),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _messageDetail?['reference_number'] ?? 'Detail Pesan',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ID: ${_messageDetail?['id'] ?? widget.messageId}',
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
          const SizedBox(height: 12),
          if (_messageDetail != null) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(_messageDetail?['status'] ?? 'Pending').withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Status: ${_messageDetail?['status'] ?? 'Pending'}',
                    style: TextStyle(
                      color: _getStatusColor(_messageDetail?['status'] ?? 'Pending'),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getPriorityColor(_messageDetail?['priority'] ?? 'Medium').withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Prioritas: ${_getPriorityText(_messageDetail?['priority'])}',
                    style: TextStyle(
                      color: _getPriorityColor(_messageDetail?['priority'] ?? 'Medium'),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if ((_messageDetail?['is_external'] ?? 0) == 1)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'External',
                      style: TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.w500),
                    ),
                  ),
                if ((_messageDetail?['has_response'] ?? false) == true)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Sudah Direspon',
                      style: TextStyle(color: Colors.green.shade700, fontSize: 11, fontWeight: FontWeight.w500),
                    ),
                  ),
                if ((_messageDetail?['has_review'] ?? false) == true)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Sudah Direview: ${_messageDetail?['reviewer_type'] ?? 'Pimpinan'}',
                      style: const TextStyle(color: Colors.purple, fontSize: 11, fontWeight: FontWeight.w500),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailContent() {
  if (_messageDetail == null) {
    return const Center(child: Text('Data tidak ditemukan'));
  }

  final msg = _messageDetail!;
  final hasResponse = msg['has_response'] == true;
  final hasReview = msg['has_review'] == true;
  final isExternal = (msg['is_external'] ?? 0) == 1;
  
  return SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // INFORMASI PENGIRIM
        _buildSectionCard(
          title: 'Informasi Pengirim',
          icon: Icons.person,
          iconColor: Colors.blue,
          children: [
            _buildInfoRow('Nama', msg['pengirim_nama_display'] ?? '-'),
            _buildInfoRow('Tipe', msg['pengirim_tipe'] ?? '-'),
            _buildInfoRow('Identitas', msg['nomor_identitas'] ?? '-'),
            _buildInfoRow('Email', msg['pengirim_email'] ?? '-'),
            _buildInfoRow('No. HP', msg['pengirim_phone'] ?? '-'),
            _buildInfoRow('Tanggal Kirim', _formatDate(msg['created_at'])),
          ],
        ),
        const SizedBox(height: 16),
        
        // ISI PESAN
        _buildSectionCard(
          title: 'Isi Pesan',
          icon: Icons.message,
          iconColor: Colors.green,
          children: [
            Container(
              width: double.infinity,
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
        
        // ============================================================
        // LAMPIRAN GAMBAR - DIPINDAHKAN KE SINI (SETELAH ISI PESAN)
        // ============================================================
        const SizedBox(height: 16),
        _buildSectionCard(
          title: 'Lampiran (${_attachments.length})',
          icon: Icons.attach_file,
          iconColor: Colors.purple,
          children: [
            if (_attachments.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('Tidak ada lampiran', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1,
                ),
                itemCount: _attachments.length,
                itemBuilder: (context, index) {
                  final attachment = _attachments[index];
                  final filepath = attachment['filepath'] ?? '';
                  final imageUrl = filepath.startsWith('http') 
                      ? filepath 
                      : '${Constants.baseUrl}/${filepath.replaceFirst(RegExp(r'^/'), '')}';
                  final fileName = attachment['original_name'] ?? attachment['filename'] ?? 'Lampiran';
                  final fileSize = attachment['filesize'] != null 
                      ? _formatFileSize(attachment['filesize'])
                      : '';
                  
                  return GestureDetector(
                    onTap: () => _showImagePreview(imageUrl, fileName),
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
                            CachedNetworkImage(
                              imageUrl: imageUrl,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: Colors.grey[200],
                                child: const Center(
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: Colors.grey[200],
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.broken_image, size: 40, color: Colors.grey),
                                    SizedBox(height: 4),
                                    Text('Gambar error', style: TextStyle(fontSize: 10)),
                                  ],
                                ),
                              ),
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
          ],
        ),
        
        // RESPON GURU (jika ada)
        if (hasResponse) ...[
          const SizedBox(height: 16),
          _buildSectionCard(
            title: 'Respon Guru',
            icon: Icons.reply_all,
            iconColor: Colors.orange,
            children: [
              _buildInfoRow('Responder', msg['responder_name'] ?? '-'),
              _buildInfoRow('Tipe Responder', msg['responder_type'] ?? '-'),
              _buildInfoRow('Status Respon', 
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: msg['response_status'] == 'Disetujui' 
                        ? Colors.green.withOpacity(0.1) 
                        : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    msg['response_status'] ?? '-',
                    style: TextStyle(
                      color: msg['response_status'] == 'Disetujui' ? Colors.green : Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              _buildInfoRow('Waktu Respon', _formatDate(msg['response_date'])),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Catatan Respon:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      msg['last_response'] ?? 'Tidak ada catatan',
                      style: const TextStyle(fontSize: 13, height: 1.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
        
        // REVIEW PIMPINAN (jika ada)
        if (hasReview) ...[
          const SizedBox(height: 16),
          _buildSectionCard(
            title: 'Review ${msg['reviewer_type'] ?? 'Pimpinan'}',
            icon: msg['reviewer_type'] == 'Kepala_Sekolah' ? Icons.verified : Icons.people,
            iconColor: msg['reviewer_type'] == 'Kepala_Sekolah' ? Colors.amber : Colors.purple,
            children: [
              _buildInfoRow('Reviewer', msg['reviewer_name'] ?? '-'),
              _buildInfoRow('Jabatan', msg['reviewer_type'] ?? '-'),
              _buildInfoRow('Waktu Review', _formatDate(msg['review_date'])),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: msg['reviewer_type'] == 'Kepala_Sekolah' 
                      ? Colors.amber.shade50 
                      : Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: msg['reviewer_type'] == 'Kepala_Sekolah' 
                        ? Colors.amber.shade200 
                        : Colors.purple.shade200,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          msg['reviewer_type'] == 'Kepala_Sekolah' 
                              ? Icons.verified 
                              : Icons.comment,
                          size: 16,
                          color: msg['reviewer_type'] == 'Kepala_Sekolah' 
                              ? Colors.amber 
                              : Colors.purple,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Catatan Review:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold, 
                            fontSize: 12,
                            color: msg['reviewer_type'] == 'Kepala_Sekolah' 
                                ? Colors.amber.shade800 
                                : Colors.purple.shade800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      msg['review_catatan'] ?? 'Tidak ada catatan review',
                      style: const TextStyle(fontSize: 13, height: 1.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ],
    ),
  );
}

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1048576).toStringAsFixed(1)} MB';
  }

  Widget _buildSectionCard({
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

  Widget _buildInfoRow(String label, dynamic value) {
    Widget content;
    
    if (value is Widget) {
      content = value;
    } else {
      content = Text(
        value?.toString() ?? '-',
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      );
    }
    
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
            child: content,
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    final hasResponse = _messageDetail?['has_response'] == true;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text('Tutup'),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to response page
              final route = hasResponse 
                  ? '/guru/response/edit/${_messageDetail?['id']}'
                  : '/guru/response/${_messageDetail?['id']}';
              // Handle navigation based on your routing
            },
            icon: Icon(hasResponse ? Icons.edit : Icons.reply),
            label: Text(hasResponse ? 'Edit Respons' : 'Beri Respons'),
            style: ElevatedButton.styleFrom(
              backgroundColor: hasResponse ? Colors.orange : Colors.blue,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
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
          Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(_error!, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadCompleteData,
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }
}