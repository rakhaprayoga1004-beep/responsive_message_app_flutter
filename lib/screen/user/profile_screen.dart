import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import '../../widgets/custom_text_field.dart';
import '../../utils/validators.dart';
import '../../utils/date_formatter.dart';
import '../../widgets/window_resizer_shortcut.dart'; // Import window resizer shortcut
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _nisNipController = TextEditingController();
  final _kelasController = TextEditingController();
  final _jurusanController = TextEditingController();
  final _mapelController = TextEditingController();
  
  bool _isEditing = false;
  bool _isLoading = false;
  String? _error;
  String? _successMessage;
  File? _selectedImage;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _namaController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _nisNipController.dispose();
    _kelasController.dispose();
    _jurusanController.dispose();
    _mapelController.dispose();
    super.dispose();
  }

  void _loadUserData() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.user;
    
    if (user != null) {
      _namaController.text = user.namaLengkap;
      _emailController.text = user.email;
      _phoneController.text = user.phoneNumber ?? '';
      _nisNipController.text = user.nisNip ?? '';
      _kelasController.text = user.kelas ?? '';
      _jurusanController.text = user.jurusan ?? '';
      _mapelController.text = user.mataPelajaran ?? '';
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 500,
        maxHeight: 500,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memilih gambar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _successMessage = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      
      final data = {
        'nama_lengkap': _namaController.text.trim(),
        'email': _emailController.text.trim(),
        'phone_number': _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        'nis_nip': _nisNipController.text.trim().isEmpty
            ? null
            : _nisNipController.text.trim(),
        'kelas': _kelasController.text.trim().isEmpty
            ? null
            : _kelasController.text.trim(),
        'jurusan': _jurusanController.text.trim().isEmpty
            ? null
            : _jurusanController.text.trim(),
        'mata_pelajaran': _mapelController.text.trim().isEmpty
            ? null
            : _mapelController.text.trim(),
      };

      final success = await authService.updateProfile(data);

      if (success) {
        setState(() {
          _successMessage = 'Profil berhasil diperbarui';
          _isEditing = false;
        });
        
        // Clear success message after 3 seconds
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _successMessage = null;
            });
          }
        });
      } else {
        setState(() {
          _error = authService.error;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Logout'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.user;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('User tidak ditemukan')),
      );
    }

    return WindowResizerShortcut(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Profil Saya'),
          backgroundColor: const Color(0xFF0B4D8A),
          actions: [
            if (!_isEditing)
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  setState(() {
                    _isEditing = true;
                  });
                },
                tooltip: 'Edit Profil',
              ),
            if (_isEditing) ...[
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _isEditing = false;
                    _loadUserData();
                  });
                },
                tooltip: 'Batal',
              ),
              IconButton(
                icon: const Icon(Icons.save),
                onPressed: _isLoading ? null : _saveProfile,
                tooltip: 'Simpan',
              ),
            ],
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _logout,
              tooltip: 'Logout',
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Messages
                if (_successMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green[700]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _successMessage!,
                            style: TextStyle(color: Colors.green[700]),
                          ),
                        ),
                      ],
                    ),
                  ),
                
                if (_error != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error, color: Colors.red[700]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _error!,
                            style: TextStyle(color: Colors.red[700]),
                          ),
                        ),
                      ],
                    ),
                  ),
                
                // Avatar
                Center(
                  child: Stack(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF0B4D8A),
                            width: 3,
                          ),
                          image: DecorationImage(
                            image: _selectedImage != null
                                ? FileImage(_selectedImage!)
                                : NetworkImage(user.avatarUrl) as ImageProvider,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      if (_isEditing)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Color(0xFF0B4D8A),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              onPressed: _pickImage,
                              icon: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 20,
                              ),
                              tooltip: 'Ganti Foto',
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Username (readonly)
                Text(
                  '@${user.username}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 4),
                
                // User Type
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    user.displayUserType,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[700],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Profile Form
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Informasi Pribadi',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Nama Lengkap
                        CustomTextField(
                          controller: _namaController,
                          label: 'Nama Lengkap',
                          prefixIcon: Icons.person_outline,
                          enabled: _isEditing,
                          validator: Validators.required('Nama lengkap'),
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // Email
                        CustomTextField(
                          controller: _emailController,
                          label: 'Email',
                          prefixIcon: Icons.email_outlined,
                          enabled: _isEditing,
                          keyboardType: TextInputType.emailAddress,
                          validator: Validators.email,
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // Phone
                        CustomTextField(
                          controller: _phoneController,
                          label: 'Nomor HP',
                          prefixIcon: Icons.phone_outlined,
                          enabled: _isEditing,
                          keyboardType: TextInputType.phone,
                          validator: Validators.phone,
                        ),
                        
                        // NIS/NIP (if available)
                        if (user.nisNip != null || _isEditing) ...[
                          const SizedBox(height: 12),
                          CustomTextField(
                            controller: _nisNipController,
                            label: user.isSiswa ? 'NIS' : 'NIP',
                            prefixIcon: Icons.numbers,
                            enabled: _isEditing,
                          ),
                        ],
                        
                        // Kelas & Jurusan (for students)
                        if (user.isSiswa) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: CustomTextField(
                                  controller: _kelasController,
                                  label: 'Kelas',
                                  prefixIcon: Icons.class_,
                                  enabled: _isEditing,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: CustomTextField(
                                  controller: _jurusanController,
                                  label: 'Jurusan',
                                  prefixIcon: Icons.school,
                                  enabled: _isEditing,
                                ),
                              ),
                            ],
                          ),
                        ],
                        
                        // Mata Pelajaran (for teachers)
                        if (user.isGuruRole) ...[
                          const SizedBox(height: 12),
                          CustomTextField(
                            controller: _mapelController,
                            label: 'Mata Pelajaran',
                            prefixIcon: Icons.menu_book,
                            enabled: _isEditing,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Account Info Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Informasi Akun',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        _buildInfoRow(
                          'Tipe Akun',
                          user.displayUserType,
                        ),
                        const Divider(height: 16),
                        
                        _buildInfoRow(
                          'Level Privilege',
                          user.privilegeLevel.replaceAll('_', ' '),
                        ),
                        const Divider(height: 16),
                        
                        _buildInfoRow(
                          'Status',
                          user.isActive ? 'Aktif' : 'Nonaktif',
                          valueColor: user.isActive ? Colors.green : Colors.red,
                        ),
                        const Divider(height: 16),
                        
                        _buildInfoRow(
                          'Bergabung',
                          DateFormatter.formatDate(user.createdAt),
                        ),
                        if (user.lastLogin != null) ...[
                          const Divider(height: 16),
                          _buildInfoRow(
                            'Terakhir Login',
                            DateFormatter.formatDateTime(user.lastLogin!),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Action Buttons
                if (!_isEditing) ...[
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            // Navigate to change password
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Fitur ubah password akan segera hadir'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          icon: const Icon(Icons.lock_reset),
                          label: const Text('Ubah Password'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _isEditing = true;
                            });
                          },
                          icon: const Icon(Icons.edit),
                          label: const Text('Edit Profil'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}