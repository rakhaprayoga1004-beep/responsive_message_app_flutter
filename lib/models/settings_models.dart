import 'package:flutter/foundation.dart';
import '../utils/environment.dart';

// ============================================
// GENERAL SETTINGS
// ============================================
class GeneralSettings {
  final String appName;
  final String appUrl;
  final String schoolName;
  final String schoolAddress;
  final String schoolPhone;
  final String schoolEmail;
  final String adminEmail;
  final String timezone;
  final String dateFormat;
  final String timeFormat;
  final int itemsPerPage;
  final bool enableRegistration;
  final bool requireEmailVerification;
  final bool maintenanceMode;

  GeneralSettings({
    required this.appName,
    required this.appUrl,
    required this.schoolName,
    required this.schoolAddress,
    required this.schoolPhone,
    required this.schoolEmail,
    required this.adminEmail,
    required this.timezone,
    required this.dateFormat,
    required this.timeFormat,
    required this.itemsPerPage,
    required this.enableRegistration,
    required this.requireEmailVerification,
    required this.maintenanceMode,
  });

  factory GeneralSettings.fromJson(Map<String, dynamic> json) {
    return GeneralSettings(
      appName: json['app_name'] ?? 'Responsive Message SMKN 12 Jakarta',
      appUrl: json['app_url'] ?? Environment.baseUrl,
      schoolName: json['school_name'] ?? 'SMKN 12 Jakarta',
      schoolAddress: json['school_address'] ?? 'Jl. Kebon Bawang XV B Mo. 15, Tanjung Priok, Jakarta Utara 14320',
      schoolPhone: json['school_phone'] ?? '(021) 43932785, 43913815',
      schoolEmail: json['school_email'] ?? 'info@smkn12jakarta.sch.id',
      adminEmail: json['admin_email'] ?? 'admin@smkn12jakarta.sch.id',
      timezone: json['timezone'] ?? 'Asia/Jakarta',
      dateFormat: json['date_format'] ?? 'd/m/Y',
      timeFormat: json['time_format'] ?? 'H:i:s',
      itemsPerPage: json['items_per_page'] ?? 10,
      enableRegistration: json['enable_registration'] == 1,
      requireEmailVerification: json['require_email_verification'] == 1,
      maintenanceMode: json['maintenance_mode'] == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'app_name': appName,
      'app_url': appUrl,
      'school_name': schoolName,
      'school_address': schoolAddress,
      'school_phone': schoolPhone,
      'school_email': schoolEmail,
      'admin_email': adminEmail,
      'timezone': timezone,
      'date_format': dateFormat,
      'time_format': timeFormat,
      'items_per_page': itemsPerPage,
      'enable_registration': enableRegistration ? 1 : 0,
      'require_email_verification': requireEmailVerification ? 1 : 0,
      'maintenance_mode': maintenanceMode ? 1 : 0,
    };
  }
}

// ============================================
// MESSAGE TYPE
// ============================================
class MessageType {
  final int id;
  final String jenisPesan;
  final String? responderType;
  final String? deskripsi;
  final int responseDeadlineHours;
  final String? colorCode;
  final String? iconClass;
  final bool isActive;
  final bool allowExternal;
  final String? createdAt;
  final String? updatedAt;
  final int messageCount;
  final String? assignedTeachers;

  MessageType({
    required this.id,
    required this.jenisPesan,
    this.responderType,
    this.deskripsi,
    required this.responseDeadlineHours,
    this.colorCode,
    this.iconClass,
    required this.isActive,
    required this.allowExternal,
    this.createdAt,
    this.updatedAt,
    this.messageCount = 0,
    this.assignedTeachers,
  });

