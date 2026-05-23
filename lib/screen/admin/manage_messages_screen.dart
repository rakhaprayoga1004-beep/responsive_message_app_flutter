// lib/screen/admin/manage_messages_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../services/auth_service.dart';
import '../../utils/helpers.dart';
import '../../utils/date_formatter.dart';
import '../../utils/constants.dart';
import '../../widgets/message_detail_dialog.dart';
import '../../widgets/window_resizer_shortcut.dart';

class ManageMessagesScreen extends StatefulWidget {
  const ManageMessagesScreen({super.key});

  @override
  State<ManageMessagesScreen> createState() => _ManageMessagesScreenState();
}

class _ManageMessagesScreenState extends State<ManageMessagesScreen> {
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  String _selectedStatus = 'all';
  String _selectedType = 'all';
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalMessages = 0;
  final int _itemsPerPage = 10;
  
  final ScrollController _horizontalScrollController = ScrollController();

  final List<String> _statusOptions = const [
    'all', 'Pending', 'Dibaca', 'Diproses', 'Disetujui', 'Ditolak', 'Selesai'
  ];
  
  final List<String> _typeOptions = const ['all', 'Internal', 'External'];

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final token = await AuthService.getToken();
      if (token == null) {
        setState(() {
          _error = 'Token tidak ditemukan';
          _isLoading = false;
        });
        return;
      }
      
