// lib/test_login.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'utils/environment.dart';

class TestLoginScreen extends StatefulWidget {
  const TestLoginScreen({Key? key}) : super(key: key);

  @override
  State<TestLoginScreen> createState() => _TestLoginScreenState();
}

class _TestLoginScreenState extends State<TestLoginScreen> {
  bool _isLoading = false;
  String _result = '';
  String _sessionId = '';

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  Future<void> _loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _sessionId = prefs.getString('session_id') ?? '';
    });
  }

  Future<void> _testLogin() async {
    setState(() {
      _isLoading = true;
      _result = 'Loading...';
    });

    try {
      final url = Uri.parse('${Environment.baseUrl}/api/test_login.php');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success'] == true) {
          // Simpan session ID
          final sessionId = data['session_id'];
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('session_id', sessionId);
          
          // Update auth service jika perlu
          final authService = Provider.of<AuthService>(context, listen: false);
          // Refresh auth service jika ada method untuk reload session
          
          setState(() {
            _result = 'Login test berhasil!\nSession ID: $sessionId';
            _sessionId = sessionId;
          });
        } else {
          setState(() {
            _result = 'Login test gagal: ${data['error'] ?? data['message']}';
          });
        }
      } else {
        setState(() {
          _result = 'HTTP Error: ${response.statusCode}\n${response.body}';
        });
      }
    } catch (e) {
      setState(() {
        _result = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testGetMessage(String messageId) async {
    setState(() {
      _isLoading = true;
      _result = 'Loading message $messageId...';
    });

    try {
      final url = Uri.parse('${Environment.baseUrl}/api/get_message_detail.php?id=$messageId');
      
      final response = await http.get(
        url,
        headers: {
          'Cookie': 'PHPSESSID=$_sessionId',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      setState(() {
        _result = 'Status: ${response.statusCode}\nBody: ${response.body}';
      });
    } catch (e) {
      setState(() {
        _result = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _checkSession() async {
    setState(() {
      _isLoading = true;
      _result = 'Checking session...';
    });

    try {
      final url = Uri.parse('${Environment.baseUrl}/api/check_session.php');
      
      final response = await http.get(
        url,
        headers: {
          'Cookie': 'PHPSESSID=$_sessionId',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      setState(() {
        _result = 'Status: ${response.statusCode}\nBody: ${response.body}';
      });
    } catch (e) {
      setState(() {
        _result = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('session_id');
    setState(() {
      _sessionId = '';
      _result = 'Session cleared';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Login & Session'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
            tooltip: 'Go to Home',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Session Info Card
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Session Info:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text('Session ID: $_sessionId'),
                    if (_sessionId.isNotEmpty)
                      Text('Length: ${_sessionId.length}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Test Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _testLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Test Login'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _sessionId.isEmpty ? null : _checkSession,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Check Session'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _sessionId.isEmpty ? null : () => _testGetMessage('59'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Get Msg #59'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _sessionId.isEmpty ? null : () => _testGetMessage('60'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Get Msg #60'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            ElevatedButton(
              onPressed: _clearSession,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Clear Session'),
            ),
            
            const SizedBox(height: 16),
            
            // Result Display
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[400]!),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Result:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      SelectableText(
                        _result,
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}