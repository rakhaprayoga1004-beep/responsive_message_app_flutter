// lib/models/dashboard_model.dart

import 'package:flutter/material.dart';

class MessageStatus {
  final String status;
  final int count;

  MessageStatus({required this.status, required this.count});

  factory MessageStatus.fromJson(Map<String, dynamic> json) {
    return MessageStatus(
      status: json['status']?.toString() ?? '',
      count: _toInt(json['count']),
    );
  }
}

class MessageTypeStat {
  final String jenisPesan;
  final int total;
  final int pending;
  final int processed;
  final int approved;
  final int rejected;

  MessageTypeStat({
    required this.jenisPesan,
    required this.total,
    required this.pending,
    required this.processed,
    required this.approved,
    required this.rejected,
  });

  factory MessageTypeStat.fromJson(Map<String, dynamic> json) {
    return MessageTypeStat(
      jenisPesan: json['type']?.toString() ?? json['jenis_pesan']?.toString() ?? '',
      total: _toInt(json['total']),
      pending: _toInt(json['pending']),
      processed: _toInt(json['processed']),
      approved: _toInt(json['approved']),
      rejected: _toInt(json['rejected']),
    );
  }
}

class RecentMessage {
  final int id;
  final String? namaLengkap;
  final String? jenisPesan;
  final String isiPesan;
  final String status;
  final DateTime createdAt;
  final String? pengirimNisNip;

  RecentMessage({
    required this.id,
    this.namaLengkap,
    this.jenisPesan,
    required this.isiPesan,
    required this.status,
    required this.createdAt,
    this.pengirimNisNip,
  });

  factory RecentMessage.fromJson(Map<String, dynamic> json) {
    return RecentMessage(
      id: _toInt(json['id']),
      namaLengkap: json['nama_lengkap']?.toString(),
      jenisPesan: json['jenis_pesan']?.toString(),
      isiPesan: json['isi_pesan']?.toString() ?? '',
      status: json['status']?.toString() ?? 'Pending',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      pengirimNisNip: json['pengirim_nis_nip']?.toString(),
    );
  }
}

class ResponseStats {
  final int totalMessages;
  final int responded;
  final double responseRate;

  ResponseStats({
    required this.totalMessages,
    required this.responded,
    required this.responseRate,
  });

  factory ResponseStats.fromJson(Map<String, dynamic> json) {
    print('📊 Parsing ResponseStats from: $json');
    return ResponseStats(
      totalMessages: _toInt(json['total_messages']),
      responded: _toInt(json['responded']),
      responseRate: _toDouble(json['response_rate']),
    );
  }

  factory ResponseStats.empty() {
    return ResponseStats(
      totalMessages: 0,
      responded: 0,
      responseRate: 0,
    );
  }
}

class DailyMessage {
  final DateTime date;
  final int messageCount;
  final int pendingCount;
  final int approvedCount;

  DailyMessage({
    required this.date,
    required this.messageCount,
    this.pendingCount = 0,
    this.approvedCount = 0,
  });

  factory DailyMessage.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is DateTime) return value;
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          return DateTime.now();
        }
      }
      return DateTime.now();
    }

    return DailyMessage(
      date: parseDate(json['date']),
      messageCount: _toInt(json['message_count']),
      pendingCount: _toInt(json['pending_count']),
      approvedCount: _toInt(json['approved_count']),
    );
  }
}

// MODEL USER GROWTH
class UserGrowth {
  final DateTime date;
  final int newUsers;

  UserGrowth({
    required this.date,
    required this.newUsers,
  });

  factory UserGrowth.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is DateTime) return value;
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          return DateTime.now();
        }
      }
      return DateTime.now();
    }

    return UserGrowth(
      date: parseDate(json['date']),
      newUsers: _toInt(json['new_users']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'new_users': newUsers,
    };
  }
}

// DASHBOARD STATS
class DashboardStats {
  final int totalUsers;
  final int newUsers30Days;
  final int totalMessages;
  final int pendingMessages;
  final int expiredMessages;
  final ResponseStats responseStats;
  final List<MessageStatus> messageStatus;
  final List<MessageTypeStat> messageTypeStats;
  final List<RecentMessage> recentMessages;

  DashboardStats({
    required this.totalUsers,
    required this.newUsers30Days,
    required this.totalMessages,
    required this.pendingMessages,
    required this.expiredMessages,
    required this.responseStats,
    required this.messageStatus,
    required this.messageTypeStats,
    required this.recentMessages,
  });

  factory DashboardStats.empty() {
    return DashboardStats(
      totalUsers: 0,
      newUsers30Days: 0,
      totalMessages: 0,
      pendingMessages: 0,
      expiredMessages: 0,
      responseStats: ResponseStats.empty(),
      messageStatus: [],
      messageTypeStats: [],
      recentMessages: [],
    );
  }

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    // API mengirim response dengan struktur { success: true, data: {...} }
    Map<String, dynamic> source = json;
    
    // Jika ada key 'data', gunakan itu
    if (json.containsKey('data') && json['data'] != null) {
      source = json['data'];
    }
    
    print('📊 Parsing DashboardStats from source: $source');
    
    // Debug response_stats
    if (source.containsKey('response_stats')) {
      print('📊 response_stats found: ${source['response_stats']}');
    } else {
      print('📊 response_stats NOT found in source');
    }
    
    return DashboardStats(
      totalUsers: _toInt(source['total_users']),
      newUsers30Days: _toInt(source['new_users_30days']),
      totalMessages: _toInt(source['total_messages']),
      pendingMessages: _toInt(source['pending_messages']),
      expiredMessages: _toInt(source['expired_messages']),
      responseStats: ResponseStats.fromJson(source['response_stats'] ?? {}),
      messageStatus: (source['message_status'] as List? ?? [])
          .map((e) => MessageStatus.fromJson(e))
          .toList(),
      messageTypeStats: (source['message_type_stats'] as List? ?? [])
          .map((e) => MessageTypeStat.fromJson(e))
          .toList(),
      recentMessages: (source['recent_messages'] as List? ?? [])
          .map((e) => RecentMessage.fromJson(e))
          .toList(),
    );
  }
}

// ==================== HELPER FUNCTIONS ====================
// Helper function to convert dynamic to int safely
int _toInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is String) return int.tryParse(value) ?? 0;
  if (value is double) return value.toInt();
  if (value is num) return value.toInt();
  return 0;
}

// Helper function to convert dynamic to double safely
double _toDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  if (value is num) return value.toDouble();
  return 0.0;
}