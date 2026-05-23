// lib/widgets/attachments_viewer_dialog.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/auth_service.dart';
import '../utils/constants.dart';

class AttachmentsViewerDialog extends StatefulWidget {
  final int messageId;

  const AttachmentsViewerDialog({
    super.key,
    required this.messageId,
  });

  @override
  State<AttachmentsViewerDialog> createState() => _AttachmentsViewerDialogState();
}

class _AttachmentsViewerDialogState extends State<AttachmentsViewerDialog> {
  List<Map<String, dynamic>> _attachments = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAttachmentsFromMessageData();
  }

  Future<void> _loadAttachmentsFromMessageData() async {
  setState(() {
    _isLoading = true;
    _error = null;
  });

  try {
    final token = await AuthService.getToken();
    
    // Ambil data dari followup API
    final url = Uri.parse('${Constants.baseUrl}/modules/guru/api/followup_api.php?status=all&priority=all&source=all&search=&page=1');
    
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 30));
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        final messages = List<Map<String, dynamic>>.from(data['messages'] ?? []);
        final foundMessage = messages.firstWhere(
          (m) => m['id'] == widget.messageId,
          orElse: () => {},
        );
        
        final attachmentCount = foundMessage['attachment_count'] ?? 0;
        
        if (attachmentCount > 0) {
          final List<Map<String, dynamic>> attachments = [];
          
          // Dapatkan informasi unik dari pesan
          final messageId = foundMessage['id'];
          final referenceNumber = foundMessage['reference_number'] ?? '';
          final createdAt = foundMessage['created_at'] ?? '';
          final isExternal = foundMessage['is_external'] ?? 0;
          
          // Parse tanggal untuk mendapatkan path folder
          String year = '';
          String month = '';
          String day = '';
          if (createdAt.isNotEmpty) {
            try {
              final date = DateTime.parse(createdAt);
              year = date.year.toString();
              month = date.month.toString().padLeft(2, '0');
              day = date.day.toString().padLeft(2, '0');
            } catch (e) {
              print('Error parsing date: $e');
            }
          }
          
          // Tentukan folder berdasarkan tipe pesan
          String uploadFolder = isExternal == 1 ? 'external_messages' : 'messages';
          
          // Format nama file berdasarkan reference number
          String baseFileName = referenceNumber.isNotEmpty 
              ? referenceNumber.replaceAll('-', '_')
              : 'MSG_$messageId';
          
          // Buat URL untuk attachment
          String imageUrl = '${Constants.baseUrl}/uploads/$uploadFolder/$year/$month/$day/${baseFileName}_1.jpg';
          
          // Coba cek apakah file ada
          try {
            final headResponse = await http.head(Uri.parse(imageUrl));
            if (headResponse.statusCode != 200) {
              // Coba format lain
              imageUrl = '${Constants.baseUrl}/uploads/$uploadFolder/$year/$month/$day/${baseFileName}.jpg';
              final headResponse2 = await http.head(Uri.parse(imageUrl));
              if (headResponse2.statusCode != 200) {
                imageUrl = '${Constants.baseUrl}/uploads/$uploadFolder/$year/$month/$day/message_${messageId}_1.jpg';
              }
            }
          } catch (e) {
            // Gunakan URL default
          }
          
          print('📸 Attachment URL for message $messageId: $imageUrl');
          
          attachments.add({
            'filepath': 'uploads/$uploadFolder/$year/$month/$day/${baseFileName}_1.jpg',
            'filename': 'lampiran_1.jpg',
            'filesize': 0,
            'filetype': 'image/jpeg',
            'full_url': imageUrl,
          });
          
          setState(() {
            _attachments = attachments;
            _isLoading = false;
          });
        } else {
          setState(() {
            _attachments = [];
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _error = 'Gagal memuat data';
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _error = 'Server error: ${response.statusCode}';
        _isLoading = false;
      });
    }
  } catch (e) {
    setState(() {
      _error = 'Error: $e';
      _isLoading = false;
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

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1048576).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
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
              decoration: BoxDecoration(
                color: Colors.purple,
                borderRadius: const BorderRadius.only(
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
                      '${_attachments.length} file',
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
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                              const SizedBox(height: 16),
                              Text(_error!),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loadAttachmentsFromMessageData,
                                child: const Text('Coba Lagi'),
                              ),
                            ],
                          ),
                        )
                      : _attachments.isEmpty
                          ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.image_not_supported, size: 64, color: Colors.grey),
                                  SizedBox(height: 16),
                                  Text('Tidak ada lampiran', style: TextStyle(color: Colors.grey)),
                                ],
                              ),
                            )
                          : GridView.builder(
                              padding: const EdgeInsets.all(16),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 1,
                              ),
                              itemCount: _attachments.length,
                              itemBuilder: (context, index) {
                                final attachment = _attachments[index];
                                final filePath = attachment['filepath'] ?? '';
                                final fileName = attachment['filename'] ?? 'file';
                                final fileSize = attachment['filesize'] != null 
                                    ? _formatFileSize(attachment['filesize'])
                                    : '';
                                
                                final imageUrl = filePath.startsWith('http') 
                                    ? filePath 
                                    : '${Constants.baseUrl}/$filePath';
                                
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
                                                    Text('Gambar tidak tersedia', style: TextStyle(fontSize: 10)),
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
  }
}