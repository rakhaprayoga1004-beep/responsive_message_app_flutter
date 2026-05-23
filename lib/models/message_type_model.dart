// lib/models/message_type_model.dart
class MessageTypeModel {
  final int id;
  final String jenisPesan;
  final String? description;
  final int responseDeadlineHours;
  final String? responderType;
  final bool isActive;
  final String? createdAt;
  final String? updatedAt;
  
  MessageTypeModel({
    required this.id,
    required this.jenisPesan,
    this.description,
    required this.responseDeadlineHours,
    this.responderType,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
  });
  
  factory MessageTypeModel.fromJson(Map<String, dynamic> json) {
    return MessageTypeModel(
      id: json['id'] ?? 0,
      jenisPesan: json['jenis_pesan'] ?? '',
      description: json['description'],
      responseDeadlineHours: json['response_deadline_hours'] ?? 72,
      responderType: json['responder_type'],
      isActive: json['is_active'] == 1,
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }
}