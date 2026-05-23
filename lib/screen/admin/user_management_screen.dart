// lib/screen/admin/user_management_screen.dart - Perbaikan untuk Edit User

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../services/auth_service.dart';
import '../../utils/helpers.dart';
import '../../utils/date_formatter.dart';
import '../../utils/constants.dart';
import '../../widgets/message_detail_dialog.dart';
import '../../widgets/window_resizer_shortcut.dart';
import 'user_detail_screen.dart';
import 'edit_user_screen.dart'; // Import EditUserScreen

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  String _selectedUserType = 'Semua';
  bool _isAddingUser = false;

  final List<String> _userTypes = [
    'Semua', 'Admin', 'Kepala_Sekolah', 'Wakil_Kepala',
    'Guru_BK', 'Guru_Humas', 'Guru_Kurikulum', 'Guru_Kesiswaan', 'Guru_Sarana',
    'Guru', 'Siswa', 'Orang_Tua', 'External'
  ];

  // Form controllers untuk tambah user
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _namaController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _nisNipController = TextEditingController();
  final _kelasController = TextEditingController();
  final _jurusanController = TextEditingController();
  final _mataPelajaranController = TextEditingController();
  String _selectedAddUserType = 'Siswa';
  String _selectedPrivilegeLevel = 'Limited_Access';

  final List<String> _addUserTypes = [
    'Admin', 'Kepala_Sekolah', 'Wakil_Kepala',
    'Guru_BK', 'Guru_Humas', 'Guru_Kurikulum', 'Guru_Kesiswaan', 'Guru_Sarana',
    'Guru', 'Siswa', 'Orang_Tua', 'External'
  ];

  final List<String> _privilegeLevels = [
    'Full_Access', 'Standard_Access', 'Limited_Access'
  ];

  // Password generator
  String _generatedUsername = '';
  String _generatedPassword = '';
  String _generatedPasswordHash = '';
  bool _isGenerating = false;
  List<Map<String, dynamic>> _passwordHistory = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _loadPasswordHistory();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _namaController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _nisNipController.dispose();
    _kelasController.dispose();
    _jurusanController.dispose();
    _mataPelajaranController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final token = await AuthService.getToken();
      final url = Uri.parse('${Constants.baseUrl}/api/admin/users.php');
      
      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };
      
      final response = await http.get(url, headers: headers).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            _users = List<Map<String, dynamic>>.from(data['users']);
            _isLoading = false;
          });
        } else {
          setState(() {
            _error = data['message'] ?? 'Gagal memuat data user';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _error = 'Server error: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadPasswordHistory() async {
    try {
      final token = await AuthService.getToken();
      final url = Uri.parse('${Constants.baseUrl}/api/admin/password_history.php');
      
      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };
      
      final response = await http.get(url, headers: headers).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            _passwordHistory = List<Map<String, dynamic>>.from(data['history']);
          });
        }
      }
    } catch (e) {
      print('Error loading password history: $e');
    }
  }

  Future<void> _generatePassword() async {
    if (_usernameController.text.trim().isEmpty) {
      Helpers.showToast(context, 'Username harus diisi terlebih dahulu', isError: true);
      return;
    }
    
    if (_passwordController.text.isEmpty) {
      Helpers.showToast(context, 'Password harus diisi terlebih dahulu', isError: true);
      return;
    }
    
    setState(() {
      _isGenerating = true;
    });

    try {
      final token = await AuthService.getToken();
      final url = Uri.parse('${Constants.baseUrl}/api/admin/generate_password.php');
      
      final data = {
        'username': _usernameController.text.trim(),
        'password_asli': _passwordController.text,
      };
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(data),
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['success'] == true) {
          setState(() {
            _generatedUsername = result['username'];
            _generatedPassword = result['password_asli'];
            _generatedPasswordHash = result['password_hash'];
          });
          
          await _loadPasswordHistory();
          
          Helpers.showToast(context, 'Password berhasil digenerate!');
        } else {
          Helpers.showToast(context, result['message'] ?? 'Gagal generate password', isError: true);
        }
      } else {
        Helpers.showToast(context, 'Server error: ${response.statusCode}', isError: true);
      }
    } catch (e) {
      Helpers.showToast(context, 'Error: $e', isError: true);
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  Future<void> _addUser() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_passwordController.text != _confirmPasswordController.text) {
      Helpers.showToast(context, 'Password dan konfirmasi password tidak sama', isError: true);
      return;
    }
    
    if (_generatedPasswordHash.isEmpty) {
      Helpers.showToast(context, 'Harap generate password terlebih dahulu menggunakan tombol "Generate Password"', isError: true);
      return;
    }
    
    setState(() {
      _isAddingUser = true;
    });

    try {
      final token = await AuthService.getToken();
      final url = Uri.parse('${Constants.baseUrl}/api/admin/users.php');
      
      final data = {
        'username': _usernameController.text.trim(),
        'password_asli': _passwordController.text,
        'password_hash': _generatedPasswordHash,
        'nama_lengkap': _namaController.text.trim(),
        'user_type': _selectedAddUserType,
        'email': _emailController.text.trim(),
        'phone_number': _phoneController.text.trim(),
        'nis_nip': _nisNipController.text.trim(),
        'kelas': _kelasController.text.trim().isEmpty ? null : _kelasController.text.trim(),
        'jurusan': _jurusanController.text.trim().isEmpty ? null : _jurusanController.text.trim(),
        'mata_pelajaran': _mataPelajaranController.text.trim().isEmpty ? null : _mataPelajaranController.text.trim(),
        'privilege_level': _selectedPrivilegeLevel,
        'is_active': 1,
      };
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(data),
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['success'] == true) {
          Helpers.showToast(context, 'User berhasil ditambahkan${result['notifications_sent'] == true ? ' dan notifikasi terkirim' : ''}');
          Navigator.pop(context);
          _clearAddUserForm();
          _loadUsers();
        } else {
          Helpers.showToast(context, result['message'] ?? 'Gagal menambahkan user', isError: true);
        }
      } else {
        Helpers.showToast(context, 'Server error: ${response.statusCode}', isError: true);
      }
    } catch (e) {
      Helpers.showToast(context, 'Error: $e', isError: true);
    } finally {
      setState(() {
        _isAddingUser = false;
      });
    }
  }

  void _clearAddUserForm() {
    _usernameController.clear();
    _passwordController.clear();
    _confirmPasswordController.clear();
    _namaController.clear();
    _emailController.clear();
    _phoneController.clear();
    _nisNipController.clear();
    _kelasController.clear();
    _jurusanController.clear();
    _mataPelajaranController.clear();
    _selectedAddUserType = 'Siswa';
    _selectedPrivilegeLevel = 'Limited_Access';
    _generatedUsername = '';
    _generatedPassword = '';
    _generatedPasswordHash = '';
  }

  // ============================================================
  // METHOD UNTUK NAVIGASI KE EDIT USER
  // ============================================================
  void _navigateToEditUser(Map<String, dynamic> userData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditUserScreen(userData: userData),
      ),
    ).then((_) => _loadUsers()); // Refresh setelah kembali
  }

  // ============================================================
  // METHOD UNTUK MENAMPILKAN DIALOG DETAIL PESAN
  // ============================================================
  void _showMessageDetailDialog(int messageId) {
    showDialog(
      context: context,
      builder: (context) => MessageDetailDialog(
        messageId: messageId,
        initialData: null,
      ),
    );
  }

  void _showAddUserDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.person_add, color: Color(0xFF0B4D8A)),
                SizedBox(width: 8),
                Text('Tambah User Baru'),
              ],
            ),
            content: SingleChildScrollView(
              child: Container(
                width: 500,
                padding: const EdgeInsets.all(8),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: _usernameController,
                        decoration: const InputDecoration(
                          labelText: 'Username *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                          helperText: 'Username untuk login',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Username harus diisi';
                          if (value.length < 3) return 'Username minimal 3 karakter';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Password Asli *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.lock),
                          helperText: 'Password yang akan diberikan ke user',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Password harus diisi';
                          if (value.length < 6) return 'Password minimal 6 karakter';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Konfirmasi Password *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Konfirmasi password harus diisi';
                          if (value != _passwordController.text) return 'Password tidak sama';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _isGenerating ? null : _generatePassword,
                        icon: _isGenerating
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.calculate),
                        label: const Text('Generate Password Hash'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      if (_generatedPasswordHash.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Column(
                            children: [
                              const Text('✓ Password Hash siap digunakan', style: TextStyle(color: Colors.green)),
                              const SizedBox(height: 4),
                              Text(
                                'Username: $_generatedUsername',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _namaController,
                        decoration: const InputDecoration(
                          labelText: 'Nama Lengkap *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.badge),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Nama lengkap harus diisi';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.email),
                          helperText: 'Notifikasi akan dikirim ke email ini',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Email harus diisi';
                          if (!value.contains('@') || !value.contains('.')) return 'Email tidak valid';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Nomor HP (WhatsApp)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.phone),
                          helperText: 'Notifikasi WhatsApp akan dikirim ke nomor ini',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _nisNipController,
                        decoration: const InputDecoration(
                          labelText: 'NIS/NIP',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.numbers),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _selectedAddUserType,
                        decoration: const InputDecoration(
                          labelText: 'Tipe User *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.category),
                        ),
                        items: _addUserTypes.map((type) {
                          return DropdownMenuItem(value: type, child: Text(type));
                        }).toList(),
                        onChanged: (value) {
                          setStateDialog(() {
                            _selectedAddUserType = value!;
                            if (value == 'Admin') {
                              _selectedPrivilegeLevel = 'Full_Access';
                            } else if (value == 'Guru' || value.contains('Guru')) {
                              _selectedPrivilegeLevel = 'Standard_Access';
                            } else {
                              _selectedPrivilegeLevel = 'Limited_Access';
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _privilegeLevels.contains(_selectedPrivilegeLevel) 
                            ? _selectedPrivilegeLevel 
                            : 'Limited_Access',
                        decoration: const InputDecoration(
                          labelText: 'Privilege Level',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.security),
                        ),
                        items: _privilegeLevels.map((level) {
                          return DropdownMenuItem(value: level, child: Text(level));
                        }).toList(),
                        onChanged: (value) => setStateDialog(() => _selectedPrivilegeLevel = value!),
                      ),
                      if (_selectedAddUserType == 'Siswa') ...[
                        const SizedBox(height: 12),
                        const Divider(),
                        const SizedBox(height: 12),
                        const Text('Informasi Siswa', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _kelasController.text.isEmpty ? null : _kelasController.text,
                          decoration: const InputDecoration(
                            labelText: 'Kelas *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.class_),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'X', child: Text('X')),
                            DropdownMenuItem(value: 'XI', child: Text('XI')),
                            DropdownMenuItem(value: 'XII', child: Text('XII')),
                          ],
                          onChanged: (value) => setStateDialog(() => _kelasController.text = value ?? ''),
                          validator: (value) => value == null || value.isEmpty ? 'Kelas harus diisi' : null,
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _jurusanController.text.isEmpty ? null : _jurusanController.text,
                          decoration: const InputDecoration(
                            labelText: 'Jurusan *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.school),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'IPA', child: Text('IPA')),
                            DropdownMenuItem(value: 'IPS', child: Text('IPS')),
                            DropdownMenuItem(value: 'Bahasa', child: Text('Bahasa')),
                            DropdownMenuItem(value: 'TKJ', child: Text('TKJ')),
                            DropdownMenuItem(value: 'RPL', child: Text('RPL')),
                            DropdownMenuItem(value: 'AKL', child: Text('AKL')),
                            DropdownMenuItem(value: 'OTKP', child: Text('OTKP')),
                            DropdownMenuItem(value: 'BDP', child: Text('BDP')),
                          ],
                          onChanged: (value) => setStateDialog(() => _jurusanController.text = value ?? ''),
                          validator: (value) => value == null || value.isEmpty ? 'Jurusan harus diisi' : null,
                        ),
                      ],
                      if (_selectedAddUserType.contains('Guru')) ...[
                        const SizedBox(height: 12),
                        const Divider(),
                        const SizedBox(height: 12),
                        const Text('Informasi Guru', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _mataPelajaranController,
                          decoration: const InputDecoration(
                            labelText: 'Mata Pelajaran *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.book),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Mata pelajaran harus diisi';
                            return null;
                          },
                        ),
                      ],
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Notifikasi akan dikirim ke email dan WhatsApp user (jika diisi)',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  _clearAddUserForm();
                  Navigator.pop(context);
                },
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: _isAddingUser ? null : _addUser,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0B4D8A),
                  foregroundColor: Colors.white,
                ),
                child: _isAddingUser
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Simpan'),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Map<String, dynamic>> get _filteredUsers {
    return _users.where((user) {
      final matchesSearch = _searchQuery.isEmpty ||
          (user['nama_lengkap']?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
          (user['username']?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
          (user['email']?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      
      final matchesType = _selectedUserType == 'Semua' || user['user_type'] == _selectedUserType;
      
      return matchesSearch && matchesType;
    }).toList();
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

  String _getInfoTambahan(Map<String, dynamic> user) {
    List<String> info = [];
    
    if (user['kelas'] != null && user['kelas'].toString().isNotEmpty) {
      info.add('Kelas: ${user['kelas']}');
    }
    if (user['jurusan'] != null && user['jurusan'].toString().isNotEmpty) {
      info.add('Jurusan: ${user['jurusan']}');
    }
    if (user['mata_pelajaran'] != null && user['mata_pelajaran'].toString().isNotEmpty) {
      info.add('Mata Pelajaran: ${user['mata_pelajaran']}');
    }
    
    return info.isEmpty ? '-' : info.join(' • ');
  }

  @override
  Widget build(BuildContext context) {
    return WindowResizerShortcut(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Manajemen User'),
          backgroundColor: const Color(0xFF0B4D8A),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadUsers,
              tooltip: 'Refresh',
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _showAddUserDialog,
              tooltip: 'Tambah User',
            ),
          ],
        ),
        body: Column(
          children: [
            // Search and Filter
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Cari user...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onChanged: (value) => setState(() => _searchQuery = value),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: DropdownButton<String>(
                      value: _selectedUserType,
                      underline: const SizedBox(),
                      items: _userTypes.map((type) {
                        return DropdownMenuItem(value: type, child: Text(type));
                      }).toList(),
                      onChanged: (value) => setState(() => _selectedUserType = value!),
                    ),
                  ),
                ],
              ),
            ),
            // User List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
                              const SizedBox(height: 16),
                              Text(_error!, textAlign: TextAlign.center),
                              const SizedBox(height: 16),
                              ElevatedButton(onPressed: _loadUsers, child: const Text('Coba Lagi')),
                            ],
                          ),
                        )
                      : _filteredUsers.isEmpty
                          ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.people_outline, size: 60, color: Colors.grey),
                                  SizedBox(height: 16),
                                  Text('Tidak ada user ditemukan'),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(12),
                              itemCount: _filteredUsers.length,
                              itemBuilder: (context, index) {
                                final user = _filteredUsers[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => UserDetailScreen(user: user),
                                        ),
                                      );
                                    },
                                    borderRadius: BorderRadius.circular(12),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              CircleAvatar(
                                                radius: 24,
                                                backgroundColor: _getUserTypeColor(user['user_type']).withOpacity(0.1),
                                                child: Text(
                                                  (user['nama_lengkap']?[0] ?? user['username']?[0] ?? 'U').toUpperCase(),
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: _getUserTypeColor(user['user_type']),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      user['nama_lengkap'] ?? user['username'] ?? 'Unknown',
                                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      '@${user['username']}',
                                                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                                                    ),
                                                    if (user['email'] != null && user['email'].isNotEmpty)
                                                      Text(
                                                        user['email'],
                                                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.end,
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: _getUserTypeColor(user['user_type']).withOpacity(0.1),
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                    child: Text(
                                                      _getDisplayUserType(user['user_type']),
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color: _getUserTypeColor(user['user_type']),
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: (user['is_active'] == 1 ? Colors.green : Colors.red).withOpacity(0.1),
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                    child: Text(
                                                      user['is_active'] == 1 ? 'Aktif' : 'Nonaktif',
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        color: user['is_active'] == 1 ? Colors.green : Colors.red,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Divider(color: Colors.grey.shade200),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.tag, size: 14, color: Colors.grey[500]),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      '#${user['id']}',
                                                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              if (user['phone_number'] != null && user['phone_number'].isNotEmpty)
                                                Expanded(
                                                  child: Row(
                                                    children: [
                                                      Icon(Icons.phone, size: 14, color: Colors.grey[500]),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        user['phone_number'],
                                                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          if (_getInfoTambahan(user) != '-')
                                            Row(
                                              children: [
                                                Icon(Icons.info_outline, size: 14, color: Colors.grey[500]),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    _getInfoTambahan(user),
                                                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.calendar_today, size: 12, color: Colors.grey[500]),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      'Bergabung: ${DateFormatter.formatDateShort(_parseDate(user['created_at']))}',
                                                      style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Expanded(
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.history, size: 12, color: Colors.grey[500]),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      user['last_login'] != null 
                                                          ? 'Login: ${DateFormatter.formatDateTime(_parseDate(user['last_login']))}'
                                                          : 'Belum pernah login',
                                                      style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          // TOMBOL AKSI: Edit User
                                          const SizedBox(height: 8),
                                          Divider(color: Colors.grey.shade200),
                                          const SizedBox(height: 8),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.end,
                                            children: [
                                              TextButton.icon(
                                                onPressed: () => _navigateToEditUser(user),
                                                icon: const Icon(Icons.edit, size: 16, color: Colors.blue),
                                                label: const Text('Edit', style: TextStyle(fontSize: 11)),
                                                style: TextButton.styleFrom(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  minimumSize: Size.zero,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
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