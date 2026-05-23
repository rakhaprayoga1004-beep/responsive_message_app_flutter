import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/settings_service.dart';
import '../models/settings_models.dart';

class SettingsProvider extends ChangeNotifier {
  final SettingsService _service = SettingsService();

  // State
  GeneralSettings? _generalSettings;
  List<MessageType> _messageTypes = [];
  List<ResponseTemplate> _templates = [];
  
  // 🔥 DATA UNTUK TAMPILAN (BISA DIFILTER)
  List<User> _allUsers = [];      // SEMUA user dari database
  List<User> _filteredUsers = []; // User yang sedang ditampilkan (terfilter)
  bool _allUsersLoaded = false;
  
  // 🔥 DATA KHUSUS UNTUK COUNTER "SEMUA" - SEPENUHNYA TERPISAH!
  int _counterTotalAllUsers = 0;
  final Map<String, int> _counterTypeCounts = {};
  bool _counterDataLoaded = false;
  
  MailerSendConfig? _mailerSendConfig;
  FonnteConfig? _fonnteConfig;
  SystemStats? _systemStats;
  bool _systemStatsLoaded = false;
  List<AuditLog> _auditLogs = [];
  List<BackupFile> _backupFiles = [];

  bool _isLoading = false;
  String? _error;
  String _currentUserFilter = '';

  // Getters
  GeneralSettings? get generalSettings => _generalSettings;
  List<MessageType> get messageTypes => _messageTypes;
  List<ResponseTemplate> get templates => _templates;
  List<User> get users => _filteredUsers;
  List<User> get allUsers => _allUsers;
  
  // 🔥 GETTER UNTUK COUNTER - DARI DATA TERPISAH!
  int get counterTotalAllUsers => _counterTotalAllUsers;
  Map<String, int> get counterTypeCounts => _counterTypeCounts;
  bool get isCounterDataLoaded => _counterDataLoaded;
  
  MailerSendConfig? get mailerSendConfig => _mailerSendConfig;
  FonnteConfig? get fonnteConfig => _fonnteConfig;
  SystemStats? get systemStats => _systemStats;
  List<AuditLog> get auditLogs => _auditLogs;
  List<BackupFile> get backupFiles => _backupFiles;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get currentUserFilter => _currentUserFilter;

  // ============================================
  // LOAD ALL DATA
  // ============================================
  
