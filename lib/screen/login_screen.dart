// lib/screen/login_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:responsive_message_app_flutter/services/auth_service.dart';
import 'package:responsive_message_app_flutter/utils/helpers.dart';
import '../../widgets/window_resizer_shortcut.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _clearOldSession();
  }

  // ============================================================
  // HAPUS SESSION LAMA SEBELUM LOGIN
  // ============================================================
  Future<void> _clearOldSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Hapus semua data auth yang mungkin tersisa
      await prefs.remove('auth_token');
      await prefs.remove('is_logged_in');
      await prefs.remove('user_id');
      await prefs.remove('user_name');
      await prefs.remove('user_type');
      await prefs.remove('user_email');
      await prefs.remove('user_phone');
      await prefs.remove('user_avatar');
      await prefs.remove('privilege_level');
      await prefs.remove('user_token');
      print('✅ Old session cleared');
    } catch (e) {
      print('❌ Error clearing old session: $e');
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final username = _usernameController.text.trim();
      final password = _passwordController.text;
      
      // Bersihkan session lama terlebih dahulu
      await _clearOldSession();
      
      final response = await AuthService.login(username, password);

      print('Login response: $response');

      if (response['success'] == true) {
        final userData = response['user'];
        final token = userData?['token'];
        
        print('User data from response:');
        print('  - id: ${userData?['id']}');
        print('  - username: ${userData?['username']}');
        print('  - user_type: ${userData?['user_type']}');
        print('  - token: ${token != null ? token.substring(0, token.length > 30 ? 30 : token.length) + '...' : 'null'}');
        
        if (token != null && token.isNotEmpty) {
          // Save token dan user data langsung ke SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_token', token);
          await prefs.setBool('is_logged_in', true);
          await prefs.setInt('user_id', userData['id'] ?? 0);
          await prefs.setString('user_name', userData['nama_lengkap'] ?? userData['username'] ?? '');
          await prefs.setString('user_type', userData['user_type'] ?? '');
          await prefs.setString('user_email', userData['email'] ?? '');
          await prefs.setString('user_phone', userData['phone_number'] ?? '');
          
          print('Token saved successfully');
          print('User type saved: ${userData['user_type']}');
          
          // Verifikasi data yang tersimpan
          final savedType = await AuthService.getUserType();
          print('Verified saved user_type: $savedType');
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Login berhasil sebagai ${_getUserDisplayName(userData['user_type'] ?? 'User')}'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
          
          _redirectToDashboard(userData['user_type'] ?? '');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Token tidak ditemukan dalam response'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Login gagal. Periksa username dan password Anda.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      print('Login error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Mendapatkan nama display untuk user type
  String _getUserDisplayName(String userType) {
    switch (userType) {
      case 'Admin':
      case 'Super_Admin':
        return 'Administrator';
      case 'Kepala_Sekolah':
        return 'Kepala Sekolah';
      case 'Wakil_Kepala':
        return 'Wakil Kepala';
      case 'Guru_BK':
        return 'Guru BK';
      case 'Guru_Humas':
        return 'Guru Humas';
      case 'Guru_Kurikulum':
        return 'Guru Kurikulum';
      case 'Guru_Kesiswaan':
        return 'Guru Kesiswaan';
      case 'Guru_Sarana':
        return 'Guru Sarana';
      case 'Guru':
        return 'Guru';
      case 'Siswa':
        return 'Siswa';
      case 'Orang_Tua':
        return 'Orang Tua';
      default:
        return userType.replaceAll('_', ' ');
    }
  }

  /// Menentukan dashboard yang tepat berdasarkan user type
  void _redirectToDashboard(String userType) async {
    await Future.delayed(const Duration(milliseconds: 100));
    
    if (!mounted) return;
    
    print('Redirecting with userType: $userType');
    
    String routeName;
    
    // ============================================================
    // LOGIKA REDIRECT YANG DIPERBAIKI
    // ============================================================
    
    // 1. ADMIN - redirect ke admin dashboard
    if (userType == 'Admin' || userType == 'Super_Admin') {
      routeName = '/admin';
    }
    // 2. KEPALA SEKOLAH & WAKIL KEPALA - redirect ke wakepsek dashboard
    else if (userType == 'Kepala_Sekolah' || userType == 'Wakil_Kepala') {
      routeName = '/wakepsek';
    }
    // 3. GURU RESPONDER (BK, Humas, Kurikulum, Kesiswaan, Sarana) - redirect ke guru dashboard
    else if (userType == 'Guru_BK' || 
             userType == 'Guru_Humas' || 
             userType == 'Guru_Kurikulum' || 
             userType == 'Guru_Kesiswaan' || 
             userType == 'Guru_Sarana') {
      routeName = '/guru';
    }
    // 4. GURU UMUM (guru001, guru002, dll) - redirect ke send_message_screen
    else if (userType == 'Guru') {
      routeName = '/send_message';
    }
    // 5. SISWA (siswa001, siswa002, dll) - redirect ke send_message_screen
    else if (userType == 'Siswa') {
      routeName = '/send_message';
    }
    // 6. ORANG TUA (orang_tua001, dll) - redirect ke send_message_screen
    else if (userType == 'Orang_Tua') {
      routeName = '/send_message';
    }
    // 7. FALLBACK - redirect ke send_message_screen untuk user umum lainnya
    else {
      // Untuk semua user type yang tidak dikenali, redirect ke send_message_screen
      print('Unknown user type: $userType, redirecting to send_message_screen');
      routeName = '/send_message';
    }
    
    print('Redirecting to: $routeName (userType: $userType)');
    
    // Eksekusi redirect
    Navigator.pushReplacementNamed(context, routeName);
  }

  @override
  Widget build(BuildContext context) {
    // Membungkus dengan WindowResizerShortcut
    return WindowResizerShortcut(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Login'),
          backgroundColor: const Color(0xFF0B4D8A),
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            TextButton.icon(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/landing');
              },
              icon: const Icon(Icons.home, size: 18),
              label: const Text('Beranda', style: TextStyle(fontSize: 13)),
              style: TextButton.styleFrom(foregroundColor: Colors.white),
            ),
            // Tombol untuk membuka window resizer
            IconButton(
              icon: const Icon(Icons.aspect_ratio),
              onPressed: () => WindowResizerExtension.showResizerPanel(context),
              tooltip: 'Ubah Ukuran Window (F2)',
            ),
          ],
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0B4D8A), Color(0xFF1A6FB0)],
            ),
          ),
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0B4D8A).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.message,
                          size: 48,
                          color: Color(0xFF0B4D8A),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'SMKN 12 Jakarta',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const Text(
                        'Responsive Message App',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 32),
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _usernameController,
                              decoration: const InputDecoration(
                                labelText: 'Username / Email',
                                prefixIcon: Icon(Icons.person),
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Username tidak boleh kosong';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                prefixIcon: const Icon(Icons.lock),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                                border: const OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Password tidak boleh kosong';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0B4D8A),
                            foregroundColor: Colors.white, // ✅ Perbaikan: Warna teks menjadi putih
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Login',
                                  style: TextStyle(fontSize: 16, color: Colors.white), // ✅ Tambahan: Pastikan warna putih
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.pushReplacementNamed(context, '/landing');
                        },
                        icon: const Icon(Icons.arrow_back, size: 16),
                        label: const Text('Kembali ke Beranda'),
                        style: TextButton.styleFrom(foregroundColor: const Color(0xFF0B4D8A)),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'Akun Demo:',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '👑 Admin: admin / password\n'
                              '🎓 Kepala Sekolah: kepsek / password\n'
                              '📚 Guru BK: gurubk / password\n'
                              '🔧 Guru Sarana: sarana / password\n'
                              '👨‍🏫 Guru Umum: guru001 / password\n'
                              '👨‍🎓 Siswa: siswa001 / password\n'
                              '👪 Orang Tua: orangtua001 / password',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}