  factory MessageType.fromJson(Map<String, dynamic> json) {
    if (kDebugMode) {
      print('Parsing message type: ${json['jenis_pesan']} (ID: ${json['id']})');
      print('Raw JSON: $json');
    }
    
    return MessageType(
      id: json['id'] ?? 0,
      jenisPesan: json['jenis_pesan'] ?? '',
      responderType: json['responder_type'] ?? json['responderType'],
      deskripsi: json['description'] ?? json['deskripsi'],
      responseDeadlineHours: json['response_deadline_hours'] ?? 72,
      colorCode: json['color_code'] ?? json['colorCode'],
      iconClass: json['icon_class'] ?? json['iconClass'],
      isActive: json['is_active'] == 1,
      allowExternal: json['allow_external'] == 1,
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      messageCount: json['message_count'] ?? 0,
      assignedTeachers: json['assigned_teachers'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'jenis_pesan': jenisPesan,
      'responder_type': responderType,
      'description': deskripsi,
      'response_deadline_hours': responseDeadlineHours,
      'color_code': colorCode,
      'icon_class': iconClass,
      'is_active': isActive ? 1 : 0,
      'allow_external': allowExternal ? 1 : 0,
    };
  }
}

// ============================================
// RESPONSE TEMPLATE
// ============================================
class ResponseTemplate {
  final int id;
  final String name;
  final String content;
  final String category;
  final String defaultStatus;
  final String guruType;
  final bool isActive;
  final int useCount;
  final int? createdBy;
  final String? createdAt;
  final String? updatedAt;

