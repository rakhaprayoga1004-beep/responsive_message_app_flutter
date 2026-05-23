import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';

class Helpers {
  static void showToast(BuildContext context, String message, {bool isError = false}) {
    // Cek apakah context masih valid dan memiliki Scaffold
    if (context.mounted) {
      try {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: isError ? Colors.red : Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      } catch (e) {
        print('Error showing toast: $e');
      }
    } else {
      print('Toast skipped: context not mounted - $message');
    }
  }

  static Future<bool> showConfirmationDialog(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Ya',
    String cancelText = 'Tidak',
    Color confirmColor = Colors.red,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancelText),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: confirmColor),
            child: Text(confirmText),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  static String getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name[0].toUpperCase();
  }

  static String getFullInitials(String name) {
    return getInitials(name);
  }

  static String getDayName(int day) {
    const days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    return days[day - 1];
  }

  static String getMonthName(int month) {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return months[month - 1];
  }

  static String formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  static String timeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} tahun lalu';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} bulan lalu';
    } else if (difference.inDays > 7) {
      return '${(difference.inDays / 7).floor()} minggu lalu';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} hari lalu';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} jam lalu';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} menit lalu';
    } else {
      return 'Baru saja';
    }
  }

  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return Colors.orange;
      case 'dibaca': return Colors.blue;
      case 'diproses': return Colors.cyan;
      case 'disetujui': return Colors.green;
      case 'ditolak': return Colors.red;
      case 'selesai': return Colors.teal;
      default: return Colors.grey;
    }
  }

  // ============================================================================
  // FUNGSI TAMBAHAN UNTUK LOADING DAN DOWNLOAD
  // ============================================================================

  /// Menampilkan dialog loading dengan pesan tertentu
  static Future<void> showLoading(BuildContext context, String message) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }

  /// Menutup dialog loading
  static void hideLoading(BuildContext context) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  /// Download file untuk semua platform (Web, Windows, Mobile)
  static Future<void> downloadFile(List<int> bytes, String fileName, BuildContext context) async {
    try {
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        // Untuk Desktop (Windows, Linux, macOS)
        final directory = await getDownloadsDirectory();
        if (directory != null) {
          final file = File('${directory.path}/$fileName');
          await file.writeAsBytes(bytes);
          showToast(context, 'File berhasil diunduh ke ${directory.path}');
        } else {
          throw Exception('Tidak dapat mengakses direktori Downloads');
        }
      } else if (Platform.isAndroid || Platform.isIOS) {
        // Untuk Mobile
        final directory = await getTemporaryDirectory();
        final file = File('${directory.path}/$fileName');
        await file.writeAsBytes(bytes);
        await Share.shareXFiles([XFile(file.path)], text: 'Laporan $fileName');
      } else {
        // Fallback - simpan ke temporary
        final directory = await getTemporaryDirectory();
        final file = File('${directory.path}/$fileName');
        await file.writeAsBytes(bytes);
        showToast(context, 'File berhasil diunduh ke ${directory.path}');
      }
    } catch (e) {
      showToast(context, 'Error downloading file: $e', isError: true);
    }
  }

  /// Format tanggal dengan hari (contoh: Senin, 1 Januari 2024)
  static String formatDateWithDay(DateTime date) {
    final days = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
    final months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return '${days[date.weekday % 7]}, ${date.day} ${months[date.month - 1]} ${date.year}';
  }

  /// Format tanggal lengkap dengan waktu (contoh: Senin, 1 Januari 2024 14:30:45)
  static String formatDateTimeFull(DateTime date) {
    return '${formatDateWithDay(date)} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')} WIB';
  }

  /// Format waktu saja (contoh: 14:30:45)
  static String formatTimeOnly(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}';
  }

  /// Format tanggal saja (contoh: 1 Januari 2024)
  static String formatDateOnly(DateTime date) {
    final months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  /// Format tanggal pendek (contoh: 01/01/2024)
  static String formatDateShort(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  /// Format tanggal dengan waktu pendek (contoh: 01/01/2024 14:30)
  static String formatDateTimeShort(DateTime date) {
    return '${formatDateShort(date)} ${formatTimeShort(date)}';
  }

  /// Format waktu pendek (contoh: 14:30)
  static String formatTimeShort(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  /// Menghitung selisih waktu dalam format yang mudah dibaca
  static String formatTimeDifference(DateTime start, DateTime end) {
    final diff = end.difference(start);
    final hours = diff.inHours;
    final minutes = diff.inMinutes.remainder(60);
    
    if (hours > 0) {
      return '$hours jam ${minutes > 0 ? '$minutes menit' : ''}';
    } else if (minutes > 0) {
      return '$minutes menit';
    } else {
      return '${diff.inSeconds} detik';
    }
  }

  /// Memotong teks jika terlalu panjang
  static String truncateText(String text, int maxLength, {String suffix = '...'}) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}$suffix';
  }

  /// Validasi email
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  /// Validasi phone number (minimal 10 digit, maksimal 13 digit)
  static bool isValidPhoneNumber(String phone) {
    final phoneRegex = RegExp(r'^[0-9]{10,13}$');
    return phoneRegex.hasMatch(phone);
  }

  /// Mengubah ukuran bytes menjadi format yang mudah dibaca (KB, MB, GB)
  static String formatFileSize(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var i = 0;
    var size = bytes.toDouble();
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    return '${size.toStringAsFixed(1)} ${suffixes[i]}';
  }

  /// Mendapatkan ekstensi file dari nama file
  static String getFileExtension(String fileName) {
    final lastDot = fileName.lastIndexOf('.');
    if (lastDot == -1) return '';
    return fileName.substring(lastDot + 1).toLowerCase();
  }

  /// Cek apakah file adalah gambar berdasarkan ekstensi
  static bool isImageFile(String fileName) {
    const imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'svg'];
    final ext = getFileExtension(fileName);
    return imageExtensions.contains(ext);
  }

  /// Cek apakah file adalah PDF
  static bool isPdfFile(String fileName) {
    return getFileExtension(fileName) == 'pdf';
  }

  /// Mendapatkan icon untuk tipe file
  static IconData getFileIcon(String fileName) {
    if (isImageFile(fileName)) return Icons.image;
    if (isPdfFile(fileName)) return Icons.picture_as_pdf;
    
    final ext = getFileExtension(fileName);
    switch (ext) {
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'txt':
        return Icons.text_fields;
      case 'zip':
      case 'rar':
      case '7z':
        return Icons.folder_zip;
      default:
        return Icons.insert_drive_file;
    }
  }

  /// Mengubah warna menjadi hex string
  static String colorToHex(Color color) {
    return '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}';
  }

  /// Mengubah hex string menjadi Color
  static Color hexToColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  /// Menampilkan dialog error
  static Future<void> showErrorDialog(BuildContext context, String message) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text('Error'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Menampilkan dialog sukses
  static Future<void> showSuccessDialog(BuildContext context, String message) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Sukses'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Menampilkan dialog info
  static Future<void> showInfoDialog(BuildContext context, String title, String message) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}