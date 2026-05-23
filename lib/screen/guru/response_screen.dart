// lib/screen/guru/response_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../services/api_service.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../widgets/window_resizer_shortcut.dart'; // Import window resizer shortcut

class ResponseScreen extends StatefulWidget {
  const ResponseScreen({super.key});

  @override
  State<ResponseScreen> createState() => _ResponseScreenState();
}

class _ResponseScreenState extends State<ResponseScreen> {
  bool _isLoading = true;
  bool _isSending = false;
  String? _errorMsg;
  Map<String, dynamic>? _message;
  int? _messageId;
  bool _isEdit = false;
  
  final TextEditingController _responseController = TextEditingController();
  String _selectedStatus = 'Disetujui';
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      _messageId = args['message_id'];
      _isEdit = args['is_edit'] ?? false;
      _loadMessageDetail();
    }
  }
  
  @override
  void dispose() {
    _responseController.dispose();
    super.dispose();
  }
  
  void showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }
  
  Future<void> _loadMessageDetail() async {
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });
    
    try {
      final token = await ApiService.getToken();
      if (token == null || token.isEmpty) {
        showSnackBar('Token tidak ditemukan. Silakan login kembali.', Colors.red);
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }
      
      final uri = Uri.parse('${Constants.baseUrl}${Constants.apiGuruMessageDetail}')
          .replace(queryParameters: {'message_id': _messageId.toString()});
      
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            _message = data['message'];
            if (_isEdit && _message!['last_response'] != null) {
              _responseController.text = _message!['last_response'];
              _selectedStatus = _message!['response_status'] ?? 'Disetujui';
            }
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMsg = data['message'] ?? 'Gagal memuat detail pesan';
            _isLoading = false;
          });
        }
      } else if (response.statusCode == 401) {
        showSnackBar('Sesi login habis. Silakan login kembali.', Colors.red);
        await ApiService.logout();
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        setState(() {
          _errorMsg = 'Server error: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading message detail: $e');
      setState(() {
        _errorMsg = 'Error: $e';
        _isLoading = false;
      });
    }
  }
  
  Future<void> _sendResponse() async {
    if (_responseController.text.isEmpty) {
      showSnackBar('Catatan respons tidak boleh kosong', Colors.orange);
      return;
    }
    
    setState(() => _isSending = true);
    
    try {
      final token = await ApiService.getToken();
      final response = await http.post(
        Uri.parse('${Constants.baseUrl}${Constants.apiGuruMessageRespond}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'message_id': _messageId,
          'status': _selectedStatus,
          'catatan': _responseController.text,
        }),
      ).timeout(const Duration(seconds: 30));
      
      final data = json.decode(response.body);
      if (data['success'] == true) {
        showSnackBar(_isEdit ? 'Respons berhasil diupdate' : 'Respons berhasil dikirim', Colors.green);
        Navigator.pop(context, true);
      } else {
        showSnackBar(data['message'] ?? 'Gagal mengirim respons', Colors.red);
      }
    } catch (e) {
      showSnackBar('Error: $e', Colors.red);
    } finally {
      setState(() => _isSending = false);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return WindowResizerShortcut(
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEdit ? 'Edit Respons' : 'Beri Respons'),
          backgroundColor: const Color(0xFF0B4D8A),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadMessageDetail,
              tooltip: 'Refresh',
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: SpinKitFadingCircle(color: Color(0xFF0B4D8A), size: 50))
            : _errorMsg != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                        const SizedBox(height: 16),
                        Text(_errorMsg!),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadMessageDetail,
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Informasi Pesan
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Informasi Pesan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                const Divider(),
                                _buildInfoRow('Pengirim', _message?['pengirim_nama_display']),
                                _buildInfoRow('Jenis Pesan', _message?['jenis_pesan']),
                                _buildInfoRow('Status', _message?['status']),
                                _buildInfoRow('Prioritas', _message?['priority']),
                                _buildInfoRow('Isi Pesan', _message?['isi_pesan'], isLongText: true),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Form Respons
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_isEdit ? 'Edit Respons' : 'Buat Respons', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                const Divider(),
                                const SizedBox(height: 8),
                                
                                // Status
                                DropdownButtonFormField<String>(
                                  value: _selectedStatus,
                                  decoration: const InputDecoration(
                                    labelText: 'Status',
                                    border: OutlineInputBorder(),
                                  ),
                                  items: const [
                                    DropdownMenuItem(value: 'Disetujui', child: Text('Disetujui')),
                                    DropdownMenuItem(value: 'Ditolak', child: Text('Ditolak')),
                                  ],
                                  onChanged: (value) {
                                    if (value != null) setState(() => _selectedStatus = value);
                                  },
                                ),
                                const SizedBox(height: 16),
                                
                                // Catatan Respons
                                TextField(
                                  controller: _responseController,
                                  maxLines: 8,
                                  decoration: const InputDecoration(
                                    labelText: 'Catatan Respons',
                                    hintText: 'Tulis catatan respons Anda...',
                                    border: OutlineInputBorder(),
                                    alignLabelWithHint: true,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                
                                // Tombol Kirim
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _isSending ? null : _sendResponse,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                    ),
                                    child: _isSending
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                          )
                                        : Text(_isEdit ? 'Update Respons' : 'Kirim Respons'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String? value, {bool isLongText = false}) {
    if (value == null || value.isEmpty) return const SizedBox();
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: isLongText ? 12 : 13),
            ),
          ),
        ],
      ),
    );
  }
}