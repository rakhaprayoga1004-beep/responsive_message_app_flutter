// lib/screen/chat_screen.dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../../widgets/window_resizer_shortcut.dart';

class ChatScreen extends StatefulWidget {
  final int conversationId;
  final String contactName;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.contactName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;
  bool _isSending = false;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final userData = await AuthService.getCurrentUser();
      if (userData != null) {
        setState(() {
          _currentUser = User(
            id: userData['id'] ?? 0,
            username: userData['username'] ?? '',
            namaLengkap: userData['nama_lengkap'] ?? '',
            userType: userData['user_type'] ?? '',
            email: userData['email'],
            phoneNumber: userData['phone_number'],
            avatar: userData['avatar'],
            privilegeLevel: userData['privilege_level'],
          );
        });
      }
    } catch (e) {
      print('Error loading current user: $e');
    }
  }

  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await Future.delayed(Duration(seconds: 1));
      
      setState(() {
        _messages = [
          {
            'id': 1,
            'sender_id': 2,
            'message': 'Halo, ada yang bisa saya bantu?',
            'created_at': DateTime.now().subtract(Duration(hours: 2)),
            'is_me': false,
          },
          {
            'id': 2,
            'sender_id': 1,
            'message': 'Saya ingin bertanya tentang tugas',
            'created_at': DateTime.now().subtract(Duration(hours: 1, minutes: 30)),
            'is_me': true,
          },
          {
            'id': 3,
            'sender_id': 2,
            'message': 'Silakan, ada yang ingin ditanyakan?',
            'created_at': DateTime.now().subtract(Duration(hours: 1)),
            'is_me': false,
          },
        ];
        _isLoading = false;
      });

      _scrollToBottom();
    } catch (e) {
      print('Error loading messages: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final message = _messageController.text;
    _messageController.clear();

    setState(() {
      _isSending = true;
      _messages.add({
        'id': DateTime.now().millisecondsSinceEpoch,
        'sender_id': 1,
        'message': message,
        'created_at': DateTime.now(),
        'is_me': true,
        'status': 'sending',
      });
    });

    _scrollToBottom();

    try {
      await Future.delayed(Duration(seconds: 1));

      setState(() {
        final index = _messages.length - 1;
        _messages[index]['status'] = 'sent';
        _isSending = false;
      });
    } catch (e) {
      print('Error sending message: $e');
      setState(() {
        final index = _messages.length - 1;
        _messages[index]['status'] = 'failed';
        _isSending = false;
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Tambahkan WindowResizerShortcut di sini
    return WindowResizerShortcut(
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.white,
                child: Text(
                  widget.contactName[0],
                  style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.contactName, style: TextStyle(fontSize: 16)),
                    Text('Online', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            IconButton(
              icon: Icon(Icons.more_vert),
              onPressed: () => _showChatOptions(context),
            ),
            // Tambahkan tombol untuk window resizer (opsional)
            IconButton(
              icon: Icon(Icons.aspect_ratio),
              onPressed: () => WindowResizerExtension.showResizerPanel(context),
              tooltip: 'Ubah Ukuran Window (F2)',
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : _messages.isEmpty
                      ? _buildEmptyChat()
                      : _buildMessageList(),
            ),
            _buildMessageInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyChat() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 60, color: Colors.grey.shade400),
          SizedBox(height: 16),
          Text('Belum ada pesan', style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
          SizedBox(height: 8),
          Text('Kirim pesan pertama Anda', style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) => _buildMessageBubble(_messages[index]),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final isMe = message['is_me'] == true;
    final status = message['status'] ?? 'sent';
    
    return Container(
      margin: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe)
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey.shade200,
              child: Text(
                widget.contactName[0],
                style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.bold),
              ),
            ),
          if (!isMe) SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? Colors.blue : Colors.grey.shade200,
                borderRadius: isMe
                    ? BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(4),
                      )
                    : BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                        bottomLeft: Radius.circular(4),
                        bottomRight: Radius.circular(20),
                      ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(message['message'], style: TextStyle(color: isMe ? Colors.white : Colors.black87)),
                  SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_formatTime(message['created_at']), style: TextStyle(fontSize: 10, color: isMe ? Colors.white70 : Colors.grey.shade600)),
                      if (isMe && status != 'sent') ...[
                        SizedBox(width: 4),
                        Icon(status == 'sending' ? Icons.hourglass_empty : Icons.error, size: 12, color: isMe ? Colors.white70 : Colors.red),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isMe) SizedBox(width: 8),
          if (isMe)
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue.shade100,
              child: Text(
                _currentUser?.namaLengkap[0] ?? 'U',
                style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            offset: Offset(0, -2),
            blurRadius: 4,
            color: Colors.black.withOpacity(0.05),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.attach_file),
            onPressed: () {},
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Ketik pesan...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: EdgeInsets.symmetric(horizontal: 16),
              ),
              maxLines: null,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: _messageController.text.isNotEmpty ? Colors.blue : Colors.grey,
            child: IconButton(
              icon: Icon(Icons.send, color: Colors.white, size: 18),
              onPressed: _isSending ? null : _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  void _showChatOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Wrap(
        children: [
          ListTile(
            leading: Icon(Icons.person),
            title: Text('Lihat Profil'),
            onTap: () {
              Navigator.pop(context);
              _showContactProfile();
            },
          ),
          ListTile(
            leading: Icon(Icons.search),
            title: Text('Cari Pesan'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: Icon(Icons.delete, color: Colors.red),
            title: Text('Hapus Percakapan', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              _deleteConversation();
            },
          ),
        ],
      ),
    );
  }

  void _showContactProfile() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Profil Kontak'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.blue.shade100,
              child: Text(
                widget.contactName[0],
                style: TextStyle(fontSize: 30, color: Colors.blue.shade700),
              ),
            ),
            SizedBox(height: 16),
            Text(
              widget.contactName,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('Online', style: TextStyle(color: Colors.green)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteConversation() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hapus Percakapan'),
        content: Text('Apakah Anda yakin ingin menghapus percakapan ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      Navigator.pop(context);
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inHours < 24) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Kemarin';
    } else {
      return '${time.day}/${time.month}';
    }
  }
}