      final url = Uri.parse('${Constants.baseUrl}/modules/admin/api/messages.php?page=$_currentPage&search=${Uri.encodeComponent(_searchQuery)}&status=$_selectedStatus&type=$_selectedType&per_page=$_itemsPerPage');
      
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            _messages = List<Map<String, dynamic>>.from(data['messages'] ?? []);
            _totalMessages = data['total'] ?? 0;
            _totalPages = data['total_pages'] ?? 1;
            _isLoading = false;
          });
          return;
        }
      }
      setState(() {
        _error = 'Gagal memuat data';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    setState(() {
      _currentPage = 1;
    });
    _loadMessages();
  }

  void _goToPage(int page) {
    if (page >= 1 && page <= _totalPages) {
      setState(() => _currentPage = page);
      _loadMessages();
    }
  }

  Future<void> _deleteMessage(int messageId, String messageTitle) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text('Hapus pesan "$messageTitle" ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Hapus', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed != true) return;
    
    setState(() => _isLoading = true);
    try {
      final token = await AuthService.getToken();
      final url = Uri.parse('${Constants.baseUrl}/api/messages/delete.php?id=$messageId');
      final response = await http.delete(url, headers: {'Authorization': 'Bearer $token'});
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          Helpers.showToast(context, 'Pesan dihapus');
          _loadMessages();
          return;
        }
      }
      Helpers.showToast(context, 'Gagal hapus', isError: true);
      setState(() => _isLoading = false);
    } catch (e) {
      Helpers.showToast(context, 'Error: $e', isError: true);
      setState(() => _isLoading = false);
    }
  }

  void _showDetail(int messageId) {
    showDialog(
      context: context,
      builder: (context) => MessageDetailDialog(messageId: messageId, initialData: null),
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
    switch (priority) {
      case 'Low': return Colors.green;
      case 'Medium': return Colors.orange;
      case 'High': return Colors.deepOrange;
      case 'Urgent': return Colors.red;
      default: return Colors.grey;
    }
  }

  String _getPriorityText(String priority) {
    switch (priority) {
      case 'Low': return 'Rendah';
      case 'Medium': return 'Sedang';
      case 'High': return 'Tinggi';
      case 'Urgent': return 'Urgent';
      default: return priority;
    }
  }

  String _formatDateTimeShort(DateTime date) {
    return '${date.day}/${date.month} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return WindowResizerShortcut(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Manajemen Pesan'),
          backgroundColor: const Color(0xFF0B4D8A),
          actions: [
            IconButton(
              icon: const Icon(Icons.aspect_ratio),
              onPressed: () => WindowResizerExtension.showResizerPanel(context),
              tooltip: 'Resize (F2)',
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadMessages,
              tooltip: 'Refresh',
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.error, size: 60, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(_error!),
                    ElevatedButton(onPressed: _loadMessages, child: const Text('Coba Lagi')),
                  ]))
                : Column(children: [
                    _buildFilterBar(),
                    Expanded(child: _buildMessagesTable()),
                    _buildPagination(),
                  ]),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.grey[50],
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isSmall = constraints.maxWidth < 700;
          
          if (isSmall) {
            return Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Cari pesan...',
                          prefixIcon: const Icon(Icons.search, size: 18),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                          filled: true,
                          fillColor: Colors.white,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        onChanged: (v) => _searchQuery = v,
                        onSubmitted: (_) => _applyFilters(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedStatus,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          filled: true,
                          fillColor: Colors.white,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: _statusOptions.map((s) => DropdownMenuItem<String>(
                          value: s, 
                          child: Text(s == 'all' ? 'Semua' : s, style: const TextStyle(fontSize: 12))
                        )).toList(),
                        onChanged: (v) { if (v != null) { setState(() => _selectedStatus = v); _applyFilters(); } },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedType,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          filled: true,
                          fillColor: Colors.white,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: _typeOptions.map((t) => DropdownMenuItem<String>(
                          value: t, 
                          child: Text(t == 'all' ? 'Semua' : t, style: const TextStyle(fontSize: 12))
                        )).toList(),
                        onChanged: (v) { if (v != null) { setState(() => _selectedType = v); _applyFilters(); } },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _applyFilters,
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0B4D8A), padding: const EdgeInsets.symmetric(vertical: 10)),
                        child: const Text('Filter', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() { _searchQuery = ''; _selectedStatus = 'all'; _selectedType = 'all'; _currentPage = 1; });
                          _applyFilters();
                        },
                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 10)),
                        child: const Text('Reset', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                  ],
                ),
              ],
            );
          }
          
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              SizedBox(
                width: 200,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Cari pesan...',
                    prefixIcon: const Icon(Icons.search, size: 18),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    filled: true,
                    fillColor: Colors.white,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  onChanged: (v) => _searchQuery = v,
                  onSubmitted: (_) => _applyFilters(),
                ),
              ),
              SizedBox(
                width: 130,
                child: DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    filled: true,
                    fillColor: Colors.white,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: _statusOptions.map((s) => DropdownMenuItem<String>(
                    value: s, 
                    child: Text(s == 'all' ? 'Semua' : s, style: const TextStyle(fontSize: 12))
                  )).toList(),
                  onChanged: (v) { if (v != null) { setState(() => _selectedStatus = v); _applyFilters(); } },
                ),
              ),
              SizedBox(
                width: 120,
                child: DropdownButtonFormField<String>(
                  value: _selectedType,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    filled: true,
                    fillColor: Colors.white,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: _typeOptions.map((t) => DropdownMenuItem<String>(
                    value: t, 
                    child: Text(t == 'all' ? 'Semua' : t, style: const TextStyle(fontSize: 12))
                  )).toList(),
                  onChanged: (v) { if (v != null) { setState(() => _selectedType = v); _applyFilters(); } },
                ),
              ),
              ElevatedButton(
                onPressed: _applyFilters,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0B4D8A), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10)),
                child: const Text('Filter', style: TextStyle(fontSize: 12)),
              ),
              OutlinedButton(
                onPressed: () {
                  setState(() { _searchQuery = ''; _selectedStatus = 'all'; _selectedType = 'all'; _currentPage = 1; });
                  _applyFilters();
                },
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                child: const Text('Reset', style: TextStyle(fontSize: 12)),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMessagesTable() {
    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('Tidak ada pesan', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
            const SizedBox(height: 8),
            Text('Gunakan filter untuk mencari pesan tertentu', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          ],
        ),
      );
    }
    
    return Scrollbar(
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
          columnSpacing: 16,
          headingRowColor: MaterialStateProperty.all(Colors.grey[100]),
          columns: const [
            DataColumn(label: SizedBox(width: 50, child: Text('#', style: TextStyle(fontWeight: FontWeight.bold)))),
            DataColumn(label: SizedBox(width: 140, child: Text('Referensi', style: TextStyle(fontWeight: FontWeight.bold)))),
            DataColumn(label: SizedBox(width: 130, child: Text('Pengirim', style: TextStyle(fontWeight: FontWeight.bold)))),
            DataColumn(label: SizedBox(width: 120, child: Text('Jenis Pesan', style: TextStyle(fontWeight: FontWeight.bold)))),
            DataColumn(label: SizedBox(width: 200, child: Text('Isi Pesan', style: TextStyle(fontWeight: FontWeight.bold)))),
            DataColumn(label: SizedBox(width: 80, child: Text('Lampiran', style: TextStyle(fontWeight: FontWeight.bold)))),
            DataColumn(label: SizedBox(width: 100, child: Text('Prioritas', style: TextStyle(fontWeight: FontWeight.bold)))),
            DataColumn(label: SizedBox(width: 100, child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold)))),
            DataColumn(label: SizedBox(width: 120, child: Text('Waktu', style: TextStyle(fontWeight: FontWeight.bold)))),
            DataColumn(label: SizedBox(width: 150, child: Text('Respons/Review', style: TextStyle(fontWeight: FontWeight.bold)))),
            DataColumn(label: SizedBox(width: 80, child: Text('Aksi', style: TextStyle(fontWeight: FontWeight.bold)))),
          ],
          rows: _messages.asMap().entries.map((entry) {
            final idx = (_currentPage - 1) * _itemsPerPage + entry.key + 1;
            final msg = entry.value;
            final status = msg['status'] ?? 'Pending';
            final priority = msg['priority'] ?? 'Medium';
            final hasAttachment = (msg['attachment_count'] ?? 0) > 0;
            final hasResponse = (msg['response_count'] ?? 0) > 0;
            final hasReview = (msg['review_id'] != null);
            final responseStatus = msg['response_status'];
            final reviewCatatan = msg['review_catatan'];
            final createdAt = DateTime.tryParse(msg['created_at'] ?? '');
            
            return DataRow(cells: [
              // Nomor
              DataCell(Text('$idx', style: const TextStyle(fontSize: 12))),
              
              // Referensi
              DataCell(Text(msg['reference_number'] ?? '-', style: const TextStyle(fontSize: 12))),
              
              // Pengirim
              DataCell(Text(msg['pengirim_nama'] ?? '-', style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)),
              
              // Jenis Pesan
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    msg['jenis_pesan'] ?? '-',
                    style: const TextStyle(fontSize: 11, color: Colors.blue),
                  ),
                ),
              ),
              
              // Isi Pesan
              DataCell(
                SizedBox(
                  width: 200,
                  child: Text(
                    msg['isi_pesan'] ?? '-',
                    style: const TextStyle(fontSize: 11),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              
              // Lampiran
              DataCell(
                hasAttachment
                    ? Row(
                        children: [
                          Icon(Icons.attach_file, size: 14, color: Colors.purple),
                          const SizedBox(width: 4),
                          Text(
                            '${msg['attachment_count']}',
                            style: const TextStyle(fontSize: 11, color: Colors.purple, fontWeight: FontWeight.bold),
                          ),
                        ],
                      )
                    : const Text('-', style: TextStyle(fontSize: 11)),
              ),
              
              // Prioritas
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getPriorityColor(priority).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _getPriorityText(priority),
                    style: TextStyle(
                      fontSize: 10,
                      color: _getPriorityColor(priority),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              
              // Status
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 10,
                      color: _getStatusColor(status),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              
              // Waktu
              DataCell(Text(_formatDateTimeShort(createdAt ?? DateTime.now()), style: const TextStyle(fontSize: 11))),
              
              // Respons/Review
              DataCell(
                _buildResponseReviewStatus(hasResponse, hasReview, responseStatus, reviewCatatan),
              ),
              
              // Aksi
              DataCell(
                IconButton(
                  icon: const Icon(Icons.visibility, size: 20, color: Colors.blue),
                  onPressed: () => _showDetail(msg['id']),
                  tooltip: 'Lihat Detail',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildResponseReviewStatus(bool hasResponse, bool hasReview, String? responseStatus, String? reviewCatatan) {
    if (hasResponse && hasReview) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.reply, size: 12, color: Colors.green.shade700),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Respons: ${responseStatus ?? "Ada"}',
                    style: TextStyle(fontSize: 10, color: Colors.green.shade700, fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.verified, size: 12, color: Colors.purple.shade700),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Review: ${reviewCatatan != null ? (reviewCatatan.length > 30 ? '${reviewCatatan.substring(0, 30)}...' : reviewCatatan) : "Ada"}',
                    style: TextStyle(fontSize: 10, color: Colors.purple.shade700, fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    } else if (hasResponse && !hasReview) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.reply, size: 12, color: Colors.blue.shade700),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                'Sudah Direspons',
                style: TextStyle(fontSize: 10, color: Colors.blue.shade700, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      );
    } else if (hasReview && !hasResponse) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.purple.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.purple.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.verified, size: 12, color: Colors.purple.shade700),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                'Direview oleh Pimpinan',
                style: TextStyle(fontSize: 10, color: Colors.purple.shade700, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.pending, size: 12, color: Colors.grey.shade600),
            const SizedBox(width: 4),
            const Text(
              'Menunggu Respons',
              style: TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildPagination() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, -2))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Tombol First Page
          IconButton(
            icon: const Icon(Icons.first_page, size: 20),
            onPressed: _totalPages > 0 && _currentPage > 1 ? () => _goToPage(1) : null,
            tooltip: 'Halaman Pertama',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          // Tombol Previous
          IconButton(
            icon: const Icon(Icons.chevron_left, size: 24),
            onPressed: _totalPages > 0 && _currentPage > 1 ? () => _goToPage(_currentPage - 1) : null,
            tooltip: 'Halaman Sebelumnya',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          // Indikator Halaman
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF0B4D8A).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _totalPages > 0 ? '$_currentPage / $_totalPages' : '0 / 0',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0B4D8A),
              ),
            ),
          ),
          // Tombol Next
          IconButton(
            icon: const Icon(Icons.chevron_right, size: 24),
            onPressed: _totalPages > 0 && _currentPage < _totalPages ? () => _goToPage(_currentPage + 1) : null,
            tooltip: 'Halaman Selanjutnya',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          // Tombol Last Page
          IconButton(
            icon: const Icon(Icons.last_page, size: 20),
            onPressed: _totalPages > 0 && _currentPage < _totalPages ? () => _goToPage(_totalPages) : null,
            tooltip: 'Halaman Terakhir',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          // Info Total Data
          Container(
            margin: const EdgeInsets.only(left: 16),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Total: $_totalMessages pesan',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}