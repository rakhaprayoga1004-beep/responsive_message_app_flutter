// lib/utils/session_debug.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class SessionDebugger {
  static Future<void> printAllSessionData() async {
    print('\n🔍 ===== SESSION DEBUG ====');
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      print('📋 SharedPreferences keys (${keys.length}):');
      for (var key in keys) {
        final value = prefs.get(key);
        String valueStr = value.toString();
        if (valueStr.length > 50) {
          valueStr = valueStr.substring(0, 50) + '...';
        }
        print('   $key: $valueStr');
      }
    } catch (e) {
      print('❌ Error reading SharedPreferences: $e');
    }
    print('==========================\n');
  }

  static Future<void> clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('session_id');
      await prefs.remove('token');
      await prefs.remove('user_data');
      await prefs.remove('user_id');
      await prefs.remove('user_type');
      print('🧹 Session data cleared');
    } catch (e) {
      print('❌ Error clearing session: $e');
    }
  }

  static Widget buildDebugPanel(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: Colors.yellow.shade100,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.bug_report, size: 14, color: Colors.brown),
          const SizedBox(width: 4),
          Expanded(
            child: Consumer<AuthService>(
              builder: (context, authService, _) {
                return Text(
                  'Auth: ${authService.isAuthenticated ? '✅' : '❌'} | '
                  'User: ${authService.user?.namaLengkap ?? 'none'} | '
                  'Type: ${authService.user?.userType ?? 'none'}',
                  style: const TextStyle(fontSize: 10, color: Colors.brown),
                  overflow: TextOverflow.ellipsis,
                );
              },
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.refresh, size: 14, color: Colors.brown),
            onPressed: () async {
              await SessionDebugger.printAllSessionData();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Session data printed to console'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.clear, size: 14, color: Colors.red),
            onPressed: () async {
              await SessionDebugger.clearSession();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Session cleared'),
                    duration: Duration(seconds: 1),
                  ),
                );
                // Force refresh
                Provider.of<AuthService>(context, listen: false).logout();
              }
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}