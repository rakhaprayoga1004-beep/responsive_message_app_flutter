import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';

class SettingsNavigation extends StatelessWidget {
  final String activeTab;
  final Function(String) onTabChanged;

  const SettingsNavigation({
    super.key,
    required this.activeTab,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SettingsProvider>(context);
    final stats = provider.systemStats;
    final mailerSendConfig = provider.mailerSendConfig;
    final fonnteConfig = provider.fonnteConfig;
    final backupFiles = provider.backupFiles;

    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey, width: 0.5),
              ),
            ),
            child: const Text(
              'Menu Pengaturan',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0B4D8A),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildNavItem(
                  context,
                  icon: Icons.settings,
                  label: 'Umum',
                  tabId: 'general',
                ),
                _buildNavItem(
                  context,
                  icon: Icons.label,
                  label: 'Jenis Pesan',
                  tabId: 'message_types',
                  badge: '${provider.messageTypes.length}',
                ),
                _buildNavItem(
                  context,
                  icon: Icons.description,
                  label: 'Template Respons',
                  tabId: 'templates',
                  badge: '${provider.templates.length}',
                ),
                _buildNavItem(
                  context,
                  icon: Icons.people,
                  label: 'Manajemen Pengguna',
                  tabId: 'users',
                  badge: '${provider.users.length}',
                ),
                _buildNavItem(
                  context,
                  icon: Icons.notifications,
                  label: 'Notifikasi',
                  tabId: 'notifications',
                ),
                _buildNavItem(
                  context,
                  icon: Icons.security,
                  label: 'Sistem & Keamanan',
                  tabId: 'system',
                ),
                _buildNavItem(
                  context,
                  icon: Icons.history,
                  label: 'Audit Trail',
                  tabId: 'audit',
                  badge: '${provider.auditLogs.length}',
                ),
                _buildNavItem(
                  context,
                  icon: Icons.backup,
                  label: 'Backup & Restore',
                  tabId: 'backup',
                  badge: '${backupFiles.length}',
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey, width: 0.5),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.check_circle, size: 14, color: Colors.green),
                    SizedBox(width: 8),
                    Text(
                      'System Status',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Database:',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Active',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildStatusItem('Size', '${stats?.dbSizeMb ?? 0} MB', Colors.blue),
                const SizedBox(height: 8),
                _buildStatusItem('Last 24h logs', '${stats?.logs24h ?? 0}', Colors.orange),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'MailerSend:',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: (mailerSendConfig?.isActive ?? false) 
                            ? Colors.green.withOpacity(0.1) 
                            : Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        (mailerSendConfig?.isActive ?? false) ? 'Aktif' : 'Nonaktif',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: (mailerSendConfig?.isActive ?? false) ? Colors.green : Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Fonnte:',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: (fonnteConfig?.isActive ?? false) 
                            ? Colors.green.withOpacity(0.1) 
                            : Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        (fonnteConfig?.isActive ?? false) ? 'Aktif' : 'Nonaktif',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: (fonnteConfig?.isActive ?? false) ? Colors.green : Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildStatusItem('Backups', '${backupFiles.length} files', Colors.purple),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, {
    required IconData icon,
    required String label,
    required String tabId,
    String? badge,
  }) {
    final isActive = activeTab == tabId;
    
    return InkWell(
      onTap: () => onTabChanged(tabId),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFE7F1FF) : Colors.transparent,
          border: Border(
            left: BorderSide(
              color: isActive ? const Color(0xFF0B4D8A) : Colors.transparent,
              width: 4,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isActive ? const Color(0xFF0B4D8A) : Colors.grey.shade600,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  color: isActive ? const Color(0xFF0B4D8A) : Colors.grey.shade800,
                ),
              ),
            ),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isActive ? const Color(0xFF0B4D8A) : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isActive ? Colors.white : Colors.grey.shade600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusItem(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}