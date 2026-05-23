// lib/models/statistic_model.dart

class GuruStatistics {
  final int totalActiveGuru;
  final int totalRespondedAll;
  final double avgResponseAll;
  final double completionRate;
  final String topPerformer;
  final int topPerformerCount;
  final String fastestResponder;
  final double fastestTime;
  final int highPerformers;
  final int mediumPerformers;
  final int lowPerformers;
  
  GuruStatistics({
    required this.totalActiveGuru,
    required this.totalRespondedAll,
    required this.avgResponseAll,
    required this.completionRate,
    required this.topPerformer,
    required this.topPerformerCount,
    required this.fastestResponder,
    required this.fastestTime,
    required this.highPerformers,
    required this.mediumPerformers,
    required this.lowPerformers,
  });
  
  factory GuruStatistics.empty() {
    return GuruStatistics(
      totalActiveGuru: 0,
      totalRespondedAll: 0,
      avgResponseAll: 0,
      completionRate: 0,
      topPerformer: '-',
      topPerformerCount: 0,
      fastestResponder: '-',
      fastestTime: 0,
      highPerformers: 0,
      mediumPerformers: 0,
      lowPerformers: 0,
    );
  }
  
  factory GuruStatistics.fromJson(Map<String, dynamic> json) {
    // Helper function untuk konversi aman ke int
    int _toInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      if (value is double) return value.toInt();
      return 0;
    }
    
    // Helper function untuk konversi aman ke double
    double _toDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }
    
    return GuruStatistics(
      totalActiveGuru: _toInt(json['total_active_guru']),
      totalRespondedAll: _toInt(json['total_responded_all']),
      avgResponseAll: _toDouble(json['avg_response_all']),
      completionRate: _toDouble(json['completion_rate']),
      topPerformer: json['top_performer']?.toString() ?? '-',
      topPerformerCount: _toInt(json['top_performer_count']),
      fastestResponder: json['fastest_responder']?.toString() ?? '-',
      fastestTime: _toDouble(json['fastest_time']),
      highPerformers: _toInt(json['high_performers']),
      mediumPerformers: _toInt(json['medium_performers']),
      lowPerformers: _toInt(json['low_performers']),
    );
  }
}

// Statistics untuk card dashboard
class Statistics {
  final int totalResponded;
  final int pendingReview;
  final int reviewed;
  final int avgResponseTime;
  final String fastestResponder;
  final int totalGuru;
  final int totalMessageTypes;
  
  Statistics({
    required this.totalResponded,
    required this.pendingReview,
    required this.reviewed,
    required this.avgResponseTime,
    required this.fastestResponder,
    required this.totalGuru,
    required this.totalMessageTypes,
  });
  
  factory Statistics.empty() {
    return Statistics(
      totalResponded: 0,
      pendingReview: 0,
      reviewed: 0,
      avgResponseTime: 0,
      fastestResponder: '-',
      totalGuru: 0,
      totalMessageTypes: 0,
    );
  }
  
  factory Statistics.fromJson(Map<String, dynamic> json) {
    // Helper function untuk konversi aman ke int
    int _toInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      if (value is double) return value.toInt();
      return 0;
    }
    
    return Statistics(
      totalResponded: _toInt(json['total_responded']),
      pendingReview: _toInt(json['pending_review']),
      reviewed: _toInt(json['reviewed']),
      avgResponseTime: _toInt(json['avg_response_time']),
      fastestResponder: json['fastest_responder']?.toString() ?? '-',
      totalGuru: _toInt(json['total_guru']),
      totalMessageTypes: _toInt(json['total_message_types']),
    );
  }
}

// DashboardData yang menggabungkan semua data
class DashboardData {
  final Statistics stats;
  final GuruStatistics guruStats;
  final List<dynamic> messages;
  final List<GuruPerformance> guruPerformances;
  final List<MessageTypeStat> messageTypeStats;
  final List<GuruItem> guruList;
  final int total;
  final int totalPages;
  final int messageTypeTotal;
  final int messageTotal;
  
  DashboardData({
    required this.stats,
    required this.guruStats,
    required this.messages,
    required this.guruPerformances,
    required this.messageTypeStats,
    required this.guruList,
    required this.total,
    required this.totalPages,
    required this.messageTypeTotal,
    required this.messageTotal,
  });
  
  factory DashboardData.fromJson(Map<String, dynamic> json) {
    // Helper function untuk konversi aman ke int
    int _toInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      if (value is double) return value.toInt();
      return 0;
    }
    
