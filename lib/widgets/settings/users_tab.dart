import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../models/settings_models.dart';

class UsersTab extends StatefulWidget {
  const UsersTab({super.key});

  @override
  State<UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<UsersTab> {
  String _selectedFilter = 'Semua';
  final Set<int> _selectedUserIds = {};

  final List<String> _allFilters = [
    'Semua',
    'Admin',
    'Kepala_Sekolah',
    'Wakil_Kepala',
    'Guru_BK',
    'Guru_Humas',
    'Guru_Kurikulum',
    'Guru_Kesiswaan',
    'Guru_Sarana',
    'Guru',
    'Siswa',
    'Orang_Tua',
    'External',
    '',
  ];

  List<String> get _activeFilters {
    final provider = Provider.of<SettingsProvider>(context, listen: false);
    return _allFilters.where((filter) {
      if (filter == 'Semua') return true;
      return (provider.counterTypeCounts[filter] ?? 0) > 0;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<SettingsProvider>(context, listen: false);
      provider.loadUsers();        // Untuk tampilan tabel
      provider.loadCounterData();  // 🔥 Untuk counter filter - INDEPENDEN!
    });
  }

  void _selectAll(bool? selected) {
    setState(() {
      final provider = Provider.of<SettingsProvider>(context, listen: false);
      if (selected == true) {
        _selectedUserIds.addAll(provider.users.map((u) => u.id));
      } else {
        _selectedUserIds.clear();
      }
    });
  }

  void _toggleSelection(int userId) {
    setState(() {
      if (_selectedUserIds.contains(userId)) {
        _selectedUserIds.remove(userId);
      } else {
        _selectedUserIds.add(userId);
      }
    });
  }

  Future<void> _bulkActivate() async {
    final provider = Provider.of<SettingsProvider>(context, listen: false);
    
    if (_selectedUserIds.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pilih minimal satu user'), backgroundColor: Colors.orange),
        );
      }
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aktifkan User'),
        content: Text('Aktifkan ${_selectedUserIds.length} user?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Aktifkan')),
        ],
      ),
    );

    if (confirm == true && mounted) {
      for (final userId in _selectedUserIds) {
        await provider.updateUserStatus(userId, true);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${_selectedUserIds.length} user diaktifkan'), backgroundColor: Colors.green),
        );
        setState(() {
          _selectedUserIds.clear();
        });
      }
    }
  }

  Future<void> _bulkDeactivate() async {
    final provider = Provider.of<SettingsProvider>(context, listen: false);
    
    if (_selectedUserIds.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pilih minimal satu user'), backgroundColor: Colors.orange),
        );
      }
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nonaktifkan User'),
        content: Text('Nonaktifkan ${_selectedUserIds.length} user?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Nonaktifkan')),
        ],
      ),
    );

    if (confirm == true && mounted) {
      for (final userId in _selectedUserIds) {
        await provider.updateUserStatus(userId, false);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${_selectedUserIds.length} user dinonaktifkan'), backgroundColor: Colors.red),
        );
        setState(() {
          _selectedUserIds.clear();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, provider, child) {
        // 🔥🔥🔥 KRUSIAL: Gunakan data counter yang TERPISAH!
        final totalAllUsers = provider.counterTotalAllUsers;
        final typeCounts = provider.counterTypeCounts;
        final isCounterReady = provider.isCounterDataLoaded;
        
        // 🔥 Data tampilan (bisa difilter)
        final displayedUsers = provider.users;
        
        // Statistik dari allUsers (untuk card)
        final allUsers = provider.allUsers;
        final aktifAll = allUsers.where((u) => u.isActive).length;
        final nonaktifAll = allUsers.length - aktifAll;
        final eksternalAll = allUsers.where((u) => u.userType == 'Orang_Tua' || u.userType == 'External').length;

        if (kDebugMode) {
          print('═══════════════════════════════════════════════════════════');
          print('🏗️ BUILDING UsersTab');
          print('   Counter Data (INDEPENDENT):');
          print('     Total All Users: $totalAllUsers');
          print('     Type Counts: $typeCounts');
          print('   Display Data:');
          print('     Displayed Users: ${displayedUsers.length}');
          print('     Selected Filter: $_selectedFilter');
          print('   🔥 Counter "Semua" is COMPLETELY INDEPENDENT!');
          print('═══════════════════════════════════════════════════════════');
        }

        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Manajemen Pengguna',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0B4D8A)),
              ),
              const SizedBox(height: 8),
              const Text('Kelola akun pengguna dan hak akses', style: TextStyle(fontSize: 14, color: Colors.grey)),
              const SizedBox(height: 24),

              // STATISTIK CARD
              Row(
                children: [
                  Expanded(child: _buildStatCard('Total Pengguna', '${allUsers.length}', Icons.people, Colors.blue)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildStatCard('Aktif', '$aktifAll', Icons.check_circle, Colors.green)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildStatCard('Nonaktif', '$nonaktifAll', Icons.block, Colors.red)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildStatCard('Eksternal', '$eksternalAll', Icons.public, Colors.orange)),
                ],
              ),
              const SizedBox(height: 24),

              // FILTER CHIPS - MENGGUNAKAN DATA COUNTER YANG TERPISAH
              if (isCounterReady)
                SizedBox(
                  height: 45,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _activeFilters.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final filter = _activeFilters[index];
                      final isSelected = _selectedFilter == filter;
                      final displayName = _getDisplayName(filter);
                      
                      // 🔥🔥🔥 COUNTER DARI DATA TERPISAH (TIDAK TERPENGARUH FILTER)
                      int count;
                      if (filter == 'Semua') {
                        count = totalAllUsers;  // Dari data counter independen
                      } else {
                        count = typeCounts[filter] ?? 0;  // Dari data counter independen
                      }

                      return FilterChip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(displayName),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.blue.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '$count',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected ? Colors.blue : Colors.grey.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        selected: isSelected,
                        onSelected: (_) {
                          if (kDebugMode) {
                            print('🖱️ Filter clicked: $filter');
                            print('   Counter Semua (independent): $totalAllUsers');
                          }
                          
                          // 🔥 Filter hanya mempengaruhi tampilan tabel
                          provider.filterUsers(filter == 'Semua' ? '' : filter);
                          setState(() {
                            _selectedFilter = filter;
                            _selectedUserIds.clear();
                          });
                          
                          if (kDebugMode) {
                            print('   After filter - Counter Semua: $totalAllUsers (TIDAK BERUBAH!)');
                          }
                        },
                        backgroundColor: Colors.grey.shade100,
                        selectedColor: Colors.blue.shade50,
                      );
                    },
                  ),
                )
              else
                const SizedBox(height: 45, child: Center(child: CircularProgressIndicator())),
              
              const SizedBox(height: 16),

              // BULK ACTIONS
              if (_selectedUserIds.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Text('${_selectedUserIds.length} user dipilih', style: const TextStyle(fontWeight: FontWeight.w500)),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: _bulkActivate,
                        icon: const Icon(Icons.check_circle, size: 18),
                        label: const Text('Aktifkan'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: _bulkDeactivate,
                        icon: const Icon(Icons.block, size: 18),
                        label: const Text('Nonaktifkan'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                      ),
                    ],
                  ),
                ),

              if (provider.isLoading)
                const Center(child: CircularProgressIndicator())
              else if (displayedUsers.isEmpty)
                const Center(child: Text('Belum ada pengguna', style: TextStyle(color: Colors.grey)))
              else
                _buildUsersTable(displayedUsers),
            ],
          ),
        );
      },
    );
  }

  // ============================================
  // METHOD LAINNYA (SAMA SEPERTI SEBELUMNYA)
  // ============================================
  
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          Text(title, style: TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildUsersTable(List<User> users) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 20,
        headingRowHeight: 50,
        dataRowHeight: 70,
        headingRowColor: WidgetStateProperty.all(Colors.grey.shade50),
        columns: const [
          DataColumn(label: Text('User', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
          DataColumn(label: Text('Tipe', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
          DataColumn(label: Text('Kontak', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
          DataColumn(label: Text('Info Tambahan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
          DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
          DataColumn(label: Text('Terakhir Login', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
          DataColumn(label: Text('Aksi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
        ],
        rows: users.map((user) {
          final isSelected = _selectedUserIds.contains(user.id);
          return DataRow(
            selected: isSelected,
            onSelectChanged: (_) => _toggleSelection(user.id),
            cells: [
              DataCell(
                Row(
                  children: [
                    Checkbox(
                      value: isSelected,
                      onChanged: (_) => _toggleSelection(user.id),
                    ),
                    const SizedBox(width: 8),
                    _buildAvatar(user.foto, user.namaLengkap, user.userType),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          user.namaLengkap,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        Text(
                          '@${user.username}',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _getUserTypeColor(user.userType).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _getDisplayName(user.userType),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _getUserTypeColor(user.userType),
                    ),
                  ),
                ),
              ),
              DataCell(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      user.email,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                    ),
                    if (user.noTelp != null && user.noTelp!.isNotEmpty)
                      Text(
                        user.noTelp!,
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                      ),
                  ],
                ),
              ),
              DataCell(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (user.kelas != null && user.kelas!.isNotEmpty)
                      Text('Kelas: ${user.kelas}', style: const TextStyle(fontSize: 12)),
                    if (user.jurusan != null && user.jurusan!.isNotEmpty)
                      Text('Jurusan: ${user.jurusan}', style: const TextStyle(fontSize: 12)),
                    if (user.mataPelajaran != null && user.mataPelajaran!.isNotEmpty)
                      Text('Mapel: ${user.mataPelajaran}', style: const TextStyle(fontSize: 12)),
                    if (user.nisNip != null && user.nisNip!.isNotEmpty)
                      Text(
                        user.userType == 'Siswa' ? 'NIS: ${user.nisNip}' : 'NIP: ${user.nisNip}',
                        style: const TextStyle(fontSize: 12),
                      ),
                  ],
                ),
              ),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: user.isActive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    user.isActive ? 'Aktif' : 'Nonaktif',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: user.isActive ? Colors.green : Colors.red,
                    ),
                  ),
                ),
              ),
              DataCell(_buildLastLoginCell(user)),
              DataCell(
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        user.isActive ? Icons.block : Icons.check_circle,
                        size: 20,
                        color: user.isActive ? Colors.red : Colors.green,
                      ),
                      onPressed: () => _toggleUserStatus(context, user),
                      tooltip: user.isActive ? 'Nonaktifkan' : 'Aktifkan',
                    ),
                    IconButton(
                      icon: const Icon(Icons.key, size: 20, color: Colors.orange),
                      onPressed: () => _resetPassword(context, user),
                      tooltip: 'Reset Password',
                    ),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAvatar(String? fotoUrl, String namaLengkap, String userType) {
    final color = _getUserTypeColor(userType);
    final initials = _getInitials(namaLengkap);
    
    return CircleAvatar(
      radius: 20,
      backgroundColor: color.withOpacity(0.1),
      child: Text(
        initials,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildLastLoginCell(User user) {
    final lastLogin = user.lastLogin;
    final updatedAt = user.updatedAt;

    if (lastLogin == null) {
      return const Text(
        'Belum pernah login',
        style: TextStyle(fontSize: 12, color: Colors.grey),
      );
    }

    final now = DateTime.now();
    final isToday = lastLogin.year == now.year && lastLogin.month == now.month && lastLogin.day == now.day;
    final isUpdatedAfterLogin = updatedAt != null && updatedAt.isAfter(lastLogin);
    final diffDays = now.difference(lastLogin).inDays;

    String statusText;
    Color statusColor;

    if (isToday) {
      statusText = 'Baru saja login';
      statusColor = Colors.green;
    } else if (isUpdatedAfterLogin) {
      statusText = _formatDate(lastLogin);
      statusColor = Colors.orange;
    } else if (diffDays == 1) {
      statusText = 'Kemarin';
      statusColor = Colors.orange;
    } else if (diffDays <= 7) {
      statusText = '$diffDays hari yang lalu';
      statusColor = Colors.blue;
    } else {
      statusText = _formatDate(lastLogin);
      statusColor = Colors.grey.shade700;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            statusText,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: statusColor),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _formatDateTime(lastLogin),
          style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
        ),
      ],
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length > 1) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    if (parts[0].length >= 2) {
      return parts[0].substring(0, 2).toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  String _getDisplayName(String userType) {
    switch (userType) {
      case 'Admin': return 'Admin';
      case 'Kepala_Sekolah': return 'Kepala Sekolah';
      case 'Wakil_Kepala': return 'Wakil Kepala';
      case 'Guru_BK': return 'Guru BK';
      case 'Guru_Humas': return 'Guru Humas';
      case 'Guru_Kurikulum': return 'Guru Kurikulum';
      case 'Guru_Kesiswaan': return 'Guru Kesiswaan';
      case 'Guru_Sarana': return 'Guru Sarana';
      case 'Guru': return 'Guru';
      case 'Siswa': return 'Siswa';
      case 'Orang_Tua': return 'Orang Tua';
      case 'External': return 'Eksternal';
      case '': return '';
      default: return userType;
    }
  }

  Color _getUserTypeColor(String userType) {
    switch (userType) {
      case 'Admin': return Colors.red;
      case 'Kepala_Sekolah': 
      case 'Wakil_Kepala': return Colors.purple;
      case 'Guru_BK': 
      case 'Guru_Humas': 
      case 'Guru_Kurikulum': 
      case 'Guru_Kesiswaan': 
      case 'Guru_Sarana': 
      case 'Guru': return Colors.teal;
      case 'Siswa': return Colors.blue;
      case 'Orang_Tua': 
      case 'External':
      case '': return Colors.orange;
      default: return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatDateTime(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _toggleUserStatus(BuildContext context, User user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(user.isActive ? 'Nonaktifkan User' : 'Aktifkan User'),
        content: Text('${user.isActive ? 'Nonaktifkan' : 'Aktifkan'} "${user.namaLengkap}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: Text(user.isActive ? 'Nonaktifkan' : 'Aktifkan')),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final success = await Provider.of<SettingsProvider>(context, listen: false)
          .updateUserStatus(user.id, !user.isActive);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Status berhasil diubah'), backgroundColor: Colors.green),
        );
        setState(() {
          if (_selectedUserIds.contains(user.id)) {
            _selectedUserIds.remove(user.id);
          }
        });
      }
    }
  }

  void _resetPassword(BuildContext context, User user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Password'),
        content: Text('Reset password untuk ${user.namaLengkap}?\nPassword baru akan dikirim ke email.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Reset')),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final success = await Provider.of<SettingsProvider>(context, listen: false).resetUserPassword(user.id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password berhasil direset'), backgroundColor: Colors.green),
        );
      }
    }
  }
}