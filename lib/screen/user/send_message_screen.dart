// lib/screen/user/send_message_screen.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import '../../services/auth_service.dart';
import '../../utils/helpers.dart';
import '../../utils/constants.dart';
import '../../widgets/window_resizer_shortcut.dart'; // Import window resizer shortcut

class SendMessageScreen extends StatefulWidget {
  const SendMessageScreen({super.key});

  @override
  State<SendMessageScreen> createState() => _SendMessageScreenState();
}

class _SendMessageScreenState extends State<SendMessageScreen> {
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  String _selectedMessageType = '';
  List<File> _attachments = [];
  List<String> _attachmentNames = [];
  bool _isLoading = false;
  
  // Data dari API
  List<Map<String, dynamic>> _messageTypes = [];
  bool _isLoadingTypes = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadMessageTypes();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadMessageTypes() async {
    try {
      final token = await AuthService.getToken();
      
      if (token == null || token.isEmpty) {
        setState(() {
          _errorMessage = 'Token tidak ditemukan. Silakan login ulang.';
          _isLoadingTypes = false;
        });
        return;
      }
      
      final url = Uri.parse('${Constants.baseUrl}/modules/user/api/get_message_types.php')
          .replace(queryParameters: {'token': token});
      print('📡 URL with token: $url');
      
      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));
      
