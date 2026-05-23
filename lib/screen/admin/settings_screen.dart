// lib/screen/admin/settings_screen.dart
// PERBAIKAN KHUSUS UNTUK FITUR BACKUP DATABASE
// Berdasarkan skrip modules/admin/settings.php versi 4.4.0

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../utils/helpers.dart';
import '../../widgets/window_resizer_shortcut.dart'; // Import window resizer shortcut
import '../../utils/environment.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with SingleTickerProviderStateMixin {
  // Tab
  int _selectedTab = 0;
  late TabController _tabController;
  
  // Loading states
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isTesting = false;
  String? _errorMsg;
  
  // Settings data
  Map<String, dynamic> _generalSettings = {};
  List<dynamic> _messageTypes = [];
  List<dynamic> _templates = [];
  List<dynamic> _users = [];
  List<dynamic> _auditLogs = [];
  List<dynamic> _backupFiles = [];
  Map<String, dynamic> _systemStats = {};
  Map<String, dynamic> _mailerSendConfig = {};
  Map<String, dynamic> _fonnteConfig = {};
  Map<String, dynamic> _systemInfo = {};
  
  // Pagination for Users
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalUsers = 0;
  int _itemsPerPage = 10;
  List<dynamic> _paginatedUsers = [];
  bool _isLoadingUsers = false;
  
  // Clear logs controller
  final TextEditingController _clearLogsDaysController = TextEditingController(text: '30');
  
  // Form controllers for General Settings
  final TextEditingController _appNameController = TextEditingController();
  final TextEditingController _appUrlController = TextEditingController();
  final TextEditingController _schoolNameController = TextEditingController();
  final TextEditingController _schoolAddressController = TextEditingController();
  final TextEditingController _schoolPhoneController = TextEditingController();
  final TextEditingController _schoolEmailController = TextEditingController();
  final TextEditingController _adminEmailController = TextEditingController();
  final TextEditingController _itemsPerPageController = TextEditingController();
  bool _enableRegistration = true;
  bool _requireEmailVerification = false;
  bool _maintenanceMode = false;
  String _timezone = 'Asia/Jakarta';
  String _dateFormat = 'd/m/Y';
  String _timeFormat = 'H:i:s';
  
  // MailerSend controllers
  final TextEditingController _mailerSendApiTokenController = TextEditingController();
  final TextEditingController _mailerSendDomainController = TextEditingController();
  final TextEditingController _mailerSendDomainIdController = TextEditingController();
  final TextEditingController _mailerSendFromEmailController = TextEditingController();
  final TextEditingController _mailerSendFromNameController = TextEditingController();
  final TextEditingController _mailerSendTestEmailController = TextEditingController();
  final TextEditingController _mailerSendSmtpServerController = TextEditingController(text: 'smtp.mailersend.net');
  final TextEditingController _mailerSendSmtpUsernameController = TextEditingController();
  final TextEditingController _mailerSendSmtpPasswordController = TextEditingController();
  final TextEditingController _mailerSendSmtpPortController = TextEditingController(text: '587');
  String _mailerSendSmtpEncryption = 'tls';
  bool _mailerSendActive = true;
  
  // Fonnte controllers
  final TextEditingController _fonnteApiTokenController = TextEditingController();
  final TextEditingController _fonnteAccountTokenController = TextEditingController();
  final TextEditingController _fonnteDeviceIdController = TextEditingController();
  final TextEditingController _fonnteApiUrlController = TextEditingController(text: 'https://api.fonnte.com/send');
  final TextEditingController _fonnteEmailController = TextEditingController();
  final TextEditingController _fonntePasswordController = TextEditingController();
  final TextEditingController _fonnteCountryCodeController = TextEditingController(text: '62');
  final TextEditingController _fonnteTestPhoneController = TextEditingController();
  bool _fonnteActive = true;
  
  // Message Type form
  final TextEditingController _messageTypeNameController = TextEditingController();
  final TextEditingController _messageTypeDescController = TextEditingController();
  final TextEditingController _messageTypeDeadlineController = TextEditingController(text: '72');
  String _messageTypeResponderType = 'Guru_BK';
  String _messageTypeColorCode = '#0d6efd';
  String _messageTypeIconClass = 'fas fa-envelope';
  bool _messageTypeAllowExternal = true;
  bool _messageTypeActive = true;
  int? _editingMessageTypeId;
  
  // Template form
  final TextEditingController _templateNameController = TextEditingController();
  final TextEditingController _templateContentController = TextEditingController();
  String _templateCategory = 'Umum';
  String _templateDefaultStatus = 'Disetujui';
  String _templateGuruType = 'ALL';
  bool _templateActive = true;
  int? _editingTemplateId;
  
  // Progress tracking for backup/restore
  double _backupProgress = 0.0;
  String _backupStatus = '';
  bool _isRestoring = false;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 8, vsync: this);
    _tabController.addListener(_handleTabChange);
    _loadAllData();
  }
  
  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _appNameController.dispose();
    _appUrlController.dispose();
    _schoolNameController.dispose();
    _schoolAddressController.dispose();
    _schoolPhoneController.dispose();
    _schoolEmailController.dispose();
    _adminEmailController.dispose();
    _itemsPerPageController.dispose();
    _clearLogsDaysController.dispose();
    _mailerSendApiTokenController.dispose();
    _mailerSendDomainController.dispose();
    _mailerSendDomainIdController.dispose();
    _mailerSendFromEmailController.dispose();
    _mailerSendFromNameController.dispose();
    _mailerSendTestEmailController.dispose();
    _mailerSendSmtpServerController.dispose();
    _mailerSendSmtpUsernameController.dispose();
    _mailerSendSmtpPasswordController.dispose();
    _mailerSendSmtpPortController.dispose();
    _fonnteApiTokenController.dispose();
    _fonnteAccountTokenController.dispose();
    _fonnteDeviceIdController.dispose();
    _fonnteApiUrlController.dispose();
    _fonnteEmailController.dispose();
    _fonntePasswordController.dispose();
    _fonnteCountryCodeController.dispose();
    _fonnteTestPhoneController.dispose();
    _messageTypeNameController.dispose();
    _messageTypeDescController.dispose();
    _messageTypeDeadlineController.dispose();
    _templateNameController.dispose();
    _templateContentController.dispose();
    super.dispose();
  }
  
  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      setState(() {
        _selectedTab = _tabController.index;
      });
      _loadDataForTab(_selectedTab);
    }
  }
  
  Future<void> _loadAllData() async {
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });
    
    try {
      await Future.wait([
        _loadGeneralSettings(),
        _loadMessageTypes(),
        _loadTemplates(),
        _loadUsers(page: 1),
        _loadAuditLogs(),
        _loadBackupFiles(),
        _loadSystemInfo(),
        _loadNotificationsConfig(),
      ]);
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMsg = e.toString();
        _isLoading = false;
      });
    }
  }
  
  Future<void> _loadDataForTab(int tabIndex) async {
    try {
      switch (tabIndex) {
        case 0:
          await _loadGeneralSettings();
          break;
        case 1:
          await _loadMessageTypes();
          break;
        case 2:
          await _loadTemplates();
          break;
        case 3:
          await _loadUsers(page: _currentPage);
          break;
        case 4:
          await _loadNotificationsConfig();
          break;
        case 5:
          await _loadSystemInfo();
          break;
        case 6:
          await _loadAuditLogs();
          break;
        case 7:
          await _loadBackupFiles();
          break;
      }
    } catch (e) {
      print('Error loading tab data: $e');
    }
  }
  
  Future<void> _loadGeneralSettings() async {
    try {
      final result = await ApiService.getGeneralSettings();
      if (result['success'] == true) {
        final settingsList = result['data'] as List? ?? [];
        final Map<String, dynamic> settingsMap = {};
        for (var setting in settingsList) {
          settingsMap[setting['setting_key']] = setting['setting_value'];
        }
        setState(() {
          _generalSettings = settingsMap;
          _appNameController.text = settingsMap['app_name']?.toString() ?? 'Responsive Message App';
          _appUrlController.text = settingsMap['app_url']?.toString() ?? Environment.baseUrl;
          _schoolNameController.text = settingsMap['school_name']?.toString() ?? 'SMKN 12 Jakarta';
          _schoolAddressController.text = settingsMap['school_address']?.toString() ?? '';
          _schoolPhoneController.text = settingsMap['school_phone']?.toString() ?? '';
          _schoolEmailController.text = settingsMap['school_email']?.toString() ?? '';
          _adminEmailController.text = settingsMap['admin_email']?.toString() ?? '';
          _itemsPerPageController.text = settingsMap['items_per_page']?.toString() ?? '10';
          _enableRegistration = settingsMap['enable_registration'] == '1';
          _requireEmailVerification = settingsMap['require_email_verification'] == '1';
          _maintenanceMode = settingsMap['maintenance_mode'] == '1';
          _timezone = settingsMap['timezone']?.toString() ?? 'Asia/Jakarta';
          _dateFormat = settingsMap['date_format']?.toString() ?? 'd/m/Y';
          _timeFormat = settingsMap['time_format']?.toString() ?? 'H:i:s';
        });
      }
    } catch (e) {
      print('Error loading general settings: $e');
    }
  }
  
  Future<void> _loadMessageTypes() async {
    try {
      final result = await ApiService.getMessageTypes();
      if (result['success'] == true) {
        setState(() {
          _messageTypes = result['data'] ?? [];
        });
      }
    } catch (e) {
      print('Error loading message types: $e');
    }
  }
  
  Future<void> _loadTemplates() async {
    try {
      final result = await ApiService.getTemplates();
      if (result['success'] == true) {
        setState(() {
          _templates = result['data'] ?? [];
        });
      }
    } catch (e) {
      print('Error loading templates: $e');
    }
  }
  
  Future<void> _loadUsers({int page = 1}) async {
    setState(() {
      _isLoadingUsers = true;
    });
    
    try {
      final result = await ApiService.getUsers();
      if (result['success'] == true) {
        final allUsers = result['data'] ?? [];
        setState(() {
          _users = allUsers;
          _totalUsers = allUsers.length;
          _totalPages = (_totalUsers / _itemsPerPage).ceil();
          _currentPage = page.clamp(1, _totalPages);
          
          final startIndex = (_currentPage - 1) * _itemsPerPage;
          final endIndex = startIndex + _itemsPerPage;
          _paginatedUsers = _users.sublist(
            startIndex,
            endIndex > _users.length ? _users.length : endIndex
          );
          _isLoadingUsers = false;
        });
      }
    } catch (e) {
      print('Error loading users: $e');
      setState(() {
        _isLoadingUsers = false;
      });
    }
  }
  
  void _goToPage(int page) {
    if (page != _currentPage && page >= 1 && page <= _totalPages) {
      _loadUsers(page: page);
    }
  }
  
  Future<void> _loadAuditLogs() async {
    try {
      final result = await ApiService.getAuditLogs();
      if (result['success'] == true) {
        setState(() {
          _auditLogs = result['data'] ?? [];
        });
      }
    } catch (e) {
      print('Error loading audit logs: $e');
    }
  }
  
  Future<void> _loadBackupFiles() async {
    try {
      final result = await ApiService.getBackupFiles();
      if (result['success'] == true) {
        setState(() {
          _backupFiles = result['data']['backup_files'] ?? [];
          _systemStats = result['data']['system_stats'] ?? {};
        });
      }
    } catch (e) {
      print('Error loading backup files: $e');
    }
  }
  
  Future<void> _loadSystemInfo() async {
    try {
      final result = await ApiService.getSystemInfo();
      if (result['success'] == true) {
        setState(() {
          _systemInfo = result['data'] ?? {};
        });
      }
    } catch (e) {
      print('Error loading system info: $e');
    }
  }
  
  Future<void> _loadNotificationsConfig() async {
    try {
      final result = await ApiService.getNotificationsConfig();
      if (result['success'] == true) {
        final data = result['data'] ?? {};
        setState(() {
          _mailerSendConfig = data['mailersend'] ?? {};
          _mailerSendApiTokenController.text = _mailerSendConfig['api_token']?.toString() ?? '';
          _mailerSendDomainController.text = _mailerSendConfig['domain']?.toString() ?? '';
          _mailerSendDomainIdController.text = _mailerSendConfig['domain_id']?.toString() ?? '';
          _mailerSendFromEmailController.text = _mailerSendConfig['from_email']?.toString() ?? '';
          _mailerSendFromNameController.text = _mailerSendConfig['from_name']?.toString() ?? 'SMKN 12 Jakarta - Aplikasi Pesan Responsif';
          _mailerSendSmtpServerController.text = _mailerSendConfig['smtp_server']?.toString() ?? 'smtp.mailersend.net';
          _mailerSendSmtpUsernameController.text = _mailerSendConfig['smtp_username']?.toString() ?? '';
          _mailerSendSmtpPasswordController.text = _mailerSendConfig['smtp_password']?.toString() ?? '';
          _mailerSendSmtpPortController.text = _mailerSendConfig['smtp_port']?.toString() ?? '587';
          _mailerSendSmtpEncryption = _mailerSendConfig['smtp_encryption']?.toString() ?? 'tls';
          _mailerSendActive = _mailerSendConfig['is_active'] == 1;
          
          _fonnteConfig = data['fonnte'] ?? {};
          _fonnteApiTokenController.text = _fonnteConfig['api_token']?.toString() ?? '';
          _fonnteAccountTokenController.text = _fonnteConfig['account_token']?.toString() ?? '';
          _fonnteDeviceIdController.text = _fonnteConfig['device_id']?.toString() ?? '';
          _fonnteApiUrlController.text = _fonnteConfig['api_url']?.toString() ?? 'https://api.fonnte.com/send';
          _fonnteEmailController.text = _fonnteConfig['email']?.toString() ?? '';
          _fonntePasswordController.text = _fonnteConfig['password']?.toString() ?? '';
          _fonnteCountryCodeController.text = _fonnteConfig['country_code']?.toString() ?? '62';
          _fonnteActive = _fonnteConfig['is_active'] == 1;
        });
      }
    } catch (e) {
      print('Error loading notifications config: $e');
    }
  }
  
  Future<void> _saveGeneralSettings() async {
    setState(() => _isSaving = true);
    
    try {
      final settings = {
        'app_name': _appNameController.text,
        'app_url': _appUrlController.text,
        'school_name': _schoolNameController.text,
        'school_address': _schoolAddressController.text,
        'school_phone': _schoolPhoneController.text,
        'school_email': _schoolEmailController.text,
        'admin_email': _adminEmailController.text,
        'timezone': _timezone,
        'date_format': _dateFormat,
        'time_format': _timeFormat,
        'items_per_page': int.tryParse(_itemsPerPageController.text) ?? 10,
        'enable_registration': _enableRegistration ? '1' : '0',
        'require_email_verification': _requireEmailVerification ? '1' : '0',
        'maintenance_mode': _maintenanceMode ? '1' : '0',
      };
      
      final result = await ApiService.updateGeneralSettings(settings);
      
      if (result['success'] == true) {
        Helpers.showToast(context, 'Pengaturan umum berhasil disimpan');
        await _loadGeneralSettings();
      } else {
        Helpers.showToast(context, result['message'] ?? 'Gagal menyimpan pengaturan', isError: true);
      }
    } catch (e) {
      Helpers.showToast(context, 'Error: $e', isError: true);
    } finally {
      setState(() => _isSaving = false);
    }
  }
  
  Future<void> _saveMailerSendConfig() async {
    setState(() => _isSaving = true);
    
    try {
      final config = {
        'api_token': _mailerSendApiTokenController.text,
        'domain': _mailerSendDomainController.text,
        'domain_id': _mailerSendDomainIdController.text,
        'from_email': _mailerSendFromEmailController.text,
        'from_name': _mailerSendFromNameController.text,
        'smtp_server': _mailerSendSmtpServerController.text,
        'smtp_username': _mailerSendSmtpUsernameController.text,
        'smtp_password': _mailerSendSmtpPasswordController.text,
        'smtp_port': int.tryParse(_mailerSendSmtpPortController.text) ?? 587,
        'smtp_encryption': _mailerSendSmtpEncryption,
        'is_active': _mailerSendActive ? 1 : 0,
      };
      
      final result = await ApiService.updateMailerSendConfig(config);
      
      if (result['success'] == true) {
        Helpers.showToast(context, 'Konfigurasi MailerSend berhasil disimpan');
        await _loadNotificationsConfig();
      } else {
        Helpers.showToast(context, result['message'] ?? 'Gagal menyimpan', isError: true);
      }
    } catch (e) {
      Helpers.showToast(context, 'Error: $e', isError: true);
    } finally {
      setState(() => _isSaving = false);
    }
  }
  
  Future<void> _saveFonnteConfig() async {
    setState(() => _isSaving = true);
    
    try {
      final config = {
        'api_token': _fonnteApiTokenController.text,
        'account_token': _fonnteAccountTokenController.text,
        'device_id': _fonnteDeviceIdController.text,
        'api_url': _fonnteApiUrlController.text,
        'email': _fonnteEmailController.text,
        'password': _fonntePasswordController.text,
        'country_code': _fonnteCountryCodeController.text,
        'is_active': _fonnteActive ? 1 : 0,
      };
      
      final result = await ApiService.updateFonnteConfig(config);
      
      if (result['success'] == true) {
        Helpers.showToast(context, 'Konfigurasi Fonnte berhasil disimpan');
        await _loadNotificationsConfig();
      } else {
        Helpers.showToast(context, result['message'] ?? 'Gagal menyimpan', isError: true);
      }
    } catch (e) {
      Helpers.showToast(context, 'Error: $e', isError: true);
    } finally {
      setState(() => _isSaving = false);
    }
  }
  
  Future<void> _testMailerSendConnection() async {
    setState(() => _isTesting = true);
    
    try {
      final config = {
        'api_token': _mailerSendApiTokenController.text,
        'from_email': _mailerSendFromEmailController.text,
        'from_name': _mailerSendFromNameController.text,
        'domain': _mailerSendDomainController.text,
      };
      
      final result = await ApiService.testMailerSendConnection(config);
      
      if (result['success'] == true) {
        Helpers.showToast(context, result['message'] ?? 'Koneksi MailerSend berhasil');
      } else {
        Helpers.showToast(context, result['message'] ?? 'Koneksi gagal', isError: true);
      }
    } catch (e) {
      Helpers.showToast(context, 'Error: $e', isError: true);
    } finally {
      setState(() => _isTesting = false);
    }
  }
  
  Future<void> _sendTestEmail() async {
    if (_mailerSendTestEmailController.text.isEmpty) {
      Helpers.showToast(context, 'Email tujuan harus diisi', isError: true);
      return;
    }
    
    setState(() => _isTesting = true);
    
    try {
      final config = {
        'api_token': _mailerSendApiTokenController.text,
        'from_email': _mailerSendFromEmailController.text,
        'from_name': _mailerSendFromNameController.text,
        'domain': _mailerSendDomainController.text,
        'test_email': _mailerSendTestEmailController.text,
      };
      
      final result = await ApiService.sendTestEmail(config);
      
      if (result['success'] == true) {
        Helpers.showToast(context, result['message'] ?? 'Email test berhasil dikirim');
      } else {
        Helpers.showToast(context, result['message'] ?? 'Gagal mengirim email', isError: true);
      }
    } catch (e) {
      Helpers.showToast(context, 'Error: $e', isError: true);
    } finally {
      setState(() => _isTesting = false);
    }
  }
  
  Future<void> _testFonnteConnection() async {
    setState(() => _isTesting = true);
    
    try {
      final config = {
        'api_token': _fonnteApiTokenController.text,
        'device_id': _fonnteDeviceIdController.text,
        'api_url': _fonnteApiUrlController.text,
        'country_code': _fonnteCountryCodeController.text,
      };
      
      final result = await ApiService.testFonnteConnection(config);
      
      if (result['success'] == true) {
        Helpers.showToast(context, result['message'] ?? 'Koneksi Fonnte berhasil');
      } else {
        Helpers.showToast(context, result['message'] ?? 'Koneksi gagal', isError: true);
      }
    } catch (e) {
      Helpers.showToast(context, 'Error: $e', isError: true);
    } finally {
      setState(() => _isTesting = false);
    }
  }
  
  Future<void> _sendTestWhatsApp() async {
    if (_fonnteTestPhoneController.text.isEmpty) {
      Helpers.showToast(context, 'Nomor WhatsApp tujuan harus diisi', isError: true);
      return;
    }
    
    setState(() => _isTesting = true);
    
    try {
      final config = {
        'api_token': _fonnteApiTokenController.text,
        'device_id': _fonnteDeviceIdController.text,
        'api_url': _fonnteApiUrlController.text,
        'country_code': _fonnteCountryCodeController.text,
        'test_phone': _fonnteTestPhoneController.text,
      };
      
      final result = await ApiService.sendTestWhatsApp(config);
      
      if (result['success'] == true) {
        Helpers.showToast(context, result['message'] ?? 'WhatsApp test berhasil dikirim');
      } else {
        Helpers.showToast(context, result['message'] ?? 'Gagal mengirim WhatsApp', isError: true);
      }
    } catch (e) {
      Helpers.showToast(context, 'Error: $e', isError: true);
    } finally {
      setState(() => _isTesting = false);
    }
  }
  
  Future<void> _addMessageType() async {
    if (_messageTypeNameController.text.isEmpty) {
      Helpers.showToast(context, 'Nama jenis pesan harus diisi', isError: true);
      return;
    }
    
    setState(() => _isSaving = true);
    
    try {
      final data = {
        'jenis_pesan': _messageTypeNameController.text,
        'deskripsi': _messageTypeDescController.text,
        'response_deadline_hours': int.tryParse(_messageTypeDeadlineController.text) ?? 72,
        'responder_type': _messageTypeResponderType,
        'color_code': _messageTypeColorCode,
        'icon_class': _messageTypeIconClass,
        'allow_external': _messageTypeAllowExternal ? 1 : 0,
        'is_active': _messageTypeActive ? 1 : 0,
      };
      
      final result = await ApiService.addMessageType(data);
      
      if (result['success'] == true) {
        Helpers.showToast(context, 'Jenis pesan berhasil ditambahkan');
        await _loadMessageTypes();
        _resetMessageTypeForm();
      } else {
        Helpers.showToast(context, result['message'] ?? 'Gagal menambahkan', isError: true);
      }
    } catch (e) {
      Helpers.showToast(context, 'Error: $e', isError: true);
    } finally {
      setState(() => _isSaving = false);
    }
  }
  
  Future<void> _updateMessageType() async {
    if (_editingMessageTypeId == null || _messageTypeNameController.text.isEmpty) {
      Helpers.showToast(context, 'Data tidak valid', isError: true);
      return;
    }
    
    setState(() => _isSaving = true);
    
    try {
      final data = {
        'jenis_pesan': _messageTypeNameController.text,
        'deskripsi': _messageTypeDescController.text,
        'response_deadline_hours': int.tryParse(_messageTypeDeadlineController.text) ?? 72,
        'responder_type': _messageTypeResponderType,
        'color_code': _messageTypeColorCode,
        'icon_class': _messageTypeIconClass,
        'allow_external': _messageTypeAllowExternal ? 1 : 0,
        'is_active': _messageTypeActive ? 1 : 0,
      };
      
      final result = await ApiService.editMessageType(_editingMessageTypeId!, data);
      
      if (result['success'] == true) {
        Helpers.showToast(context, 'Jenis pesan berhasil diperbarui');
        await _loadMessageTypes();
        _resetMessageTypeForm();
        if (mounted) Navigator.pop(context);
      } else {
        Helpers.showToast(context, result['message'] ?? 'Gagal memperbarui', isError: true);
      }
    } catch (e) {
      Helpers.showToast(context, 'Error: $e', isError: true);
    } finally {
      setState(() => _isSaving = false);
    }
  }
  
  Future<void> _deleteMessageType(int id, String name) async {
    final confirmed = await Helpers.showConfirmationDialog(
      context,
      title: 'Konfirmasi Hapus',
      message: 'Hapus jenis pesan "$name"?',
      confirmText: 'Hapus',
      cancelText: 'Batal',
      confirmColor: Colors.red,
    );
    
    if (confirmed != true) return;
    
    setState(() => _isSaving = true);
    
    try {
      final result = await ApiService.deleteMessageType(id);
      
      if (result['success'] == true) {
        Helpers.showToast(context, 'Jenis pesan berhasil dihapus');
        await _loadMessageTypes();
      } else {
        Helpers.showToast(context, result['message'] ?? 'Gagal menghapus', isError: true);
      }
    } catch (e) {
      Helpers.showToast(context, 'Error: $e', isError: true);
    } finally {
      setState(() => _isSaving = false);
    }
  }
  
  Future<void> _addTemplate() async {
    if (_templateNameController.text.isEmpty || _templateContentController.text.isEmpty) {
      Helpers.showToast(context, 'Nama dan konten template harus diisi', isError: true);
      return;
    }
    
    setState(() => _isSaving = true);
    
    try {
      final data = {
        'name': _templateNameController.text,
        'content': _templateContentController.text,
        'category': _templateCategory,
        'default_status': _templateDefaultStatus,
        'guru_type': _templateGuruType,
        'is_active': _templateActive ? 1 : 0,
      };
      
      final result = await ApiService.addTemplate(data);
      
      if (result['success'] == true) {
        Helpers.showToast(context, 'Template berhasil ditambahkan');
        await _loadTemplates();
        _resetTemplateForm();
        if (mounted) Navigator.pop(context);
      } else {
        Helpers.showToast(context, result['message'] ?? 'Gagal menambahkan', isError: true);
      }
    } catch (e) {
      Helpers.showToast(context, 'Error: $e', isError: true);
    } finally {
      setState(() => _isSaving = false);
    }
  }
  
  Future<void> _updateTemplate() async {
    if (_editingTemplateId == null || _templateNameController.text.isEmpty || _templateContentController.text.isEmpty) {
      Helpers.showToast(context, 'Data tidak valid', isError: true);
      return;
    }
    
    setState(() => _isSaving = true);
    
    try {
      final data = {
        'name': _templateNameController.text,
        'content': _templateContentController.text,
        'category': _templateCategory,
        'default_status': _templateDefaultStatus,
        'guru_type': _templateGuruType,
        'is_active': _templateActive ? 1 : 0,
      };
      
      final result = await ApiService.editTemplate(_editingTemplateId!, data);
      
      if (result['success'] == true) {
        Helpers.showToast(context, 'Template berhasil diperbarui');
        await _loadTemplates();
        _resetTemplateForm();
        if (mounted) Navigator.pop(context);
      } else {
        Helpers.showToast(context, result['message'] ?? 'Gagal memperbarui', isError: true);
      }
    } catch (e) {
      Helpers.showToast(context, 'Error: $e', isError: true);
    } finally {
      setState(() => _isSaving = false);
    }
  }
  
  Future<void> _deleteTemplate(int id, String name) async {
    final confirmed = await Helpers.showConfirmationDialog(
      context,
      title: 'Konfirmasi Hapus',
      message: 'Hapus template "$name"?',
      confirmText: 'Hapus',
      cancelText: 'Batal',
      confirmColor: Colors.red,
    );
    
    if (confirmed != true) return;
    
    setState(() => _isSaving = true);
    
    try {
      final result = await ApiService.deleteTemplate(id);
      
      if (result['success'] == true) {
        Helpers.showToast(context, 'Template berhasil dihapus');
        await _loadTemplates();
      } else {
        Helpers.showToast(context, result['message'] ?? 'Gagal menghapus', isError: true);
      }
    } catch (e) {
      Helpers.showToast(context, 'Error: $e', isError: true);
    } finally {
      setState(() => _isSaving = false);
    }
  }
  
  Future<void> _toggleUserStatus(int userId, bool isActive, String userName) async {
    final confirmed = await Helpers.showConfirmationDialog(
      context,
      title: 'Konfirmasi',
      message: '${isActive ? 'Nonaktifkan' : 'Aktifkan'} akun "$userName"?',
      confirmText: isActive ? 'Nonaktifkan' : 'Aktifkan',
      cancelText: 'Batal',
      confirmColor: isActive ? Colors.red : Colors.green,
    );
    
    if (confirmed != true) return;
    
    setState(() => _isSaving = true);
    
    try {
      final result = await ApiService.updateUserStatus(userId, !isActive);
      
      if (result['success'] == true) {
        Helpers.showToast(context, 'Status pengguna berhasil diperbarui');
        await _loadUsers(page: _currentPage);
      } else {
        Helpers.showToast(context, result['message'] ?? 'Gagal memperbarui status', isError: true);
      }
    } catch (e) {
      Helpers.showToast(context, 'Error: $e', isError: true);
    } finally {
      setState(() => _isSaving = false);
    }
  }
  
  Future<void> _resetUserPassword(int userId, String userName, String email) async {
    final confirmed = await Helpers.showConfirmationDialog(
      context,
      title: 'Reset Password',
      message: 'Reset password untuk "$userName"? Password baru akan dikirim ke email $email.',
      confirmText: 'Reset',
      cancelText: 'Batal',
      confirmColor: Colors.orange,
    );
    
    if (confirmed != true) return;
    
    setState(() => _isSaving = true);
    
    try {
      final result = await ApiService.resetUserPassword(userId);
      
      if (result['success'] == true) {
        Helpers.showToast(context, 'Password berhasil direset. Password baru telah dikirim ke email.');
        await _loadUsers(page: _currentPage);
      } else {
        Helpers.showToast(context, result['message'] ?? 'Gagal reset password', isError: true);
      }
    } catch (e) {
      Helpers.showToast(context, 'Error: $e', isError: true);
    } finally {
      setState(() => _isSaving = false);
    }
  }
  
  Future<void> _clearOldLogs() async {
    int days = int.tryParse(_clearLogsDaysController.text) ?? 30;
    
    if (days < 1 || days > 365) {
      Helpers.showToast(context, 'Jumlah hari harus antara 1-365', isError: true);
      return;
    }
    
    final confirmed = await Helpers.showConfirmationDialog(
      context,
      title: 'Konfirmasi Hapus Log',
      message: 'Hapus log audit lebih dari $days hari? Log yang dihapus tidak dapat dikembalikan.',
      confirmText: 'Hapus',
      cancelText: 'Batal',
      confirmColor: Colors.red,
    );
    
    if (confirmed != true) return;
    
    setState(() => _isSaving = true);
    
    try {
      final result = await ApiService.clearOldLogs(days);
      
      if (result['success'] == true) {
        Helpers.showToast(context, result['message'] ?? 'Log berhasil dibersihkan');
        await _loadAuditLogs();
      } else {
        Helpers.showToast(context, result['message'] ?? 'Gagal membersihkan log', isError: true);
      }
    } catch (e) {
      Helpers.showToast(context, 'Error: $e', isError: true);
    } finally {
      setState(() => _isSaving = false);
    }
  }
  
  // ============================================================
  // FITUR BACKUP DATABASE YANG DIPERBAIKI
  // Berdasarkan modules/admin/settings.php versi 4.4.0
  // ============================================================
  
  /// Membuat backup database full menggunakan API
  /// Backup mencakup SEMUA tabel (termasuk yang kosong) dengan urutan dependensi yang benar
  // Perbaikan _createBackup di settings_screen.dart
