// lib/utils/date_utils.dart
import 'package:intl/intl.dart';

class AppDateUtils {
  static String formatDateTime(DateTime? dateTime, {String locale = 'id_ID'}) {
    if (dateTime == null) return '-';
    try {
      return DateFormat('dd MMM yyyy HH:mm', locale).format(dateTime);
    } catch (e) {
      return dateTime.toString();
    }
  }

  static String formatDate(DateTime? dateTime, {String locale = 'id_ID'}) {
    if (dateTime == null) return '-';
    try {
      return DateFormat('dd MMM yyyy', locale).format(dateTime);
    } catch (e) {
      return dateTime.toString();
    }
  }

  static String timeAgo(DateTime dateTime) {
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
      return 'Baru saja';
    }
  }

  static DateTime? parseDateString(String? dateString) {
    if (dateString == null || dateString.isEmpty) return null;
    try {
      return DateTime.parse(dateString);
    } catch (e) {
      return null;
    }
  }
}