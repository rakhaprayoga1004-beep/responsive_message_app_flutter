import 'package:flutter/material.dart';

class FollowupResponse {
  final bool success;
  final List<FollowupMessage> messages;
  final FollowupStats stats;
  final ReviewStats reviewStats;
  final List<ResponseTemplate> templates;
  final int total;
  final int totalPages;
  final int currentPage;

  FollowupResponse({
    required this.success,
    required this.messages,
    required this.stats,
    required this.reviewStats,
    required this.templates,
    required this.total,
    required this.totalPages,
    required this.currentPage,
  });

  factory FollowupResponse.fromJson(Map<String, dynamic> json) {
    return FollowupResponse(
      success: json['success'] ?? false,
      messages: (json['messages'] as List?)
              ?.map((e) => FollowupMessage.fromJson(e))
              .toList() ??
          [],
      stats: FollowupStats.fromJson(json['stats'] ?? {}),
      reviewStats: ReviewStats.fromJson(json['review_stats'] ?? {}),
      templates: (json['templates'] as List?)
              ?.map((e) => ResponseTemplate.fromJson(e))
              .toList() ??
          [],
      total: json['total'] ?? 0,
      totalPages: json['total_pages'] ?? 0,
      currentPage: json['current_page'] ?? 1,
    );
  }
}

class FollowupMessage {
  final int id;
  final String referenceNumber;
  final String tanggalPesan;
  final String isiPesan;
  final String status;
  final String priority;
  final String createdAt;
  final String? tanggalRespon;
  final int isExternal;
  final String pengirimNama;
  final String pengirimTipe;
  final String? pengirimEmail;
  final int attachmentCount;
  final int hasResponse;
  final int hoursRemaining;
  final String waktuStatus;

  FollowupMessage({
    required this.id,
    required this.referenceNumber,
    required this.tanggalPesan,
    required this.isiPesan,
    required this.status,
    required this.priority,
    required this.createdAt,
    this.tanggalRespon,
    required this.isExternal,
    required this.pengirimNama,
    required this.pengirimTipe,
    this.pengirimEmail,
    required this.attachmentCount,
    required this.hasResponse,
    required this.hoursRemaining,
    required this.waktuStatus,
  });

  factory FollowupMessage.fromJson(Map<String, dynamic> json) {
    return FollowupMessage(
      id: json['id'] ?? 0,
      referenceNumber: json['reference_number'] ?? '',
      tanggalPesan: json['tanggal_pesan'] ?? '',
      isiPesan: json['isi_pesan'] ?? '',
      status: json['status'] ?? 'Pending',
      priority: json['priority'] ?? 'Medium',
      createdAt: json['created_at'] ?? '',
      tanggalRespon: json['tanggal_respon'],
      isExternal: json['is_external'] ?? 0,
      pengirimNama: json['pengirim_nama'] ?? 'Unknown',
      pengirimTipe: json['pengirim_tipe'] ?? 'Unknown',
      pengirimEmail: json['pengirim_email'],
      attachmentCount: json['attachment_count'] ?? 0,
      hasResponse: json['has_response'] ?? 0,
      hoursRemaining: json['hours_remaining'] ?? 0,
      waktuStatus: json['waktu_status'] ?? 'Active',
    );
  }

  bool get isPending =>
      status == 'Pending' || status == 'Dibaca' || status == 'Diproses';
  bool get isExternalMessage => isExternal == 1;
  bool get hasAttachments => attachmentCount > 0;
  bool get isResponded => hasResponse == 1;
  bool get isExpired => waktuStatus == 'Expired';

  Color get statusColor {
    switch (status) {
      case 'Pending':
        return Colors.orange;
      case 'Dibaca':
        return Colors.blue;
      case 'Diproses':
        return Colors.cyan;
      case 'Disetujui':
        return Colors.green;
      case 'Ditolak':
        return Colors.red;
      case 'Selesai':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  Color get priorityColor {
    switch (priority) {
      case 'Low':
        return Colors.green;
      case 'Medium':
        return Colors.orange;
      case 'High':
        return Colors.deepOrange;
      case 'Urgent':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

class FollowupStats {
  final int totalAssigned;
  final int externalCount;
  final int pending;
  final int dibaca;
  final int diproses;
  final int disetujui;
  final int ditolak;
  final int selesai;
  final int withAttachments;

  FollowupStats({
    required this.totalAssigned,
    required this.externalCount,
    required this.pending,
    required this.dibaca,
    required this.diproses,
    required this.disetujui,
    required this.ditolak,
    required this.selesai,
    required this.withAttachments,
  });

  factory FollowupStats.fromJson(Map<String, dynamic> json) {
    return FollowupStats(
      totalAssigned: int.tryParse(json['total_assigned']?.toString() ?? '0') ?? 0,
      externalCount: int.tryParse(json['external_count']?.toString() ?? '0') ?? 0,
      pending: int.tryParse(json['pending']?.toString() ?? '0') ?? 0,
      dibaca: int.tryParse(json['dibaca']?.toString() ?? '0') ?? 0,
      diproses: int.tryParse(json['diproses']?.toString() ?? '0') ?? 0,
      disetujui: int.tryParse(json['disetujui']?.toString() ?? '0') ?? 0,
      ditolak: int.tryParse(json['ditolak']?.toString() ?? '0') ?? 0,
      selesai: int.tryParse(json['selesai']?.toString() ?? '0') ?? 0,
      withAttachments: int.tryParse(json['with_attachments']?.toString() ?? '0') ?? 0,
    );
  }

  int get totalProcessed => diproses;
  int get totalCompleted => disetujui + selesai;
  int get totalPending => pending + dibaca;
}

class ReviewStats {
  final int totalResponded;
  final int reviewedByWakepsek;
  final int reviewedByKepsek;
  final int pendingReview;

  ReviewStats({
    required this.totalResponded,
    required this.reviewedByWakepsek,
    required this.reviewedByKepsek,
    required this.pendingReview,
  });

  factory ReviewStats.fromJson(Map<String, dynamic> json) {
    return ReviewStats(
      totalResponded: json['total_responded'] ?? 0,
      reviewedByWakepsek: json['reviewed_by_wakepsek'] ?? 0,
      reviewedByKepsek: json['reviewed_by_kepsek'] ?? 0,
      pendingReview: json['pending_review'] ?? 0,
    );
  }

  int get totalReviewed => reviewedByWakepsek + reviewedByKepsek;
  double get reviewPercentage => totalResponded > 0 
      ? (totalReviewed / totalResponded) * 100 
      : 0;
}

class ResponseTemplate {
  final int id;
  final String name;
  final String content;
  final String defaultStatus;

  ResponseTemplate({
    required this.id,
    required this.name,
    required this.content,
    required this.defaultStatus,
  });

  factory ResponseTemplate.fromJson(Map<String, dynamic> json) {
    return ResponseTemplate(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      content: json['content'] ?? '',
      defaultStatus: json['default_status'] ?? 'Disetujui',
    );
  }
}