      print('📡 Response status: ${response.statusCode}');
      print('📡 Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            _messageTypes = List<Map<String, dynamic>>.from(data['data']);
            _isLoadingTypes = false;
            if (_messageTypes.isNotEmpty) {
              _selectedMessageType = _messageTypes[0]['id'].toString();
              print('✅ Message types loaded: ${_messageTypes.length} types');
            }
          });
        } else {
          setState(() {
            _errorMessage = data['message'] ?? 'Gagal memuat jenis pesan';
            _isLoadingTypes = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Gagal terhubung ke server (HTTP ${response.statusCode})';
          _isLoadingTypes = false;
        });
      }
    } catch (e) {
      print('❌ Exception: $e');
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoadingTypes = false;
      });
    }
  }

  Future<void> _pickAttachments() async {
    final ImagePicker picker = ImagePicker();
    
    if (Theme.of(context).platform == TargetPlatform.iOS || 
        Theme.of(context).platform == TargetPlatform.android) {
      final result = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Pilih Gambar'),
          content: const Text('Pilih sumber gambar:'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, 'camera'),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.camera_alt, size: 32),
                  SizedBox(height: 4),
                  Text('Kamera'),
                ],
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 'gallery'),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.photo_library, size: 32),
                  SizedBox(height: 4),
                  Text('Galeri'),
                ],
              ),
            ),
          ],
        ),
      );

      if (result == null) return;

      List<XFile>? pickedFiles;
      
      if (result == 'camera') {
        final XFile? file = await picker.pickImage(source: ImageSource.camera);
        if (file != null) {
          pickedFiles = [file];
        }
      } else {
        pickedFiles = await picker.pickMultiImage(limit: 5);
      }

      if (pickedFiles != null && pickedFiles.isNotEmpty) {
        _processPickedFiles(pickedFiles);
      }
    } else {
      final XFile? file = await picker.pickImage(source: ImageSource.gallery);
      if (file != null) {
        _processPickedFiles([file]);
      }
    }
  }

  Future<void> _processPickedFiles(List<XFile> pickedFiles) async {
    final List<File> validFiles = [];
    final List<String> validNames = [];
    
    for (var file in pickedFiles) {
      final File imageFile = File(file.path);
      final int fileSize = await imageFile.length();
      final String extension = path.extension(file.name).toLowerCase();
      
      final allowedExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.heic', '.heif', '.bmp'];
      if (!allowedExtensions.contains(extension)) {
        if (mounted) {
          Helpers.showToast(context, 'Format ${extension.substring(1).toUpperCase()} tidak didukung');
        }
        continue;
      }
      
      if (fileSize > 5 * 1024 * 1024) {
        if (mounted) {
          Helpers.showToast(context, '${file.name} melebihi 5MB');
        }
        continue;
      }
      
      validFiles.add(imageFile);
      validNames.add(file.name);
    }
    
    if (validFiles.isNotEmpty) {
      setState(() {
        _attachments.addAll(validFiles);
        _attachmentNames.addAll(validNames);
      });
      if (mounted) {
        Helpers.showToast(context, '${validFiles.length} file berhasil ditambahkan');
      }
    }
  }

  void _removeAttachment(int index) {
    setState(() {
      _attachments.removeAt(index);
      _attachmentNames.removeAt(index);
    });
    if (mounted) {
      Helpers.showToast(context, 'Lampiran dihapus');
    }
  }

  Future<void> _sendMessage() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedMessageType.isEmpty) {
      if (mounted) {
        Helpers.showToast(context, 'Pilih jenis pesan terlebih dahulu');
      }
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      final token = await AuthService.getToken();
      
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${Constants.baseUrl}/modules/user/send_message.php'),
      );
      
      request.headers['Authorization'] = 'Bearer $token';
      
      request.fields['action'] = 'send_message';
      request.fields['jenis_pesan_id'] = _selectedMessageType;
      request.fields['isi_pesan'] = _messageController.text;
      request.fields['form_unique_id'] = DateTime.now().millisecondsSinceEpoch.toString();
      
      for (int i = 0; i < _attachments.length; i++) {
        final file = _attachments[i];
        final stream = http.ByteStream(file.openRead());
        final length = await file.length();
        
        final multipartFile = http.MultipartFile(
          'attachments[]',
          stream,
          length,
          filename: path.basename(_attachmentNames[i]),
        );
        request.files.add(multipartFile);
      }
      
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      
      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody);
        if (data['success'] == true) {
          if (mounted) {
            _showSuccessDialog(data);
          }
          _messageController.clear();
          setState(() {
            _attachments.clear();
            _attachmentNames.clear();
          });
        } else {
          if (mounted) {
            Helpers.showToast(context, data['message'] ?? 'Gagal mengirim pesan');
          }
        }
      } else {
        if (mounted) {
          Helpers.showToast(context, 'Gagal terhubung ke server');
        }
      }
    } catch (e) {
      if (mounted) {
        Helpers.showToast(context, 'Error: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSuccessDialog(Map<String, dynamic> data) {
    final reference = data['reference']?.toString() ?? 'Tidak tersedia';
    final jenisPesan = data['jenis_pesan']?.toString() ?? '-';
    final uploadedFiles = data['uploaded_files'] ?? [];
    final emailNotified = data['email_notified'] ?? false;
    final whatsappNotified = data['whatsapp_notified'] ?? false;
    final userEmail = data['user_email']?.toString() ?? '';
    final userPhone = data['user_phone']?.toString() ?? '';
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            const SizedBox(width: 8),
            const Text('Pesan Berhasil Dikirim!'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    const Text('Nomor Referensi', style: TextStyle(fontSize: 12)),
                    Text(
                      reference,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _buildInfoRow('Jenis Pesan', jenisPesan),
              if (uploadedFiles.isNotEmpty) ...[
                const Divider(),
                const Text('📎 Lampiran:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                ...uploadedFiles.map<Widget>((file) => Padding(
                  padding: const EdgeInsets.only(left: 8, top: 2),
                  child: Text('• ${file['original_name']} (${(file['filesize'] / 1024).toStringAsFixed(1)} KB)'),
                )),
              ],
              const Divider(),
              const Text('📬 Status Notifikasi:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              if (userEmail.isNotEmpty)
                Row(
                  children: [
                    Icon(
                      emailNotified ? Icons.check_circle : Icons.error,
                      color: emailNotified ? Colors.green : Colors.red,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Email: ${emailNotified ? "Terkirim ke $userEmail" : "Gagal dikirim"}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              if (userPhone.isNotEmpty)
                Row(
                  children: [
                    Icon(
                      whatsappNotified ? Icons.check_circle : Icons.error,
                      color: whatsappNotified ? Colors.green : Colors.red,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'WhatsApp: ${whatsappNotified ? "Terkirim ke $userPhone" : "Gagal dikirim"}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.amber, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Simpan nomor referensi untuk melacak status pesan Anda',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(
            child: Text(': $value', style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Future<Map<String, String>> _getUserData() async {
    final fullName = await AuthService.getFullName() ?? '';
    final userType = await AuthService.getUserType() ?? '';
    final email = await AuthService.getUserEmail();
    final phone = await AuthService.getUserPhone();
    
    return {
      'name': fullName,
      'type': userType,
      'email': email,
      'phone': phone,
    };
  }

  @override
  Widget build(BuildContext context) {
    // Membungkus dengan WindowResizerShortcut
    return WindowResizerShortcut(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Kirim Pesan'),
          backgroundColor: const Color(0xFF0B4D8A),
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.aspect_ratio),
              onPressed: () => WindowResizerExtension.showResizerPanel(context),
              tooltip: 'Ubah Ukuran Window (F2)',
            ),
            IconButton(
              icon: const Icon(Icons.inbox),
              onPressed: () {
                Navigator.pushNamed(context, '/view_messages');
              },
              tooltip: 'Lihat Pesan Saya',
            ),
            IconButton(
              icon: const Icon(Icons.history),
              onPressed: () {
                Navigator.pushNamed(context, '/view_messages');
              },
              tooltip: 'Riwayat Pesan',
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
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User Info Card
                FutureBuilder<Map<String, String>>(
                  future: _getUserData(),
                  builder: (context, snapshot) {
                    final userName = snapshot.data?['name'] ?? 'User';
                    final userType = snapshot.data?['type'] ?? '';
                    final userEmail = snapshot.data?['email'] ?? '';
                    final userPhone = snapshot.data?['phone'] ?? '';
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 30,
                                  backgroundColor: Colors.blue.shade100,
                                  child: Text(
                                    Helpers.getInitials(userName),
                                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        userName,
                                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        _getDisplayUserType(userType),
                                        style: TextStyle(color: Colors.grey[600]),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(Icons.notifications_active, size: 16, color: Colors.blue),
                                      SizedBox(width: 8),
                                      Text('Status Notifikasi:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(colors: [Color(0xFF667eea), Color(0xFF764ba2)]),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.email, size: 12, color: Colors.white),
                                            const SizedBox(width: 4),
                                            Text(
                                              userEmail.isNotEmpty ? 'MailerSend: Aktif' : 'Email tidak tersedia',
                                              style: const TextStyle(fontSize: 10, color: Colors.white),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(colors: [Color(0xFF25d366), Color(0xFF128C7E)]),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.phone_android, size: 12, color: Colors.white),
                                            const SizedBox(width: 4),
                                            Text(
                                              userPhone.isNotEmpty ? 'Fonnte: Aktif' : 'WA tidak tersedia',
                                              style: const TextStyle(fontSize: 10, color: Colors.white),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Notifikasi akan dikirim ke email/WhatsApp Anda jika data tersedia.',
                                    style: TextStyle(fontSize: 10, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                
                const Text('Jenis Pesan', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _isLoadingTypes
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage != null
                        ? Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                          )
                        : DropdownButtonFormField<String>(
                            value: _selectedMessageType,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            items: _messageTypes.map((type) {
                              return DropdownMenuItem(
                                value: type['id'].toString(),
                                child: Text(type['jenis_pesan']),
                              );
                            }).toList(),
                            onChanged: (value) => setState(() => _selectedMessageType = value!),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Pilih jenis pesan';
                              }
                              return null;
                            },
                          ),
                const SizedBox(height: 16),
                
                const Text('Isi Pesan', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _messageController,
                  maxLines: 8,
                  decoration: InputDecoration(
                    hintText: 'Tulis pesan Anda di sini...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    alignLabelWithHint: true,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Pesan tidak boleh kosong';
                    }
                    if (value.length < 10) {
                      return 'Pesan minimal 10 karakter';
                    }
                    if (value.length > 5000) {
                      return 'Pesan maksimal 5000 karakter';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                const Text('Minimal 10 karakter', style: TextStyle(fontSize: 10, color: Colors.grey)),
                const SizedBox(height: 16),
                
                const Text('Lampiran Gambar (Opsional)', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                
                InkWell(
                  onTap: _pickAttachments,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.blue.shade300, width: 2),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.blue.shade50,
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.cloud_upload, size: 48, color: Colors.blue.shade400),
                        const SizedBox(height: 8),
                        const Text(
                          'Klik untuk pilih gambar',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Format: JPG, JPEG, PNG, GIF, WEBP, HEIC, BMP (Max 5MB per file)',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ),
                
                if (_attachments.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text('Preview Gambar:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 1,
                    ),
                    itemCount: _attachments.length,
                    itemBuilder: (context, index) {
                      return Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              _attachments[index],
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.broken_image, size: 32),
                                );
                              },
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => _removeAttachment(index),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close, size: 14, color: Colors.white),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 4,
                            left: 4,
                            right: 4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _attachmentNames[index],
                                style: const TextStyle(fontSize: 9, color: Colors.white),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
                
                const SizedBox(height: 24),
                
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _sendMessage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0B4D8A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('KIRIM PESAN', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                Card(
                  color: Colors.grey.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('ℹ️ Informasi:', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        const Text('• Pesan akan diproses dalam 1x24 jam', style: TextStyle(fontSize: 11)),
                        const Text('• Nomor referensi akan diberikan setelah pesan terkirim', style: TextStyle(fontSize: 11)),
                        const Text('• Simpan nomor referensi untuk mengecek status pesan', style: TextStyle(fontSize: 11)),
                        const Text('• Notifikasi akan dikirim ke email/WhatsApp Anda jika tersedia', style: TextStyle(fontSize: 11)),
                        TextButton(
                          onPressed: () => Navigator.pushNamed(context, '/view_messages'),
                          style: TextButton.styleFrom(padding: EdgeInsets.zero),
                          child: const Text('📋 Lihat Riwayat Pesan Saya', style: TextStyle(fontSize: 11)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getDisplayUserType(String userType) {
    switch (userType) {
      case 'Guru': return 'Guru';
      case 'Siswa': return 'Siswa';
      case 'Orang_Tua': return 'Orang Tua/Wali';
      default: return 'Pengguna';
    }
  }
}