  ResponseTemplate({
    required this.id,
    required this.name,
    required this.content,
    required this.category,
    required this.defaultStatus,
    required this.guruType,
    required this.isActive,
    required this.useCount,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  factory ResponseTemplate.fromJson(Map<String, dynamic> json) {
    return ResponseTemplate(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      content: json['content'] ?? '',
      category: json['category'] ?? 'Umum',
      defaultStatus: json['default_status'] ?? 'Disetujui',
      guruType: json['guru_type'] ?? 'ALL',
      isActive: json['is_active'] == 1,
      useCount: json['use_count'] ?? 0,
      createdBy: json['created_by'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'content': content,
      'category': category,
      'default_status': defaultStatus,
      'guru_type': guruType,
      'is_active': isActive ? 1 : 0,
    };
  }
}

// ============================================
// USER - VERSION WITH COMPLETE FIELDS
// ============================================
class User {
  final int id;
  final String namaLengkap;
  final String email;
  final String userType;
  final bool isActive;
  final int totalMessages;
  final int totalResponses;
  
  // 🔥 Field tambahan untuk informasi lengkap user
  final String? username;
  final String? noTelp;
  final String? nisNip;
  final String? kelas;
  final String? jurusan;
  final String? mataPelajaran;
  final String? foto;
  final DateTime? lastLogin;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  User({
    required this.id,
    required this.namaLengkap,
    required this.email,
    required this.userType,
    required this.isActive,
    required this.totalMessages,
    required this.totalResponses,
    this.username,
    this.noTelp,
    this.nisNip,
    this.kelas,
    this.jurusan,
    this.mataPelajaran,
    this.foto,
    this.lastLogin,
    this.createdAt,
    this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      namaLengkap: json['nama_lengkap'] ?? '',
      email: json['email'] ?? '',
      userType: json['user_type'] ?? '',
      isActive: json['is_active'] == true || json['status'] == 'aktif',
      totalMessages: json['total_messages'] ?? 0,
      totalResponses: json['total_responses'] ?? 0,
      username: json['username'],
      noTelp: json['no_telp'] ?? json['phone_number'],
      nisNip: json['nis_nip'],
      kelas: json['kelas'],
      jurusan: json['jurusan'],
      mataPelajaran: json['mata_pelajaran'],
      foto: json['foto'],
      lastLogin: json['last_login'] != null ? DateTime.tryParse(json['last_login']) : null,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama_lengkap': namaLengkap,
      'email': email,
      'user_type': userType,
      'is_active': isActive,
      'total_messages': totalMessages,
      'total_responses': totalResponses,
      'username': username,
      'no_telp': noTelp,
      'nis_nip': nisNip,
      'kelas': kelas,
      'jurusan': jurusan,
      'mata_pelajaran': mataPelajaran,
      'foto': foto,
      'last_login': lastLogin?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  User copyWith({
    int? id,
    String? namaLengkap,
    String? email,
    String? userType,
    bool? isActive,
    int? totalMessages,
    int? totalResponses,
    String? username,
    String? noTelp,
    String? nisNip,
    String? kelas,
    String? jurusan,
    String? mataPelajaran,
    String? foto,
    DateTime? lastLogin,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      namaLengkap: namaLengkap ?? this.namaLengkap,
      email: email ?? this.email,
      userType: userType ?? this.userType,
      isActive: isActive ?? this.isActive,
      totalMessages: totalMessages ?? this.totalMessages,
      totalResponses: totalResponses ?? this.totalResponses,
      username: username ?? this.username,
      noTelp: noTelp ?? this.noTelp,
      nisNip: nisNip ?? this.nisNip,
      kelas: kelas ?? this.kelas,
      jurusan: jurusan ?? this.jurusan,
      mataPelajaran: mataPelajaran ?? this.mataPelajaran,
      foto: foto ?? this.foto,
      lastLogin: lastLogin ?? this.lastLogin,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// ============================================
// MAILERSEND CONFIG
// ============================================
class MailerSendConfig {
  final String apiToken;
  final String domain;
  final String domainId;
  final String fromEmail;
  final String fromName;
  final String smtpServer;
  final String smtpUsername;
  final String smtpPassword;
  final int smtpPort;
  final String smtpEncryption;
  final String testDomain;
  final bool isActive;

  MailerSendConfig({
    required this.apiToken,
    required this.domain,
    required this.domainId,
    required this.fromEmail,
    required this.fromName,
    required this.smtpServer,
    required this.smtpUsername,
    required this.smtpPassword,
    required this.smtpPort,
    required this.smtpEncryption,
    required this.testDomain,
    required this.isActive,
  });

  factory MailerSendConfig.fromJson(Map<String, dynamic> json) {
    return MailerSendConfig(
      apiToken: json['api_token'] ?? '',
      domain: json['domain'] ?? '',
      domainId: json['domain_id'] ?? '',
      fromEmail: json['from_email'] ?? '',
      fromName: json['from_name'] ?? 'SMKN 12 Jakarta - Aplikasi Pesan Responsif',
      smtpServer: json['smtp_server'] ?? 'smtp.mailersend.net',
      smtpUsername: json['smtp_username'] ?? '',
      smtpPassword: json['smtp_password'] ?? '',
      smtpPort: json['smtp_port'] ?? 587,
      smtpEncryption: json['smtp_encryption'] ?? 'tls',
      testDomain: json['test_domain'] ?? '',
      isActive: json['is_active'] == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'api_token': apiToken,
      'domain': domain,
      'domain_id': domainId,
      'from_email': fromEmail,
      'from_name': fromName,
      'smtp_server': smtpServer,
      'smtp_username': smtpUsername,
      'smtp_password': smtpPassword,
      'smtp_port': smtpPort,
      'smtp_encryption': smtpEncryption,
      'test_domain': testDomain,
      'is_active': isActive ? 1 : 0,
    };
  }
}

// ============================================
// FONNTE CONFIG
// ============================================
class FonnteConfig {
  final String apiToken;
  final String accountToken;
  final String deviceId;
  final String apiUrl;
  final String email;
  final String password;
  final String countryCode;
  final bool isActive;

  FonnteConfig({
    required this.apiToken,
    required this.accountToken,
    required this.deviceId,
    required this.apiUrl,
    required this.email,
    required this.password,
    required this.countryCode,
    required this.isActive,
  });

  factory FonnteConfig.fromJson(Map<String, dynamic> json) {
    return FonnteConfig(
      apiToken: json['api_token'] ?? '',
      accountToken: json['account_token'] ?? '',
      deviceId: json['device_id'] ?? '',
      apiUrl: json['api_url'] ?? 'https://api.fonnte.com/send',
      email: json['email'] ?? '',
      password: json['password'] ?? '',
      countryCode: json['country_code'] ?? '62',
      isActive: json['is_active'] == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'api_token': apiToken,
      'account_token': accountToken,
      'device_id': deviceId,
      'api_url': apiUrl,
      'email': email,
      'password': password,
      'country_code': countryCode,
      'is_active': isActive ? 1 : 0,
    };
  }
}

// ============================================
// SYSTEM STATS
// ============================================
class SystemStats {
  final int totalUsers;
  final int activeUsers;
  final int totalMessages;
  final int totalResponses;
  final int totalExternal;
  final int logs24h;
  final double dbSizeMb;

  SystemStats({
    required this.totalUsers,
    required this.activeUsers,
    required this.totalMessages,
    required this.totalResponses,
    required this.totalExternal,
    required this.logs24h,
    required this.dbSizeMb,
  });

  factory SystemStats.fromJson(Map<String, dynamic> json) {
    return SystemStats(
      totalUsers: json['total_users'] ?? 0,
      activeUsers: json['active_users'] ?? 0,
      totalMessages: json['total_messages'] ?? 0,
      totalResponses: json['total_responses'] ?? 0,
      totalExternal: json['total_external'] ?? 0,
      logs24h: json['logs_24h'] ?? 0,
      dbSizeMb: (json['db_size_mb'] ?? 0).toDouble(),
    );
  }
}

// ============================================
// AUDIT LOG
// ============================================
class AuditLog {
  final int id;
  final String? userName;
  final String actionType;
  final String? tableName;
  final int? recordId;
  final String? newValue;
  final String? ipAddress;
  final DateTime createdAt;

  AuditLog({
    required this.id,
    this.userName,
    required this.actionType,
    this.tableName,
    this.recordId,
    this.newValue,
    this.ipAddress,
    required this.createdAt,
  });

  factory AuditLog.fromJson(Map<String, dynamic> json) {
    return AuditLog(
      id: json['id'] ?? 0,
      userName: json['user_name'],
      actionType: json['action_type'] ?? '',
      tableName: json['table_name'],
      recordId: json['record_id'],
      newValue: json['new_value'],
      ipAddress: json['ip_address'],
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }
}

// ============================================
// BACKUP FILE
// ============================================
class BackupFile {
  final String name;
  final String path;
  final int size;
  final String sizeFormatted;
  final DateTime date;
  final String dateFormatted;

  BackupFile({
    required this.name,
    required this.path,
    required this.size,
    required this.sizeFormatted,
    required this.date,
    required this.dateFormatted,
  });

  factory BackupFile.fromJson(Map<String, dynamic> json) {
    return BackupFile(
      name: json['name'] ?? '',
      path: json['path'] ?? '',
      size: json['size'] ?? 0,
      sizeFormatted: json['size_formatted'] ?? '0 B',
      date: DateTime.fromMillisecondsSinceEpoch(json['date'] ?? 0),
      dateFormatted: json['date_formatted'] ?? '',
    );
  }
}

// ============================================
// BACKUP RESULT
// ============================================
class BackupResult {
  final bool success;
  final String message;
  final String? filename;
  final String? path;
  final int? size;

  BackupResult({
    required this.success,
    required this.message,
    this.filename,
    this.path,
    this.size,
  });

  factory BackupResult.fromJson(Map<String, dynamic> json) {
    return BackupResult(
      success: json['success'] == true,
      message: json['message'] ?? '',
      filename: json['filename'],
      path: json['path'],
      size: json['size'],
    );
  }
}

// ============================================
// TEST RESULT
// ============================================
class TestResult {
  final bool success;
  final String message;
  final bool sent;
  final String? error;
  final int? httpCode;

  TestResult({
    required this.success,
    required this.message,
    required this.sent,
    this.error,
    this.httpCode,
  });

  factory TestResult.fromJson(Map<String, dynamic> json) {
    return TestResult(
      success: json['success'] == true,
      message: json['message'] ?? '',
      sent: json['sent'] == true,
      error: json['error'],
      httpCode: json['http_code'],
    );
  }
}