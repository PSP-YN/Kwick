/// Assignment status enum matching PostgreSQL constraints
enum AssignmentStatus {
  offered('offered', 'Offered'),
  accepted('accepted', 'Accepted'),
  declined('declined', 'Declined'),
  withdrawn('withdrawn', 'Withdrawn'),
  expired('expired', 'Expired'),
  completed('completed', 'Completed');

  final String value;
  final String label;

  const AssignmentStatus(this.value, this.label);

  static AssignmentStatus fromString(String val) {
    for (final s in AssignmentStatus.values) {
      if (s.value == val) return s;
    }
    return AssignmentStatus.offered;
  }
}

/// Assignment model corresponding to public.assignments table
class Assignment {
  final String id;
  final String requestId;
  final String providerId;
  final AssignmentStatus status;
  final String? assignedBy;
  final DateTime assignedAt;
  final DateTime? respondedAt;
  final String? declineReason;
  final String? providerName;
  final String? providerPhone;

  const Assignment({
    required this.id,
    required this.requestId,
    required this.providerId,
    required this.status,
    this.assignedBy,
    required this.assignedAt,
    this.respondedAt,
    this.declineReason,
    this.providerName,
    this.providerPhone,
  });

  factory Assignment.fromJson(Map<String, dynamic> json) {
    String? name;
    String? phone;
    if (json['providers'] != null) {
      final prov = json['providers'] as Map<String, dynamic>;
      if (prov['profiles'] != null) {
        final prof = prov['profiles'] as Map<String, dynamic>;
        name = prof['full_name'] as String?;
        phone = prof['phone'] as String?;
      }
    }

    return Assignment(
      id: json['id'] as String,
      requestId: json['request_id'] as String,
      providerId: json['provider_id'] as String,
      status: AssignmentStatus.fromString(
        json['status'] as String? ?? 'offered',
      ),
      assignedBy: json['assigned_by'] as String?,
      assignedAt: json['assigned_at'] != null
          ? DateTime.parse(json['assigned_at'] as String)
          : DateTime.now(),
      respondedAt: json['responded_at'] != null
          ? DateTime.parse(json['responded_at'] as String)
          : null,
      declineReason: json['decline_reason'] as String?,
      providerName: name ?? json['provider_name'] as String?,
      providerPhone: phone ?? json['provider_phone'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'request_id': requestId,
      'provider_id': providerId,
      'status': status.value,
      'assigned_by': assignedBy,
      'assigned_at': assignedAt.toIso8601String(),
      'responded_at': respondedAt?.toIso8601String(),
      'decline_reason': declineReason,
    };
  }
}