    return DashboardData(
      stats: Statistics.fromJson(json['stats'] ?? {}),
      guruStats: GuruStatistics.fromJson(json['guru_stats'] ?? {}),
      messages: json['messages'] ?? [],
      guruPerformances: (json['guru_performances'] as List?)
          ?.map((g) => GuruPerformance.fromJson(g))
          .toList() ?? [],
      messageTypeStats: (json['message_type_stats'] as List?)
          ?.map((m) => MessageTypeStat.fromJson(m))
          .toList() ?? [],
      guruList: (json['guru_list'] as List?)
          ?.map((g) => GuruItem.fromJson(g))
          .toList() ?? [],
      total: _toInt(json['total']),
      totalPages: _toInt(json['total_pages']),
      messageTypeTotal: _toInt(json['message_type_total']),
      messageTotal: _toInt(json['message_total']),
    );
  }
}

// GuruPerformance untuk chart
class GuruPerformance {
  final int id;
  final String namaLengkap;
  final String userType;
  final int totalMessages;
  final int pendingMessages;
  final int respondedMessages;
  final int expiredMessages;
  final double avgResponseHours;
  
  GuruPerformance({
    required this.id,
    required this.namaLengkap,
    required this.userType,
    required this.totalMessages,
    required this.pendingMessages,
    required this.respondedMessages,
    required this.expiredMessages,
    required this.avgResponseHours,
  });
  
  factory GuruPerformance.fromJson(Map<String, dynamic> json) {
    // Helper function untuk konversi aman ke int
    int _toInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      if (value is double) return value.toInt();
      return 0;
    }
    
    // Helper function untuk konversi aman ke double
    double _toDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }
    
    return GuruPerformance(
      id: _toInt(json['id']),
      namaLengkap: json['nama_lengkap']?.toString() ?? '',
      userType: json['user_type']?.toString() ?? '',
      totalMessages: _toInt(json['total_messages']),
      pendingMessages: _toInt(json['pending_messages']),
      respondedMessages: _toInt(json['responded_messages']),
      expiredMessages: _toInt(json['expired_messages']),
      avgResponseHours: _toDouble(json['avg_response_hours']),
    );
  }
}

// MessageTypeStat untuk chart jenis pesan
class MessageTypeStat {
  final int id;
  final String jenisPesan;
  final String? responderType;
  final int totalMessages;
  final int respondedMessages;
  final int pendingMessages;
  final int expiredMessages;
  final double avgResponseHours;
  
  MessageTypeStat({
    required this.id,
    required this.jenisPesan,
    this.responderType,
    required this.totalMessages,
    required this.respondedMessages,
    required this.pendingMessages,
    required this.expiredMessages,
    required this.avgResponseHours,
  });
  
  factory MessageTypeStat.fromJson(Map<String, dynamic> json) {
    // Helper function untuk konversi aman ke int
    int _toInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      if (value is double) return value.toInt();
      return 0;
    }
    
    // Helper function untuk konversi aman ke double
    double _toDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }
    
    return MessageTypeStat(
      id: _toInt(json['id']),
      jenisPesan: json['jenis_pesan']?.toString() ?? '',
      responderType: json['responder_type']?.toString(),
      totalMessages: _toInt(json['total_messages']),
      respondedMessages: _toInt(json['responded_messages']),
      pendingMessages: _toInt(json['pending_messages']),
      expiredMessages: _toInt(json['expired_messages']),
      avgResponseHours: _toDouble(json['avg_response_hours']),
    );
  }
}

// GuruItem untuk dropdown filter
class GuruItem {
  final int id;
  final String namaLengkap;
  final String userType;
  
  GuruItem({
    required this.id,
    required this.namaLengkap,
    required this.userType,
  });
  
  factory GuruItem.fromJson(Map<String, dynamic> json) {
    // Helper function untuk konversi aman ke int
    int _toInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      if (value is double) return value.toInt();
      return 0;
    }
    
    return GuruItem(
      id: _toInt(json['id']),
      namaLengkap: json['nama_lengkap']?.toString() ?? '',
      userType: json['user_type']?.toString() ?? '',
    );
  }
}

