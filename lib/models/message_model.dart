import 'package:flutter/material.dart';

class DashboardStats {
  final int totalAssigned;
  final int pending;
  final int dibaca;
  final int diproses;
  final int disetujui;
  final int ditolak;
  final int selesai;
  final double avgResponseTime;

  DashboardStats({
    required this.totalAssigned,
    required this.pending,
    required this.dibaca,
    required this.diproses,
    required this.disetujui,
    required this.ditolak,
    required this.selesai,
    required this.avgResponseTime,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalAssigned: json['total_assigned'] ?? 0,
      pending: json['pending'] ?? 0,
      dibaca: json['dibaca'] ?? 0,
      diproses: json['diproses'] ?? 0,
      disetujui: json['disetujui'] ?? 0,
      ditolak: json['ditolak'] ?? 0,
      selesai: json['selesai'] ?? 0,
      avgResponseTime: (json['avg_response_time'] ?? 0).toDouble(),
    );
  }
}

class RecentActivity {
  final String id;
  final String senderName;
  final String isiPesan;
  final String status;
  final DateTime createdAt;
  final Color statusColor;

  RecentActivity({
    required this.id,
    required this.senderName,
    required this.isiPesan,
    required this.status,
    required this.createdAt,
    required this.statusColor,
  });

  factory RecentActivity.fromJson(Map<String, dynamic> json) {
    Color getStatusColor(String status) {
      switch (status.toLowerCase()) {
        case 'pending': return Colors.orange;
        case 'dibaca': return Colors.blue;
        case 'diproses': return Colors.cyan;
        case 'disetujui': return Colors.green;
        case 'ditolak': return Colors.red;
        case 'selesai': return Colors.teal;
        default: return Colors.grey;
      }
    }

    return RecentActivity(
      id: json['id'].toString(),
      senderName: json['nama_lengkap'] ?? 'Unknown',
      isiPesan: json['isi_pesan'] ?? '',
      status: json['status'] ?? 'Pending',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      statusColor: getStatusColor(json['status'] ?? 'Pending'),
    );
  }
}