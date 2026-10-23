/// Support ticket model corresponding to public.support_tickets table
class SupportTicket {
  final String id;
  final String? requestId;
  final String userId;
  final String issueCategory;
  final String description;
  final String status;
  final String? resolutionNotes;
  final DateTime createdAt;

  const SupportTicket({
    required this.id,
    this.requestId,
    required this.userId,
    required this.issueCategory,
    required this.description,
    this.status = 'open',
    this.resolutionNotes,
    required this.createdAt,
  });

  factory SupportTicket.fromJson(Map<String, dynamic> json) {
    return SupportTicket(
      id: json['id'] as String,
      requestId: json['request_id'] as String?,
      userId: json['user_id'] as String,
      issueCategory: json['issue_category'] as String,
      description: json['description'] as String,
      status: json['status'] as String? ?? 'open',
      resolutionNotes: json['resolution_notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'request_id': requestId,
      'user_id': userId,
      'issue_category': issueCategory,
      'description': description,
      'status': status,
    };
  }
}
