// lib/screen/user/chat_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../widgets/window_resizer_shortcut.dart'; // Import window resizer shortcut

class ChatScreen extends StatelessWidget {
  final int messageId;
  final String messageTitle;

  const ChatScreen({
    super.key,
    required this.messageId,
    required this.messageTitle,
  });

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    
    return WindowResizerShortcut(
      child: Scaffold(
        appBar: AppBar(
          title: Text(messageTitle),
          backgroundColor: const Color(0xFF0B4D8A),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => authService.logout(),
              tooltip: 'Logout',
            ),
          ],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.chat, size: 100, color: Color(0xFF0B4D8A)),
              const SizedBox(height: 20),
              Text(
                'Chat dengan ID: $messageId',
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(height: 10),
              const Text('Fitur Chat akan segera hadir'),
            ],
          ),
        ),
      ),
    );
  }
}