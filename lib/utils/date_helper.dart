import 'package:intl/intl.dart';

class DateHelper {
  /// Format DateTime ke format: dd MMM yyyy HH:mm
  /// Contoh: 01 Apr 2026 14:30
  static String formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '-';
    return DateFormat('dd MMM yyyy HH:mm', 'id_ID').format(dateTime);
  }
  
  /// Format DateTime ke format: dd MMM yyyy
  /// Contoh: 01 Apr 2026
  static String formatDate(DateTime? dateTime) {
    if (dateTime == null) return '-';
    return DateFormat('dd MMM yyyy', 'id_ID').format(dateTime);
  }
  
  /// Format DateTime ke format: HH:mm
  /// Contoh: 14:30
  static String formatTime(DateTime? dateTime) {
    if (dateTime == null) return '-';
    return DateFormat('HH:mm', 'id_ID').format(dateTime);
  }
  
  /// Format DateTime ke format: dd MMM yyyy HH:mm:ss
  /// Contoh: 01 Apr 2026 14:30:25
  static String formatDateTimeSeconds(DateTime? dateTime) {
    if (dateTime == null) return '-';
    return DateFormat('dd MMM yyyy HH:mm:ss', 'id_ID').format(dateTime);
  }
  
  /// Format DateTime ke format: E, dd MMM yyyy
  /// Contoh: Sen, 01 Apr 2026
  static String formatDateWithDay(DateTime? dateTime) {
    if (dateTime == null) return '-';
    return DateFormat('E, dd MMM yyyy', 'id_ID').format(dateTime);
  }
  
  /// Format relative time (time ago)
  /// Contoh: 2 jam yang lalu, 3 hari yang lalu
  static String timeAgo(DateTime? dateTime) {
    if (dateTime == null) return '-';
    
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} tahun yang lalu';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} bulan yang lalu';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} hari yang lalu';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} jam yang lalu';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} menit yang lalu';
    } else {
      return 'baru saja';
    }
  }
  
  /// Mendapatkan selisih waktu dalam format jam
  static String getHoursDifference(DateTime? start, DateTime? end) {
    if (start == null || end == null) return '-';
    final diff = end.difference(start);
    final hours = diff.inHours;
    final minutes = diff.inMinutes.remainder(60);
    return '$hours jam $minutes menit';
  }
  
  /// Cek apakah tanggal adalah hari ini
  static bool isToday(DateTime? dateTime) {
    if (dateTime == null) return false;
    final now = DateTime.now();
    return dateTime.year == now.year &&
           dateTime.month == now.month &&
           dateTime.day == now.day;
  }
  
  /// Cek apakah tanggal adalah kemarin
  static bool isYesterday(DateTime? dateTime) {
    if (dateTime == null) return false;
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return dateTime.year == yesterday.year &&
           dateTime.month == yesterday.month &&
           dateTime.day == yesterday.day;
  }
  
  /// Mendapatkan status waktu (Pagi, Siang, Sore, Malam)
  static String getTimeOfDay(DateTime? dateTime) {
    if (dateTime == null) return '-';
    final hour = dateTime.hour;
    if (hour >= 5 && hour < 11) return 'Pagi';
    if (hour >= 11 && hour < 15) return 'Siang';
    if (hour >= 15 && hour < 18) return 'Sore';
    return 'Malam';
  }
  
  /// Format untuk tampilan singkat (dd/MM/yyyy HH:mm)
  static String formatShort(DateTime? dateTime) {
    if (dateTime == null) return '-';
    return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
  }
}