// MessageItem untuk daftar pesan
class MessageItem {
  final int id;
  final String isiPesan;
  final DateTime createdAt;
  final String? status;
  final bool isExternal;
  final String pengirimNamaDisplay;
  final String? pengirimTipe;
  final String? messageType;
  final String? expectedResponderType;
  final int? responseId;
  final int? guruResponderId;
  final String? guruResponderNama;
  final String? guruResponderType;
  final String? guruResponse;
  final String? guruResponseStatus;
  final DateTime? guruResponseDate;
  final int? reviewId;
  final int? reviewerId;
  final String? reviewerNama;
  final String? reviewerType;
  final String? reviewCatatan;
  final DateTime? reviewDate;
  final int? wakepsekReviewId;
  final String? wakepsekReviewerNama;
  final String? wakepsekReviewerType;
  final String? wakepsekReviewCatatan;
  final DateTime? wakepsekReviewDate;
  final int? kepsekReviewId;
  final String? kepsekReviewerNama;
  final String? kepsekReviewCatatan;
  final DateTime? kepsekReviewDate;
  final int attachmentCount;
  
  MessageItem({
    required this.id,
    required this.isiPesan,
    required this.createdAt,
    this.status,
    required this.isExternal,
    required this.pengirimNamaDisplay,
    this.pengirimTipe,
    this.messageType,
    this.expectedResponderType,
    this.responseId,
    this.guruResponderId,
    this.guruResponderNama,
    this.guruResponderType,
    this.guruResponse,
    this.guruResponseStatus,
    this.guruResponseDate,
    this.reviewId,
    this.reviewerId,
    this.reviewerNama,
    this.reviewerType,
    this.reviewCatatan,
    this.reviewDate,
    this.wakepsekReviewId,
    this.wakepsekReviewerNama,
    this.wakepsekReviewerType,
    this.wakepsekReviewCatatan,
    this.wakepsekReviewDate,
    this.kepsekReviewId,
    this.kepsekReviewerNama,
    this.kepsekReviewCatatan,
    this.kepsekReviewDate,
    required this.attachmentCount,
  });
  
  factory MessageItem.fromJson(Map<String, dynamic> json) {
    // Helper function untuk konversi aman ke int
    int _toInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      if (value is double) return value.toInt();
      return 0;
    }
    
    // Helper function untuk konversi aman ke DateTime
    DateTime _toDateTime(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }
    
    return MessageItem(
      id: _toInt(json['id']),
      isiPesan: json['isi_pesan']?.toString() ?? '',
      createdAt: _toDateTime(json['created_at']),
      status: json['status']?.toString(),
      isExternal: json['is_external'] == 1 || json['is_external'] == '1',
      pengirimNamaDisplay: json['pengirim_nama_display']?.toString() ?? 'Unknown',
      pengirimTipe: json['pengirim_tipe']?.toString(),
      messageType: json['message_type']?.toString(),
      expectedResponderType: json['expected_responder_type']?.toString(),
      responseId: json['response_id'] != null ? _toInt(json['response_id']) : null,
      guruResponderId: json['guru_responder_id'] != null ? _toInt(json['guru_responder_id']) : null,
      guruResponderNama: json['guru_responder_nama']?.toString(),
      guruResponderType: json['guru_responder_type']?.toString(),
      guruResponse: json['guru_response']?.toString(),
      guruResponseStatus: json['guru_response_status']?.toString(),
      guruResponseDate: json['guru_response_date'] != null ? _toDateTime(json['guru_response_date']) : null,
      reviewId: json['review_id'] != null ? _toInt(json['review_id']) : null,
      reviewerId: json['reviewer_id'] != null ? _toInt(json['reviewer_id']) : null,
      reviewerNama: json['reviewer_nama']?.toString(),
      reviewerType: json['reviewer_type']?.toString(),
      reviewCatatan: json['review_catatan']?.toString(),
      reviewDate: json['review_date'] != null ? _toDateTime(json['review_date']) : null,
      wakepsekReviewId: json['wakepsek_review_id'] != null ? _toInt(json['wakepsek_review_id']) : null,
      wakepsekReviewerNama: json['wakepsek_reviewer_nama']?.toString(),
      wakepsekReviewerType: json['wakepsek_reviewer_type']?.toString(),
      wakepsekReviewCatatan: json['wakepsek_review_catatan']?.toString(),
      wakepsekReviewDate: json['wakepsek_review_date'] != null ? _toDateTime(json['wakepsek_review_date']) : null,
      kepsekReviewId: json['kepsek_review_id'] != null ? _toInt(json['kepsek_review_id']) : null,
      kepsekReviewerNama: json['kepsek_reviewer_nama']?.toString(),
      kepsekReviewCatatan: json['kepsek_review_catatan']?.toString(),
      kepsekReviewDate: json['kepsek_review_date'] != null ? _toDateTime(json['kepsek_review_date']) : null,
      attachmentCount: _toInt(json['attachment_count']),
    );
  }
}