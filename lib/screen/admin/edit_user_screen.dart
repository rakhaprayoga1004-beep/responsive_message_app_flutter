// lib/screen/admin/edit_user_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/auth_service.dart';
import '../../utils/helpers.dart';
import '../../utils/constants.dart';
import '../../widgets/loading_widget.dart';
import '../../utils/user_types.dart';
import '../../widgets/window_resizer_shortcut.dart';

class EditUserScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const EditUserScreen({super.key, required this.userData});
  
  @override
  State<EditUserScreen> createState() => _EditUserScreenState();
}

class _EditUserScreenState extends State<EditUserScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  late TextEditingController _namaController;
  late TextEditingController _nisNipController;
  late TextEditingController _emailController;
  late TextEditingController _noTelpController;
  late TextEditingController _usernameController;
  
  // Password generator
  final TextEditingController _genUsernameController = TextEditingController();
  final TextEditingController _genPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _showPasswordField = false;
  
  // Password generator result
  String? _generatedPassword;
  String? _generatedHash;
  String? _generatedUsername;
  bool _showGeneratedResult = false;
  
  // Password history
  List<Map<String, dynamic>> _passwordHistory = [];
  bool _isLoadingHistory = false;
  
  // Form fields
  String _selectedUserType = 'Guru';
  String _selectedPrivilegeLevel = '';
  String _selectedKelas = '';
  String _selectedJurusan = '';
  String _selectedMataPelajaran = '';
  
  bool _isActive = true;
  bool _isLoading = false;
  bool _isSaving = false;
  
  // Validation status
  bool _isEmailAvailable = true;
  bool _isUsernameAvailable = true;
  String? _emailStatusMessage;
  String? _usernameStatusMessage;
  
  // Config untuk notifikasi
  Map<String, dynamic> _mailerConfig = {};
  Map<String, dynamic> _fonnteConfig = {};
  
  // User data awal untuk tracking perubahan
  Map<String, dynamic> _originalData = {};
  Map<String, dynamic> _changes = {};

  final List<String> _userTypes = UserTypes.allTypes;
  
  final List<String> _classes = ['X', 'XI', 'XII'];
  
  final List<String> _majors = [
    'Teknik Komputer dan Jaringan', 'Rekayasa Perangkat Lunak', 'Multimedia',
    'Teknik Elektronika', 'Teknik Mesin', 'Teknik Kendaraan Ringan',
    'Akuntansi', 'Pemasaran', 'Perhotelan'
  ];
  
  final List<String> _subjects = [
    'Matematika', 'Bahasa Indonesia', 'Bahasa Inggris', 'IPA', 'IPS',
    'PKN', 'Seni Budaya', 'PJOK', 'Agama', 'Bimbingan Konseling',
    'Kurikulum', 'Hubungan Masyarakat', 'Kesiswaan', 'Sarana Prasarana'
  ];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadConfig();
    _loadPasswordHistory();
    _trackOriginalData();
  }

  void _initializeControllers() {
    _namaController = TextEditingController(text: widget.userData['nama_lengkap'] ?? '');
    _nisNipController = TextEditingController(text: widget.userData['nis_nip'] ?? '');
    _emailController = TextEditingController(text: widget.userData['email'] ?? '');
    _noTelpController = TextEditingController(text: widget.userData['phone_number'] ?? '');
    _usernameController = TextEditingController(text: widget.userData['username'] ?? '');
    _genUsernameController.text = widget.userData['username'] ?? '';
    
    _selectedUserType = widget.userData['user_type'] ?? 'Guru';
    _selectedPrivilegeLevel = widget.userData['privilege_level'] ?? '';
    _selectedKelas = widget.userData['kelas'] ?? '';
    _selectedJurusan = widget.userData['jurusan'] ?? '';
    _selectedMataPelajaran = widget.userData['mata_pelajaran'] ?? '';
    _isActive = widget.userData['is_active'] == 1;
  }

  Future<void> _loadConfig() async {
    try {
      final token = await AuthService.getToken();
      
      final mailerResponse = await http.get(
        Uri.parse('${Constants.baseUrl}/api/config/mailersend.php'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (mailerResponse.statusCode == 200) {
        final data = jsonDecode(mailerResponse.body);
        if (data['success'] == true) {
          _mailerConfig = data['data'] ?? {};
        }
      }
      
      final fonnteResponse = await http.get(
        Uri.parse('${Constants.baseUrl}/api/config/fonnte.php'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (fonnteResponse.statusCode == 200) {
        final data = jsonDecode(fonnteResponse.body);
        if (data['success'] == true) {
          _fonnteConfig = data['data'] ?? {};
        }
      }
    } catch (e) {
      print('Error loading config: $e');
    }
    setState(() {});
  }

  Future<void> _loadPasswordHistory() async {
    setState(() => _isLoadingHistory = true);
    
    try {
      final token = await AuthService.getToken();
      
      final response = await http.post(
        Uri.parse('${Constants.baseUrl}/api/admin/get_password_history.php'),
        headers: {'Authorization': 'Bearer $token'},
        body: {'user_id': widget.userData['id'].toString()},
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            _passwordHistory = List<Map<String, dynamic>>.from(data['history'] ?? []);
          });
        }
      }
    } catch (e) {
      print('Error loading password history: $e');
    } finally {
      setState(() => _isLoadingHistory = false);
    }
  }

  void _trackOriginalData() {
    _originalData = {
      'username': widget.userData['username'] ?? '',
      'email': widget.userData['email'] ?? '',
      'phone_number': widget.userData['phone_number'] ?? '',
    };
  }

  Future<void> _generatePassword() async {
    final username = _genUsernameController.text.trim();
    final password = _genPasswordController.text.trim();
    
    if (username.isEmpty) {
      Helpers.showToast(context, 'Username harus diisi!');
      return;
    }
    
    if (password.isEmpty) {
      Helpers.showToast(context, 'Password baru harus diisi!');
      return;
    }
    
    if (password.length < 8) {
      Helpers.showToast(context, 'Password minimal 8 karakter!');
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      final token = await AuthService.getToken();
      
      final response = await http.post(
        Uri.parse('${Constants.baseUrl}/api/admin/generate_password.php'),
        headers: {'Authorization': 'Bearer $token'},
        body: {
          'username': username,
          'password_asli': password,
          'user_id': widget.userData['id'].toString(),
        },
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            _generatedUsername = data['username'];
            _generatedPassword = data['password_asli'];
            _generatedHash = data['password_hash'];
            _showGeneratedResult = true;
          });
          
          _loadPasswordHistory();
          
          Helpers.showToast(context, 'Password berhasil digenerate!');
        } else {
          Helpers.showToast(context, data['error'] ?? 'Gagal generate password');
        }
      }
    } catch (e) {
      Helpers.showToast(context, 'Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _useGeneratedPassword() {
    if (_generatedPassword != null && _generatedHash != null) {
      _changes['password'] = _generatedPassword;
      _changes['password_hash'] = _generatedHash;
      
      setState(() {
        _showGeneratedResult = false;
        _showPasswordField = true;
      });
      
      Helpers.showToast(context, 'Password siap digunakan. Simpan perubahan untuk mengaktifkan.');
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    Helpers.showToast(context, 'Berhasil disalin ke clipboard');
  }

  Future<void> _checkEmail(String email) async {
    if (email.isEmpty) return;
    
    try {
      final token = await AuthService.getToken();
      
      final response = await http.post(
        Uri.parse('${Constants.baseUrl}/api/admin/check_email.php'),
        headers: {'Authorization': 'Bearer $token'},
        body: {
          'email': email,
          'user_id': widget.userData['id'].toString(),
        },
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          if (data['exists'] == true) {
            _isEmailAvailable = false;
            _emailStatusMessage = data['message'] ?? 'Email sudah terdaftar';
          } else {
            _isEmailAvailable = true;
            _emailStatusMessage = 'Email tersedia';
          }
        });
      }
    } catch (e) {
      print('Error checking email: $e');
    }
  }

  Future<void> _checkUsername(String username) async {
    if (username.isEmpty) return;
    
    try {
      final token = await AuthService.getToken();
      
      final response = await http.post(
        Uri.parse('${Constants.baseUrl}/api/admin/check_username.php'),
        headers: {'Authorization': 'Bearer $token'},
        body: {
          'username': username,
          'user_id': widget.userData['id'].toString(),
        },
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          if (data['exists'] == true) {
            _isUsernameAvailable = false;
            _usernameStatusMessage = 'Username sudah terdaftar';
          } else {
            _isUsernameAvailable = true;
            _usernameStatusMessage = 'Username tersedia';
          }
        });
      }
    } catch (e) {
      print('Error checking username: $e');
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    
    final Map<String, dynamic> updateData = {};
    final List<String> changedFields = [];
    
    if (_namaController.text.trim() != widget.userData['nama_lengkap']) {
      updateData['nama_lengkap'] = _namaController.text.trim();
      changedFields.add('Nama Lengkap');
    }
    
    if (_usernameController.text.trim() != (widget.userData['username'] ?? '')) {
      if (!_isUsernameAvailable) {
        Helpers.showToast(context, 'Username tidak tersedia!');
        return;
      }
      updateData['username'] = _usernameController.text.trim();
      changedFields.add('Username');
    }
    
    if (_emailController.text.trim() != widget.userData['email']) {
      if (!_isEmailAvailable) {
        Helpers.showToast(context, 'Email tidak tersedia!');
        return;
      }
      updateData['email'] = _emailController.text.trim();
      changedFields.add('Email');
    }
    
    if (_noTelpController.text.trim() != (widget.userData['phone_number'] ?? '')) {
      updateData['phone_number'] = _noTelpController.text.trim();
      changedFields.add('Nomor Telepon');
    }
    
    if (_nisNipController.text.trim() != (widget.userData['nis_nip'] ?? '')) {
      updateData['nis_nip'] = _nisNipController.text.trim().isEmpty ? null : _nisNipController.text.trim();
      changedFields.add('NIS/NIP');
    }
    
    if (_selectedUserType != widget.userData['user_type']) {
      updateData['user_type'] = _selectedUserType;
      changedFields.add('Tipe User');
    }
    
    if (_selectedPrivilegeLevel != (widget.userData['privilege_level'] ?? '')) {
      updateData['privilege_level'] = _selectedPrivilegeLevel.isEmpty ? null : _selectedPrivilegeLevel;
      changedFields.add('Level Privilege');
    }
    
    if (_selectedKelas != (widget.userData['kelas'] ?? '')) {
      updateData['kelas'] = _selectedKelas.isEmpty ? null : _selectedKelas;
      changedFields.add('Kelas');
    }
    
    if (_selectedJurusan != (widget.userData['jurusan'] ?? '')) {
      updateData['jurusan'] = _selectedJurusan.isEmpty ? null : _selectedJurusan;
      changedFields.add('Jurusan');
    }
    
    if (_selectedMataPelajaran != (widget.userData['mata_pelajaran'] ?? '')) {
      updateData['mata_pelajaran'] = _selectedMataPelajaran.isEmpty ? null : _selectedMataPelajaran;
      changedFields.add('Mata Pelajaran');
    }
    
    if (_isActive != (widget.userData['is_active'] == 1)) {
      updateData['is_active'] = _isActive ? 1 : 0;
      changedFields.add('Status Akun');
    }
    
    if (_changes.containsKey('password_hash')) {
      updateData['password_hash'] = _changes['password_hash'];
      updateData['password_asli'] = _changes['password'];
      changedFields.add('Password');
    }
    
    if (updateData.isEmpty) {
      Helpers.showToast(context, 'Tidak ada perubahan yang dilakukan');
      return;
    }
    
    setState(() => _isSaving = true);
    
    try {
      final token = await AuthService.getToken();
      final url = Uri.parse('${Constants.baseUrl}/api/admin/users.php');
      
      updateData['id'] = widget.userData['id'];
      
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(updateData),
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['success'] == true) {
          String successMessage = 'User berhasil diperbarui.';
          
          if (mounted) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => AlertDialog(
                title: const Icon(Icons.check_circle, color: Colors.green, size: 48),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Berhasil!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(successMessage),
                    if (changedFields.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Perubahan yang dilakukan:', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 8,
                              children: changedFields.map((field) => Chip(
                                label: Text(field),
                                backgroundColor: Colors.blue[50],
                              )).toList(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context, true);
                    },
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          }
        } else {
          Helpers.showToast(context, result['message'] ?? 'Gagal mengupdate user');
        }
      } else {
        Helpers.showToast(context, 'Server error: ${response.statusCode}', isError: true);
      }
    } catch (e) {
      Helpers.showToast(context, 'Error: $e', isError: true);
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteUser() async {
    final confirm = await Helpers.showConfirmationDialog(
      context,
      title: 'Konfirmasi Hapus',
      message: 'Apakah Anda yakin ingin menghapus user "${widget.userData['nama_lengkap']}"?\n\nTindakan ini tidak dapat dibatalkan!',
      confirmText: 'Hapus',
      confirmColor: Colors.red,
    );
    
    if (confirm) {
      setState(() => _isSaving = true);
      try {
        final token = await AuthService.getToken();
        final url = Uri.parse('${Constants.baseUrl}/api/admin/users.php');
        
        final response = await http.delete(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: json.encode({'id': widget.userData['id']}),
        ).timeout(const Duration(seconds: 30));
        
        if (response.statusCode == 200) {
          final result = json.decode(response.body);
          if (result['success'] == true) {
            Helpers.showToast(context, 'User berhasil dihapus');
            if (mounted) {
              Navigator.pop(context, true);
            }
          } else {
            Helpers.showToast(context, result['message'] ?? 'Gagal menghapus user');
          }
        } else {
          Helpers.showToast(context, 'Server error: ${response.statusCode}', isError: true);
        }
      } catch (e) {
        Helpers.showToast(context, 'Error: $e', isError: true);
      } finally {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WindowResizerShortcut(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Edit User'),
          backgroundColor: const Color(0xFF0B4D8A),
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.aspect_ratio),
              onPressed: () => WindowResizerExtension.showResizerPanel(context),
              tooltip: 'Ubah Ukuran Window (F2)',
            ),
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _isSaving ? null : _saveChanges,
              tooltip: 'Simpan',
            ),
          ],
        ),
        body: _isSaving
            ? const LoadingWidget(message: 'Menyimpan perubahan...')
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Info Notifikasi Config
                    if (_mailerConfig.isNotEmpty || _fonnteConfig.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.settings, color: Colors.blue),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '⚙️ Konfigurasi Notifikasi',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                  const SizedBox(height: 4),
                                  Wrap(
                                    spacing: 8,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                                          ),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Text(
                                          'MailerSend',
                                          style: TextStyle(color: Colors.white, fontSize: 10),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [Color(0xFF25D366), Color(0xFF128C7E)],
                                          ),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Text(
                                          'Fonnte',
                                          style: TextStyle(color: Colors.white, fontSize: 10),
                                        ),
                                      ),
                                      Text(
                                        'Email: ${_mailerConfig['is_active'] == 1 ? 'Aktif' : 'Nonaktif'}',
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                      Text(
                                        'WA: ${_fonnteConfig['is_active'] == 1 ? 'Aktif' : 'Nonaktif'}',
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    // Password Generator Panel
                    Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: const BoxDecoration(
                              color: Color(0xFF0B4D8A),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(12),
                                topRight: Radius.circular(12),
                              ),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.key, color: Colors.white),
                                SizedBox(width: 8),
                                Text(
                                  'Fitur Ubah Password User',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      flex: 5,
                                      child: TextFormField(
                                        controller: _genUsernameController,
                                        readOnly: true,
                                        decoration: const InputDecoration(
                                          labelText: 'Username',
                                          prefixIcon: Icon(Icons.person),
                                          border: OutlineInputBorder(),
                                          helperText: 'Username user (tidak dapat diubah di sini)',
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      flex: 5,
                                      child: TextFormField(
                                        controller: _genPasswordController,
                                        obscureText: _obscurePassword,
                                        decoration: InputDecoration(
                                          labelText: 'Password Baru',
                                          prefixIcon: const Icon(Icons.lock),
                                          suffixIcon: IconButton(
                                            icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                          ),
                                          border: const OutlineInputBorder(),
                                          helperText: 'Password baru yang akan diberikan ke user',
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      flex: 2,
                                      child: ElevatedButton(
                                        onPressed: _isLoading ? null : _generatePassword,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          padding: const EdgeInsets.symmetric(vertical: 16),
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
                                            : const Text('Generate'),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[50],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.info, color: Colors.blue),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Password hash akan otomatis tergenerate dan disimpan ke log untuk backup. '
                                          'Password asli akan dikirim ke user via MailerSend dan Fonnte jika ada perubahan.',
                                          style: TextStyle(fontSize: 12),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                
                                if (_showGeneratedResult && _generatedPassword != null) ...[
                                  const SizedBox(height: 16),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.green[50],
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.green[200]!),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Row(
                                          children: [
                                            Icon(Icons.check_circle, color: Colors.green),
                                            SizedBox(width: 8),
                                            Text(
                                              'Password Berhasil Digenerate:',
                                              style: TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Wrap(
                                          spacing: 16,
                                          runSpacing: 8,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.grey[200],
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text('Username: $_generatedUsername'),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.grey[200],
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text('Password: $_generatedPassword'),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.grey[200],
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text('Hash: ${_generatedHash?.substring(0, 20)}...'),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            ElevatedButton.icon(
                                              onPressed: _useGeneratedPassword,
                                              icon: const Icon(Icons.arrow_downward),
                                              label: const Text('Gunakan Password Ini'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.green,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            OutlinedButton.icon(
                                              onPressed: () {
                                                if (_generatedHash != null) {
                                                  _copyToClipboard(_generatedHash!);
                                                }
                                              },
                                              icon: const Icon(Icons.copy),
                                              label: const Text('Copy Hash'),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                
                                const SizedBox(height: 16),
                                Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey[300]!),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.history, size: 16),
                                            const SizedBox(width: 8),
                                            const Text(
                                              'History Password Terbaru',
                                              style: TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                            const Spacer(),
                                            IconButton(
                                              icon: const Icon(Icons.refresh, size: 16),
                                              onPressed: _loadPasswordHistory,
                                              tooltip: 'Refresh',
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Divider(height: 1),
                                      Container(
                                        constraints: const BoxConstraints(maxHeight: 200),
                                        child: _isLoadingHistory
                                            ? const Center(
                                                child: Padding(
                                                  padding: EdgeInsets.all(20),
                                                  child: CircularProgressIndicator(),
                                                ),
                                              )
                                            : _passwordHistory.isEmpty
                                                ? const Center(
                                                    child: Padding(
                                                      padding: EdgeInsets.all(20),
                                                      child: Text('Belum ada history password'),
                                                    ),
                                                  )
                                                : ListView.builder(
                                                    shrinkWrap: true,
                                                    itemCount: _passwordHistory.length,
                                                    itemBuilder: (context, index) {
                                                      final item = _passwordHistory[index];
                                                      return Container(
                                                        padding: const EdgeInsets.all(8),
                                                        decoration: BoxDecoration(
                                                          border: Border(
                                                            bottom: BorderSide(
                                                              color: Colors.grey[200]!,
                                                            ),
                                                          ),
                                                        ),
                                                        child: Column(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                            Text(
                                                              item['timestamp'] ?? '',
                                                              style: const TextStyle(
                                                                fontSize: 10,
                                                                color: Colors.grey,
                                                              ),
                                                            ),
                                                            const SizedBox(height: 4),
                                                            Text('Username: ${item['username'] ?? ''}'),
                                                            Text('Password: ${item['password_asli'] ?? ''}'),
                                                            Text(
                                                              'Hash: ${(item['password_hash'] ?? '').substring(0, 30)}...',
                                                              style: const TextStyle(fontSize: 11),
                                                            ),
                                                          ],
                                                        ),
                                                      );
                                                    },
                                                  ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Edit User Form
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Informasi Dasar',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const Divider(),
                              
                              TextFormField(
                                controller: _usernameController,
                                decoration: InputDecoration(
                                  labelText: 'Username *',
                                  prefixIcon: const Icon(Icons.person),
                                  border: const OutlineInputBorder(),
                                  suffixIcon: IconButton(
                                    icon: const Icon(Icons.check),
                                    onPressed: () => _checkUsername(_usernameController.text.trim()),
                                  ),
                                  helperText: 'Untuk login. Perubahan akan dinotifikasikan ke user.',
                                  errorText: _isUsernameAvailable ? null : _usernameStatusMessage,
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) return 'Username harus diisi';
                                  if (!RegExp(r'^[a-zA-Z0-9._-]{3,50}$').hasMatch(value)) {
                                    return 'Username hanya boleh berisi huruf, angka, titik, underscore, dan dash (3-50 karakter)';
                                  }
                                  return null;
                                },
                                onChanged: (value) => _checkUsername(value.trim()),
                              ),
                              const SizedBox(height: 16),
                              
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                  labelText: 'Email *',
                                  prefixIcon: const Icon(Icons.email),
                                  border: const OutlineInputBorder(),
                                  suffixIcon: IconButton(
                                    icon: const Icon(Icons.check),
                                    onPressed: () => _checkEmail(_emailController.text.trim()),
                                  ),
                                  helperText: 'MailerSend Perubahan akan dinotifikasikan ke email ini.',
                                  errorText: _isEmailAvailable ? null : _emailStatusMessage,
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) return 'Email harus diisi';
                                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                    return 'Format email tidak valid';
                                  }
                                  return null;
                                },
                                onChanged: (value) => _checkEmail(value.trim()),
                              ),
                              const SizedBox(height: 16),
                              
                              TextFormField(
                                controller: _namaController,
                                decoration: const InputDecoration(
                                  labelText: 'Nama Lengkap *',
                                  prefixIcon: Icon(Icons.badge),
                                  border: OutlineInputBorder(),
                                  helperText: 'Nama lengkap harus 3-100 karakter',
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) return 'Nama lengkap harus diisi';
                                  if (value.length < 3) return 'Nama lengkap minimal 3 karakter';
                                  if (value.length > 100) return 'Nama lengkap maksimal 100 karakter';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              
                              TextFormField(
                                controller: _nisNipController,
                                decoration: const InputDecoration(
                                  labelText: 'NIS / NIP',
                                  prefixIcon: Icon(Icons.badge),
                                  border: OutlineInputBorder(),
                                  helperText: 'Nomor Induk Siswa / Nomor Induk Pegawai',
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              TextFormField(
                                controller: _noTelpController,
                                keyboardType: TextInputType.phone,
                                decoration: const InputDecoration(
                                  labelText: 'Nomor Telepon',
                                  prefixIcon: Icon(Icons.phone),
                                  border: OutlineInputBorder(),
                                  helperText: 'Fonnte Perubahan akan dinotifikasikan ke nomor ini.',
                                ),
                                validator: (value) {
                                  if (value != null && value.isNotEmpty) {
                                    if (!RegExp(r'^[0-9+\-\s()]{10,20}$').hasMatch(value)) {
                                      return 'Format nomor telepon tidak valid';
                                    }
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 24),
                              
                              const Text(
                                'Pengaturan Akun',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const Divider(),
                              
                              DropdownButtonFormField<String>(
                                value: _userTypes.contains(_selectedUserType) ? _selectedUserType : null,
                                decoration: const InputDecoration(
                                  labelText: 'Tipe User *',
                                  prefixIcon: Icon(Icons.category),
                                  border: OutlineInputBorder(),
                                ),
                                items: _userTypes.map((type) {
                                  return DropdownMenuItem(
                                    value: type,
                                    child: Text(type.replaceAll('_', ' ')),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() => _selectedUserType = value!);
                                },
                              ),
                              const SizedBox(height: 16),
                              
                              // Privilege Level Dropdown
                              DropdownButtonFormField<String>(
                                value: UserTypes.privilegeLevels.contains(_selectedPrivilegeLevel) 
                                    ? _selectedPrivilegeLevel 
                                    : 'Standard',
                                decoration: const InputDecoration(
                                  labelText: 'Level Privilege',
                                  prefixIcon: Icon(Icons.security),
                                  border: OutlineInputBorder(),
                                ),
                                items: UserTypes.privilegeLevels.map((level) {
                                  return DropdownMenuItem(
                                    value: level,
                                    child: Text(UserTypes.getPrivilegeDisplay(level)),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() => _selectedPrivilegeLevel = value ?? '');
                                },
                              ),
                              const SizedBox(height: 16),
                              
                              if (_selectedUserType == 'Siswa') ...[
                                const Text('Data Akademik', style: TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<String>(
                                  value: _selectedKelas.isEmpty ? null : _selectedKelas,
                                  decoration: const InputDecoration(
                                    labelText: 'Kelas',
                                    border: OutlineInputBorder(),
                                  ),
                                  items: _classes.map((kelas) {
                                    return DropdownMenuItem(
                                      value: kelas,
                                      child: Text('Kelas $kelas'),
                                    );
                                  }).toList(),
                                  onChanged: (value) => setState(() => _selectedKelas = value ?? ''),
                                ),
                                const SizedBox(height: 12),
                                DropdownButtonFormField<String>(
                                  value: _selectedJurusan.isEmpty ? null : _selectedJurusan,
                                  decoration: const InputDecoration(
                                    labelText: 'Jurusan',
                                    border: OutlineInputBorder(),
                                  ),
                                  items: _majors.map((jurusan) {
                                    return DropdownMenuItem(
                                      value: jurusan,
                                      child: Text(jurusan.length > 30 ? '${jurusan.substring(0, 27)}...' : jurusan),
                                    );
                                  }).toList(),
                                  onChanged: (value) => setState(() => _selectedJurusan = value ?? ''),
                                ),
                              ],
                              
                              if (_selectedUserType.startsWith('Guru') || 
                                  _selectedUserType == 'Admin' ||
                                  _selectedUserType == 'Wakil_Kepala' ||
                                  _selectedUserType == 'Kepala_Sekolah') ...[
                                const Text('Bidang / Mata Pelajaran', style: TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<String>(
                                  value: _selectedMataPelajaran.isEmpty ? null : _selectedMataPelajaran,
                                  decoration: const InputDecoration(
                                    labelText: 'Mata Pelajaran / Bidang',
                                    border: OutlineInputBorder(),
                                  ),
                                  items: _subjects.map((subject) {
                                    return DropdownMenuItem(
                                      value: subject,
                                      child: Text(subject),
                                    );
                                  }).toList(),
                                  onChanged: (value) => setState(() => _selectedMataPelajaran = value ?? ''),
                                ),
                              ],
                              
                              const SizedBox(height: 16),
                              
                              SwitchListTile(
                                title: const Text('Akun Aktif'),
                                subtitle: const Text('Nonaktifkan untuk menonaktifkan akun user tanpa menghapus datanya'),
                                value: _isActive,
                                onChanged: (value) => setState(() => _isActive = value),
                                activeColor: Colors.green,
                                contentPadding: EdgeInsets.zero,
                              ),
                              
                              const SizedBox(height: 24),
                              
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.orange[50],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.orange[200]!),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      '📋 Informasi Penting',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      '• Gunakan fitur Ubah Password User di atas jika ingin mengganti password\n'
                                      '• Password asli akan dikirim ke user via MailerSend (Email) dan Fonnte (WhatsApp) jika ada perubahan\n'
                                      '• Password hash akan disimpan di database dan log untuk backup\n'
                                      '• Semua perubahan dicatat dalam log dengan timestamp lengkap\n'
                                      '• Untuk Siswa: wajib mengisi Kelas dan Jurusan\n'
                                      '• Untuk Guru: wajib mengisi Mata Pelajaran\n'
                                      '• ⚙️ Konfigurasi notifikasi dikelola melalui Admin → Settings',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              
                              const SizedBox(height: 24),
                              
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () => Navigator.pop(context),
                                      icon: const Icon(Icons.arrow_back),
                                      label: const Text('Batal'),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: _saveChanges,
                                      icon: const Icon(Icons.save),
                                      label: const Text('Simpan Perubahan'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: _deleteUser,
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      label: const Text('Hapus User'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.red,
                                        side: const BorderSide(color: Colors.red),
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 16),
                              
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.info, size: 16, color: Colors.grey),
                                        const SizedBox(width: 8),
                                        Text('ID User: #${widget.userData['id']}', style: const TextStyle(fontSize: 12)),
                                        const Spacer(),
                                        Text(
                                          'Bergabung: ${DateFormat('dd MMM yyyy HH:mm', 'id_ID').format(DateTime.parse(widget.userData['created_at'] ?? DateTime.now().toString()))}',
                                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Terakhir Login: ${widget.userData['last_login'] != null 
                                          ? '${DateFormat('dd MMM yyyy HH:mm', 'id_ID').format(DateTime.parse(widget.userData['last_login']))} (${_timeAgo(DateTime.parse(widget.userData['last_login']))})'
                                          : 'Belum pernah login'}',
                                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  String _timeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} tahun lalu';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} bulan lalu';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} hari lalu';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} jam lalu';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} menit lalu';
    } else {
      return 'baru saja';
    }
  }
}