// lib/screen/admin/message_types_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/auth_service.dart';
import '../../widgets/window_resizer_shortcut.dart';
import '../../utils/environment.dart';

// ==================== MODEL CLASS ====================
class MessageType {
  final int id;
  final String jenisPesan;
  final String? description;
  final int responseDeadlineHours;
  final bool isActive;
  final int totalMessages;
  final int pendingCount;
  final int approvedCount;
  final int rejectedCount;
  final int processedCount;
  final int completedCount;
  final double avgResponseTime;

  int get totalRealTime => pendingCount + approvedCount + rejectedCount;

  MessageType({
    required this.id,
    required this.jenisPesan,
    this.description,
    required this.responseDeadlineHours,
    required this.isActive,
    required this.totalMessages,
    required this.pendingCount,
    required this.approvedCount,
    required this.rejectedCount,
    required this.processedCount,
    required this.completedCount,
    required this.avgResponseTime,
  });

  factory MessageType.fromJson(Map<String, dynamic> json) {
    return MessageType(
      id: json['id'] ?? 0,
      jenisPesan: json['jenis_pesan'] ?? '',
      description: json['description'],
      responseDeadlineHours: json['response_deadline_hours'] ?? 72,
      isActive: json['is_active'] == 1,
      totalMessages: json['total_messages'] ?? 0,
      pendingCount: json['pending_count'] ?? 0,
      approvedCount: json['approved_count'] ?? 0,
      rejectedCount: json['rejected_count'] ?? 0,
      processedCount: json['processed_count'] ?? 0,
      completedCount: json['completed_count'] ?? 0,
      avgResponseTime: (json['avg_response_time'] is int) 
          ? (json['avg_response_time'] as int).toDouble()
          : double.tryParse(json['avg_response_time']?.toString() ?? '0') ?? 0,
    );
  }
  
  double get completionRate {
    if (totalMessages == 0) return 0;
    return (completedCount / totalMessages) * 100;
  }
}

// ==================== API SERVICE ====================
class MessageTypeApiService {
  static String get baseUrl => '${Environment.baseUrl}/api';
  
  static Future<String?> getToken() async {
    return await AuthService.getToken();
  }
  
  static Future<List<MessageType>> getMessageTypes() async {
    try {
      final token = await getToken();
      final url = Uri.parse('$baseUrl/message_types/list.php');
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> types = data['data'] ?? [];
          return types.map((t) => MessageType.fromJson(t)).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error loading message types: $e');
      return [];
    }
  }
  
  static Future<bool> toggleStatus(int id) async {
    try {
      final token = await getToken();
      final url = Uri.parse('$baseUrl/message_types/toggle.php?id=$id');
      final response = await http.post(
        url,
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
  
  static Future<bool> deleteType(int id) async {
    try {
      final token = await getToken();
      final url = Uri.parse('$baseUrl/message_types/delete.php?id=$id');
      final response = await http.delete(
        url,
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}

// ==================== FORM DIALOG ====================
class MessageTypeFormDialog extends StatefulWidget {
  final String title;
  final bool isEdit;
  final Map<String, dynamic>? initialData;

  const MessageTypeFormDialog({
    super.key,
    required this.title,
    required this.isEdit,
    this.initialData,
  });

  @override
  State<MessageTypeFormDialog> createState() => _MessageTypeFormDialogState();
}

class _MessageTypeFormDialogState extends State<MessageTypeFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _jenisPesanController;
  late TextEditingController _descriptionController;
  late TextEditingController _deadlineController;
  late bool _isActive;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _jenisPesanController = TextEditingController(text: widget.initialData?['jenisPesan'] ?? '');
    _descriptionController = TextEditingController(text: widget.initialData?['description'] ?? '');
    _deadlineController = TextEditingController(text: (widget.initialData?['responseDeadlineHours'] ?? 72).toString());
    _isActive = widget.initialData?['isActive'] ?? true;
  }

  @override
  void dispose() {
    _jenisPesanController.dispose();
    _descriptionController.dispose();
    _deadlineController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    final result = {
      'jenisPesan': _jenisPesanController.text.trim(),
      'description': _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
      'responseDeadlineHours': int.parse(_deadlineController.text),
      'isActive': _isActive,
    };
    
    if (widget.isEdit && widget.initialData?['id'] != null) {
      result['id'] = widget.initialData!['id'];
    }

    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _jenisPesanController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Jenis Pesan *',
                    hintText: 'Contoh: Konsultasi/Konseling',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nama jenis pesan tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Deskripsi',
                    hintText: 'Penjelasan singkat tentang jenis pesan ini',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _deadlineController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Deadline Respons (jam) *',
                    hintText: 'Waktu maksimal untuk merespons',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Deadline tidak boleh kosong';
                    }
                    final deadline = int.tryParse(value);
                    if (deadline == null || deadline < 1 || deadline > 720) {
                      return 'Deadline harus antara 1-720 jam';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Aktif'),
                  subtitle: const Text('Nonaktifkan untuk menyembunyikan jenis pesan'),
                  value: _isActive,
                  onChanged: (value) {
                    setState(() {
                      _isActive = value;
                    });
                  },
                  activeColor: Colors.green,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0B4D8A),
          ),
          child: _isSubmitting
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Simpan'),
        ),
      ],
    );
  }
}

