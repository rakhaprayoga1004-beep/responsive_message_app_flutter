import '../utils/environment.dart';

class ApiConstants {
  static String get baseUrl => Environment.baseUrl;
  static const String sessionName = 'RMSESSID'; // Nama session dari config.php
  
  // Auth endpoints
  static const String login = '/api/login_flutter.php';
  static const String register = '/api/auth/register.php';
  static const String logout = '/api/auth/logout.php';
  static const String verify = '/api/auth/verify.php';
  
  // Settings endpoints
  static const String settingsGeneral = '/api/settings/general.php';
  static const String settingsMessageTypes = '/api/message_types.php';
  static const String settingsTemplates = '/api/response_templates.php';
  static const String settingsUsers = '/api/users.php';
  static const String settingsMailerSend = '/api/settings/mailersend.php';
  static const String settingsFonnte = '/api/settings/fonnte.php';
  static const String settingsSystemStats = '/api/settings/stats.php';
  static const String settingsAuditLogs = '/api/audit_logs.php';
  static const String settingsBackup = '/api/backup.php';
  
  // Backup actions
  static const String backupCreate = '/api/backup.php?action=create';
  static const String backupList = '/api/backup.php?action=list';
  static const String backupRestore = '/api/backup.php?action=restore';
  static const String backupDelete = '/api/backup.php?action=delete';
  static const String backupDownload = '/api/backup.php?action=download';
  
  // User actions
  static const String userStatus = '/api/users.php?action=status';
  static const String userResetPassword = '/api/users.php?action=reset-password';
  
  // Test endpoints
  static const String testMailerSend = '/api/settings/mailersend_test.php';
  static const String testEmail = '/api/settings/mailersend_test.php?action=email';
  static const String testFonnte = '/api/settings/fonnte_test.php';
  static const String testWhatsApp = '/api/settings/fonnte_test.php?action=whatsapp';
  
  // Export/Import
  static const String exportConfig = '/api/settings/export.php';
  static const String importConfig = '/api/settings/import.php';
  
  // Clear logs
  static const String clearLogs = '/api/audit_logs.php';
}