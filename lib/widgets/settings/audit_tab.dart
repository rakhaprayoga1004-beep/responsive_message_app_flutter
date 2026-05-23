import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../models/settings_models.dart';

class AuditTab extends StatefulWidget {
  const AuditTab({super.key});

  @override
  State<AuditTab> createState() => _AuditTabState();
}

class _AuditTabState extends State<AuditTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<SettingsProvider>(context, listen: false);
      provider.loadAuditLogs();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, provider, child) {
        final auditLogs = provider.auditLogs;
        
        if (kDebugMode) {
          print('📜 AuditTab - auditLogs length: ${auditLogs.length}');
        }
        
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Audit Trail',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0B4D8A),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Riwayat aktivitas sistem',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  Badge(
                    label: Text('50 Log Terbaru'),
                    backgroundColor: Color(0xFF0B4D8A),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (provider.isLoading)
                const Center(child: CircularProgressIndicator())
              else if (auditLogs.isEmpty)
                _buildEmptyState()
              else
                Expanded(
                  child: _buildAuditTable(auditLogs),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 60),
          Icon(
            Icons.history,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'Belum ada log aktivitas',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _buildAuditTable(List<AuditLog> auditLogs) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildTableHeader(),
          Expanded(
            child: ListView.separated(
              itemCount: auditLogs.length,
              separatorBuilder: (context, index) => Divider(
                height: 0,
                color: Colors.grey.shade200,
              ),
              itemBuilder: (context, index) {
                final log = auditLogs[index];
                return _buildAuditRow(log);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: const Row(
        children: [
          Expanded(flex: 1, child: Text('Waktu', style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(flex: 1, child: Text('Pengguna', style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(flex: 1, child: Text('Aksi', style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(flex: 1, child: Text('Tabel', style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(flex: 1, child: Text('ID', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
          Expanded(flex: 3, child: Text('Deskripsi', style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(flex: 1, child: Text('IP Address', style: TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildAuditRow(AuditLog log) {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Text(
              _formatDate(log.createdAt),
              style: const TextStyle(fontSize: 12),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              log.userName ?? 'System',
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getActionColor(log.actionType).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                log.actionType,
                style: TextStyle(
                  fontSize: 11,
                  color: _getActionColor(log.actionType),
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              log.tableName ?? '-',
              style: const TextStyle(fontSize: 12),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              '${log.recordId ?? '-'}',
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 3,
            child: Tooltip(
              message: log.newValue ?? '-',
              child: Text(
                _truncateDescription(log.newValue ?? '-'),
                style: const TextStyle(fontSize: 11),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              log.ipAddress ?? '-',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  String _truncateDescription(String description) {
    if (description.length > 100) {
      return '${description.substring(0, 100)}...';
    }
    return description;
  }

  Color _getActionColor(String action) {
    switch (action.toUpperCase()) {
      case 'CREATE':
      case 'INSERT':
      case 'REGISTER':
        return Colors.green;
      case 'UPDATE':
        return Colors.blue;
      case 'DELETE':
        return Colors.red;
      case 'BACKUP':
        return Colors.orange;
      case 'RESTORE':
        return Colors.purple;
      case 'LOGIN':
        return Colors.indigo;
      case 'LOGOUT':
        return Colors.grey;
      case 'IMPORT':
        return Colors.teal;
      case 'EXPORT':
        return Colors.cyan;
      case 'CLEANUP':
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}';
  }
}