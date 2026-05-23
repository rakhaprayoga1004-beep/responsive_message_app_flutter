// lib/models/dashboard_data.dart
class DashboardData {
  final Statistics stats;
  final GuruStatistics guruStats;
  final List<GuruPerformance> guruPerformances;
  final List<MessageTypeStat> messageTypeStats;
  final int messageTypeTotal;
  final int messageTotal;
  final List<MessageItem> messages;
  final int totalMessages;
  final List<GuruItem> guruList;
  final String dateFrom;
  final String dateTo;
  
  DashboardData({
    required this.stats,
    required this.guruStats,
    required this.guruPerformances,
    required this.messageTypeStats,
    required this.messageTypeTotal,
    required this.messageTotal,
    required this.messages,
    required this.totalMessages,
    required this.guruList,
    required this.dateFrom,
    required this.dateTo,
  });
  
  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      stats: Statistics.fromJson(json['stats'] ?? {}),
      guruStats: GuruStatistics.fromJson(json['guru_stats'] ?? {}),
      guruPerformances: (json['guru_performances'] as List?)
          ?.map((g) => GuruPerformance.fromJson(g))
          .toList() ?? [],
      messageTypeStats: (json['message_type_stats'] as List?)
          ?.map((m) => MessageTypeStat.fromJson(m))
          .toList() ?? [],
      messageTypeTotal: json['message_type_total'] ?? 0,
      messageTotal: json['message_total'] ?? 0,
      messages: (json['messages'] as List?)
          ?.map((m) => MessageItem.fromJson(m))
          .toList() ?? [],
      totalMessages: json['total_messages'] ?? 0,
      guruList: (json['guru_list'] as List?)
          ?.map((g) => GuruItem.fromJson(g))
          .toList() ?? [],
      dateFrom: json['date_from'] ?? '',
      dateTo: json['date_to'] ?? '',
    );
  }
}

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
  
  factory GuruStatistics.fromJson(Map<String, dynamic> json) {
    return GuruStatistics(
      totalActiveGuru: json['total_active_guru'] ?? 0,
      totalRespondedAll: json['total_responded_all'] ?? 0,
      avgResponseAll: (json['avg_response_all'] ?? 0).toDouble(),
      completionRate: (json['completion_rate'] ?? 0).toDouble(),
      topPerformer: json['top_performer'] ?? '-',
      topPerformerCount: json['top_performer_count'] ?? 0,
      fastestResponder: json['fastest_responder'] ?? '-',
      fastestTime: (json['fastest_time'] ?? 0).toDouble(),
      highPerformers: json['high_performers'] ?? 0,
      mediumPerformers: json['medium_performers'] ?? 0,
      lowPerformers: json['low_performers'] ?? 0,
    );
  }
}