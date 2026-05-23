// lib/screen/landing_page.dart - PERBAIKAN LENGKAP

import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/api_service.dart';
import '../utils/helpers.dart';
import '../../widgets/window_resizer_shortcut.dart';
import '../../utils/environment.dart';
//import 'package:responsive_message_app_flutter/main.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  bool _isDarkMode = false;
  bool _isLoading = false;
  String? _messageResult;
  String? _trackingResult;
  String _trackingReference = '';
  
  // Data tracking
  Map<String, dynamic>? _trackingData;
  
  // Form data
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  String _identitas = '';
  int _jenisPesanId = 0;
  String _prioritas = 'Medium';
  final _isiPesanController = TextEditingController();
  bool _captcha = false;
  
  // Upload files
  List<XFile> _selectedFiles = [];
  List<Map<String, dynamic>> _uploadedFiles = [];
  
  // Dropdown options
  List<Map<String, dynamic>> _messageTypes = [];
  bool _isLoadingTypes = true;
  String? _messageTypesError;
  
  // Service status
  Map<String, dynamic> _serviceStatus = {
    'mailersend_active': true,
    'fonnte_active': true,
    'mailersend_from': 'noreply@test-r9084zv6rpjgw63d.mlsender.net'
  };
  
  final List<String> _identitasOptions = [
    'siswa', 'guru', 'staff_tu', 'alumni', 'orang_tua', 'masyarakat', 'instansi', 'kemitraan'
  ];
  
  final Map<String, String> _identitasLabels = {
    'siswa': 'Siswa',
    'guru': 'Guru',
    'staff_tu': 'Staff Tata Usaha',
    'alumni': 'Alumni',
    'orang_tua': 'Orang Tua/Wali Siswa',
    'masyarakat': 'Masyarakat',
    'instansi': 'Instansi/Institusi',
    'kemitraan': 'Kemitraan',
  };
  
  final Map<String, String> _prioritasLabels = {
    'Low': '🔵 Rendah',
    'Medium': '🟡 Sedang',
    'High': '🔴 Tinggi',
  };

  @override
  void initState() {
    super.initState();
    _loadMessageTypes();
    _loadServiceStatus();
  }
  
  @override
  void dispose() {
    _namaController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _isiPesanController.dispose();
    super.dispose();
  }
  
  // ============================================================
  // LOAD FALLBACK MESSAGE TYPES (jika API gagal)
  // ============================================================
  Future<void> _loadFallbackMessageTypes() async {
    print('📋 Loading fallback message types');
    
    final fallbackTypes = [
      {'id': 1, 'jenis_pesan': 'Informasi'},
      {'id': 2, 'jenis_pesan': 'Pengaduan'},
      {'id': 3, 'jenis_pesan': 'Konsultasi'},
      {'id': 4, 'jenis_pesan': 'Saran'},
      {'id': 5, 'jenis_pesan': 'Kritik'},
      {'id': 6, 'jenis_pesan': 'Lainnya'},
    ];
    
    setState(() {
      _messageTypes = fallbackTypes;
      _isLoadingTypes = false;
      if (_messageTypes.isNotEmpty && _jenisPesanId == 0) {
        _jenisPesanId = _messageTypes[0]['id'] as int;
      }
    });
    
    print('✅ Loaded ${_messageTypes.length} fallback message types');
  }
  
  // ============================================================
  // LOAD MESSAGE TYPES - DENGAN TIMEOUT DAN RETRY MECHANISM
  // ============================================================
  Future<void> _loadMessageTypes({int retryCount = 0}) async {
    setState(() {
      _isLoadingTypes = true;
      _messageTypesError = null;
    });
    
    try {
      print('📡 Loading message types (attempt ${retryCount + 1})...');
      
      final response = await ApiService.getPublicMessageTypes().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException('Request timeout after 15 seconds');
        },
      );
      
      print('📡 Response from API: ${response['success']}');
      
      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];
        final types = data['message_types'] as List?;
        
        if (types != null && types.isNotEmpty) {
          setState(() {
            _messageTypes = List<Map<String, dynamic>>.from(types);
            _isLoadingTypes = false;
          });
          print('✅ Loaded ${_messageTypes.length} message types successfully');
          
          if (_messageTypes.isNotEmpty && _jenisPesanId == 0) {
            setState(() {
              _jenisPesanId = _messageTypes[0]['id'] as int;
            });
          }
        } else {
          setState(() {
            _messageTypes = [];
            _isLoadingTypes = false;
            _messageTypesError = 'Tidak ada data jenis pesan';
          });
          await _loadFallbackMessageTypes();
        }
      } else {
        setState(() {
          _messageTypes = [];
          _isLoadingTypes = false;
          _messageTypesError = response['message'] ?? 'Gagal memuat jenis pesan';
        });
        
        if (retryCount < 3) {
          print('🔄 Retrying... (${retryCount + 1}/3)');
          await Future.delayed(const Duration(seconds: 2));
          await _loadMessageTypes(retryCount: retryCount + 1);
        } else {
          await _loadFallbackMessageTypes();
        }
      }
    } catch (e) {
      print('❌ Error loading message types: $e');
      
      if (retryCount < 3) {
        print('🔄 Retrying... (${retryCount + 1}/3)');
        await Future.delayed(const Duration(seconds: 2));
        await _loadMessageTypes(retryCount: retryCount + 1);
      } else {
        setState(() {
          _messageTypes = [];
          _isLoadingTypes = false;
          _messageTypesError = 'Error: ${e.toString()}. Silakan periksa koneksi internet Anda.';
        });
        await _loadFallbackMessageTypes();
      }
    }
  }
  
  Future<void> _loadServiceStatus() async {
    try {
      final response = await ApiService.getGeneralSettings();
      if (response['success'] == true) {
        setState(() {
          _serviceStatus['mailersend_active'] = response['data']['mailersend_active'] ?? true;
          _serviceStatus['fonnte_active'] = response['data']['fonnte_active'] ?? true;
          _serviceStatus['mailersend_from'] = response['data']['mailersend_from'] ?? 'noreply@domain.com';
        });
      }
    } catch (e) {
      // Use defaults
    }
  }
  
  Future<void> _selectFiles() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> files = await picker.pickMultiImage();
    
    if (files.isNotEmpty) {
      if (files.length > 5) {
        Helpers.showToast(context, 'Maksimal 5 file', isError: true);
        return;
      }
      
      setState(() {
        _selectedFiles = files;
      });
      
      _uploadedFiles.clear();
      for (var file in files) {
        final size = await file.length();
        if (size > 5 * 1024 * 1024) {
          Helpers.showToast(context, 'File ${file.name} melebihi 5MB', isError: true);
          setState(() {
            _selectedFiles.remove(file);
          });
          continue;
        }
        _uploadedFiles.add({
          'name': file.name,
          'size': size,
          'path': file.path,
        });
      }
    }
  }
  
  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
      _uploadedFiles.removeAt(index);
    });
  }
  
  void _resetForm() {
    _namaController.clear();
    _emailController.clear();
    _phoneController.clear();
    _identitas = '';
    _jenisPesanId = 0;
    _prioritas = 'Medium';
    _isiPesanController.clear();
    _captcha = false;
    _selectedFiles.clear();
    _uploadedFiles.clear();
    _trackingReference = '';
    _trackingData = null;
    _trackingResult = null;
    setState(() {});
  }
  
  Future<void> _submitMessage() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_identitas.isEmpty) {
      Helpers.showToast(context, 'Pilih identitas', isError: true);
      return;
    }
    
    if (_jenisPesanId == 0) {
      Helpers.showToast(context, 'Pilih jenis pesan', isError: true);
      return;
    }
    
    if (!_captcha) {
      Helpers.showToast(context, 'Centang "Saya bukan robot"', isError: true);
      return;
    }
    
    setState(() {
      _isLoading = true;
      _messageResult = null;
    });
    
    try {
      final response = await ApiService.sendExternalMessage(
        nama: _namaController.text,
        email: _emailController.text.isNotEmpty ? _emailController.text : null,
        phone: _phoneController.text.isNotEmpty ? _phoneController.text : null,
        identitas: _identitas,
        jenisPesanId: _jenisPesanId,
        prioritas: _prioritas,
        isiPesan: _isiPesanController.text,
        files: _selectedFiles,
      );
      
      setState(() {
        _isLoading = false;
      });
      
      if (response['success'] == true) {
        final data = response['data'];
        _messageResult = '''
          ✓ PESAN BERHASIL DIKIRIM!
          
          Nomor Referensi: ${data['reference']}
          Jenis Pesan: ${data['jenis_pesan']}
          ${_uploadedFiles.isNotEmpty ? '\n📎 Lampiran: ${_uploadedFiles.length} file berhasil diupload' : ''}
          
          External Sender ID: ${data['external_sender_id']}
          User ID: ${data['pengirim_id'] ?? 'Tidak dibuat'}
        ''';
        _resetForm();
      } else {
        Helpers.showToast(context, response['message'] ?? 'Gagal mengirim pesan', isError: true);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      Helpers.showToast(context, 'Error: ${e.toString()}', isError: true);
    }
  }
  
  // ============================================================
  // TRACK MESSAGE - DENGAN GLOBAL SCAFFOLD MESSENGER KEY
  // ============================================================
  Future<void> _trackMessage() async {
  if (_trackingReference.isEmpty) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Masukkan nomor referensi'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    return;
  }
  
  setState(() {
    _isLoading = true;
    _trackingResult = null;
    _trackingData = null;
  });
  
  try {
    print('🔍 Tracking message: ${_trackingReference}');
    
    final response = await ApiService.trackMessage(_trackingReference).timeout(
      const Duration(seconds: 20),
      onTimeout: () {
        throw TimeoutException('Tracking timeout after 20 seconds');
      },
    );
    
    if (!mounted) return;
    
    setState(() {
      _isLoading = false;
    });
    
    print('📡 Tracking response success: ${response['success']}');
    
    if (response['success'] == true && response['data'] != null) {
      setState(() {
        _trackingData = response['data'];
        _trackingResult = 'success';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pesan ditemukan!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else {
      setState(() {
        _trackingResult = 'error: ${response['message'] ?? 'Pesan tidak ditemukan'}';
        _trackingData = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Pesan tidak ditemukan'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  } catch (e) {
    if (!mounted) return;
    
    setState(() {
      _isLoading = false;
    });
    print('❌ Track error: $e');
    
    String errorMessage = e.toString();
    if (e is TimeoutException) {
      errorMessage = 'Koneksi timeout. Silakan coba lagi.';
    } else if (e.toString().contains('SocketException')) {
      errorMessage = 'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.';
    }
    
    setState(() {
      _trackingResult = 'error: $errorMessage';
      _trackingData = null;
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
  
  // Widget untuk menampilkan hasil tracking
  Widget _buildTrackingResultWidget() {
    if (_trackingData == null) {
      if (_trackingResult != null && _trackingResult!.startsWith('error')) {
        return Container(
          margin: const EdgeInsets.only(top: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red.shade700),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _trackingResult!.replaceFirst('error: ', ''),
                  style: TextStyle(color: Colors.red.shade700),
                ),
              ),
            ],
          ),
        );
      }
      return const SizedBox.shrink();
    }
    
    final message = _trackingData!['message'] as Map<String, dynamic>;
    final responses = _trackingData!['responses'] as List? ?? [];
    final reviews = _trackingData!['reviews'] as List? ?? [];
    
    final status = message['status'] ?? 'Pending';
    final statusColor = _getStatusColor(status);
    final statusText = _getStatusText(status);
    final referenceNumber = message['reference_number'] ?? 'Unknown';
    final pengirimNama = message['pengirim_nama'] ?? 'Unknown';
    final jenisPesan = message['jenis_pesan'] ?? 'Pesan';
    final isiPesan = message['isi_pesan'] ?? '';
    final createdAt = _formatDate(message['created_at'] ?? message['tanggal_pesan']);
    final expiredAt = _formatDate(message['expired_at']);
    
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0B4D8A), Color(0xFF1A73E8)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.search, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '#$referenceNumber',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        statusText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(Icons.person, size: 14, color: Colors.white70),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              pengirimNama,
                              style: const TextStyle(color: Colors.white70, fontSize: 11),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(Icons.category, size: 14, color: Colors.white70),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              jenisPesan,
                              style: const TextStyle(color: Colors.white70, fontSize: 11),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 14, color: Colors.white70),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              createdAt,
                              style: const TextStyle(color: Colors.white70, fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(Icons.hourglass_empty, size: 14, color: Colors.white70),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              expiredAt,
                              style: const TextStyle(color: Colors.white70, fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Isi Pesan:',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
                const SizedBox(height: 4),
                Text(
                  isiPesan,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ],
            ),
          ),
          if (responses.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.school, size: 16, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'Respon Guru',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...responses.map((resp) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              resp['responder_name'] ?? 'Guru',
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                            const Spacer(),
                            Text(
                              _formatDate(resp['created_at']),
                              style: const TextStyle(color: Colors.white70, fontSize: 10),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          resp['catatan_respon'] ?? '',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ],
          if (reviews.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.verified_user, size: 16, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'Review Pimpinan',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...reviews.map((review) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              review['user_type'] == 'Kepala_Sekolah' ? 'Kepala Sekolah' : 'Wakil Kepala Sekolah',
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                            const Spacer(),
                            Text(
                              _formatDate(review['created_at']),
                              style: const TextStyle(color: Colors.white70, fontSize: 10),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          review['catatan'] ?? '',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 16,
              children: [
                _buildLegendItem(Colors.green, 'Selesai'),
                _buildLegendItem(Colors.orange, 'Proses'),
                _buildLegendItem(Colors.grey, 'Tunggu'),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 10),
        ),
      ],
    );
  }
  
  Color _getStatusColor(String status) {
    switch (status) {
      case 'Disetujui':
        return Colors.green;
      case 'Ditolak':
        return Colors.red;
      case 'Diproses':
        return Colors.blue;
      default:
        return Colors.orange;
    }
  }
  
  String _getStatusText(String status) {
    switch (status) {
      case 'Disetujui':
        return 'Disetujui';
      case 'Ditolak':
        return 'Ditolak';
      case 'Diproses':
        return 'Diproses';
      default:
        return 'Menunggu';
    }
  }
  
  String _formatDate(dynamic dateString) {
    if (dateString == null) return '-';
    try {
      DateTime date;
      if (dateString is DateTime) {
        date = dateString;
      } else {
        date = DateTime.parse(dateString.toString());
      }
      return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString.toString();
    }
  }
  
  void _toggleDarkMode() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }
  
  String getFullUrl() {
    return Environment.baseUrlRoot;
  }
  
  @override
Widget build(BuildContext context) {
  final fullUrl = getFullUrl();
  
  return WindowResizerShortcut(
    child: Scaffold(  // ✅ LANGSUNG SCAFFOLD, tanpa MaterialApp
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _isDarkMode
                ? [Colors.grey[900]!, Colors.grey[800]!]
                : [const Color(0xFF0B4D8A), const Color(0xFF1A73E8), const Color(0xFF4285F4)],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 20),
                    _buildHeroSection(fullUrl),
                    const SizedBox(height: 20),
                    _buildServiceInfo(),
                    const SizedBox(height: 20),
                    _buildTrackingSection(),
                    const SizedBox(height: 20),
                    if (_trackingData != null) _buildTrackingResultWidget(),
                    if (_trackingData != null) const SizedBox(height: 20),
                    _buildMessageForm(),
                    const SizedBox(height: 20),
                    if (_messageResult != null) _buildResultCard(_messageResult!),
                    const SizedBox(height: 20),
                    _buildFooter(),
                  ],
                ),
              ),
              Positioned(
                top: 8,
                right: 16,
                child: FloatingActionButton.small(
                  onPressed: _toggleDarkMode,
                  backgroundColor: _isDarkMode ? Colors.grey[800] : Colors.white,
                  child: Icon(
                    _isDarkMode ? Icons.light_mode : Icons.dark_mode,
                    color: _isDarkMode ? Colors.white : const Color(0xFF0B4D8A),
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
  
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF0B4D8A), Color(0xFF1A73E8)]),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(Icons.comment, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SMKN 12 Jakarta',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0B4D8A)),
                ),
                Text(
                  'Responsive Message App • ${DateTime.now().year}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Flexible(
            child: Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              children: [
                TextButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/login'),
                  icon: const Icon(Icons.login, size: 18),
                  label: const Text('Masuk'),
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFF0B4D8A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/register'),
                  icon: const Icon(Icons.person_add, size: 18),
                  label: const Text('Daftar'),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildHeroSection(String fullUrl) {
    final baseUrl = Environment.baseUrl;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    
    if (isSmallScreen) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: const Offset(0, 5))],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  margin: const EdgeInsets.only(right: 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      '$baseUrl/assets/images/message-hero.png',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFF0B4D8A), Color(0xFF1A73E8)]),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.message, size: 40, color: Colors.white),
                        );
                      },
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Selamat Datang di RMA',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0B4D8A)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Platform komunikasi terpadu SMKN 12 Jakarta.',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(child: _buildQrCode(fullUrl)),
          ],
        ),
      );
    }
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            margin: const EdgeInsets.only(right: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                '$baseUrl/assets/images/message-hero.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF0B4D8A), Color(0xFF1A73E8)]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.message, size: 40, color: Colors.white),
                  );
                },
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Selamat Datang di RMA',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0B4D8A)),
                ),
                const SizedBox(height: 8),
                Text(
                  'Platform komunikasi terpadu SMKN 12 Jakarta. Kirim pesan, dapatkan respon cepat, dan pantau progress dengan mudah.',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          _buildQrCode(fullUrl),
        ],
      ),
    );
  }
  
  Widget _buildQrCode(String fullUrl) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 15, offset: const Offset(8, 8)),
          BoxShadow(color: Colors.white70, blurRadius: 10, offset: const Offset(-3, -3)),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black38, blurRadius: 8, offset: const Offset(4, 4))],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: QrImageView(
                data: fullUrl,
                version: QrVersions.auto,
                size: 100,
                backgroundColor: Colors.white,
                eyeStyle: const QrEyeStyle(color: Color(0xFF0B4D8A), eyeShape: QrEyeShape.square),
                dataModuleStyle: const QrDataModuleStyle(color: Color(0xFF0B4D8A), dataModuleShape: QrDataModuleShape.square),
                errorStateBuilder: (cxt, err) {
                  return Container(
                    color: Colors.white,
                    child: const Icon(Icons.qr_code, size: 60, color: Color(0xFF0B4D8A)),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Scan untuk akses',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey[700]),
          ),
          const SizedBox(height: 2),
          Text('mobile', style: TextStyle(fontSize: 9, color: Colors.grey[500])),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: const Color(0xFF0B4D8A).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Text(
              fullUrl.replaceAll('http://', '').replaceAll('https://', ''),
              style: const TextStyle(fontSize: 8, color: Color(0xFF0B4D8A)),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildServiceInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
        border: Border(left: BorderSide(color: const Color(0xFF0B4D8A), width: 4)),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 8,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.info, size: 16, color: Color(0xFF0B4D8A)),
              const SizedBox(width: 8),
              Text(
                'Status Layanan:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey[700]),
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              _buildServiceBadge(
                icon: Icons.email,
                label: 'MailerSend',
                active: _serviceStatus['mailersend_active'] == true,
                gradient: const [Color(0xFF667EEA), Color(0xFF764BA2)],
              ),
              _buildServiceBadge(
                icon: Icons.message,
                label: 'Fonnte',
                active: _serviceStatus['fonnte_active'] == true,
                gradient: const [Color(0xFF25D366), Color(0xFF128C7E)],
              ),
              Text(
                'From: ${_serviceStatus['mailersend_from']}',
                style: TextStyle(fontSize: 10, color: Colors.grey[500]),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildServiceBadge({
    required IconData icon,
    required String label,
    required bool active,
    required List<Color> gradient,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(gradient: LinearGradient(colors: gradient), borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: Colors.white),
          const SizedBox(width: 4),
          Text('$label: ${active ? "Aktif" : "Nonaktif"}', style: const TextStyle(fontSize: 9, color: Colors.white)),
        ],
      ),
    );
  }
  
  Widget _buildTrackingSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.search, color: Color(0xFF0B4D8A), size: 20),
              const SizedBox(width: 8),
              const Text('Lacak Status Pesan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0B4D8A))),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final isSmall = constraints.maxWidth < 500;
              
              if (isSmall) {
                return Column(
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Nomor Referensi',
                        hintText: 'EXT20260219-18588',
                        prefixIcon: const Icon(Icons.tag, size: 18),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      onChanged: (value) => _trackingReference = value,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading || !mounted ? null : _trackMessage,
                        icon: _isLoading
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.search, size: 18),
                        label: const Text('Lacak'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                );
              }
              
              return Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        labelText: 'Nomor Referensi',
                        hintText: 'EXT20260219-18588 / MSG-20260219-84BC10',
                        prefixIcon: const Icon(Icons.tag, size: 18),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      onChanged: (value) => _trackingReference = value,
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _trackMessage,
                    icon: _isLoading
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.search, size: 18),
                    label: const Text('Lacak'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 8),
          Text(
            'Masukkan nomor referensi yang diberikan saat mengirim pesan',
            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMessageForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Kirim Pesan Tanpa Login',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0B4D8A)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: _resetForm,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Reset'),
                  style: TextButton.styleFrom(foregroundColor: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            LayoutBuilder(
              builder: (context, constraints) {
                final isSmall = constraints.maxWidth < 500;
                
                if (isSmall) {
                  return Column(
                    children: [
                      TextFormField(
                        controller: _namaController,
                        decoration: const InputDecoration(
                          labelText: 'Nama Lengkap *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (value) => value == null || value.isEmpty ? 'Nama harus diisi' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.email),
                          suffix: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [Color(0xFF667EEA), Color(0xFF764BA2)]),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text('MailerSend', style: TextStyle(fontSize: 9, color: Colors.white)),
                          ),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _phoneController,
                        decoration: InputDecoration(
                          labelText: 'Nomor HP',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.phone),
                          suffix: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [Color(0xFF25D366), Color(0xFF128C7E)]),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text('Fonnte', style: TextStyle(fontSize: 9, color: Colors.white)),
                          ),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _identitas.isEmpty ? null : _identitas,
                        decoration: const InputDecoration(
                          labelText: 'Identitas *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.badge),
                        ),
                        items: [
                          const DropdownMenuItem(value: '', child: Text('-- Pilih Identitas --')),
                          ..._identitasOptions.map((value) => DropdownMenuItem(
                            value: value,
                            child: Text(_identitasLabels[value] ?? value),
                          )),
                        ],
                        onChanged: (value) => setState(() => _identitas = value ?? ''),
                        validator: (value) => value == null || value.isEmpty ? 'Identitas harus dipilih' : null,
                      ),
                      const SizedBox(height: 12),
                      _buildJenisPesanDropdown(),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _prioritas,
                        decoration: const InputDecoration(
                          labelText: 'Prioritas',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.flag),
                        ),
                        items: _prioritasLabels.entries.map((entry) => DropdownMenuItem(
                          value: entry.key,
                          child: Text(entry.value),
                        )).toList(),
                        onChanged: (value) => setState(() => _prioritas = value ?? 'Medium'),
                      ),
                    ],
                  );
                }
                
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _namaController,
                            decoration: const InputDecoration(
                              labelText: 'Nama Lengkap *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.person),
                            ),
                            validator: (value) => value == null || value.isEmpty ? 'Nama harus diisi' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.email),
                              suffix: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(colors: [Color(0xFF667EEA), Color(0xFF764BA2)]),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text('MailerSend', style: TextStyle(fontSize: 9, color: Colors.white)),
                              ),
                            ),
                            keyboardType: TextInputType.emailAddress,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _phoneController,
                            decoration: InputDecoration(
                              labelText: 'Nomor HP',
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.phone),
                              suffix: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(colors: [Color(0xFF25D366), Color(0xFF128C7E)]),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text('Fonnte', style: TextStyle(fontSize: 9, color: Colors.white)),
                              ),
                            ),
                            keyboardType: TextInputType.phone,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _identitas.isEmpty ? null : _identitas,
                            decoration: const InputDecoration(
                              labelText: 'Identitas *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.badge),
                            ),
                            items: [
                              const DropdownMenuItem(value: '', child: Text('-- Pilih Identitas --')),
                              ..._identitasOptions.map((value) => DropdownMenuItem(
                                value: value,
                                child: Text(_identitasLabels[value] ?? value),
                              )),
                            ],
                            onChanged: (value) => setState(() => _identitas = value ?? ''),
                            validator: (value) => value == null || value.isEmpty ? 'Identitas harus dipilih' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildJenisPesanDropdown()),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _prioritas,
                            decoration: const InputDecoration(
                              labelText: 'Prioritas',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.flag),
                            ),
                            items: _prioritasLabels.entries.map((entry) => DropdownMenuItem(
                              value: entry.key,
                              child: Text(entry.value),
                            )).toList(),
                            onChanged: (value) => setState(() => _prioritas = value ?? 'Medium'),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _isiPesanController,
              decoration: const InputDecoration(
                labelText: 'Isi Pesan *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.message),
                alignLabelWithHint: true,
              ),
              maxLines: 5,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Isi pesan harus diisi';
                if (value.length < 10) return 'Isi pesan minimal 10 karakter';
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildUploadArea(),
            const SizedBox(height: 16),
            Row(
              children: [
                Checkbox(
                  value: _captcha,
                  onChanged: (value) => setState(() => _captcha = value ?? false),
                ),
                const Text('Saya bukan robot'),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _submitMessage,
                icon: _isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.send),
                label: Text(_isLoading ? 'Mengirim...' : 'Kirim Pesan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0B4D8A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildJenisPesanDropdown() {
    if (_isLoadingTypes) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(8)),
        child: const Row(
          children: [
            SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            SizedBox(width: 12),
            Text('Memuat jenis pesan...'),
          ],
        ),
      );
    }
    
    if (_messageTypesError != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(border: Border.all(color: Colors.red), borderRadius: BorderRadius.circular(8), color: Colors.red.shade50),
        child: Row(
          children: [
            Icon(Icons.error, size: 18, color: Colors.red),
            const SizedBox(width: 8),
            Expanded(child: Text(_messageTypesError!, style: const TextStyle(fontSize: 12, color: Colors.red))),
            TextButton(onPressed: () => _loadMessageTypes(), child: const Text('Coba Lagi', style: TextStyle(fontSize: 12))),
          ],
        ),
      );
    }
    
    if (_messageTypes.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(border: Border.all(color: Colors.orange), borderRadius: BorderRadius.circular(8), color: Colors.orange.shade50),
        child: Row(
          children: [
            Icon(Icons.warning, size: 18, color: Colors.orange),
            const SizedBox(width: 8),
            const Expanded(child: Text('Tidak ada jenis pesan tersedia')),
            TextButton(onPressed: () => _loadMessageTypes(), child: const Text('Muat Ulang', style: TextStyle(fontSize: 12))),
          ],
        ),
      );
    }
    
    return DropdownButtonFormField<int>(
      value: _jenisPesanId == 0 ? null : _jenisPesanId,
      decoration: const InputDecoration(
        labelText: 'Jenis Pesan *',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.category),
      ),
      items: [
        const DropdownMenuItem(value: 0, child: Text('-- Pilih Jenis Pesan --')),
        ..._messageTypes.map((type) => DropdownMenuItem(
          value: type['id'] as int,
          child: Text(type['jenis_pesan'] as String),
        )),
      ],
      onChanged: (value) {
        setState(() {
          _jenisPesanId = value ?? 0;
          print('📋 Selected jenis pesan ID: $_jenisPesanId');
        });
      },
      validator: (value) {
        if (value == null || value == 0) {
          return 'Jenis pesan harus dipilih';
        }
        return null;
      },
    );
  }
  
  Widget _buildUploadArea() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Lampiran Gambar (Opsional)', style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _selectFiles,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.blue, width: 2, style: BorderStyle.solid),
              borderRadius: BorderRadius.circular(10),
              color: Colors.grey[50],
            ),
            child: Column(
              children: [
                const Icon(Icons.cloud_upload, size: 40, color: Colors.blue),
                const Text('Klik untuk pilih gambar atau drag & drop'),
                Text(
                  'Format: JPG, JPEG, PNG, GIF, WEBP (Max 5MB per file)',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _selectFiles,
                  icon: const Icon(Icons.folder_open, size: 16),
                  label: const Text('Pilih File'),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.blue, side: const BorderSide(color: Colors.blue)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Anda dapat memilih lebih dari satu gambar. Hanya gambar yang akan ditampilkan di preview.',
          style: TextStyle(fontSize: 11, color: Colors.grey[500]),
        ),
        if (_uploadedFiles.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _uploadedFiles.asMap().entries.map((entry) {
                final index = entry.key;
                final file = entry.value;
                return Container(
                  width: 100,
                  decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(8)),
                  child: Stack(
                    children: [
                      Column(
                        children: [
                          Container(height: 80, color: Colors.grey[100], child: const Center(child: Icon(Icons.image, size: 40, color: Colors.grey))),
                          Padding(
                            padding: const EdgeInsets.all(4),
                            child: Text(
                              file['name'].length > 12 ? '${file['name'].substring(0, 10)}...' : file['name'],
                              style: const TextStyle(fontSize: 9),
                            ),
                          ),
                          Text('${(file['size'] / 1024).toStringAsFixed(1)} KB', style: TextStyle(fontSize: 8, color: Colors.grey[500])),
                        ],
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _removeFile(index),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                            child: const Icon(Icons.close, size: 12, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
  
  Widget _buildResultCard(String message) {
    return Container(
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
              Icon(Icons.check_circle, color: Colors.green.shade700),
              const SizedBox(width: 8),
              Text('Informasi Pesan', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade800)),
            ],
          ),
          const SizedBox(height: 8),
          Text(message, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
  
  Widget _buildFooter() {
    return Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 16,
        children: [
          Text('© ${DateTime.now().year} SMKN 12 Jakarta', style: TextStyle(fontSize: 12, color: Colors.white70)),
          Text('Versi 1.0.0', style: TextStyle(fontSize: 12, color: Colors.white54)),
        ],
      ),
    );
  }
}