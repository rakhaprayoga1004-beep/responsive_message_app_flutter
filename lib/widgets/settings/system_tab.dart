import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../providers/settings_provider.dart';
import '../../models/settings_models.dart';
import '../../utils/snackbar_utils.dart';

class SystemTab extends StatefulWidget {
  const SystemTab({super.key});

  @override
  State<SystemTab> createState() => _SystemTabState();
}

class _SystemTabState extends State<SystemTab> {
  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, provider, child) {
        final stats = provider.systemStats;
        
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sistem & Keamanan',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0B4D8A),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: _buildDatabaseMaintenanceCard(provider)),
                  const SizedBox(width: 24),
                  Expanded(child: _buildExportImportCard(provider)),
                ],
              ),
              const SizedBox(height: 24),
              _buildLeadershipAccountsCard(),
              const SizedBox(height: 24),
              _buildSystemInfoCard(stats),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDatabaseMaintenanceCard(SettingsProvider provider) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.storage, color: Colors.blue),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Database Maintenance',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Buat backup database lengkap termasuk semua tabel, data, dan struktur.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _createBackup(provider),
                icon: const Icon(Icons.backup),
                label: const Text('Backup Database Sekarang'),
              ),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            const Text(
              'Bersihkan Log',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: '30',
                    decoration: const InputDecoration(
                      labelText: 'Hari',
                      border: OutlineInputBorder(),
                      suffixText: 'hari',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {},
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () => _clearLogs(provider),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                  child: const Text('Bersihkan'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportImportCard(SettingsProvider provider) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.file_copy, color: Colors.green),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Ekspor / Impor Konfigurasi',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Ekspor semua pengaturan, jenis pesan, template, dan konfigurasi notifikasi.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _exportConfig(provider),
                icon: const Icon(Icons.download),
                label: const Text('Ekspor Konfigurasi'),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Impor Konfigurasi',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _importConfig(provider),
                icon: const Icon(Icons.upload),
                label: const Text('Pilih File Konfigurasi'),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Format file: JSON (.json)',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeadershipAccountsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.people_outline, color: Colors.orange),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Manajemen Akun Pimpinan',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Kelola akun Kepala Sekolah dan Wakil Kepala Sekolah:',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _navigateToManageUsers('Kepala_Sekolah'),
                    icon: const Icon(Icons.person),
                    label: const Text('Kelola Kepala Sekolah'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0B4D8A),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _navigateToManageUsers('Wakil_Kepala'),
                    icon: const Icon(Icons.people),
                    label: const Text('Kelola Wakil Kepala'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2D9CDB),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemInfoCard(SystemStats? stats) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.info_outline, color: Colors.purple),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Informasi Sistem',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 3,
              children: [
                _buildInfoRow('PHP Version', '8.2.12'),
                _buildInfoRow('MySQL Version', '10.4.32-MariaDB'),
                _buildInfoRow('Server', 'Apache/2.4.58 (Win64) OpenSSL/3.1.3 PHP/8.2.12'),
                _buildInfoRow('Database Size', '${stats?.dbSizeMb ?? 1.45} MB'),
                _buildInfoRow('Host', 'localhost:3307'),
                _buildInfoRow('Database', 'responsive_message_db'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  void _createBackup(SettingsProvider provider) async {
    final result = await provider.createBackup();
    if (result != null && mounted) {
      if (result.success) {
        showSuccessSnackbar(context, result.message);
      } else {
        showErrorSnackbar(context, result.message);
      }
    }
  }

  void _clearLogs(SettingsProvider provider) async {
    final days = 30;
    final success = await provider.clearOldLogs(days);
    if (success && mounted) {
      showSuccessSnackbar(context, 'Log lebih dari $days hari berhasil dihapus');
    }
  }

  void _exportConfig(SettingsProvider provider) async {
    final config = await provider.exportConfig();
    if (config != null && mounted) {
      showSuccessSnackbar(context, 'Konfigurasi berhasil diekspor');
    }
  }

  void _importConfig(SettingsProvider provider) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        allowedExtensions: ['json'],
        dialogTitle: 'Pilih File Konfigurasi',
      );

      if (result != null && mounted) {
        final file = result.files.single;
        
        if (file.path != null) {
          final fileContent = await File(file.path!).readAsString();
          
          if (fileContent.isNotEmpty) {
            try {
              json.decode(fileContent);
              final confirm = await _showImportConfirmDialog();
              if (confirm == true) {
                final success = await provider.importConfig(fileContent);
                if (success && mounted) {
                  showSuccessSnackbar(context, 'Konfigurasi berhasil diimpor');
                } else {
                  showErrorSnackbar(context, 'Gagal mengimpor konfigurasi');
                }
              }
            } catch (e) {
              showErrorSnackbar(context, 'File bukan format JSON yang valid');
            }
          } else {
            showErrorSnackbar(context, 'File kosong');
          }
        } else {
          showErrorSnackbar(context, 'Path file tidak valid');
        }
      }
    } catch (e) {
      showErrorSnackbar(context, 'Error: $e');
    }
  }

  Future<bool?> _showImportConfirmDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Impor'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PERINGATAN:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Impor konfigurasi akan menimpa pengaturan yang ada:\n'
              '• Pengaturan Umum\n'
              '• Jenis Pesan\n'
              '• Template Respons\n'
              '• Konfigurasi Notifikasi\n\n'
              'Lanjutkan impor?',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Lanjutkan Impor'),
          ),
        ],
      ),
    );
  }

  void _navigateToManageUsers(String userType) {
    Navigator.pushNamed(context, '/admin/users', arguments: {'filter': userType});
  }
}