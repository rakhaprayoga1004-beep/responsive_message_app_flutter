import 'package:flutter/material.dart';
import 'package:responsive_message_app_flutter/utils/helpers.dart';
import '../../widgets/window_resizer_shortcut.dart'; // Import window resizer shortcut
import 'message_detail_screen.dart';

class MessageListScreen extends StatefulWidget {
  const MessageListScreen({super.key});

  @override
  State<MessageListScreen> createState() => _MessageListScreenState();
}

class _MessageListScreenState extends State<MessageListScreen> {
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _messages = [
        {
          'id': '1',
          'sender': 'Ahmad Wijaya',
          'message': 'Saya ingin melaporkan bahwa ada kerusakan pada fasilitas laboratorium komputer...',
          'status': 'Pending',
          'date': DateTime.now().subtract(const Duration(hours: 2)),
          'type': 'Pengaduan',
        },
        {
          'id': '2',
          'sender': 'Siti Nurhaliza',
          'message': 'Mohon informasi mengenai jadwal ujian semester ganjil...',
          'status': 'Diproses',
          'date': DateTime.now().subtract(const Duration(days: 1)),
          'type': 'Informasi',
        },
        {
          'id': '3',
          'sender': 'Budi Santoso',
          'message': 'Saran untuk perbaikan sistem pembelajaran online...',
          'status': 'Pending',
          'date': DateTime.now().subtract(const Duration(days: 2)),
          'type': 'Saran',
        },
      ];
      _isLoading = false;
    });
  }

  Future<void> _refreshMessages() async {
    setState(() => _isLoading = true);
    await _loadMessages();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending': return Colors.orange;
      case 'Diproses': return Colors.blue;
      case 'Selesai': return Colors.green;
      case 'Ditolak': return Colors.red;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return WindowResizerShortcut(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Daftar Pesan'),
          backgroundColor: const Color(0xFF0B4D8A),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _refreshMessages,
              tooltip: 'Refresh',
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _messages.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('Belum ada pesan masuk', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _refreshMessages,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MessageDetailScreen(
                                    messageId: message['id'],
                                    messageData: {
                                      'id': message['id'],
                                      'nama_lengkap': message['sender'],
                                      'isi_pesan': message['message'],
                                      'status': message['status'],
                                      'jenis_pesan': message['type'],
                                      'created_at': message['date'].toIso8601String(),
                                    },
                                  ),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 20,
                                        backgroundColor: Colors.blue.shade100,
                                        child: Text(
                                          message['sender'][0],
                                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              message['sender'],
                                              style: const TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                            Text(
                                              message['type'],
                                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(message['status']).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          message['status'],
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: _getStatusColor(message['status']),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    message['message'],
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _formatDate(message['date']),
                                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inDays > 0) {
      return '${diff.inDays} hari lalu';
    } else if (diff.inHours > 0) {
      return '${diff.inHours} jam lalu';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes} menit lalu';
    } else {
      return 'Baru saja';
    }
  }
}