Future<void> _createBackup() async {
  final confirmed = await Helpers.showConfirmationDialog(
    context,
    title: 'Konfirmasi Backup Database',
    message: 'Backup akan mencakup SEMUA tabel (termasuk yang kosong) dengan urutan dependensi yang benar.\n\n'
             'Proses backup dapat memakan waktu beberapa saat tergantung ukuran database.\n\n'
             'Lanjutkan?',
    confirmText: 'Ya, Backup',
    cancelText: 'Batal',
    confirmColor: Colors.green,
  );
  
  if (confirmed != true) return;
  
  setState(() {
    _isSaving = true;
    _backupProgress = 0.0;
    _backupStatus = 'Memulai proses backup database...';
  });
  
  try {
    setState(() {
      _backupStatus = 'Mengirim permintaan backup ke server...';
      _backupProgress = 0.3;
    });
    
    final result = await ApiService.createBackup();
    
    setState(() {
      _backupProgress = 0.9;
      _backupStatus = 'Memproses hasil backup...';
    });
    
    if (result['success'] == true) {
      setState(() {
        _backupProgress = 1.0;
        _backupStatus = 'Backup selesai!';
      });
      
      await _showBackupResultDialog(
        title: '✅ Backup Berhasil',
        message: result['message'] ?? 'Backup database berhasil dibuat',
        isSuccess: true,
      );
      
      // Refresh daftar backup
      await _loadBackupFiles();
      
      // Refresh daftar backup lagi setelah beberapa detik untuk memastikan file terdeteksi
      Future.delayed(const Duration(seconds: 2), () {
        _loadBackupFiles();
      });
    } else {
      setState(() {
        _backupProgress = 0;
        _backupStatus = '';
      });
      
      await _showBackupResultDialog(
        title: '❌ Backup Gagal',
        message: result['message'] ?? 'Gagal membuat backup database',
        isSuccess: false,
      );
    }
  } catch (e) {
    setState(() {
      _backupProgress = 0;
      _backupStatus = '';
    });
    
    await _showBackupResultDialog(
      title: '❌ Error Backup',
      message: 'Terjadi kesalahan: $e',
      isSuccess: false,
    );
  } finally {
    setState(() => _isSaving = false);
  }
}
  
  /// Menampilkan dialog hasil backup/restore
  Future<void> _showBackupResultDialog({
    required String title,
    required String message,
    required bool isSuccess,
  }) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.error,
              color: isSuccess ? Colors.green : Colors.red,
              size: 28,
            ),
            const SizedBox(width: 12),
            Text(title),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(
            message,
            style: const TextStyle(fontSize: 14),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
          if (isSuccess)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // Buka tab backup untuk melihat hasil
                _tabController.animateTo(7);
              },
              child: const Text('Lihat Backup'),
            ),
        ],
      ),
    );
  }
  
  /// Restore database dari file backup
  Future<void> _restoreDatabase() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        allowedExtensions: ['sql'],
        dialogTitle: 'Pilih File Backup (.sql)',
      );
      
      if (result == null) {
        Helpers.showToast(context, 'Restore dibatalkan');
        return;
      }
      
      final file = File(result.files.single.path!);
      final fileName = result.files.single.name;
      final fileSize = result.files.single.size;
      
      String sizeStr = '';
      if (fileSize < 1024) {
        sizeStr = '$fileSize B';
      } else if (fileSize < 1024 * 1024) {
        sizeStr = '${(fileSize / 1024).toStringAsFixed(2)} KB';
      } else {
        sizeStr = '${(fileSize / (1024 * 1024)).toStringAsFixed(2)} MB';
      }
      
      final confirmed = await Helpers.showConfirmationDialog(
        context,
        title: '⚠️ Peringatan Restore Database',
        message: 'Proses restore akan menimpa SEMUA data yang ada saat ini.\n\n'
                 'File backup: $fileName\n'
                 'Ukuran file: $sizeStr\n\n'
                 'Pastikan Anda telah memiliki backup terbaru sebelum melanjutkan.\n\n'
                 'LANJUTKAN RESTORE?',
        confirmText: 'Ya, Restore',
        cancelText: 'Batal',
        confirmColor: Colors.red,
      );
      
      if (confirmed != true) return;
      
      setState(() {
        _isRestoring = true;
        _backupProgress = 0.0;
        _backupStatus = 'Memulai proses restore database...';
      });
      
      // Update progress
      setState(() {
        _backupStatus = 'Mengupload file backup ke server...';
        _backupProgress = 0.2;
      });
      
      final restoreResult = await ApiService.restoreDatabase(file);
      
      setState(() {
        _backupProgress = 0.9;
        _backupStatus = 'Memproses restore...';
      });
      
      if (restoreResult['success'] == true) {
        setState(() {
          _backupProgress = 1.0;
          _backupStatus = 'Restore selesai!';
        });
        
        await _showBackupResultDialog(
          title: '✅ Restore Berhasil',
          message: restoreResult['message'] ?? 'Database berhasil direstore dari file $fileName',
          isSuccess: true,
        );
        
        // Reload semua data setelah restore
        await _loadAllData();
      } else {
        setState(() {
          _backupProgress = 0;
          _backupStatus = '';
        });
        
        await _showBackupResultDialog(
          title: '❌ Restore Gagal',
          message: restoreResult['message'] ?? 'Gagal merestore database',
          isSuccess: false,
        );
      }
    } catch (e) {
      setState(() {
        _backupProgress = 0;
        _backupStatus = '';
      });
      
      await _showBackupResultDialog(
        title: '❌ Error Restore',
        message: 'Terjadi kesalahan: $e',
        isSuccess: false,
      );
    } finally {
      setState(() {
        _isRestoring = false;
        _isSaving = false;
      });
    }
  }
  
  /// Download file backup
  Future<void> _downloadBackup(String filename) async {
  try {
    setState(() => _isSaving = true);
    
    final result = await ApiService.downloadBackup(filename);
    
    if (result['success'] == true) {
      Helpers.showToast(context, result['message'] ?? 'File backup berhasil diunduh');
      
      // Opsional: Buka folder tempat file disimpan
      // if (Platform.isWindows) {
      //   final file = File(result['file_path']);
      //   await file.open();
      // }
    } else {
      Helpers.showToast(context, result['message'] ?? 'Gagal mengunduh backup', isError: true);
    }
  } catch (e) {
    Helpers.showToast(context, 'Error: $e', isError: true);
  } finally {
    setState(() => _isSaving = false);
  }
}
  
  /// Hapus file backup
  Future<void> _deleteBackup(String filename) async {
    final confirmed = await Helpers.showConfirmationDialog(
      context,
      title: 'Konfirmasi Hapus',
      message: 'Hapus file backup $filename?\n\nFile yang dihapus tidak dapat dikembalikan.',
      confirmText: 'Hapus',
      cancelText: 'Batal',
      confirmColor: Colors.red,
    );
    
    if (confirmed != true) return;
    
    setState(() => _isSaving = true);
    
    try {
      final result = await ApiService.deleteBackup(filename);
      
      if (result['success'] == true) {
        Helpers.showToast(context, 'File backup berhasil dihapus');
        await _loadBackupFiles();
      } else {
        Helpers.showToast(context, result['message'] ?? 'Gagal menghapus file', isError: true);
      }
    } catch (e) {
      Helpers.showToast(context, 'Error: $e', isError: true);
    } finally {
      setState(() => _isSaving = false);
    }
  }
  
  // ============================================================
  // EXPORT & IMPORT CONFIG METHODS
  // ============================================================
  
  Future<void> _exportConfig() async {
    setState(() => _isSaving = true);
    
    try {
      final result = await ApiService.exportConfig();
      
      if (result['success'] == true) {
        final configData = result['config'];
        final jsonString = json.encode(configData);
        
        final fileName = 'config_export_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.json';
        
        final String? outputFile = await FilePicker.platform.saveFile(
          dialogTitle: 'Simpan Konfigurasi',
          fileName: fileName,
        );
        
        if (outputFile != null) {
          final File file = File(outputFile);
          await file.writeAsString(jsonString);
          Helpers.showToast(context, 'Konfigurasi berhasil diekspor ke $fileName');
        } else {
          Helpers.showToast(context, 'Ekspor dibatalkan');
        }
      } else {
        Helpers.showToast(context, result['message'] ?? 'Gagal mengekspor konfigurasi', isError: true);
      }
    } catch (e) {
      Helpers.showToast(context, 'Error: $e', isError: true);
    } finally {
      setState(() => _isSaving = false);
    }
  }
  
  Future<void> _importConfig() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        allowedExtensions: ['json'],
        dialogTitle: 'Pilih File Konfigurasi',
      );
      
      if (result == null) {
        Helpers.showToast(context, 'Import dibatalkan');
        return;
      }
      
      final confirmed = await Helpers.showConfirmationDialog(
        context,
        title: 'Konfirmasi Import',
        message: 'Impor konfigurasi akan menimpa pengaturan yang ada. Lanjutkan?',
        confirmText: 'Import',
        cancelText: 'Batal',
        confirmColor: Colors.orange,
      );
      
      if (confirmed != true) return;
      
      setState(() => _isSaving = true);
      
      final file = File(result.files.single.path!);
      final importResult = await ApiService.importConfig(file);
      
      if (importResult['success'] == true) {
        Helpers.showToast(context, importResult['message'] ?? 'Konfigurasi berhasil diimpor');
        await _loadAllData();
      } else {
        Helpers.showToast(context, importResult['message'] ?? 'Gagal mengimpor konfigurasi', isError: true);
      }
    } catch (e) {
      Helpers.showToast(context, 'Error: $e', isError: true);
    } finally {
      setState(() => _isSaving = false);
    }
  }
  
  void _navigateToManageUsers(String userType) {
    Navigator.pushNamed(
      context,
      '/manage_users',
      arguments: {'type': userType},
    ).catchError((e) {
      Helpers.showToast(context, 'Fitur manajemen pengguna untuk $userType akan segera hadir');
    });
  }
  
  void _resetMessageTypeForm() {
    _messageTypeNameController.clear();
    _messageTypeDescController.clear();
    _messageTypeDeadlineController.text = '72';
    _messageTypeResponderType = 'Guru_BK';
    _messageTypeColorCode = '#0d6efd';
    _messageTypeIconClass = 'fas fa-envelope';
    _messageTypeAllowExternal = true;
    _messageTypeActive = true;
    _editingMessageTypeId = null;
  }
  
  void _editMessageType(Map<String, dynamic> type) {
    setState(() {
      _editingMessageTypeId = type['id'];
      _messageTypeNameController.text = type['jenis_pesan'] ?? '';
      _messageTypeDescController.text = type['deskripsi'] ?? '';
      _messageTypeDeadlineController.text = (type['response_deadline_hours'] ?? 72).toString();
      _messageTypeResponderType = type['responder_type'] ?? 'Guru_BK';
      _messageTypeColorCode = type['color_code'] ?? '#0d6efd';
      _messageTypeIconClass = type['icon_class'] ?? 'fas fa-envelope';
      _messageTypeAllowExternal = type['allow_external'] == 1;
      _messageTypeActive = type['is_active'] == 1;
    });
    _showMessageTypeDialog(isEdit: true);
  }
  
  void _resetTemplateForm() {
    _templateNameController.clear();
    _templateContentController.clear();
    _templateCategory = 'Umum';
    _templateDefaultStatus = 'Disetujui';
    _templateGuruType = 'ALL';
    _templateActive = true;
    _editingTemplateId = null;
  }
  
  void _editTemplate(Map<String, dynamic> template) {
    setState(() {
      _editingTemplateId = template['id'];
      _templateNameController.text = template['name'] ?? '';
      _templateContentController.text = template['content'] ?? '';
      _templateCategory = template['category'] ?? 'Umum';
      _templateDefaultStatus = template['default_status'] ?? 'Disetujui';
      _templateGuruType = template['guru_type'] ?? 'ALL';
      _templateActive = template['is_active'] == 1;
    });
    _showTemplateDialog(isEdit: true);
  }
  
  void _showMessageTypeDialog({bool isEdit = false}) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text(isEdit ? 'Edit Jenis Pesan' : 'Tambah Jenis Pesan'),
            content: SizedBox(
              width: 400,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _messageTypeNameController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Jenis Pesan',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _messageTypeDescController,
                      decoration: const InputDecoration(
                        labelText: 'Deskripsi',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _messageTypeDeadlineController,
                      decoration: const InputDecoration(
                        labelText: 'Batas Waktu Respons (jam)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _messageTypeResponderType,
                      decoration: const InputDecoration(
                        labelText: 'Responder Type',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Guru_BK', child: Text('Guru BK')),
                        DropdownMenuItem(value: 'Guru_Humas', child: Text('Guru Humas')),
                        DropdownMenuItem(value: 'Guru_Kurikulum', child: Text('Guru Kurikulum')),
                        DropdownMenuItem(value: 'Guru_Kesiswaan', child: Text('Guru Kesiswaan')),
                        DropdownMenuItem(value: 'Guru_Sarana', child: Text('Guru Sarana')),
                      ],
                      onChanged: (value) {
                        setStateDialog(() {
                          _messageTypeResponderType = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Warna', style: TextStyle(fontSize: 12)),
                              const SizedBox(height: 4),
                              GestureDetector(
                                onTap: () async {
                                  final color = await _showColorPicker(context);
                                  if (color != null) {
                                    setStateDialog(() {
                                      _messageTypeColorCode = color;
                                    });
                                  }
                                },
                                child: Container(
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Color(int.parse(_messageTypeColorCode.substring(1, 7), radix: 16) + 0xFF000000),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey.shade300),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _messageTypeIconClass,
                            decoration: const InputDecoration(
                              labelText: 'Icon',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'fas fa-envelope', child: Text('📧 Envelope')),
                              DropdownMenuItem(value: 'fas fa-comments', child: Text('💬 Comments')),
                              DropdownMenuItem(value: 'fas fa-handshake', child: Text('🤝 Handshake')),
                              DropdownMenuItem(value: 'fas fa-book', child: Text('📚 Book')),
                              DropdownMenuItem(value: 'fas fa-users', child: Text('👥 Users')),
                              DropdownMenuItem(value: 'fas fa-school', child: Text('🏫 School')),
                              DropdownMenuItem(value: 'fas fa-question', child: Text('❓ Question')),
                            ],
                            onChanged: (value) {
                              setStateDialog(() {
                                _messageTypeIconClass = value!;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: const Text('Izinkan Pengirim Eksternal'),
                      value: _messageTypeAllowExternal,
                      onChanged: (value) {
                        setStateDialog(() {
                          _messageTypeAllowExternal = value;
                        });
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Aktif'),
                      value: _messageTypeActive,
                      onChanged: (value) {
                        setStateDialog(() {
                          _messageTypeActive = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  if (!isEdit) _resetMessageTypeForm();
                  Navigator.pop(context);
                },
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (isEdit) {
                    _updateMessageType();
                  } else {
                    _addMessageType();
                  }
                  Navigator.pop(context);
                },
                child: Text(isEdit ? 'Update' : 'Simpan'),
              ),
            ],
          );
        },
      ),
    );
  }
  
  void _showTemplateDialog({bool isEdit = false}) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text(isEdit ? 'Edit Template' : 'Tambah Template'),
            content: SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _templateNameController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Template',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _templateCategory,
                      decoration: const InputDecoration(
                        labelText: 'Kategori',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Umum', child: Text('Umum')),
                        DropdownMenuItem(value: 'Persetujuan', child: Text('Persetujuan')),
                        DropdownMenuItem(value: 'Penolakan', child: Text('Penolakan')),
                        DropdownMenuItem(value: 'Informasi', child: Text('Informasi')),
                        DropdownMenuItem(value: 'External', child: Text('External')),
                        DropdownMenuItem(value: 'Follow-up', child: Text('Follow-up')),
                      ],
                      onChanged: (value) {
                        setStateDialog(() {
                          _templateCategory = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _templateDefaultStatus,
                      decoration: const InputDecoration(
                        labelText: 'Default Status',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Disetujui', child: Text('Disetujui')),
                        DropdownMenuItem(value: 'Ditolak', child: Text('Ditolak')),
                        DropdownMenuItem(value: 'Selesai', child: Text('Selesai')),
                        DropdownMenuItem(value: 'Diproses', child: Text('Diproses')),
                      ],
                      onChanged: (value) {
                        setStateDialog(() {
                          _templateDefaultStatus = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _templateGuruType,
                      decoration: const InputDecoration(
                        labelText: 'Tipe Guru',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'ALL', child: Text('Semua Guru')),
                        DropdownMenuItem(value: 'Guru_BK', child: Text('Guru BK')),
                        DropdownMenuItem(value: 'Guru_Humas', child: Text('Guru Humas')),
                        DropdownMenuItem(value: 'Guru_Kurikulum', child: Text('Guru Kurikulum')),
                        DropdownMenuItem(value: 'Guru_Kesiswaan', child: Text('Guru Kesiswaan')),
                        DropdownMenuItem(value: 'Guru_Sarana', child: Text('Guru Sarana')),
                      ],
                      onChanged: (value) {
                        setStateDialog(() {
                          _templateGuruType = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _templateContentController,
                      decoration: const InputDecoration(
                        labelText: 'Konten Template',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 6,
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: const Text('Aktif'),
                      value: _templateActive,
                      onChanged: (value) {
                        setStateDialog(() {
                          _templateActive = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  if (!isEdit) _resetTemplateForm();
                  Navigator.pop(context);
                },
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (isEdit) {
                    _updateTemplate();
                  } else {
                    _addTemplate();
                  }
                  Navigator.pop(context);
                },
                child: Text(isEdit ? 'Update' : 'Simpan'),
              ),
            ],
          );
        },
      ),
    );
  }
  
  Future<String?> _showColorPicker(BuildContext context) async {
    Color? selectedColor;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pilih Warna'),
        content: SizedBox(
          width: 300,
          height: 200,
          child: GridView.count(
            crossAxisCount: 6,
            children: [
              Colors.red, Colors.pink, Colors.purple, Colors.deepPurple,
              Colors.indigo, Colors.blue, Colors.lightBlue, Colors.cyan,
              Colors.teal, Colors.green, Colors.lightGreen, Colors.lime,
              Colors.yellow, Colors.amber, Colors.orange, Colors.deepOrange,
              Colors.brown, Colors.grey, Colors.blueGrey, Colors.black,
            ].map((color) {
              return GestureDetector(
                onTap: () {
                  selectedColor = color;
                  Navigator.pop(context);
                },
                child: Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
    if (selectedColor != null) {
      return '#${selectedColor!.value.toRadixString(16).substring(2)}';
    }
    return null;
  }
  
  String _formatDate(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yyyy HH:mm:ss').format(date);
    } catch (e) {
      return dateStr;
    }
  }
  
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
  
  Color _getColorForActionType(String action) {
    switch (action) {
      case 'CREATE':
        return Colors.green;
      case 'UPDATE':
        return Colors.orange;
      case 'DELETE':
        return Colors.red;
      case 'BACKUP':
        return Colors.blue;
      case 'RESTORE':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return WindowResizerShortcut(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Pengaturan Sistem'),
          backgroundColor: const Color(0xFF0B4D8A),
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: const [
              Tab(text: 'Umum', icon: Icon(Icons.settings)),
              Tab(text: 'Jenis Pesan', icon: Icon(Icons.category)),
              Tab(text: 'Template', icon: Icon(Icons.description)),
              Tab(text: 'Pengguna', icon: Icon(Icons.people)),
              Tab(text: 'Notifikasi', icon: Icon(Icons.notifications)),
              Tab(text: 'Sistem', icon: Icon(Icons.computer)),
              Tab(text: 'Audit Trail', icon: Icon(Icons.history)),
              Tab(text: 'Backup', icon: Icon(Icons.backup)),
            ],
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadAllData,
              tooltip: 'Refresh',
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: SpinKitFadingCircle(color: Color(0xFF0B4D8A), size: 50))
            : _errorMsg != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(_errorMsg!, textAlign: TextAlign.center),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadAllData,
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadAllData,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildGeneralTab(),
                        _buildMessageTypesTab(),
                        _buildTemplatesTab(),
                        _buildUsersTab(),
                        _buildNotificationsTab(),
                        _buildSystemTab(),
                        _buildAuditTab(),
                        _buildBackupTab(),
                      ],
                    ),
                  ),
      ),
    );
  }
  
  // ============================================================
  // BUILD METHODS FOR EACH TAB
  // ============================================================
  
  Widget _buildGeneralTab() {
  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();
  
  return Scrollbar(
    controller: _verticalScrollController,
    thumbVisibility: true,
    trackVisibility: true,
    interactive: true,
    thickness: 12,
    radius: const Radius.circular(8),
    child: SingleChildScrollView(
      controller: _verticalScrollController,
      scrollDirection: Axis.vertical,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Scrollbar(
        controller: _horizontalScrollController,
        thumbVisibility: true,
        trackVisibility: true,
        interactive: true,
        thickness: 12,
        radius: const Radius.circular(8),
        child: SingleChildScrollView(
          controller: _horizontalScrollController,
          scrollDirection: Axis.horizontal,
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: MediaQuery.of(context).size.width - 32,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Pengaturan Umum',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 20),
                        
                        // Nama Aplikasi
                        SizedBox(
                          width: 400,
                          child: TextField(
                            controller: _appNameController,
                            decoration: const InputDecoration(
                              labelText: 'Nama Aplikasi',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // URL Aplikasi
                        SizedBox(
                          width: 400,
                          child: TextField(
                            controller: _appUrlController,
                            decoration: const InputDecoration(
                              labelText: 'URL Aplikasi',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Nama Sekolah
                        SizedBox(
                          width: 400,
                          child: TextField(
                            controller: _schoolNameController,
                            decoration: const InputDecoration(
                              labelText: 'Nama Sekolah',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Telepon Sekolah
                        SizedBox(
                          width: 400,
                          child: TextField(
                            controller: _schoolPhoneController,
                            decoration: const InputDecoration(
                              labelText: 'Telepon Sekolah',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Email Sekolah
                        SizedBox(
                          width: 400,
                          child: TextField(
                            controller: _schoolEmailController,
                            decoration: const InputDecoration(
                              labelText: 'Email Sekolah',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Email Admin
                        SizedBox(
                          width: 400,
                          child: TextField(
                            controller: _adminEmailController,
                            decoration: const InputDecoration(
                              labelText: 'Email Admin',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Alamat Sekolah
                        SizedBox(
                          width: 600,
                          child: TextField(
                            controller: _schoolAddressController,
                            decoration: const InputDecoration(
                              labelText: 'Alamat Sekolah',
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 2,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Zona Waktu
                        SizedBox(
                          width: 300,
                          child: DropdownButtonFormField<String>(
                            value: _timezone,
                            decoration: const InputDecoration(
                              labelText: 'Zona Waktu',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'Asia/Jakarta', child: Text('WIB (Jakarta)')),
                              DropdownMenuItem(value: 'Asia/Makassar', child: Text('WITA (Makassar)')),
                              DropdownMenuItem(value: 'Asia/Jayapura', child: Text('WIT (Jayapura)')),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _timezone = value!;
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Format Tanggal
                        SizedBox(
                          width: 300,
                          child: DropdownButtonFormField<String>(
                            value: _dateFormat,
                            decoration: const InputDecoration(
                              labelText: 'Format Tanggal',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'd/m/Y', child: Text('31/12/2025')),
                              DropdownMenuItem(value: 'Y-m-d', child: Text('2025-12-31')),
                              DropdownMenuItem(value: 'm/d/Y', child: Text('12/31/2025')),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _dateFormat = value!;
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Items per page
                        SizedBox(
                          width: 200,
                          child: TextField(
                            controller: _itemsPerPageController,
                            decoration: const InputDecoration(
                              labelText: 'Item per Halaman',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Switch buttons - dibungkus dengan Container lebar tetap
                        Container(
                          width: 500,
                          child: SwitchListTile(
                            title: const Text('Izinkan pendaftaran pengguna baru'),
                            value: _enableRegistration,
                            onChanged: (value) {
                              setState(() {
                                _enableRegistration = value;
                              });
                            },
                          ),
                        ),
                        Container(
                          width: 500,
                          child: SwitchListTile(
                            title: const Text('Wajib verifikasi email'),
                            value: _requireEmailVerification,
                            onChanged: (value) {
                              setState(() {
                                _requireEmailVerification = value;
                              });
                            },
                          ),
                        ),
                        Container(
                          width: 500,
                          child: SwitchListTile(
                            title: const Text('Mode pemeliharaan'),
                            subtitle: const Text('Saat diaktifkan, hanya admin yang dapat mengakses sistem'),
                            value: _maintenanceMode,
                            onChanged: (value) {
                              setState(() {
                                _maintenanceMode = value;
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        // Tombol Simpan dengan warna huruf putih bold
Row(
  mainAxisAlignment: MainAxisAlignment.end,
  children: [
    ElevatedButton(
      onPressed: _isSaving ? null : _saveGeneralSettings,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF0B4D8A),
        foregroundColor: Colors.white,  // <-- Warna huruf putih
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,  // <-- Huruf bold
        ),
      ),
      child: _isSaving
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : const Text('Simpan Pengaturan'),
    ),
  ],
),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
  
  Widget _buildMessageTypesTab() {
  // State untuk pagination
  int _itemsPerPage = 10;
  int _currentPage = 1;
  
  // Scroll controller untuk tabel scrollbar
  final ScrollController _tableScrollController = ScrollController();
  
  return StatefulBuilder(
    builder: (context, setStateDialog) {
      // Update total pages ketika message types berubah
      int totalPages = (_messageTypes.length / _itemsPerPage).ceil();
      if (totalPages == 0) totalPages = 1;
      if (_currentPage > totalPages) _currentPage = totalPages;
      
      // Hitung data untuk halaman saat ini
      int startIndex = (_currentPage - 1) * _itemsPerPage;
      int endIndex = startIndex + _itemsPerPage;
      if (endIndex > _messageTypes.length) endIndex = _messageTypes.length;
      final List<dynamic> currentTypes = _messageTypes.isEmpty ? [] : _messageTypes.sublist(startIndex, endIndex);
      
      return Column(
        children: [
          // Header - Responsif dengan SingleChildScrollView
          Container(
            padding: const EdgeInsets.all(12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Daftar Jenis Pesan',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_messageTypes.length} Jenis',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Tombol Tambah Jenis Pesan dengan warna huruf putih bold
ElevatedButton.icon(
  onPressed: () {
    _resetMessageTypeForm();
    _showMessageTypeDialog(isEdit: false);
  },
  icon: const Icon(Icons.add, size: 18, color: Colors.white),  // Icon putih
  label: const Text(
    'Tambah Jenis Pesan',
    style: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    ),
  ),
  style: ElevatedButton.styleFrom(
    backgroundColor: const Color(0xFF0B4D8A),
    foregroundColor: Colors.white,  // Warna teks dan icon putih
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    textStyle: const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.bold,
    ),
  ),
),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // Tabel dengan Scrollbar Horizontal
          Expanded(
            child: _messageTypes.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.category, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('Belum ada jenis pesan'),
                        SizedBox(height: 8),
                        Text('Klik tombol "Tambah" untuk menambahkan', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      // Tabel dengan Scrollbar Horizontal
                      Expanded(
                        child: Scrollbar(
                          controller: _tableScrollController,
                          thumbVisibility: true,
                          trackVisibility: true,
                          interactive: true,
                          thickness: 10,
                          radius: const Radius.circular(8),
                          child: SingleChildScrollView(
                            controller: _tableScrollController,
                            scrollDirection: Axis.horizontal,
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.vertical,
                              child: DataTable(
                                columnSpacing: 12,
                                headingRowColor: MaterialStateProperty.all(Colors.grey[50]),
                                columns: const [
                                  DataColumn(label: Text('#', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                  DataColumn(label: Text('Jenis Pesan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                  DataColumn(label: Text('Deskripsi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                  DataColumn(label: Text('SLA (jam)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                  DataColumn(label: Text('External', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                  DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                  DataColumn(label: Text('Pesan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                  DataColumn(label: Text('Aksi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                ],
                                rows: currentTypes.asMap().entries.map((entry) {
                                  final index = entry.key + 1 + ((_currentPage - 1) * _itemsPerPage);
                                  final type = entry.value;
                                  final id = type['id'];
                                  final name = type['jenis_pesan'] ?? 'Unknown';
                                  final description = type['deskripsi'] ?? '-';
                                  final sla = type['response_deadline_hours'] ?? 72;
                                  final allowExternal = type['allow_external'] == 1;
                                  final isActive = type['is_active'] == 1;
                                  final messageCount = type['message_count'] ?? 0;
                                  
                                  return DataRow(
                                    cells: [
                                      DataCell(Text('$index', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12))),
                                      DataCell(
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.category,
                                              size: 16,
                                              color: Color(int.parse(type['color_code']?.substring(1) ?? '0d6efd', radix: 16) + 0xFF000000),
                                            ),
                                            const SizedBox(width: 8),
                                            SizedBox(
                                              width: 150,
                                              child: Text(
                                                name,
                                                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      DataCell(
                                        SizedBox(
                                          width: 200,
                                          child: Text(
                                            description != '-' ? description : '-', 
                                            maxLines: 2, 
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontSize: 12),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            '${sla}h',
                                            style: TextStyle(fontSize: 11, color: Colors.blue[700]),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: allowExternal ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            allowExternal ? 'Ya' : 'Tidak',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: allowExternal ? Colors.green[700] : Colors.grey[600],
                                            ),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: isActive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            isActive ? 'Aktif' : 'Nonaktif',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: isActive ? Colors.green[700] : Colors.red[700],
                                            ),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.orange.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            messageCount.toString(),
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.orange[700],
                                            ),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.edit, size: 18, color: Colors.blue),
                                              onPressed: () => _editMessageType(type),
                                              tooltip: 'Edit',
                                            ),
                                            if (messageCount == 0)
                                              IconButton(
                                                icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                                                onPressed: () => _deleteMessageType(id, name),
                                                tooltip: 'Hapus',
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      // Pagination
                      if (totalPages > 1)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border(
                              top: BorderSide(color: Colors.grey.shade200),
                            ),
                          ),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            child: Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 4,
                              runSpacing: 4,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.first_page, size: 18),
                                  onPressed: _currentPage > 1
                                      ? () {
                                          setStateDialog(() {
                                            _currentPage = 1;
                                          });
                                        }
                                      : null,
                                  tooltip: 'Halaman Pertama',
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(minWidth: 32),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.chevron_left, size: 18),
                                  onPressed: _currentPage > 1
                                      ? () {
                                          setStateDialog(() {
                                            _currentPage--;
                                          });
                                        }
                                      : null,
                                  tooltip: 'Halaman Sebelumnya',
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(minWidth: 32),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0B4D8A).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    '$_currentPage / $totalPages',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF0B4D8A),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.chevron_right, size: 18),
                                  onPressed: _currentPage < totalPages
                                      ? () {
                                          setStateDialog(() {
                                            _currentPage++;
                                          });
                                        }
                                      : null,
                                  tooltip: 'Halaman Selanjutnya',
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(minWidth: 32),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.last_page, size: 18),
                                  onPressed: _currentPage < totalPages
                                      ? () {
                                          setStateDialog(() {
                                            _currentPage = totalPages;
                                          });
                                        }
                                      : null,
                                  tooltip: 'Halaman Terakhir',
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(minWidth: 32),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Total: ${_messageTypes.length}',
                                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      
                      // Informasi menampilkan data
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        child: Text(
                          'Menampilkan ${currentTypes.length} dari ${_messageTypes.length} jenis pesan',
                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      );
    },
  );
}
  
  Widget _buildTemplatesTab() {
  // Scroll controller untuk scrollbar
  final ScrollController _verticalScrollController = ScrollController();
  
  return Column(
    children: [
      Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Template Respons',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(width: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_templates.length} Template',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Tombol Tambah Template yang lebih kecil dengan huruf putih bold
                  ElevatedButton(
                    onPressed: () {
                      _resetTemplateForm();
                      _showTemplateDialog(isEdit: false);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0B4D8A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      minimumSize: const Size(0, 30),
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add, size: 16),
                        SizedBox(width: 4),
                        Text('Tambah Template'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      Expanded(
        child: _templates.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.description, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'Belum ada template respons',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Klik tombol "Tambah Template" untuk membuat template baru',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              )
            : Scrollbar(
                controller: _verticalScrollController,
                thumbVisibility: true,
                trackVisibility: true,
                interactive: true,
                thickness: 10,
                radius: const Radius.circular(8),
                child: ListView.builder(
                  controller: _verticalScrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _templates.length,
                  itemBuilder: (context, index) {
                    final template = _templates[index];
                    final isActive = template['is_active'] == 1;
                    final guruType = template['guru_type_display'] ?? template['guru_type'] ?? 'Semua Guru';
                    final category = template['category'] ?? 'Umum';
                    final useCount = template['use_count'] ?? 0;
                    final contentPreview = template['content_preview'] ?? 
                        (template['content']?.toString().substring(0, 100) ?? '-');
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header dengan judul dan badge
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.description, size: 24, color: Colors.blue),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        template['name'] ?? 'Unknown',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 4,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.blue.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              category,
                                              style: TextStyle(fontSize: 10, color: Colors.blue[700]),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.purple.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              guruType,
                                              style: TextStyle(fontSize: 10, color: Colors.purple[700]),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: (template['default_status'] == 'Disetujui' 
                                                  ? Colors.green : Colors.orange).withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              template['default_status'] ?? 'Diproses',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: template['default_status'] == 'Disetujui' 
                                                    ? Colors.green[700] 
                                                    : Colors.orange[700],
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: isActive 
                                                  ? Colors.green.withOpacity(0.1) 
                                                  : Colors.red.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              isActive ? 'Aktif' : 'Nonaktif',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: isActive ? Colors.green[700] : Colors.red[700],
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.orange.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.trending_up, size: 10, color: Colors.orange),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'Digunakan $useCount kali',
                                                  style: TextStyle(fontSize: 10, color: Colors.orange[700]),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Konten preview
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Text(
                                contentPreview,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12, color: Colors.grey, height: 1.4),
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Tombol aksi
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  onPressed: () => _editTemplate(template),
                                  icon: const Icon(Icons.edit, size: 18),
                                  label: const Text('Edit'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.blue,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                TextButton.icon(
                                  onPressed: () => _deleteTemplate(template['id'], template['name']),
                                  icon: const Icon(Icons.delete, size: 18),
                                  label: const Text('Hapus'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
      ),
    ],
  );
}
  
  Widget _buildUsersTab() {
    final totalUsers = _users.length;
    final activeUsers = _users.where((user) => user['is_active'] == 1).length;
    final inactiveUsers = _users.where((user) => user['is_active'] != 1).length;
    final externalUsers = _users.where((user) => user['user_type'] == 'External' || user['user_type'] == 'Eksternal').length;
    
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: _buildUserStatCard(
                  title: 'Total',
                  value: totalUsers.toString(),
                  icon: Icons.people,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildUserStatCard(
                  title: 'Aktif',
                  value: activeUsers.toString(),
                  icon: Icons.check_circle,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildUserStatCard(
                  title: 'Non Aktif',
                  value: inactiveUsers.toString(),
                  icon: Icons.block,
                  color: Colors.red,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildUserStatCard(
                  title: 'Eksternal',
                  value: externalUsers.toString(),
                  icon: Icons.public,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
        ),
        
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Daftar Pengguna',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Total: $_totalUsers pengguna',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.blue[700],
                  ),
                ),
              ),
            ],
          ),
        ),
        
        Expanded(
          child: _isLoadingUsers
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  ),
                )
              : _paginatedUsers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'Belum ada pengguna terdaftar',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _paginatedUsers.length,
                      itemBuilder: (context, index) {
                        final user = _paginatedUsers[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: (user['is_active'] == 1 ? Colors.green : Colors.red).withOpacity(0.1),
                                  child: Icon(
                                    user['user_type'] == 'Admin' ? Icons.admin_panel_settings : Icons.person,
                                    color: user['is_active'] == 1 ? Colors.green : Colors.red,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        user['nama_lengkap'] ?? 'Unknown',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        user['email'] ?? '-',
                                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                      ),
                                      Wrap(
                                        spacing: 8,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.blue.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              user['user_type'] ?? 'User',
                                              style: const TextStyle(fontSize: 10, color: Colors.blue),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.green.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              'Pesan: ${user['total_messages'] ?? 0}',
                                              style: const TextStyle(fontSize: 10, color: Colors.green),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: (user['is_active'] == 1 ? Colors.green : Colors.red).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        user['is_active'] == 1 ? 'Aktif' : 'Nonaktif',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: user['is_active'] == 1 ? Colors.green : Colors.red,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: Icon(
                                            user['is_active'] == 1 ? Icons.block : Icons.check_circle,
                                            size: 18,
                                            color: user['is_active'] == 1 ? Colors.red : Colors.green,
                                          ),
                                          onPressed: () => _toggleUserStatus(
                                            user['id'],
                                            user['is_active'] == 1,
                                            user['nama_lengkap'] ?? 'User',
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.key, size: 18, color: Colors.orange),
                                          onPressed: () => _resetUserPassword(
                                            user['id'],
                                            user['nama_lengkap'] ?? 'User',
                                            user['email'] ?? '',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),
        
        if (_totalPages > 1)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.first_page, size: 20),
                  onPressed: _currentPage > 1 ? () => _goToPage(1) : null,
                  tooltip: 'Halaman Pertama',
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_left, size: 24),
                  onPressed: _currentPage > 1 ? () => _goToPage(_currentPage - 1) : null,
                  tooltip: 'Halaman Sebelumnya',
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$_currentPage / $_totalPages',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue[700],
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right, size: 24),
                  onPressed: _currentPage < _totalPages ? () => _goToPage(_currentPage + 1) : null,
                  tooltip: 'Halaman Selanjutnya',
                ),
                IconButton(
                  icon: const Icon(Icons.last_page, size: 20),
                  onPressed: _currentPage < _totalPages ? () => _goToPage(_totalPages) : null,
                  tooltip: 'Halaman Terakhir',
                ),
                Container(
                  margin: const EdgeInsets.only(left: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<int>(
                    value: _itemsPerPage,
                    underline: const SizedBox(),
                    icon: const Icon(Icons.arrow_drop_down, size: 18),
                    items: const [
                      DropdownMenuItem(value: 5, child: Text('5', style: TextStyle(fontSize: 12))),
                      DropdownMenuItem(value: 10, child: Text('10', style: TextStyle(fontSize: 12))),
                      DropdownMenuItem(value: 20, child: Text('20', style: TextStyle(fontSize: 12))),
                      DropdownMenuItem(value: 50, child: Text('50', style: TextStyle(fontSize: 12))),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _itemsPerPage = value;
                          _totalPages = (_totalUsers / _itemsPerPage).ceil();
                          _currentPage = 1;
                        });
                        _loadUsers(page: 1);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
  
  Widget _buildUserStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.1),
              color.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildNotificationsTab() {
    bool _showMailerSendToken = false;
    bool _showMailerSendPassword = false;
    bool _showFonnteApiToken = false;
    bool _showFonnteAccountToken = false;
    bool _showFonntePassword = false;
    
    return StatefulBuilder(
      builder: (context, setStateDialog) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.only(bottom: 20),
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
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.email, color: Colors.blue),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'MailerSend Configuration',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'Email Notification Service',
                                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: (_mailerSendActive ? Colors.green : Colors.red).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _mailerSendActive ? 'Aktif' : 'Nonaktif',
                              style: TextStyle(
                                fontSize: 11,
                                color: _mailerSendActive ? Colors.green : Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _mailerSendApiTokenController,
                        obscureText: !_showMailerSendToken,
                        decoration: InputDecoration(
                          labelText: 'API Token',
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _showMailerSendToken ? Icons.visibility_off : Icons.visibility,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              setStateDialog(() {
                                _showMailerSendToken = !_showMailerSendToken;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _mailerSendDomainController,
                              decoration: const InputDecoration(
                                labelText: 'Domain',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _mailerSendDomainIdController,
                              decoration: const InputDecoration(
                                labelText: 'Domain ID',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _mailerSendFromEmailController,
                        decoration: const InputDecoration(
                          labelText: 'From Email',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _mailerSendFromNameController,
                        decoration: const InputDecoration(
                          labelText: 'From Name',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 12),
                      const Text(
                        'SMTP Settings (Optional)',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _mailerSendSmtpServerController,
                              decoration: const InputDecoration(
                                labelText: 'SMTP Server',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _mailerSendSmtpPortController,
                              decoration: const InputDecoration(
                                labelText: 'SMTP Port',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _mailerSendSmtpUsernameController,
                        decoration: const InputDecoration(
                          labelText: 'SMTP Username',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _mailerSendSmtpPasswordController,
                        obscureText: !_showMailerSendPassword,
                        decoration: InputDecoration(
                          labelText: 'SMTP Password',
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _showMailerSendPassword ? Icons.visibility_off : Icons.visibility,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              setStateDialog(() {
                                _showMailerSendPassword = !_showMailerSendPassword;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _mailerSendSmtpEncryption,
                        decoration: const InputDecoration(
                          labelText: 'SMTP Encryption',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'tls', child: Text('TLS')),
                          DropdownMenuItem(value: 'ssl', child: Text('SSL')),
                          DropdownMenuItem(value: 'none', child: Text('None')),
                        ],
                        onChanged: (value) {
                          setStateDialog(() {
                            _mailerSendSmtpEncryption = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text('Aktifkan MailerSend'),
                        value: _mailerSendActive,
                        onChanged: (value) {
                          setState(() {
                            _mailerSendActive = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isTesting ? null : _testMailerSendConnection,
                              icon: _isTesting
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                  : const Icon(Icons.play_arrow),
                              label: const Text('Test Koneksi'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
  child: ElevatedButton.icon(
    onPressed: _isSaving ? null : _saveMailerSendConfig,
    icon: _isSaving
        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
        : const Icon(Icons.save),
    label: const Text('Simpan'),
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF0B4D8A),
      foregroundColor: Colors.white,  // Warna teks dan icon putih
      textStyle: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,  // Huruf bold
      ),
    ),
  ),
),
                        ],
                      ),
                      const Divider(height: 32),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _mailerSendTestEmailController,
                              decoration: const InputDecoration(
                                labelText: 'Email Tujuan (opsional)',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: _isTesting ? null : _sendTestEmail,
                            icon: _isTesting
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Icon(Icons.send),
                            label: const Text('Kirim Test'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Card(
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
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.message, color: Color(0xFF25D366)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Fonnte Configuration',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'WhatsApp Notification Service',
                                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: (_fonnteActive ? Colors.green : Colors.red).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _fonnteActive ? 'Aktif' : 'Nonaktif',
                              style: TextStyle(
                                fontSize: 11,
                                color: _fonnteActive ? Colors.green : Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _fonnteApiTokenController,
                        obscureText: !_showFonnteApiToken,
                        decoration: InputDecoration(
                          labelText: 'API Token',
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _showFonnteApiToken ? Icons.visibility_off : Icons.visibility,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              setStateDialog(() {
                                _showFonnteApiToken = !_showFonnteApiToken;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _fonnteAccountTokenController,
                        obscureText: !_showFonnteAccountToken,
                        decoration: InputDecoration(
                          labelText: 'Account Token',
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _showFonnteAccountToken ? Icons.visibility_off : Icons.visibility,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              setStateDialog(() {
                                _showFonnteAccountToken = !_showFonnteAccountToken;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _fonnteDeviceIdController,
                              decoration: const InputDecoration(
                                labelText: 'Device ID / Nomor',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _fonnteCountryCodeController,
                              decoration: const InputDecoration(
                                labelText: 'Country Code',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _fonnteApiUrlController,
                        decoration: const InputDecoration(
                          labelText: 'API URL',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _fonnteEmailController,
                        decoration: const InputDecoration(
                          labelText: 'Email (Optional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _fonntePasswordController,
                        obscureText: !_showFonntePassword,
                        decoration: InputDecoration(
                          labelText: 'Password (Optional)',
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _showFonntePassword ? Icons.visibility_off : Icons.visibility,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              setStateDialog(() {
                                _showFonntePassword = !_showFonntePassword;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text('Aktifkan Fonnte'),
                        value: _fonnteActive,
                        onChanged: (value) {
                          setState(() {
                            _fonnteActive = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isTesting ? null : _testFonnteConnection,
                              icon: _isTesting
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                  : const Icon(Icons.play_arrow),
                              label: const Text('Test Koneksi'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
  child: ElevatedButton.icon(
    onPressed: _isSaving ? null : _saveFonnteConfig,
    icon: _isSaving
        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
        : const Icon(Icons.save),
    label: const Text('Simpan'),
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF0B4D8A),
      foregroundColor: Colors.white,  // Warna teks dan icon putih
      textStyle: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,  // Huruf bold
      ),
    ),
  ),
),
                        ],
                      ),
                      const Divider(height: 32),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _fonnteTestPhoneController,
                              decoration: const InputDecoration(
                                labelText: 'Nomor WhatsApp Tujuan (opsional)',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: _isTesting ? null : _sendTestWhatsApp,
                            icon: _isTesting
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Icon(Icons.send),
                            label: const Text('Kirim Test'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildSystemTab() {
  return SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildInfoCard('Total Pengguna', _systemInfo['total_users']?.toString() ?? '0', Icons.people, Colors.blue),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildInfoCard('Pengguna Aktif', _systemInfo['active_users']?.toString() ?? '0', Icons.check_circle, Colors.green),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildInfoCard('Total Pesan', _systemInfo['total_messages']?.toString() ?? '0', Icons.message, Colors.orange),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildInfoCard('Total Respons', _systemInfo['total_responses']?.toString() ?? '0', Icons.reply, Colors.purple),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildInfoCard('Database Size', '${_systemInfo['db_size_mb'] ?? 0} MB', Icons.storage, Colors.teal),
        const SizedBox(height: 24),
        
        // Database Maintenance Card
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Database Maintenance',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _createBackup,
                  icon: const Icon(Icons.backup),
                  label: const Text('Backup Database Sekarang'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                const Text(
                  'Bersihkan Log Lama',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _clearLogsDaysController,
                        decoration: const InputDecoration(
                          labelText: 'Hari',
                          border: OutlineInputBorder(),
                          suffixText: 'hari',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _clearOldLogs,
                      icon: const Icon(Icons.delete_sweep),
                      label: const Text('Hapus'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        
        // Export/Import Config Card
        Card(
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
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.settings_backup_restore, color: Colors.green, size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ekspor / Impor Konfigurasi',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Ekspor dan impor pengaturan sistem, jenis pesan, template, dan konfigurasi notifikasi',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 20),
                
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.download, color: Colors.blue, size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'Ekspor Konfigurasi',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('JSON', style: TextStyle(fontSize: 8, color: Colors.white)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Ekspor semua pengaturan, jenis pesan, template, dan konfigurasi notifikasi ke file JSON.',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isSaving ? null : _exportConfig,
                              icon: _isSaving
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                  : const Icon(Icons.download, size: 18),
                              label: const Text('Ekspor Konfigurasi'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.upload, color: Colors.orange, size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'Impor Konfigurasi',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('JSON', style: TextStyle(fontSize: 8, color: Colors.white)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Impor konfigurasi dari file JSON akan menimpa pengaturan yang ada.',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isSaving ? null : _importConfig,
                              icon: _isSaving
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                  : const Icon(Icons.upload, size: 18),
                              label: const Text('Pilih File & Impor'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'File konfigurasi berisi: Pengaturan umum, Jenis Pesan, Template Respons, Konfigurasi MailerSend, Konfigurasi Fonnte',
                          style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        
        // Manajemen Akun Pimpinan Card
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Manajemen Akun Pimpinan',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Kelola akun Kepala Sekolah dan Wakil Kepala Sekolah:',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _navigateToManageUsers('Kepala_Sekolah'),
                        icon: const Icon(Icons.admin_panel_settings),
                        label: const Text('Kepala Sekolah'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _navigateToManageUsers('Wakil_Kepala'),
                        icon: const Icon(Icons.school),
                        label: const Text('Wakil Kepala'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        
        // Informasi Sistem Card - Dengan 2 baris untuk teks panjang
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Informasi Sistem',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                // PHP Version - 1 baris
                _buildInfoRow('PHP Version', _systemInfo['php_version'] ?? '-'),
                // MySQL Version - 1 baris
                _buildInfoRow('MySQL Version', _systemInfo['mysql_version'] ?? '-'),
                // Server - 2 baris (untuk teks panjang seperti "Apache/2.4.58 (Win64) OpenSSL/1.1.1w PHP/8.2.10")
                _buildInfoRowMultiLine('Server', _systemInfo['server_software'] ?? '-'),
                // Database Size - 1 baris
                _buildInfoRow('Database Size', '${_systemInfo['db_size_mb'] ?? 0} MB'),
                // Host - 1 baris
                _buildInfoRow('Host', '${_systemInfo['db_host'] ?? '-'}:${_systemInfo['db_port'] ?? '-'}'),
                // Database - 1 baris
                _buildInfoRow('Database', _systemInfo['db_name'] ?? '-'),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

// Tambahkan method baru untuk row dengan multi-line
Widget _buildInfoRowMultiLine(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
            softWrap: true,  // Membungkus teks ke baris baru
            overflow: TextOverflow.visible,  // Tidak memotong teks
          ),
        ),
      ],
    ),
  );
}
  
  Widget _buildInfoCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
  
  Widget _buildAuditTab() {
  // State untuk pagination
  int _auditCurrentPage = 1;
  int _auditItemsPerPage = 10;
  
  return StatefulBuilder(
    builder: (context, setStateDialog) {
      // Hitung total pages
      int _auditTotalPages = (_auditLogs.length / _auditItemsPerPage).ceil();
      if (_auditTotalPages == 0) _auditTotalPages = 1;
      if (_auditCurrentPage > _auditTotalPages) _auditCurrentPage = _auditTotalPages;
      
      // Hitung data untuk halaman saat ini
      int startIndex = (_auditCurrentPage - 1) * _auditItemsPerPage;
      int endIndex = startIndex + _auditItemsPerPage;
      if (endIndex > _auditLogs.length) endIndex = _auditLogs.length;
      final List<dynamic> _paginatedAuditLogs = _auditLogs.isEmpty ? [] : _auditLogs.sublist(startIndex, endIndex);
      
      if (_auditLogs.isEmpty) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.history, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('Tidak ada data audit log'),
            ],
          ),
        );
      }
      
      // Scroll controller untuk horizontal scroll
      final ScrollController _horizontalScrollController = ScrollController();
      
      return Column(
        children: [
          // Header dengan informasi total (tanpa scrollbar)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Log Aktivitas Sistem',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Total: ${_auditLogs.length} log',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.blue[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Tabel Audit Log dengan Scrollbar Horizontal di tabel saja
          Expanded(
            child: Scrollbar(
              controller: _horizontalScrollController,
              thumbVisibility: true,
              trackVisibility: true,
              interactive: true,
              thickness: 10,
              radius: const Radius.circular(8),
              child: SingleChildScrollView(
                controller: _horizontalScrollController,
                scrollDirection: Axis.horizontal,
                physics: const AlwaysScrollableScrollPhysics(),
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: DataTable(
                    columnSpacing: 16,
                    headingRowColor: WidgetStateProperty.resolveWith(
                      (states) => Colors.grey[100],
                    ),
                    columns: const [
                      DataColumn(label: Text('No', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                      DataColumn(label: Text('Waktu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                      DataColumn(label: Text('User', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                      DataColumn(label: Text('Aksi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                      DataColumn(label: Text('Tabel', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                      DataColumn(label: Text('ID', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                      DataColumn(label: Text('Deskripsi / Perubahan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    ],
                    rows: _paginatedAuditLogs.asMap().entries.map((entry) {
                      final index = entry.key + 1 + ((_auditCurrentPage - 1) * _auditItemsPerPage);
                      final log = entry.value;
                      
                      // Ambil data dari kolom database
                      final action = log['action_type'] ?? log['action'] ?? '-';
                      final tableName = log['table_name'] ?? '-';
                      final userId = log['user_id'] ?? '-';
                      final userName = log['user_name'] ?? log['username'] ?? 'System';
                      final description = log['description'] ?? '';
                      
                      // Ambil new_value untuk deskripsi jika description kosong
                      String detailText = description;
                      if (detailText.isEmpty && log['new_value'] != null) {
                        final newValue = log['new_value'];
                        if (newValue is Map) {
                          detailText = 'Data baru: ${json.encode(newValue)}';
                        } else {
                          detailText = newValue.toString();
                        }
                      }
                      if (detailText.isEmpty && log['old_value'] != null) {
                        final oldValue = log['old_value'];
                        if (oldValue is Map) {
                          detailText = 'Data lama: ${json.encode(oldValue)}';
                        } else {
                          detailText = oldValue.toString();
                        }
                      }
                      
                      final actionColor = _getActionColorForLog(action);
                      
                      return DataRow(
                        cells: [
                          DataCell(Text('$index', style: const TextStyle(fontSize: 11))),
                          DataCell(
                            Text(
                              _formatDateTime(log['created_at']),
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                          DataCell(
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  userName,
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                                ),
                                if (userId.toString() != '-' && userId.toString() != 'null')
                                  Text(
                                    'ID: $userId',
                                    style: const TextStyle(fontSize: 9, color: Colors.grey),
                                  ),
                              ],
                            ),
                          ),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: actionColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                action,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: actionColor,
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.purple.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                tableName,
                                style: const TextStyle(fontSize: 11, color: Colors.purple),
                              ),
                            ),
                          ),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                log['record_id']?.toString() ?? '-',
                                style: const TextStyle(fontSize: 11, color: Colors.orange),
                              ),
                            ),
                          ),
                          DataCell(
                            SizedBox(
                              width: 350,
                              child: Text(
                                detailText.isNotEmpty ? detailText : '-',
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 11),
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
          
          // Pagination
          if (_auditTotalPages > 1)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.first_page, size: 20),
                    onPressed: _auditCurrentPage > 1
                        ? () {
                            setStateDialog(() {
                              _auditCurrentPage = 1;
                            });
                          }
                        : null,
                    tooltip: 'Halaman Pertama',
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_left, size: 20),
                    onPressed: _auditCurrentPage > 1
                        ? () {
                            setStateDialog(() {
                              _auditCurrentPage--;
                            });
                          }
                        : null,
                    tooltip: 'Halaman Sebelumnya',
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$_auditCurrentPage / $_auditTotalPages',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, size: 20),
                    onPressed: _auditCurrentPage < _auditTotalPages
                        ? () {
                            setStateDialog(() {
                              _auditCurrentPage++;
                            });
                          }
                        : null,
                    tooltip: 'Halaman Selanjutnya',
                  ),
                  IconButton(
                    icon: const Icon(Icons.last_page, size: 20),
                    onPressed: _auditCurrentPage < _auditTotalPages
                        ? () {
                            setStateDialog(() {
                              _auditCurrentPage = _auditTotalPages;
                            });
                          }
                        : null,
                    tooltip: 'Halaman Terakhir',
                  ),
                  Container(
                    margin: const EdgeInsets.only(left: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButton<int>(
                      value: _auditItemsPerPage,
                      underline: const SizedBox(),
                      icon: const Icon(Icons.arrow_drop_down, size: 18),
                      items: const [
                        DropdownMenuItem(value: 10, child: Text('10', style: TextStyle(fontSize: 12))),
                        DropdownMenuItem(value: 20, child: Text('20', style: TextStyle(fontSize: 12))),
                        DropdownMenuItem(value: 50, child: Text('50', style: TextStyle(fontSize: 12))),
                        DropdownMenuItem(value: 100, child: Text('100', style: TextStyle(fontSize: 12))),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setStateDialog(() {
                            _auditItemsPerPage = value;
                            _auditCurrentPage = 1;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          
          // Informasi menampilkan data
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Menampilkan ${_paginatedAuditLogs.length} dari ${_auditLogs.length} log',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ),
        ],
      );
    },
  );
}

// Tambahkan method helper untuk warna action (sudah ada, pastikan ini ada)
Color _getActionColorForLog(String action) {
  switch (action.toUpperCase()) {
    case 'CREATE':
      return Colors.green;
    case 'UPDATE':
      return Colors.orange;
    case 'DELETE':
      return Colors.red;
    case 'LOGIN':
      return Colors.blue;
    case 'LOGOUT':
      return Colors.grey;
    case 'LOGIN_FAILED':
      return Colors.red;
    case 'BACKUP':
      return Colors.purple;
    case 'RESTORE':
      return Colors.purple;
    case 'CLEANUP':
      return Colors.teal;
    case 'REGISTER':
      return Colors.cyan;
    default:
      return Colors.grey;
  }
}

// Method untuk format datetime (sudah ada, pastikan ini ada)
String _formatDateTime(String? dateTimeString) {
  if (dateTimeString == null) return '-';
  try {
    final date = DateTime.parse(dateTimeString);
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  } catch (e) {
    return dateTimeString;
  }
}
  
  // ============================================================
  // BUILD BACKUP TAB - DIPERBAIKI
  // ============================================================
  
  Widget _buildBackupTab() {
  // Hitung total ukuran backup - FIXED: convert to int safely
  int totalSize = 0;
  for (var file in _backupFiles) {
    final sizeValue = file['size'];
    if (sizeValue is int) {
      totalSize += sizeValue;
    } else if (sizeValue is num) {
      totalSize += sizeValue.toInt();
    }
  }
  
  return Column(
    children: [
      // Info Database
      Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          color: Colors.blue.shade50,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Informasi Database',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blue[800]),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Backup FULL DATABASE (SEMUA tabel termasuk yang kosong) dalam 1 file SQL dengan urutan dependensi yang benar',
                        style: TextStyle(fontSize: 10, color: Colors.blue[700]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      
      // Tombol Backup dan Restore
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _createBackup,
                icon: _isSaving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.backup),
                label: const Text('Buat Backup Baru'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isRestoring ? null : _restoreDatabase,
                icon: _isRestoring
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.restore),
                label: const Text('Restore Database'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
      
      // Progress indicator untuk backup/restore
      if ((_isSaving && _backupProgress > 0) || (_isRestoring && _backupProgress > 0))
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              LinearProgressIndicator(
                value: _backupProgress,
                backgroundColor: Colors.grey.shade200,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
              ),
              const SizedBox(height: 8),
              Text(
                _backupStatus,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      
      // Statistik Backup
      if (_backupFiles.isNotEmpty)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: _buildBackupStatCard(
                  title: 'Total Backup',
                  value: _backupFiles.length.toString(),
                  icon: Icons.archive,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildBackupStatCard(
                  title: 'Total Ukuran',
                  value: _formatFileSize(totalSize),
                  icon: Icons.storage,
                  color: Colors.teal,
                ),
              ),
            ],
          ),
        ),
      
      const Divider(height: 1),
      
      // Daftar file backup
      Expanded(
        child: _backupFiles.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.folder_open, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'Belum ada file backup',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Klik tombol "Buat Backup Baru" untuk membuat backup pertama',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _backupFiles.length,
                itemBuilder: (context, index) {
                  final file = _backupFiles[index];
                  final isLatest = index == 0;
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    elevation: isLatest ? 2 : 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: isLatest 
                          ? BorderSide(color: Colors.green.shade300, width: 1)
                          : BorderSide.none,
                    ),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.insert_drive_file,
                          color: isLatest ? Colors.green : Colors.blue,
                          size: 24,
                        ),
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              file['name'] ?? 'Unknown',
                              style: TextStyle(
                                fontWeight: isLatest ? FontWeight.bold : FontWeight.normal,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isLatest)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'LATEST',
                                style: TextStyle(fontSize: 8, color: Colors.white),
                              ),
                            ),
                        ],
                      ),
                      subtitle: Text(
                        '${_formatFileSize(file['size'] ?? 0)} • ${file['date_formatted'] ?? '-'}',
                        style: const TextStyle(fontSize: 11),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.download, color: Colors.blue, size: 20),
                            onPressed: () => _downloadBackup(file['name']),
                            tooltip: 'Download',
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                            onPressed: () => _deleteBackup(file['name']),
                            tooltip: 'Hapus',
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
      
      // Panduan Backup
      Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          color: Colors.grey.shade50,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.help_outline, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      'Panduan Backup & Restore',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[700]),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '• Backup mencakup SEMUA tabel (termasuk yang kosong)\n'
                  '• Backup dibuat dengan urutan dependensi tabel yang benar\n'
                  '• File backup disimpan dalam format SQL\n'
                  '• Restore akan mengeksekusi queries sesuai level dependensi\n'
                  '• Selalu backup sebelum melakukan restore untuk keamanan data',
                  style: TextStyle(fontSize: 10, color: Colors.grey[600], height: 1.4),
                ),
              ],
            ),
          ),
        ),
      ),
    ],
  );
}
  
  Widget _buildBackupStatCard({
  required String title,
  required String value,
  required IconData icon,
  required Color color,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: color.withOpacity(0.2)),
    ),
    child: Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                title,
                style: TextStyle(fontSize: 9, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
}
