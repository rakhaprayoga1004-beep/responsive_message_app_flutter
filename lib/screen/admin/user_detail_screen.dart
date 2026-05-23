// lib/screen/admin/user_detail_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../services/auth_service.dart';
import '../../utils/helpers.dart';
import '../../utils/date_formatter.dart';
import '../../utils/constants.dart';
import '../../widgets/message_detail_dialog.dart';
import '../../widgets/window_resizer_shortcut.dart';

class UserDetailScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const UserDetailScreen({super.key, required this.user});

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  List<Map<String, dynamic>> _userMessages = [];
  bool _isLoadingMessages = true;
  String? _errorMessages;
  String _selectedStatus = 'all';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadUserMessages();
  }

  Future<void> _loadUserMessages() async {
    setState(() {
      _isLoadingMessages = true;
      _errorMessages = null;
    });

    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final userId = widget.user['id'];
      final url = Uri.parse(
        '${Constants.baseUrl}/modules/admin/api/user_messages.php'
        '?user_id=$userId'
        '&status=$_selectedStatus'
        '&search=${Uri.encodeComponent(_searchQuery)}'
      );

      print('📡 Loading user messages from: $url');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      print('📡 Response status: ${response.statusCode}');
      print('📡 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            _userMessages = List<Map<String, dynamic>>.from(data['messages'] ?? []);
            _isLoadingMessages = false;
          });
          print('✅ Loaded ${_userMessages.length} messages for user ${widget.user['id']}');
        } else {
          setState(() {
            _errorMessages = data['message'] ?? 'Gagal memuat pesan user';
            _isLoadingMessages = false;
          });
        }
      } else if (response.statusCode == 404) {
        setState(() {
          _errorMessages = 'Endpoint API tidak ditemukan (404). Pastikan file modules/admin/api/user_messages.php sudah dibuat.';
          _isLoadingMessages = false;
        });
      } else {
        setState(() {
          _errorMessages = 'Server error: ${response.statusCode}';
          _isLoadingMessages = false;
        });
      }
    } catch (e) {
      print('❌ Error loading user messages: $e');
      setState(() {
        _errorMessages = 'Error: $e';
        _isLoadingMessages = false;
      });
    }
  }

  void _showMessageDetailDialog(int messageId) {
    showDialog(
      context: context,
      builder: (context) => MessageDetailDialog(
        messageId: messageId,
        initialData: null,
      ),
    );
  }

  Future<void> _deleteMessage(int messageId, String messageTitle) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text('Apakah Anda yakin ingin menghapus pesan "$messageTitle"? Tindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoadingMessages = true);

    try {
      final token = await AuthService.getToken();
      final url = Uri.parse('${Constants.baseUrl}/api/messages/delete.php?id=$messageId');
      
      final response = await http.delete(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          Helpers.showToast(context, 'Pesan berhasil dihapus');
          _loadUserMessages();
        } else {
          Helpers.showToast(context, data['message'] ?? 'Gagal menghapus pesan', isError: true);
          setState(() => _isLoadingMessages = false);
        }
      } else {
        Helpers.showToast(context, 'Server error: ${response.statusCode}', isError: true);
        setState(() => _isLoadingMessages = false);
      }
    } catch (e) {
      Helpers.showToast(context, 'Error: $e', isError: true);
      setState(() => _isLoadingMessages = false);
    }
  }

  void _applyFilters() {
    _loadUserMessages();
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

  @override
  Widget build(BuildContext context) {
    return WindowResizerShortcut(
      child: Scaffold(
        appBar: AppBar(
          title: Text('Detail User: ${widget.user['nama_lengkap'] ?? widget.user['username']}'),
          backgroundColor: const Color(0xFF0B4D8A),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadUserMessages,
              tooltip: 'Refresh',
            ),
          ],
        ),
        body: Column(
          children: [
            _buildUserInfoCard(),
            const SizedBox(height: 8),
            _buildFilterBar(),
            Expanded(
              child: _isLoadingMessages
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessages != null
                      ? _buildErrorWidget()
                      : _userMessages.isEmpty
                          ? _buildEmptyWidget()
                          : _buildMessagesList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfoCard() {
    return Card(
      margin: const EdgeInsets.all(12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ PERBAIKAN 1: Row untuk info user dengan Expanded
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: _getUserTypeColor(widget.user['user_type']).withOpacity(0.1),
                  child: Text(
                    (widget.user['nama_lengkap']?[0] ?? widget.user['username']?[0] ?? 'U').toUpperCase(),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: _getUserTypeColor(widget.user['user_type']),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.user['nama_lengkap'] ?? widget.user['username'] ?? 'Unknown',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getUserTypeColor(widget.user['user_type']).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getDisplayUserType(widget.user['user_type']),
                          style: TextStyle(
                            fontSize: 12,
                            color: _getUserTypeColor(widget.user['user_type']),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: (widget.user['is_active'] == 1 ? Colors.green : Colors.red).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    widget.user['is_active'] == 1 ? 'Aktif' : 'Nonaktif',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: widget.user['is_active'] == 1 ? Colors.green : Colors.red,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(color: Colors.grey.shade200),
            const SizedBox(height: 12),
            // ✅ PERBAIKAN 2: Wrap untuk info chips (sudah bagus)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.start,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _buildInfoChip(Icons.person_outline, 'Username', widget.user['username'] ?? '-'),
                _buildInfoChip(Icons.email_outlined, 'Email', widget.user['email'] ?? '-'),
                if (widget.user['phone_number'] != null && widget.user['phone_number'].isNotEmpty)
                  _buildInfoChip(Icons.phone_outlined, 'No. HP', widget.user['phone_number']),
                if (widget.user['nis_nip'] != null && widget.user['nis_nip'].isNotEmpty)
                  _buildInfoChip(Icons.numbers, 'NIS/NIP', widget.user['nis_nip']),
                if (widget.user['kelas'] != null && widget.user['kelas'].isNotEmpty)
                  _buildInfoChip(Icons.class_, 'Kelas', widget.user['kelas']),
                if (widget.user['jurusan'] != null && widget.user['jurusan'].isNotEmpty)
                  _buildInfoChip(Icons.school, 'Jurusan', widget.user['jurusan']),
                if (widget.user['mata_pelajaran'] != null && widget.user['mata_pelajaran'].isNotEmpty)
                  _buildInfoChip(Icons.book, 'Mata Pelajaran', widget.user['mata_pelajaran']),
                _buildInfoChip(Icons.calendar_today, 'Bergabung', DateFormatter.formatDateShort(_parseDate(widget.user['created_at']))),
                if (widget.user['last_login'] != null)
                  _buildInfoChip(Icons.history, 'Terakhir Login', DateFormatter.formatDateTime(_parseDate(widget.user['last_login']))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Flexible(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                  TextSpan(
                    text: value,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.black87),
                  ),
                ],
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: Colors.white,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // ✅ Responsive: jika layar kecil, gunakan Column
          if (constraints.maxWidth < 500) {
            return Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Cari pesan...',
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
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                          isDense: true,
                        ),
                        onChanged: (value) {
                          _searchQuery = value;
                        },
                        onSubmitted: (_) => _applyFilters(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButton<String>(
                          value: _selectedStatus,
                          underline: const SizedBox(),
                          isExpanded: true,
                          items: const [
                            DropdownMenuItem(value: 'all', child: Text('Semua Status')),
                            DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                            DropdownMenuItem(value: 'Dibaca', child: Text('Dibaca')),
                            DropdownMenuItem(value: 'Diproses', child: Text('Diproses')),
                            DropdownMenuItem(value: 'Disetujui', child: Text('Disetujui')),
                            DropdownMenuItem(value: 'Ditolak', child: Text('Ditolak')),
                            DropdownMenuItem(value: 'Selesai', child: Text('Selesai')),
                          ],
                          onChanged: (value) {
                            setState(() => _selectedStatus = value!);
                            _applyFilters();
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _applyFilters,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0B4D8A),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      child: const Text('Filter'),
                    ),
                  ],
                ),
              ],
            );
          }
          
          // ✅ Layar besar: gunakan Row
          return Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Cari pesan...',
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
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                    isDense: true,
                  ),
                  onChanged: (value) {
                    _searchQuery = value;
                  },
                  onSubmitted: (_) => _applyFilters(),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButton<String>(
                  value: _selectedStatus,
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('Semua Status')),
                    DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                    DropdownMenuItem(value: 'Dibaca', child: Text('Dibaca')),
                    DropdownMenuItem(value: 'Diproses', child: Text('Diproses')),
                    DropdownMenuItem(value: 'Disetujui', child: Text('Disetujui')),
                    DropdownMenuItem(value: 'Ditolak', child: Text('Ditolak')),
                    DropdownMenuItem(value: 'Selesai', child: Text('Selesai')),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedStatus = value!);
                    _applyFilters();
                  },
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _applyFilters,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0B4D8A),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                ),
                child: const Text('Filter'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMessagesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _userMessages.length,
      itemBuilder: (context, index) {
        final message = _userMessages[index];
        final messageId = message['id'] is int ? message['id'] : int.tryParse(message['id'].toString()) ?? 0;
        
        // ✅ PERBAIKAN 3: Gunakan ListTile dengan proper overflow handling
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            leading: CircleAvatar(
              radius: 20,
              backgroundColor: _getStatusColor(message['status'] ?? 'Pending').withOpacity(0.1),
              child: Icon(
                Icons.message,
                color: _getStatusColor(message['status'] ?? 'Pending'),
                size: 20,
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    message['isi_pesan'] ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(message['status'] ?? 'Pending').withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    message['status'] ?? 'Pending',
                    style: TextStyle(
                      fontSize: 10,
                      color: _getStatusColor(message['status'] ?? 'Pending'),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),
                // Jenis pesan
                Text(
                  message['jenis_pesan'] ?? '-',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // ✅ PERBAIKAN 4: Row untuk tanggal dan priority dengan Expanded
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.access_time, size: 12, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          DateFormatter.formatDateTime(_parseDate(message['created_at'])),
                          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getPriorityColor(message['priority'] ?? 'Medium').withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        message['priority'] ?? 'Medium',
                        style: TextStyle(
                          fontSize: 10,
                          color: _getPriorityColor(message['priority'] ?? 'Medium'),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // Info attachment jika ada
                    if ((message['attachment_count'] ?? 0) > 0)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.attach_file, size: 12, color: Colors.grey[500]),
                          const SizedBox(width: 2),
                          Text(
                            '${message['attachment_count']}',
                            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.visibility, size: 20, color: Colors.blue),
                  onPressed: () => _showMessageDetailDialog(messageId),
                  tooltip: 'Lihat Detail',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                  onPressed: () => _deleteMessage(messageId, (message['isi_pesan']?.toString() ?? 'Pesan').substring(0, (message['isi_pesan']?.toString()?.length ?? 30).clamp(0, 30))),
                  tooltip: 'Hapus Pesan',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ],
            ),
            isThreeLine: true,
            dense: false,
          ),
        );
      },
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              _errorMessages!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadUserMessages,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0B4D8A),
            ),
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
          Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text('Tidak ada pesan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              _searchQuery.isNotEmpty
                  ? 'Tidak ada pesan dengan kata kunci "$_searchQuery"'
                  : 'User ini belum memiliki pesan',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  String _getDisplayUserType(String type) {
    switch (type) {
      case 'Admin': return 'Administrator';
      case 'Kepala_Sekolah': return 'Kepala Sekolah';
      case 'Wakil_Kepala': return 'Wakil Kepala Sekolah';
      case 'Guru_BK': return 'Guru BK';
      case 'Guru_Humas': return 'Guru Humas';
      case 'Guru_Kurikulum': return 'Guru Kurikulum';
      case 'Guru_Kesiswaan': return 'Guru Kesiswaan';
      case 'Guru_Sarana': return 'Guru Sarana';
      case 'Guru': return 'Guru';
      case 'Siswa': return 'Siswa';
      case 'Orang_Tua': return 'Orang Tua';
      case 'External': return 'External User';
      default: return type;
    }
  }

  Color _getUserTypeColor(String type) {
    if (type == 'Admin') return Colors.red;
    if (type.contains('Kepala') || type.contains('Wakil')) return Colors.purple;
    if (type.contains('Guru')) return Colors.blue;
    if (type == 'Siswa') return Colors.green;
    if (type == 'Orang_Tua') return Colors.orange;
    return Colors.grey;
  }

  DateTime _parseDate(dynamic date) {
    if (date == null) return DateTime.now();
    if (date is DateTime) return date;
    if (date is String) {
      try {
        return DateTime.parse(date);
      } catch (e) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }
}