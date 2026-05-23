// lib/utils/date_formatter.dart
import 'package:intl/intl.dart';

class DateFormatter {
  /// Format tanggal lengkap dengan nama bulan (contoh: 16 Maret 2026)
  static String formatDate(DateTime date) {
    try {
      final format = DateFormat('dd MMMM yyyy', 'id_ID');
      return format.format(date);
    } catch (e) {
      return '${date.day} ${_getMonthName(date.month)} ${date.year}';
    }
  }

  /// Format tanggal dan waktu (contoh: 16 Mar 2026 14:30)
  static String formatDateTime(DateTime date) {
    try {
      final format = DateFormat('dd MMM yyyy HH:mm', 'id_ID');
      return format.format(date);
    } catch (e) {
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    }
  }

  /// Format hari dan bulan (contoh: 16 Mar)
  static String formatDayMonth(DateTime date) {
    try {
      final format = DateFormat('dd MMM', 'id_ID');
      return format.format(date);
    } catch (e) {
      return '${date.day}/${date.month}';
    }
  }

  /// Format waktu saja (contoh: 14:30)
  static String formatTime(DateTime date) {
    try {
      final format = DateFormat('HH:mm', 'id_ID');
      return format.format(date);
    } catch (e) {
      return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    }
  }

  /// Format tanggal pendek (contoh: 16/03/2026)
  static String formatShortDate(DateTime date) {
    try {
      final format = DateFormat('dd/MM/yyyy', 'id_ID');
      return format.format(date);
    } catch (e) {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  /// Format tanggal pendek (alias untuk formatShortDate)
  static String formatDateShort(DateTime date) {
    return formatShortDate(date);
  }

  /// Format untuk chart (contoh: 16 Mar)
  static String formatChartDate(DateTime date) {
    try {
      final format = DateFormat('dd MMM', 'id_ID');
      return format.format(date);
    } catch (e) {
      return '${date.day}/${date.month}';
    }
  }

  /// Format untuk statistik (contoh: 16/03)
  static String formatDayMonthShort(DateTime date) {
    try {
      final format = DateFormat('dd/MM', 'id_ID');
      return format.format(date);
    } catch (e) {
      return '${date.day}/${date.month}';
    }
  }

  /// Format untuk filter tanggal (YYYY-MM-DD)
  static String formatForFilter(DateTime date) {
    try {
      final format = DateFormat('yyyy-MM-dd');
      return format.format(date);
    } catch (e) {
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }
  }

  /// Format waktu relatif (contoh: 2 jam yang lalu)
  static String timeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years tahun yang lalu';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months bulan yang lalu';
    } else if (difference.inDays > 7) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks minggu yang lalu';
    } else if (difference.inDays > 0) {
      if (difference.inDays == 1) {
        return 'kemarin';
      }
      return '${difference.inDays} hari yang lalu';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} jam yang lalu';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} menit yang lalu';
    } else {
      return 'Baru saja';
    }
  }

  // ==========================================================================
  // SAFE FORMATTERS (UNTUK MENGHINDARI NULL)
  // ==========================================================================

  /// Safe version of formatDate
  static String safeFormatDate(DateTime? date) {
    if (date == null) return '-';
    try {
      return formatDate(date);
    } catch (e) {
      return '-';
    }
  }

  /// Safe version of formatDateTime
  static String safeFormatDateTime(DateTime? date) {
    if (date == null) return '-';
    try {
      return formatDateTime(date);
    } catch (e) {
      return '-';
    }
  }

  /// Safe version of formatDayMonth
  static String safeFormatDayMonth(DateTime? date) {
    if (date == null) return '-';
    try {
      return formatDayMonth(date);
    } catch (e) {
      return '-';
    }
  }

  /// Safe version of formatTime
  static String safeFormatTime(DateTime? date) {
    if (date == null) return '-';
    try {
      return formatTime(date);
    } catch (e) {
      return '-';
    }
  }

  /// Safe version of timeAgo
  static String safeTimeAgo(DateTime? date) {
    if (date == null) return '-';
    try {
      return timeAgo(date);
    } catch (e) {
      return '-';
    }
  }

  /// Safe version of formatShortDate
  static String safeFormatShortDate(DateTime? date) {
    if (date == null) return '-';
    try {
      return formatShortDate(date);
    } catch (e) {
      return '-';
    }
  }

  // ==========================================================================
  // HELPER METHODS
  // ==========================================================================

  /// Mendapatkan nama hari dalam bahasa Indonesia
  static String getDayName(int weekday) {
    const days = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    return days[weekday - 1];
  }

  /// Mendapatkan nama bulan dalam bahasa Indonesia
  static String getMonthName(int month) {
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return months[month - 1];
  }

  /// Helper untuk mendapatkan nama bulan (internal use)
  static String _getMonthName(int month) {
    return getMonthName(month);
  }

  /// Format dengan hari (contoh: Senin, 16 Maret 2026)
  static String formatWithDay(DateTime date) {
    try {
      return '${getDayName(date.weekday)}, ${date.day} ${getMonthName(date.month)} ${date.year}';
    } catch (e) {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  /// Mendapatkan awal hari (00:00:00)
  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Mendapatkan akhir hari (23:59:59)
  static DateTime endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59);
  }

  /// Mendapatkan awal bulan
  static DateTime startOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  /// Mendapatkan akhir bulan
  static DateTime endOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0, 23, 59, 59);
  }

  /// Mendapatkan awal tahun
  static DateTime startOfYear(DateTime date) {
    return DateTime(date.year, 1, 1);
  }

  /// Mendapatkan akhir tahun
  static DateTime endOfYear(DateTime date) {
    return DateTime(date.year, 12, 31, 23, 59, 59);
  }

  /// Memeriksa apakah dua tanggal sama (hanya tahun, bulan, hari)
  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Memeriksa apakah tanggal adalah hari ini
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return isSameDay(date, now);
  }

  /// Memeriksa apakah tanggal adalah kemarin
  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return isSameDay(date, yesterday);
  }

  /// Mendapatkan range tanggal untuk filter (misal: 7 days, 30 days)
  static DateTime getStartDateForPeriod(String period) {
    final now = DateTime.now();
    switch (period) {
      case '7days':
        return now.subtract(const Duration(days: 7));
      case '14days':
        return now.subtract(const Duration(days: 14));
      case '30days':
        return now.subtract(const Duration(days: 30));
      case '90days':
        return now.subtract(const Duration(days: 90));
      default:
        return now.subtract(const Duration(days: 30));
    }
  }
}