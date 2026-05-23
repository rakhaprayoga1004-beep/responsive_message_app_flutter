// lib/widgets/status_badge.dart
import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final bool showIcon;
  final double fontSize;

  const StatusBadge({
    super.key,
    required this.status,
    this.showIcon = true,
    this.fontSize = 12,
  });

  Color _getColor() {
    switch (status.toLowerCase()) {
      case 'aktif':
      case 'active':
      case 'disetujui':
        return Colors.green;
      case 'pending':
      case 'menunggu':
        return Colors.orange;
      case 'nonaktif':
      case 'inactive':
      case 'ditolak':
        return Colors.red;
      case 'diproses':
        return Colors.blue;
      case 'selesai':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData _getIcon() {
    switch (status.toLowerCase()) {
      case 'aktif':
      case 'active':
      case 'disetujui':
        return Icons.check_circle;
      case 'pending':
      case 'menunggu':
        return Icons.access_time;
      case 'nonaktif':
      case 'inactive':
      case 'ditolak':
        return Icons.cancel;
      case 'diproses':
        return Icons.settings;
      case 'selesai':
        return Icons.flag;
      default:
        return Icons.help;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(_getIcon(), size: fontSize, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            status,
            style: TextStyle(
              color: color,
              fontSize: fontSize,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}