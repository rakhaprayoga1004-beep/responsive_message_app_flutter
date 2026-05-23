import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../providers/settings_provider.dart';
import '../../models/settings_models.dart';
import '../../utils/snackbar_utils.dart';

class BackupTab extends StatefulWidget {
  const BackupTab({super.key});

  @override
  State<BackupTab> createState() => _BackupTabState();
}

class _BackupTabState extends State<BackupTab> {
  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, provider, child) {
        final backupFiles = provider.backupFiles;
        
        // Hitung total size dengan aman
        int totalSize = 0;
        for (var file in backupFiles) {
          totalSize += file.size;
        }
        final totalSizeFormatted = _formatFileSize(totalSize);
        
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
                'Backup & Restore Database',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0B4D8A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'MySQL localhost:3307',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 24),
              _buildDatabaseInfo(),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: _buildBackupCard(provider, backupFiles.length, totalSizeFormatted)),
                  const SizedBox(width: 24),
                  Expanded(child: _buildRestoreCard(provider)),
                ],
              ),
              const SizedBox(height: 24),
              _buildBackupList(backupFiles),
              const SizedBox(height: 24),
              _buildInstructions(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDatabaseInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Informasi Database:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Host: localhost | Port: 3307 | Database: responsive_message_db',
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  'Backup disimpan di folder C:\\xampp\\htdocs\\responsive-message-app/backups',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackupCard(SettingsProvider provider, int totalFiles, String totalSizeFormatted) {
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
                  child: const Icon(Icons.backup, color: Colors.blue),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Buat Backup Baru',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Membuat backup lengkap database termasuk semua tabel, data, dan struktur.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _createBackup(provider),
                icon: const Icon(Icons.save),
                label: const Text('Backup Sekarang'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0B4D8A),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Backup Files:', style: TextStyle(fontSize: 12)),
                      Text(
                        '$totalFiles',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0B4D8A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Size:', style: TextStyle(fontSize: 12)),
                      Text(
                        totalSizeFormatted,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0B4D8A),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRestoreCard(SettingsProvider provider) {
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
                  child: const Icon(Icons.restore, color: Colors.orange),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Restore Database',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Pilih file backup (.sql, .zip, .gz) untuk direstore. Semua data akan diganti.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _restoreBackup(provider),
                icon: const Icon(Icons.upload_file),
                label: const Text('Pilih File Backup'),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Format yang didukung: .sql, .zip, .gz',
                style: TextStyle(fontSize: 11, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackupList(List<BackupFile> backupFiles) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.folder, size: 20),
                SizedBox(width: 8),
                Text(
                  'Daftar Backup Tersedia',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          if (backupFiles.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.folder_open, size: 48, color: Colors.grey),
                    SizedBox(height: 12),
                    Text(
                      'Belum ada file backup',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            )
          else
            _buildBackupTable(backupFiles),
        ],
      ),
    );
  }

  Widget _buildBackupTable(List<BackupFile> backupFiles) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 24,
        headingRowColor: WidgetStateProperty.all(Colors.grey.shade50),
        columns: const [
          DataColumn(label: Text('Nama File', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Ukuran', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Tanggal', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Aksi', style: TextStyle(fontWeight: FontWeight.bold))),
        ],
        rows: backupFiles.map((file) {
          return DataRow(
            cells: [
              DataCell(
                Row(
                  children: [
                    const Icon(Icons.file_copy, size: 16, color: Colors.blue),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 300,
                      child: Text(
                        file.name,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              DataCell(Text(file.sizeFormatted)),
              DataCell(Text(file.dateFormatted)),
              DataCell(
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.download, size: 20, color: Colors.blue),
                      onPressed: () => _downloadBackup(file),
                      tooltip: 'Download',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                      onPressed: () => _deleteBackup(context, file),
                      tooltip: 'Hapus',
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

  Widget _buildInstructions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: Colors.blue),
              SizedBox(width: 8),
              Text(
                'Panduan Backup & Restore:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '• Backup menggunakan mysqldump jika tersedia, fallback ke metode PHP jika tidak\n'
            '• File backup disimpan di folder C:\\xampp\\htdocs\\responsive-message-app/backups\n'
            '• Format file: backup_nama database_tanggal.sql\n'
            '• Untuk restore, upload file .sql, .zip, atau .gz (maksimal 50MB)\n'
            '• Selalu backup sebelum melakukan restore untuk keamanan data',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
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

  void _restoreBackup(SettingsProvider provider) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      allowedExtensions: ['sql', 'zip', 'gz'],
    );

    if (result != null && mounted) {
      final filePath = result.files.single.path;
      if (filePath != null) {
        final confirm = await _showRestoreConfirmDialog();
        if (confirm == true) {
          final restoreResult = await provider.restoreBackup(filePath);
          if (restoreResult != null && mounted) {
            if (restoreResult.success) {
              showSuccessSnackbar(context, restoreResult.message);
            } else {
              showErrorSnackbar(context, restoreResult.message);
            }
          }
        }
      }
    }
  }

  void _deleteBackup(BuildContext context, BackupFile file) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus Backup'),
        content: Text('Hapus file backup ${file.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final success = await Provider.of<SettingsProvider>(context, listen: false)
          .deleteBackupFile(file.name);
      if (success && mounted) {
        showSuccessSnackbar(context, 'File backup berhasil dihapus');
      }
    }
  }

  void _downloadBackup(BackupFile file) {
    showInfoSnackbar(context, 'Download akan segera dimulai: ${file.name}');
  }

  Future<bool?> _showRestoreConfirmDialog() {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Konfirmasi Restore'),
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
              'Semua data yang ada akan ditimpa! '
              'Pastikan Anda memiliki backup terbaru.\n\n'
              'Lanjutkan restore?',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Lanjutkan Restore'),
          ),
        ],
      ),
    );
  }

  static String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
}