// ==================== DETAIL SHEET ====================
class MessageTypeDetailSheet extends StatelessWidget {
  final MessageType type;

  const MessageTypeDetailSheet({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    final completionRate = type.completionRate;
    final responseRatio = type.responseDeadlineHours > 0 
        ? (type.avgResponseTime / type.responseDeadlineHours).clamp(0.0, 1.0) 
        : 0.0;
    
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.tag, color: Colors.blue[700], size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                type.jenisPesan,
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              if (type.description != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  type.description!,
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: type.isActive ? Colors.green[50] : Colors.grey[100],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            type.isActive ? 'Aktif' : 'Nonaktif',
                            style: TextStyle(
                              color: type.isActive ? Colors.green[700] : Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 3,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.2,
                      children: [
                        _buildStatCardGrid('Total Pesan', '${type.totalRealTime}', Icons.message, Colors.blue),
                        _buildStatCardGrid('Pending', '${type.pendingCount}', Icons.hourglass_empty, Colors.orange),
                        _buildStatCardGrid('Disetujui', '${type.approvedCount}', Icons.check_circle, Colors.green),
                        _buildStatCardGrid('Ditolak', '${type.rejectedCount}', Icons.cancel, Colors.red),
                        _buildStatCardGrid('Diproses', '${type.processedCount}', Icons.settings, Colors.cyan),
                        _buildStatCardGrid('Selesai', '${type.completedCount}', Icons.flag, Colors.grey),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Waktu Respons', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  children: [
                                    Text(
                                      '${type.avgResponseTime.toStringAsFixed(1)} jam',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: type.avgResponseTime > type.responseDeadlineHours ? Colors.red : Colors.green,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text('Rata-rata', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  children: [
                                    Text(
                                      '${type.responseDeadlineHours} jam',
                                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text('Target Deadline', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          LinearProgressIndicator(
                            value: responseRatio,
                            backgroundColor: Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              type.avgResponseTime > type.responseDeadlineHours ? Colors.red : Colors.green,
                            ),
                            minHeight: 8,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Tingkat Penyelesaian', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          Text(
                            '${completionRate.toStringAsFixed(1)}%',
                            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.orange),
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: completionRate / 100,
                            backgroundColor: Colors.grey[200],
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
                            minHeight: 8,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${type.completedCount} dari ${type.totalMessages} pesan selesai',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Informasi', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          _buildInfoRow('Deadline Respons', '${type.responseDeadlineHours} jam'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildStatCardGrid(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }
}

// ==================== MAIN SCREEN ====================
class MessageTypesScreen extends StatefulWidget {
  const MessageTypesScreen({super.key});

  @override
  State<MessageTypesScreen> createState() => _MessageTypesScreenState();
}

class _MessageTypesScreenState extends State<MessageTypesScreen> {
  List<MessageType> _messageTypes = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  int _currentPage = 1;
  final int _itemsPerPage = 10;
  int _totalPages = 1;
  final ScrollController _tableScrollController = ScrollController();
  
  // Scroll controllers untuk chart
  final ScrollController _volumeChartScrollController = ScrollController();
  final ScrollController _responseChartScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _tableScrollController.dispose();
    _volumeChartScrollController.dispose();
    _responseChartScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _currentPage = 1;
    });

    try {
      final types = await MessageTypeApiService.getMessageTypes();
      setState(() {
        _messageTypes = types;
        _totalPages = (types.length / _itemsPerPage).ceil();
        if (_totalPages == 0) _totalPages = 1;
        if (_currentPage > _totalPages) _currentPage = _totalPages;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<MessageType> get _filteredTypes {
    if (_searchQuery.isEmpty) return _messageTypes;
    return _messageTypes.where((type) =>
      type.jenisPesan.toLowerCase().contains(_searchQuery.toLowerCase()) ||
      (type.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false)
    ).toList();
  }
  
  List<MessageType> get _paginatedTypes {
    final filtered = _filteredTypes;
    _totalPages = (filtered.length / _itemsPerPage).ceil();
    if (_totalPages == 0) _totalPages = 1;
    if (_currentPage > _totalPages) _currentPage = _totalPages;
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;
    if (startIndex >= filtered.length) return [];
    return filtered.sublist(startIndex, endIndex > filtered.length ? filtered.length : endIndex);
  }
  
  void _goToPage(int page) {
    if (page >= 1 && page <= _totalPages) {
      setState(() => _currentPage = page);
    }
  }

  Future<void> _showAddDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => MessageTypeFormDialog(
        title: 'Tambah Jenis Pesan Baru',
        isEdit: false,
      ),
    );
    if (result != null) {
      setState(() => _isLoading = true);
      try {
        final token = await AuthService.getToken();
        final response = await http.post(
          Uri.parse('${Environment.baseUrl}/api/message_types/create.php'),
          headers: {'Authorization': 'Bearer $token'},
          body: json.encode({
            'jenis_pesan': result['jenisPesan'],
            'description': result['description'],
            'response_deadline_hours': result['responseDeadlineHours'],
            'is_active': result['isActive'] ? 1 : 0,
          }),
        );
        final data = json.decode(response.body);
        if (data['success'] == true) {
          _showSnackBar('Jenis pesan berhasil ditambahkan', Colors.green);
          await _loadData();
        } else {
          _showSnackBar(data['message'] ?? 'Gagal menambahkan', Colors.red);
          setState(() => _isLoading = false);
        }
      } catch (e) {
        _showSnackBar('Error: $e', Colors.red);
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showEditDialog(MessageType type) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => MessageTypeFormDialog(
        title: 'Edit Jenis Pesan',
        isEdit: true,
        initialData: {
          'id': type.id,
          'jenisPesan': type.jenisPesan,
          'description': type.description ?? '',
          'responseDeadlineHours': type.responseDeadlineHours,
          'isActive': type.isActive,
        },
      ),
    );
    if (result != null) {
      setState(() => _isLoading = true);
      try {
        final token = await AuthService.getToken();
        final response = await http.put(
          Uri.parse('${Environment.baseUrl}/api/message_types/update.php'),
          headers: {'Authorization': 'Bearer $token'},
          body: json.encode({
            'id': result['id'],
            'jenis_pesan': result['jenisPesan'],
            'description': result['description'],
            'response_deadline_hours': result['responseDeadlineHours'],
            'is_active': result['isActive'] ? 1 : 0,
          }),
        );
        final data = json.decode(response.body);
        if (data['success'] == true) {
          _showSnackBar('Jenis pesan berhasil diperbarui', Colors.green);
          await _loadData();
        } else {
          _showSnackBar(data['message'] ?? 'Gagal memperbarui', Colors.red);
          setState(() => _isLoading = false);
        }
      } catch (e) {
        _showSnackBar('Error: $e', Colors.red);
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _toggleStatus(MessageType type) async {
    try {
      final success = await MessageTypeApiService.toggleStatus(type.id);
      if (success) {
        _showSnackBar('Status berhasil diubah', Colors.green);
        await _loadData();
      } else {
        _showSnackBar('Gagal mengubah status', Colors.red);
      }
    } catch (e) {
      _showSnackBar('Error: $e', Colors.red);
    }
  }

  Future<void> _deleteType(MessageType type) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text('Apakah Anda yakin ingin menghapus jenis pesan "${type.jenisPesan}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(context, true), style: TextButton.styleFrom(foregroundColor: Colors.red), child: const Text('Hapus')),
        ],
      ),
    );
    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        final success = await MessageTypeApiService.deleteType(type.id);
        if (success) {
          _showSnackBar('Jenis pesan berhasil dihapus', Colors.green);
          await _loadData();
        } else {
          _showSnackBar('Gagal menghapus jenis pesan', Colors.red);
          setState(() => _isLoading = false);
        }
      } catch (e) {
        _showSnackBar('Error: $e', Colors.red);
        setState(() => _isLoading = false);
      }
    }
  }

  void _showDetail(MessageType type) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => MessageTypeDetailSheet(type: type),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color, behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WindowResizerShortcut(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Jenis Pesan'),
          backgroundColor: const Color(0xFF0B4D8A),
          foregroundColor: Colors.white,
          actions: [
            IconButton(icon: const Icon(Icons.aspect_ratio), onPressed: () => WindowResizerExtension.showResizerPanel(context), tooltip: 'Ubah Ukuran Window (F2)'),
            IconButton(icon: const Icon(Icons.add), onPressed: _showAddDialog, tooltip: 'Tambah Jenis Pesan'),
            IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData, tooltip: 'Refresh'),
          ],
        ),
        body: _isLoading
            ? const Center(child: SpinKitFadingCircle(color: Color(0xFF0B4D8A), size: 50))
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                        const SizedBox(height: 16),
                        Text(_error!),
                        const SizedBox(height: 16),
                        ElevatedButton(onPressed: _loadData, child: const Text('Coba Lagi')),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadData,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildStatsCards(),
                          const SizedBox(height: 20),
                          _buildSearchBar(),
                          const SizedBox(height: 16),
                          _buildTypesTable(),
                          const SizedBox(height: 16),
                          _buildPagination(),
                          const SizedBox(height: 38),
                          _buildPerformanceTabView(),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }

  Widget _buildStatsCards() {
    final totalTypes = _messageTypes.length;
    final activeTypes = _messageTypes.where((t) => t.isActive).length;
    final totalMessages = _messageTypes.fold(0, (sum, t) => sum + t.totalRealTime);
    final totalCompleted = _messageTypes.fold(0, (sum, t) => sum + t.completedCount);
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.5,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: [
        _buildStatCardCompact('Jenis Pesan', '$totalTypes', Icons.category, Colors.blue, '$activeTypes aktif'),
        _buildStatCardCompact('Total Pesan', NumberFormat('#,###').format(totalMessages), Icons.message, Colors.green, 'Semua pesan'),
        _buildStatCardCompact('Penyelesaian', totalMessages > 0 ? '${((totalCompleted / totalMessages) * 100).toStringAsFixed(1)}%' : '0%', Icons.check_circle, Colors.orange, 'Pesan selesai'),
        _buildStatCardCompact('Rata Waktu', totalTypes > 0 ? '${(_messageTypes.fold(0.0, (sum, t) => sum + t.avgResponseTime) / totalTypes).toStringAsFixed(1)}h' : '0h', Icons.timer, Colors.purple, 'Target ≤72 jam'),
      ],
    );
  }

  Widget _buildStatCardCompact(String title, String value, IconData icon, Color color, String subtitle) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: color, size: 20)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
                  Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  Text(subtitle, style: const TextStyle(fontSize: 9, color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 1, blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: TextField(
        onChanged: (value) { setState(() { _searchQuery = value; _currentPage = 1; }); },
        decoration: InputDecoration(
          hintText: 'Cari jenis pesan...',
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildTypesTable() {
    final paginatedTypes = _paginatedTypes;
    if (paginatedTypes.isEmpty) {
      return const Card(child: Padding(padding: EdgeInsets.all(32), child: Center(child: Text('Tidak ada jenis pesan ditemukan'))));
    }
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(color: Colors.grey[50], border: const Border(bottom: BorderSide(color: Colors.grey))),
              child: const Row(
                children: [
                  SizedBox(width: 50, child: Text('#', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  SizedBox(width: 200, child: Text('Jenis Pesan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  SizedBox(width: 80, child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.center)),
                  SizedBox(width: 80, child: Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.center)),
                  SizedBox(width: 80, child: Text('Pending', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.center)),
                  SizedBox(width: 80, child: Text('Disetujui', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.center)),
                  SizedBox(width: 80, child: Text('Ditolak', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.center)),
                  SizedBox(width: 120, child: Text('Waktu Respons', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.center)),
                  SizedBox(width: 150, child: Text('Aksi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.center)),
                ],
              ),
            ),
          ),
          Scrollbar(
            controller: _tableScrollController,
            thumbVisibility: true,
            trackVisibility: true,
            interactive: true,
            thickness: 10,
            radius: const Radius.circular(8),
            child: SingleChildScrollView(
              controller: _tableScrollController,
              scrollDirection: Axis.horizontal,
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: paginatedTypes.asMap().entries.map((entry) {
                  final index = (_currentPage - 1) * _itemsPerPage + entry.key + 1;
                  final type = entry.value;
                  final responseRatio = type.responseDeadlineHours > 0 
                      ? (type.avgResponseTime / type.responseDeadlineHours).clamp(0.0, 1.0) 
                      : 0.0;
                  final totalRealTime = type.totalRealTime;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey[100]!))),
                    child: Row(
                      children: [
                        SizedBox(width: 50, child: Text('$index', style: const TextStyle(fontSize: 13))),
                        SizedBox(
                          width: 200,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(type.jenisPesan, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              if (type.description != null && type.description!.isNotEmpty) Text(type.description!, style: const TextStyle(fontSize: 11, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 4),
                              Text('Deadline: ${type.responseDeadlineHours} jam', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                            ],
                          ),
                        ),
                        SizedBox(width: 80, child: Center(child: Switch(value: type.isActive, onChanged: (_) => _toggleStatus(type), activeColor: Colors.green))),
                        SizedBox(width: 80, child: Center(child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12)), child: Text('$totalRealTime', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue))))),
                        SizedBox(width: 80, child: Center(child: type.pendingCount > 0 ? Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(12)), child: Text('${type.pendingCount}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange))) : const Text('-'))),
                        SizedBox(width: 80, child: Center(child: type.approvedCount > 0 ? Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12)), child: Text('${type.approvedCount}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green))) : const Text('-'))),
                        SizedBox(width: 80, child: Center(child: type.rejectedCount > 0 ? Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12)), child: Text('${type.rejectedCount}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red))) : const Text('-'))),
                        SizedBox(width: 120, child: Center(child: Column(children: [Text('${type.avgResponseTime.toStringAsFixed(1)} jam', style: TextStyle(fontWeight: FontWeight.bold, color: type.avgResponseTime > type.responseDeadlineHours ? Colors.red : Colors.green, fontSize: 12)), const SizedBox(height: 4), LinearProgressIndicator(value: responseRatio, backgroundColor: Colors.grey.shade200, valueColor: AlwaysStoppedAnimation<Color>(type.avgResponseTime > type.responseDeadlineHours ? Colors.red : Colors.green), minHeight: 4, borderRadius: BorderRadius.circular(2))]))),
                        SizedBox(width: 150, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          IconButton(icon: const Icon(Icons.edit, size: 20, color: Colors.blue), onPressed: () => _showEditDialog(type), tooltip: 'Edit'),
                          IconButton(icon: const Icon(Icons.bar_chart, size: 20, color: Colors.green), onPressed: () => _showDetail(type), tooltip: 'Detail Performa'),
                          IconButton(icon: const Icon(Icons.delete, size: 20, color: Colors.red), onPressed: () => _deleteType(type), tooltip: 'Hapus'),
                        ])),
                      ],
                    ),
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
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(icon: const Icon(Icons.first_page, size: 20), onPressed: _currentPage > 1 ? () => _goToPage(1) : null),
          IconButton(icon: const Icon(Icons.chevron_left, size: 24), onPressed: _currentPage > 1 ? () => _goToPage(_currentPage - 1) : null),
          Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), decoration: BoxDecoration(color: const Color(0xFF0B4D8A).withOpacity(0.1), borderRadius: BorderRadius.circular(16)), child: Text('$_currentPage / $_totalPages', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500))),
          IconButton(icon: const Icon(Icons.chevron_right, size: 24), onPressed: _currentPage < _totalPages ? () => _goToPage(_currentPage + 1) : null),
          IconButton(icon: const Icon(Icons.last_page, size: 20), onPressed: _currentPage < _totalPages ? () => _goToPage(_totalPages) : null),
          Container(margin: const EdgeInsets.only(left: 12), padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)), child: Text('Total: ${_filteredTypes.length} jenis', style: const TextStyle(fontSize: 10, color: Colors.grey))),
        ],
      ),
    );
  }

  // ==================== PERFORMANCE TAB VIEW ====================
  Widget _buildPerformanceTabView() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.assessment, color: Color(0xFF0B4D8A), size: 22),
                SizedBox(width: 8),
                Text('Analisis Performa',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0B4D8A))),
              ],
            ),
            const Divider(height: 20),
            SizedBox(
              height: 500,
              child: DefaultTabController(
                length: 2,
                child: Column(
                  children: [
                    const TabBar(
                      indicatorColor: Color(0xFF0B4D8A),
                      labelColor: Color(0xFF0B4D8A),
                      unselectedLabelColor: Colors.grey,
                      tabs: [
                        Tab(icon: Icon(Icons.bar_chart), text: 'Volume Pesan'),
                        Tab(icon: Icon(Icons.timeline), text: 'Waktu Respons'),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          SingleChildScrollView(
                            padding: const EdgeInsets.only(top: 8),
                            child: _buildVolumeChart(),
                          ),
                          SingleChildScrollView(
                            padding: const EdgeInsets.only(top: 8),
                            child: _buildResponseTimeChart(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== GRAFIK VOLUME PESAN (BATANG) DENGAN SCROLLBAR HORIZONTAL ====================
  Widget _buildVolumeChart() {
  if (_messageTypes.isEmpty) {
    return const Center(child: Text('Tidak ada data'));
  }

  final maxTotal = _messageTypes.fold(0, (max, t) => t.totalRealTime > max ? t.totalRealTime : max);
  if (maxTotal == 0) {
    return const Center(child: Text('Tidak ada data volume pesan'));
  }

  final chartWidth = _messageTypes.length * 120.0 > 800 ? _messageTypes.length * 120.0 : 800.0;
  // Tambahkan padding 1 unit di atas nilai maksimum
  final maxYBar = (maxTotal + 1).toDouble();

  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Wrap(
          spacing: 16,
          alignment: WrapAlignment.center,
          children: [
            _buildLegendItem('Total Pesan', Colors.blue),
            _buildLegendItem('Pending', Colors.orange),
            _buildLegendItem('Disetujui', Colors.green),
            _buildLegendItem('Ditolak', Colors.red),
          ],
        ),
      ),
      const SizedBox(height: 12),
      Scrollbar(
        controller: _volumeChartScrollController,
        thumbVisibility: true,
        trackVisibility: true,
        interactive: true,
        thickness: 10,
        radius: const Radius.circular(8),
        child: SingleChildScrollView(
          controller: _volumeChartScrollController,
          scrollDirection: Axis.horizontal,
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            width: chartWidth,
            height: 350,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxYBar,
                minY: 0,
                barGroups: _buildBarGroups(_messageTypes, maxTotal),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 60,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < _messageTypes.length) {
                          final type = _messageTypes[index];
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Transform.rotate(
                              angle: -0.4,
                              child: Text(
                                type.jenisPesan.length > 15
                                    ? '${type.jenisPesan.substring(0, 12)}..'
                                    : type.jenisPesan,
                                style: const TextStyle(
                                    fontSize: 9, fontWeight: FontWeight.w500),
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 45,
                      getTitlesWidget: (value, meta) {
                        // Hanya tampilkan integer, bulatkan ke bawah
                        int intValue = value.toInt();
                        if (value == intValue.toDouble()) {
                          return Text(
                            intValue.toString(),
                            style: const TextStyle(fontSize: 11),
                          );
                        }
                        return const Text('');
                      },
                      interval: 1, // Interval 1 unit
                    ),
                  ),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: Colors.grey.shade300, width: 1),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1, // Grid setiap 1 unit
                  getDrawingHorizontalLine: (value) {
                    // Hanya tampilkan garis pada integer
                    if (value == value.toInt()) {
                      return FlLine(
                        color: Colors.grey.shade300,
                        strokeWidth: 1,
                        dashArray: [5, 5],
                      );
                    }
                    return FlLine(color: Colors.transparent);
                  },
                ),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final type = _messageTypes[groupIndex];
                      String label = '';
                      double value = 0;
                      switch (rodIndex) {
                        case 0:
                          label = 'Total Pesan';
                          value = type.totalRealTime.toDouble();
                          break;
                        case 1:
                          label = 'Pending';
                          value = type.pendingCount.toDouble();
                          break;
                        case 2:
                          label = 'Disetujui';
                          value = type.approvedCount.toDouble();
                          break;
                        case 3:
                          label = 'Ditolak';
                          value = type.rejectedCount.toDouble();
                          break;
                      }
                      return BarTooltipItem(
                        '${type.jenisPesan}\n$label: ${value.toInt()}',
                        const TextStyle(color: Colors.white, fontSize: 11),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      if (_messageTypes.length > 6)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.swap_horiz, size: 14, color: Colors.grey.shade500),
              const SizedBox(width: 4),
              Text(
                'Geser ke kanan/kiri untuk melihat semua jenis pesan',
                style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      const SizedBox(height: 8),
    ],
  );
}

  // ==================== GRAFIK WAKTU RESPONS (GARIS) DENGAN SCROLLBAR HORIZONTAL ====================
  Widget _buildResponseTimeChart() {
    if (_messageTypes.isEmpty) {
      return const Center(child: Text('Tidak ada data'));
    }

    final maxResponse = _messageTypes.fold(0.0, (max, t) => t.avgResponseTime > max ? t.avgResponseTime : max);
    if (maxResponse == 0) {
      return const Center(child: Text('Tidak ada data waktu respons'));
    }

    final chartWidth = _messageTypes.length * 120.0 > 800 ? _messageTypes.length * 120.0 : 800.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.purple.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.info_outline, size: 14, color: Colors.purple),
              SizedBox(width: 6),
              Text('Semakin tinggi garis → semakin lama waktu respons',
                  style: TextStyle(fontSize: 10, color: Colors.purple)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Scrollbar(
          controller: _responseChartScrollController,
          thumbVisibility: true,
          trackVisibility: true,
          interactive: true,
          thickness: 10,
          radius: const Radius.circular(8),
          child: SingleChildScrollView(
            controller: _responseChartScrollController,
            scrollDirection: Axis.horizontal,
            physics: const AlwaysScrollableScrollPhysics(),
            child: SizedBox(
              width: chartWidth,
              height: 310,
              child: LineChart(
                LineChartData(
                  minX: -0.5,
                  maxX: _messageTypes.length - 0.5,
                  maxY: maxResponse + 5,
                  minY: 0,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    horizontalInterval: _getResponseInterval(maxResponse),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 60,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < _messageTypes.length) {
                            final type = _messageTypes[index];
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Transform.rotate(
                                angle: -0.4,
                                child: Text(
                                  type.jenisPesan.length > 15
                                      ? '${type.jenisPesan.substring(0, 12)}..'
                                      : type.jenisPesan,
                                  style: const TextStyle(fontSize: 9),
                                ),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 45,
                      ),
                    ),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: Colors.grey.shade300, width: 1),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _buildResponseSpots(),
                      isCurved: true,
                      color: Colors.purple,
                      barWidth: 3,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                          radius: 4,
                          color: Colors.purple,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        ),
                      ),
                      belowBarData: BarAreaData(show: false),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final index = spot.x.toInt();
                          if (index >= 0 && index < _messageTypes.length) {
                            final type = _messageTypes[index];
                            return LineTooltipItem(
                              '${type.jenisPesan}\nWaktu Respons: ${type.avgResponseTime.toStringAsFixed(1)} jam\nTarget: ${type.responseDeadlineHours} jam',
                              const TextStyle(color: Colors.white, fontSize: 11),
                            );
                          }
                          return null;
                        }).whereType<LineTooltipItem>().toList();
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (_messageTypes.length > 6)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.swap_horiz, size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(
                  'Geser ke kanan/kiri untuk melihat semua jenis pesan',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
        const SizedBox(height: 8),
      ],
    );
  }

  List<BarChartGroupData> _buildBarGroups(List<MessageType> types, int maxTotal) {
  // HAPUS maxBarHeight - gunakan nilai REAL langsung
  return types.asMap().entries.map((entry) {
    final index = entry.key;
    final type = entry.value;
    
    // Gunakan nilai REAL, bukan skala
    final double totalHeight = type.totalRealTime.toDouble();
    final double pendingHeight = type.pendingCount.toDouble();
    final double approvedHeight = type.approvedCount.toDouble();
    final double rejectedHeight = type.rejectedCount.toDouble();
    
    return BarChartGroupData(
      x: index,
      barRods: [
        BarChartRodData(
          toY: totalHeight,
          color: Colors.blue,
          width: 18,
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4)),
        ),
        BarChartRodData(
          toY: pendingHeight,
          color: Colors.orange,
          width: 18,
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4)),
        ),
        BarChartRodData(
          toY: approvedHeight,
          color: Colors.green,
          width: 18,
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4)),
        ),
        BarChartRodData(
          toY: rejectedHeight,
          color: Colors.red,
          width: 18,
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4)),
        ),
      ],
      barsSpace: 2,
    );
  }).toList();
}

  List<FlSpot> _buildResponseSpots() {
    return _messageTypes.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.avgResponseTime);
    }).toList();
  }

  double _getInterval(int maxValue) {
    if (maxValue <= 10) return 2;
    if (maxValue <= 20) return 5;
    if (maxValue <= 50) return 10;
    if (maxValue <= 100) return 20;
    return 50;
  }

  double _getResponseInterval(double maxResponse) {
    if (maxResponse <= 10) return 2;
    if (maxResponse <= 20) return 5;
    if (maxResponse <= 50) return 10;
    return 20;
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}