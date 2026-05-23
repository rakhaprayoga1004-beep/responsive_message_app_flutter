// lib/screen/admin/add_user_screen.dart
import 'package:flutter/material.dart';
import '../../services/user_service.dart';
import '../../utils/helpers.dart';
import '../../utils/user_types.dart'; // Import utility
import '../../widgets/loading_widget.dart';

class AddUserScreen extends StatefulWidget {
  const AddUserScreen({super.key});

  @override
  State<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final UserService _userService = UserService();
  
  final _namaController = TextEditingController();
  final _nisNipController = TextEditingController();
  final _emailController = TextEditingController();
  final _noTelpController = TextEditingController();
  final _passwordController = TextEditingController();
  
  String _selectedUserType = 'Guru';
  String _selectedStatus = 'aktif';
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  
  // Gunakan dari UserTypes
  final List<String> _userTypes = UserTypes.allTypes;
  final List<String> _statuses = ['aktif', 'nonaktif', 'pending'];

  @override
  void dispose() {
    _namaController.dispose();
    _nisNipController.dispose();
    _emailController.dispose();
    _noTelpController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _saveUser() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userData = {
        'nama_lengkap': _namaController.text.trim(),
        'nis_nip': _nisNipController.text.trim().isEmpty 
            ? null 
            : _nisNipController.text.trim(),
        'email': _emailController.text.trim(),
        'no_telp': _noTelpController.text.trim().isEmpty 
            ? null 
            : _noTelpController.text.trim(),
        'password': _passwordController.text.trim(),
        'user_type': _selectedUserType,
        'status': _selectedStatus,
      };

      await _userService.createUser(userData);
      
      if (mounted) {
        Helpers.showToast(context, 'User berhasil ditambahkan');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        Helpers.showToast(context, 'Gagal menambahkan user: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: _isLoading,
      message: 'Menyimpan user...',
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Tambah User Baru'),
          backgroundColor: const Color(0xFF0B4D8A),
          foregroundColor: Colors.white,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Informasi Akun',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Divider(height: 24),
                        
                        // Nama Lengkap
                        TextFormField(
                          controller: _namaController,
                          decoration: const InputDecoration(
                            labelText: 'Nama Lengkap *',
                            prefixIcon: Icon(Icons.person),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Nama lengkap harus diisi';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // NIS/NIP
                        TextFormField(
                          controller: _nisNipController,
                          decoration: const InputDecoration(
                            labelText: 'NIS/NIP',
                            prefixIcon: Icon(Icons.badge),
                            border: OutlineInputBorder(),
                            helperText: 'Kosongkan jika tidak ada',
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Email
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email *',
                            prefixIcon: Icon(Icons.email),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Email harus diisi';
                            }
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                .hasMatch(value)) {
                              return 'Format email tidak valid';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // No Telepon
                        TextFormField(
                          controller: _noTelpController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'No. Telepon',
                            prefixIcon: Icon(Icons.phone),
                            border: OutlineInputBorder(),
                            helperText: 'Kosongkan jika tidak ada',
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Password
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Password *',
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility
                                    : Icons.visibility_off,
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
                              return 'Password harus diisi';
                            }
                            if (value.length < 6) {
                              return 'Password minimal 6 karakter';
                            }
                            return null;
                          },
                        ),
                        
                        const SizedBox(height: 24),
                        
                        const Text(
                          'Pengaturan',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Divider(height: 24),
                        
                        // Tipe User
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
						    setState(() {
						      _selectedUserType = value!;
						    });
						  },
						),
                        const SizedBox(height: 16),
                        
                        // Status
                        DropdownButtonFormField<String>(
                          value: _selectedStatus,
                          decoration: const InputDecoration(
                            labelText: 'Status *',
                            prefixIcon: Icon(Icons.check_circle),
                            border: OutlineInputBorder(),
                          ),
                          items: _statuses.map((status) {
                            return DropdownMenuItem(
                              value: status,
                              child: Row(
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(status),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(status),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedStatus = value!;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Tombol Simpan
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveUser,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Simpan User',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'aktif':
        return Colors.green;
      case 'nonaktif':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}