  Future<void> loadAllSettings() async {
    _setLoading(true);
    try {
      await Future.wait([
        loadGeneralSettings(),
        loadMessageTypes(),
        loadTemplates(),
        loadUsers(),
        loadMailerSendConfig(),
        loadFonnteConfig(),
        loadSystemStats(),
        loadAuditLogs(),
        loadBackupFiles(),
      ]);
      _error = null;
      if (kDebugMode) {
        print('✅ All settings loaded successfully');
      }
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('❌ Error loading all settings: $e');
      }
    } finally {
      _setLoading(false);
    }
  }

  // ============================================
  // LOAD METHODS
  // ============================================
  
  Future<void> loadGeneralSettings() async {
    try {
      _generalSettings = await _service.getGeneralSettings();
      if (kDebugMode) {
        print('✅ General settings loaded: ${_generalSettings?.appName}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading general settings: $e');
      }
      _generalSettings = _getDefaultGeneralSettings();
    }
    notifyListeners();
  }

  Future<void> loadMessageTypes() async {
    try {
      if (kDebugMode) {
        print('🔄 Loading message types from API...');
      }
      _messageTypes = await _service.getMessageTypes();
      if (kDebugMode) {
        print('✅ Loaded ${_messageTypes.length} message types from API');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading message types: $e');
      }
      _messageTypes = [];
    }
    notifyListeners();
  }

  Future<void> loadTemplates() async {
    try {
      if (kDebugMode) {
        print('🔄 Loading templates from API...');
      }
      _templates = await _service.getResponseTemplates();
      if (kDebugMode) {
        print('✅ Loaded ${_templates.length} templates from API');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading templates: $e');
      }
      _templates = [];
    }
    notifyListeners();
  }

  // 🔥 loadUsers - HANYA SEKALI, TIDAK PERNAH DIPANGGIL ULANG
  Future<void> loadUsers() async {
    if (_allUsersLoaded) {
      if (kDebugMode) {
        print('⚠️ Users already loaded, skipping...');
        print('   Stack trace:');
        print(StackTrace.current);
      }
      return;
    }
    
    try {
      _isLoading = true;
      notifyListeners();
      
      if (kDebugMode) {
        print('🔄 Loading ALL users from API (first and last time)...');
        print('   🔥 This should ONLY happen ONCE!');
      }
      
      _allUsers = await _service.getUsers();
      _filteredUsers = List.from(_allUsers);
      _allUsersLoaded = true;
      _currentUserFilter = '';
      
      if (kDebugMode) {
        print('✅ Loaded ${_allUsers.length} users from API');
        print('   All users stored in cache');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading users: $e');
      }
      _allUsers = _getDefaultUsers();
      _filteredUsers = List.from(_allUsers);
      _allUsersLoaded = true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 🔥🔥🔥 KRUSIAL: loadCounterData - UNTUK COUNTER "SEMUA" - SEPENUHNYA TERPISAH!
  Future<void> loadCounterData() async {
    if (_counterDataLoaded) {
      if (kDebugMode) {
        print('⚠️ Counter data already loaded, skipping...');
      }
      return;
    }
    
    try {
      if (kDebugMode) {
        print('🔄 Loading COUNTER data from independent API...');
        print('   🔥 This data is for "Semua" counter only!');
        print('   🔥 This API call is COMPLETELY INDEPENDENT from filters!');
      }
      
      final result = await _service.getTotalUserStats();
      
      if (result['success'] == true) {
        _counterTotalAllUsers = result['total_all_users'];
        _counterTypeCounts.clear();
        _counterTypeCounts.addAll(Map<String, int>.from(result['stats_by_type']));
        _counterDataLoaded = true;
        
        if (kDebugMode) {
          print('═══════════════════════════════════════════════════════════');
          print('✅ COUNTER DATA LOADED (INDEPENDENT):');
          print('   Total All Users: $_counterTotalAllUsers');
          print('   Stats by type: $_counterTypeCounts');
          print('   🔥 This data is from DIRECT DATABASE QUERY!');
          print('   🔥 NOT affected by any filter whatsoever!');
          print('═══════════════════════════════════════════════════════════');
        }
      } else {
        // Fallback
        _counterTotalAllUsers = _allUsers.length;
        _counterTypeCounts.clear();
        for (final user in _allUsers) {
          _counterTypeCounts[user.userType] = (_counterTypeCounts[user.userType] ?? 0) + 1;
        }
        _counterDataLoaded = true;
        if (kDebugMode) {
          print('⚠️ Using fallback data for counter');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading counter data: $e');
      }
      _counterTotalAllUsers = _allUsers.length;
      _counterTypeCounts.clear();
      for (final user in _allUsers) {
        _counterTypeCounts[user.userType] = (_counterTypeCounts[user.userType] ?? 0) + 1;
      }
      _counterDataLoaded = true;
    }
    notifyListeners();
  }

  // 🔥 filterUsers - CLIENT-SIDE ONLY
  void filterUsers(String userType) {
    if (kDebugMode) {
      print('🔍 filterUsers called with: $userType');
      print('   _allUsers.length: ${_allUsers.length}');
      print('   🔥 This is CLIENT-SIDE filter, NO API call!');
    }
    
    if (userType.isEmpty || userType == 'Semua') {
      _filteredUsers = List.from(_allUsers);
      _currentUserFilter = '';
      if (kDebugMode) {
        print('🔍 Filter removed - showing all ${_allUsers.length} users');
      }
    } else {
      _filteredUsers = _allUsers.where((u) => u.userType == userType).toList();
      _currentUserFilter = userType;
      if (kDebugMode) {
        print('🔍 Filter applied: $userType');
        print('   Filtered users: ${_filteredUsers.length}');
      }
    }
    notifyListeners();
  }

  Future<void> loadMailerSendConfig() async {
    try {
      _mailerSendConfig = await _service.getMailerSendConfig();
      if (kDebugMode) {
        print('✅ MailerSend config loaded, isActive: ${_mailerSendConfig?.isActive}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading MailerSend config: $e');
      }
      _mailerSendConfig = _getDefaultMailerSendConfig();
    }
    notifyListeners();
  }

  Future<void> loadFonnteConfig() async {
    try {
      _fonnteConfig = await _service.getFonnteConfig();
      if (kDebugMode) {
        print('✅ Fonnte config loaded, isActive: ${_fonnteConfig?.isActive}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading Fonnte config: $e');
      }
      _fonnteConfig = _getDefaultFonnteConfig();
    }
    notifyListeners();
  }

  Future<void> loadSystemStats() async {
    if (_systemStatsLoaded) {
      if (kDebugMode) {
        print('⚠️ System stats already loaded, skipping...');
      }
      return;
    }
    
    try {
      _systemStats = await _service.getSystemStats();
      _systemStatsLoaded = true;
      
      if (kDebugMode) {
        print('✅ System stats loaded (ONCE)');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading system stats: $e');
      }
      _systemStats = _getDefaultSystemStats();
      _systemStatsLoaded = true;
    }
    notifyListeners();
  }

  Future<void> loadAuditLogs() async {
    try {
      _auditLogs = await _service.getAuditLogs();
      if (kDebugMode) {
        print('✅ Loaded ${_auditLogs.length} audit logs from API');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading audit logs: $e');
      }
      _auditLogs = _getDefaultAuditLogs();
    }
    notifyListeners();
  }

  Future<void> loadBackupFiles() async {
    try {
      _backupFiles = await _service.getBackupFiles();
      if (kDebugMode) {
        print('✅ Loaded ${_backupFiles.length} backup files from API');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading backup files: $e');
      }
      _backupFiles = _getDefaultBackupFiles();
    }
    notifyListeners();
  }

  // ============================================
  // UPDATE METHODS (sama seperti sebelumnya)
  // ============================================
  
  Future<bool> updateGeneralSettings(GeneralSettings settings) async {
    _setLoading(true);
    try {
      final success = await _service.updateGeneralSettings(settings);
      if (success) {
        _generalSettings = settings;
        notifyListeners();
      }
      return success;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<MessageType?> createMessageType(MessageType type) async {
    _setLoading(true);
    try {
      final newType = await _service.createMessageType(type);
      _messageTypes.add(newType);
      notifyListeners();
      return newType;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<MessageType?> updateMessageType(int id, MessageType type) async {
    _setLoading(true);
    try {
      final updatedType = await _service.updateMessageType(id, type);
      final index = _messageTypes.indexWhere((t) => t.id == id);
      if (index != -1) {
        _messageTypes[index] = updatedType;
        notifyListeners();
      }
      return updatedType;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteMessageType(int id) async {
    _setLoading(true);
    try {
      final success = await _service.deleteMessageType(id);
      if (success) {
        _messageTypes.removeWhere((t) => t.id == id);
        notifyListeners();
      }
      return success;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<ResponseTemplate?> createTemplate(ResponseTemplate template) async {
    _setLoading(true);
    try {
      final newTemplate = await _service.createTemplate(template);
      _templates.add(newTemplate);
      notifyListeners();
      return newTemplate;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<ResponseTemplate?> updateTemplate(int id, ResponseTemplate template) async {
    _setLoading(true);
    try {
      final updatedTemplate = await _service.updateTemplate(id, template);
      final index = _templates.indexWhere((t) => t.id == id);
      if (index != -1) {
        _templates[index] = updatedTemplate;
        notifyListeners();
      }
      return updatedTemplate;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteTemplate(int id) async {
    _setLoading(true);
    try {
      final success = await _service.deleteTemplate(id);
      if (success) {
        _templates.removeWhere((t) => t.id == id);
        notifyListeners();
      }
      return success;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // 🔥 updateUserStatus - update di kedua list
  Future<bool> updateUserStatus(int userId, bool isActive) async {
    _setLoading(true);
    try {
      final success = await _service.updateUserStatus(userId, isActive);
      if (success) {
        // Update di _allUsers
        final allIndex = _allUsers.indexWhere((u) => u.id == userId);
        if (allIndex != -1) {
          final user = _allUsers[allIndex];
          _allUsers[allIndex] = User(
            id: user.id,
            namaLengkap: user.namaLengkap,
            email: user.email,
            userType: user.userType,
            isActive: isActive,
            totalMessages: user.totalMessages,
            totalResponses: user.totalResponses,
            username: user.username,
            noTelp: user.noTelp,
            nisNip: user.nisNip,
            kelas: user.kelas,
            jurusan: user.jurusan,
            mataPelajaran: user.mataPelajaran,
            foto: user.foto,
            lastLogin: user.lastLogin,
            updatedAt: user.updatedAt,
          );
        }
        
        // Update di _filteredUsers
        final filteredIndex = _filteredUsers.indexWhere((u) => u.id == userId);
        if (filteredIndex != -1) {
          final user = _filteredUsers[filteredIndex];
          _filteredUsers[filteredIndex] = User(
            id: user.id,
            namaLengkap: user.namaLengkap,
            email: user.email,
            userType: user.userType,
            isActive: isActive,
            totalMessages: user.totalMessages,
            totalResponses: user.totalResponses,
            username: user.username,
            noTelp: user.noTelp,
            nisNip: user.nisNip,
            kelas: user.kelas,
            jurusan: user.jurusan,
            mataPelajaran: user.mataPelajaran,
            foto: user.foto,
            lastLogin: user.lastLogin,
            updatedAt: user.updatedAt,
          );
        }
        
        if (kDebugMode) {
          print('✅ User status updated: userId=$userId, isActive=$isActive');
        }
        notifyListeners();
      }
      return success;
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('❌ Error updating user status: $e');
      }
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> resetUserPassword(int userId) async {
    _setLoading(true);
    try {
      return await _service.resetUserPassword(userId);
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('❌ Error resetting password: $e');
      }
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ... (method update lainnya sama seperti sebelumnya, tidak diubah)
  
  Future<bool> updateMailerSendConfig(MailerSendConfig config) async {
    _setLoading(true);
    try {
      final success = await _service.updateMailerSendConfig(config);
      if (success) {
        _mailerSendConfig = config;
        notifyListeners();
      }
      return success;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateFonnteConfig(FonnteConfig config) async {
    _setLoading(true);
    try {
      final success = await _service.updateFonnteConfig(config);
      if (success) {
        _fonnteConfig = config;
        notifyListeners();
      }
      return success;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<TestResult?> testMailerSendConnection(MailerSendConfig config) async {
    _setLoading(true);
    try {
      return await _service.testMailerSendConnection(config);
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<TestResult?> sendTestEmail(String email, MailerSendConfig config) async {
    _setLoading(true);
    try {
      return await _service.sendTestEmail(email, config);
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<TestResult?> testFonnteConnection(FonnteConfig config) async {
    _setLoading(true);
    try {
      return await _service.testFonnteConnection(config);
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<TestResult?> sendTestWhatsApp(String phone, FonnteConfig config) async {
    _setLoading(true);
    try {
      return await _service.sendTestWhatsApp(phone, config);
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> clearOldLogs(int days) async {
    _setLoading(true);
    try {
      final success = await _service.clearOldLogs(days);
      if (success) {
        await loadAuditLogs();
      }
      return success;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<BackupResult?> createBackup() async {
    _setLoading(true);
    try {
      final result = await _service.createBackup();
      if (result.success) {
        await loadBackupFiles();
        await loadSystemStats();
      }
      return result;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<BackupResult?> restoreBackup(String filePath) async {
    _setLoading(true);
    try {
      final result = await _service.restoreBackup(filePath);
      if (result.success) {
        await loadBackupFiles();
        await loadSystemStats();
      }
      return result;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteBackupFile(String filename) async {
    _setLoading(true);
    try {
      final success = await _service.deleteBackupFile(filename);
      if (success) {
        await loadBackupFiles();
      }
      return success;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<String?> exportConfig() async {
    _setLoading(true);
    try {
      return await _service.exportConfig();
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> importConfig(String configJson) async {
    _setLoading(true);
    try {
      final success = await _service.importConfig(configJson);
      if (success) {
        await loadAllSettings();
      }
      return success;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // ============================================
  // DEFAULT DATA (FALLBACK)
  // ============================================
  
  GeneralSettings _getDefaultGeneralSettings() {
    return GeneralSettings(
      appName: 'Responsive Message SMKN 12 Jakarta',
      appUrl: 'http://localhost:8080/responsive-message-app/',
      schoolName: 'SMKN 12 Jakarta',
      schoolAddress: 'Jl. Kebon Bawang XV B Mo. 15, Tanjung Priok, Jakarta Utara 14320',
      schoolPhone: '(021) 43932785, 43913815',
      schoolEmail: 'info@smkn12jakarta.sch.id',
      adminEmail: 'admin@smkn12jakarta.sch.id',
      timezone: 'Asia/Jakarta',
      dateFormat: 'd/m/Y',
      timeFormat: 'H:i:s',
      itemsPerPage: 10,
      enableRegistration: true,
      requireEmailVerification: false,
      maintenanceMode: false,
    );
  }

  List<User> _getDefaultUsers() {
    return [
      User(id: 1, namaLengkap: 'Administrator Sistem', email: 'admin@smkn12jakarta.sch.id', userType: 'Admin', isActive: true, totalMessages: 0, totalResponses: 156),
      User(id: 2, namaLengkap: 'Budi Santoso', email: 'budi.santoso@smkn12jakarta.sch.id', userType: 'Guru_BK', isActive: true, totalMessages: 12, totalResponses: 89),
      User(id: 3, namaLengkap: 'Siti Aisyah', email: 'siti.aisyah@smkn12jakarta.sch.id', userType: 'Guru_BK', isActive: true, totalMessages: 8, totalResponses: 67),
    ];
  }

  MailerSendConfig _getDefaultMailerSendConfig() {
    return MailerSendConfig(
      apiToken: 'mlsn.7a4863017c865129ae7e7c08ca9902a7f714e0471233fab979e6a2522cc07c4d',
      domain: 'test-r6ke4n1616ygon12.mlsender.net',
      domainId: 'eqvygm0pwkwl0p7w',
      fromEmail: 'noreply@test-r6ke4n1616ygon12.mlsender.net',
      fromName: 'SMKN 12 Jakarta - Aplikasi Pesan Responsif',
      smtpServer: 'smtp.mailersend.net',
      smtpUsername: '',
      smtpPassword: '',
      smtpPort: 587,
      smtpEncryption: 'tls',
      testDomain: 'test-r6ke4n1616ygon12.mlsender.net',
      isActive: true,
    );
  }

  FonnteConfig _getDefaultFonnteConfig() {
    return FonnteConfig(
      apiToken: 'FS2cq8FckmaTegxtZpFB',
      accountToken: 'hzCktiDwSP1sfdXt4PrNtmFkaamX',
      deviceId: '6285174207795',
      apiUrl: 'https://api.fonnte.com/send',
      email: '',
      password: '',
      countryCode: '62',
      isActive: true,
    );
  }

  SystemStats _getDefaultSystemStats() {
    return SystemStats(
      totalUsers: 60,
      activeUsers: 60,
      totalMessages: 156,
      totalResponses: 245,
      totalExternal: 2,
      logs24h: 0,
      dbSizeMb: 1.45,
    );
  }

  List<AuditLog> _getDefaultAuditLogs() {
    return [
      AuditLog(
        id: 1,
        userName: 'Administrator Sistem',
        actionType: 'UPDATE',
        tableName: 'users',
        recordId: 1,
        newValue: 'Updated user settings',
        ipAddress: '127.0.0.1',
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),
      AuditLog(
        id: 2,
        userName: 'System',
        actionType: 'INSERT',
        tableName: 'users',
        recordId: 2,
        newValue: 'Created new user',
        ipAddress: '127.0.0.1',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];
  }

  List<BackupFile> _getDefaultBackupFiles() {
    return [
      BackupFile(
        name: 'backup_responsive_message_db_2026-03-01_15-16-31.sql',
        path: '/backups/backup_responsive_message_db_2026-03-01_15-16-31.sql',
        size: 340000,
        sizeFormatted: '332.86 KB',
        date: DateTime(2026, 3, 1, 15, 16, 33),
        dateFormatted: '01/03/2026 15:16:33',
      ),
    ];
  }
}