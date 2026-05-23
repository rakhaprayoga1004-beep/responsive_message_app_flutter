// lib/models/message_stats_model.dart
class MessageStatsModel {
  final int total;
  final int pending;
  final int approved;
  final int rejected;
  final int completed;
  final int expired;
  final int withAttachments;
  
  final int totalResponses;
  final int approvedResponses;
  final int rejectedResponses;
  final int processedResponses;
  final int completedResponses;
  final int responsesToday;
  final int responsesLast24h;
  
  MessageStatsModel({
    required this.total,
    required this.pending,
    required this.approved,
    required this.rejected,
    required this.completed,
    required this.expired,
    required this.withAttachments,
    required this.totalResponses,
    required this.approvedResponses,
    required this.rejectedResponses,
    required this.processedResponses,
    required this.completedResponses,
    required this.responsesToday,
    required this.responsesLast24h,
  });
  
  factory MessageStatsModel.fromJson(Map<String, dynamic> json) {
    return MessageStatsModel(
      total: json['total'] ?? 0,
      pending: json['pending'] ?? 0,
      approved: json['approved'] ?? 0,
      rejected: json['rejected'] ?? 0,
      completed: json['completed'] ?? 0,
      expired: json['expired'] ?? 0,
      withAttachments: json['with_attachments'] ?? 0,
      totalResponses: json['total_responses'] ?? 0,
      approvedResponses: json['approved_responses'] ?? 0,
      rejectedResponses: json['rejected_responses'] ?? 0,
      processedResponses: json['processed_responses'] ?? 0,
      completedResponses: json['completed_responses'] ?? 0,
      responsesToday: json['responses_today'] ?? 0,
      responsesLast24h: json['responses_last_24h'] ?? 0,
    );
  }
}