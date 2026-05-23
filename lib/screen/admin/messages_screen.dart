import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../services/api_service.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../main.dart'; // Import untuk WindowResizerShortcut

class AdminMessagesScreen extends StatefulWidget {
  const AdminMessagesScreen({super.key});

  @override
  State<AdminMessagesScreen> createState() => _AdminMessagesScreenState();
}

class _AdminMessagesScreenState extends State<AdminMessagesScreen> {
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _errorMsg;
  List<dynamic> _messages = [];
  int _totalMessages = 0;
  int _currentPage = 1;
  int _totalPages = 1;
  final int _perPage = 20;
  
  // Filters
  String _searchQuery = '';
  String _statusFilter = 'all';
  String _priorityFilter = 'all';
  final TextEditingController _searchController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _loadMessages();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  Future<void> _loadMessages() async {
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
      
      final queryParams = {
        'action': 'list',
        'page': _currentPage.toString(),
        'per_page': _perPage.toString(),
        'search': _searchQuery,
        'status': _statusFilter,
        'priority': _priorityFilter,
      };
      
      final uri = Uri.parse('${Constants.baseUrl}${Constants.apiMessages}')
          .replace(queryParameters: queryParams);
      
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
            _messages = data['messages'] ?? [];
            _totalMessages = data['total'] ?? 0;
            _totalPages = data['total_pages'] ?? 1;
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMsg = data['message'] ?? 'Gagal memuat data pesan';
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
      print('Error loading messages: $e');
      setState(() {
        _errorMsg = 'Error: $e';
        _isLoading = false;
      });
    }
  }
  
  Future<void> _refreshData() async {
    setState(() => _isRefreshing = true);
    await _loadMessages();
    setState(() => _isRefreshing = false);
  }
  
  void _changePage(int page) {
    if (page >= 1 && page <= _totalPages && page != _currentPage) {
      setState(() => _currentPage = page);
      _loadMessages();
    }
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
  
  Color _getStatusColor(String status) {
    switch (status) {
      case 'Disetujui': return Colors.green;
      case 'Ditolak': return Colors.red;
      case 'Pending': return Colors.orange;
      case 'Diproses': return Colors.blue;
      default: return Colors.grey;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    // Membungkus dengan WindowResizerShortcut
    return WindowResizerShortcut(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Manajemen Pesan'),
          backgroundColor: const Color(0xFF0B4D8A),
          actions: [
            IconButton(
              icon: const Icon(Icons.aspect_ratio),
              onPressed: () => WindowResizerExtension.showResizerPanel(context),
              tooltip: 'Ubah Ukuran Window (F2)',
            ),
            IconButton(
              icon: _isRefreshing 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.refresh),
              onPressed: _isRefreshing ? null : _refreshData,
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
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(_errorMsg!, textAlign: TextAlign.center),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadMessages,
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _refreshData,
                    child: Column(
                      children: [
                        _buildFilterBar(),
                        Expanded(
                          child: _buildMessagesTable(),
                        ),
                        if (_totalPages > 1) _buildPagination(),
                      ],
                    ),
                  ),
      ),
    );
  }
  
  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari pesan...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    isDense: true,
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                              _loadMessages();
                            },
                          )
                        : null,
                  ),
                  onSubmitted: (value) {
                    setState(() => _searchQuery = value);
                    _loadMessages();
                  },
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 130,
                child: DropdownButtonFormField<String>(
                  value: _statusFilter,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    isDense: true,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('Semua')),
                    DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                    DropdownMenuItem(value: 'Diproses', child: Text('Diproses')),
                    DropdownMenuItem(value: 'Disetujui', child: Text('Disetujui')),
                    DropdownMenuItem(value: 'Ditolak', child: Text('Ditolak')),
                    DropdownMenuItem(value: 'Selesai', child: Text('Selesai')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _statusFilter = value);
                      _loadMessages();
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 130,
                child: DropdownButtonFormField<String>(
                  value: _priorityFilter,
                  decoration: const InputDecoration(
                    labelText: 'Prioritas',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    isDense: true,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('Semua')),
                    DropdownMenuItem(value: 'Low', child: Text('Rendah')),
                    DropdownMenuItem(value: 'Medium', child: Text('Sedang')),
                    DropdownMenuItem(value: 'High', child: Text('Tinggi')),
                    DropdownMenuItem(value: 'Urgent', child: Text('Mendesak')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _priorityFilter = value);
                      _loadMessages();
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () {
                  setState(() => _searchQuery = _searchController.text);
                  _loadMessages();
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0B4D8A)),
                child: const Text('Filter'),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildMessagesTable() {
    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('Tidak ada data pesan', style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];
        final isExternal = msg['is_external'] == 1;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isExternal ? Colors.orange.shade100 : Colors.blue.shade100,
              child: Icon(
                isExternal ? Icons.public : Icons.person,
                color: isExternal ? Colors.orange : Colors.blue,
              ),
            ),
            title: Text(
              msg['isi_pesan']?.length > 50 ? '${msg['isi_pesan'].substring(0, 50)}...' : (msg['isi_pesan'] ?? '-'),
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pengirim: ${msg['pengirim_nama'] ?? '-'}', style: const TextStyle(fontSize: 12)),
                Text('Jenis: ${msg['jenis_pesan'] ?? '-'}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getStatusColor(msg['status']).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(msg['status'] ?? '-', style: TextStyle(fontSize: 10, color: _getStatusColor(msg['status']))),
                    ),
                    const SizedBox(width: 8),
                    Text(msg['created_at']?.split(' ')[0] ?? '-', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),
              ],
            ),
            trailing: msg['priority'] != null && msg['priority'] != 'Normal'
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(msg['priority'], style: const TextStyle(fontSize: 10, color: Colors.red)),
                  )
                : null,
            onTap: () => _showMessageDetail(msg),
          ),
        );
      },
    );
  }
  
  Widget _buildPagination() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _currentPage > 1 ? () => _changePage(_currentPage - 1) : null,
          ),
          Text('Halaman $_currentPage dari $_totalPages', style: const TextStyle(fontSize: 12)),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _currentPage < _totalPages ? () => _changePage(_currentPage + 1) : null,
          ),
        ],
      ),
    );
  }
  
  void _showMessageDetail(Map<String, dynamic> message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Detail Pesan #${message['id']}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow('Referensi', message['reference_number']),
              _buildInfoRow('Tanggal', message['tanggal_pesan']),
              _buildInfoRow('Jenis Pesan', message['jenis_pesan']),
              _buildInfoRow('Pengirim', message['pengirim_nama']),
              _buildInfoRow('Status', message['status']),
              _buildInfoRow('Prioritas', message['priority']),
              _buildInfoRow('Isi Pesan', message['isi_pesan'], isLongText: true),
              if (message['tanggal_respon'] != null)
                _buildInfoRow('Tanggal Respon', message['tanggal_respon']),
              if (message['catatan_respon'] != null)
                _buildInfoRow('Catatan Respon', message['catatan_respon'], isLongText: true),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String? value, {bool isLongText = false}) {
    if (value == null || value.isEmpty) return const SizedBox();
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
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