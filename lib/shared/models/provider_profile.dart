/// Verification status enum
enum VerificationStatus {
  pending('pending', 'Pending Verification'),
  approved('approved', 'Verified'),
  rejected('rejected', 'Application Rejected'),
  suspended('suspended', 'Suspended');

  final String value;
  final String label;

  const VerificationStatus(this.value, this.label);

  static VerificationStatus fromString(String val) {
    for (final v in VerificationStatus.values) {
      if (v.value == val) return v;
    }
    return VerificationStatus.pending;
  }
}

/// Availability status enum
enum AvailabilityStatus {
  available('available', 'Available for Jobs'),
  unavailable('unavailable', 'Offline / Unavailable'),
  busy('busy', 'Currently on a Job');

  final String value;
  final String label;

  const AvailabilityStatus(this.value, this.label);

  static AvailabilityStatus fromString(String val) {
    for (final a in AvailabilityStatus.values) {
      if (a.value == val) return a;
    }
    return AvailabilityStatus.unavailable;
  }
}

/// Provider profile model corresponding to public.providers table
class ProviderProfile {
  final String id;
  final String profileId;
  final VerificationStatus verificationStatus;
  final AvailabilityStatus availabilityStatus;
  final String? serviceAreaId;
  final int experienceYears;
  final String? verificationNotes;
  final String? approvedBy;
  final DateTime? approvedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined profile fields
  final String? fullName;
  final String? phone;
  final String? email;

  const ProviderProfile({
    required this.id,
    required this.profileId,
    required this.verificationStatus,
    required this.availabilityStatus,
    this.serviceAreaId,
    required this.experienceYears,
    this.verificationNotes,
    this.approvedBy,
    this.approvedAt,
    required this.createdAt,
    required this.updatedAt,
    this.fullName,
    this.phone,
    this.email,
  });

  bool get isApproved => verificationStatus == VerificationStatus.approved;
  bool get isAvailable => availabilityStatus == AvailabilityStatus.available;

  factory ProviderProfile.fromJson(Map<String, dynamic> json) {
    String? name;
    String? phone;
    String? email;
    if (json['profiles'] != null) {
      final prof = json['profiles'] as Map<String, dynamic>;
      name = prof['full_name'] as String?;
      phone = prof['phone'] as String?;
      email = prof['email'] as String?;
    }

    return ProviderProfile(
      id: json['id'] as String,
      profileId: json['profile_id'] as String,
      verificationStatus: VerificationStatus.fromString(
        json['verification_status'] as String? ?? 'pending',
      ),
      availabilityStatus: AvailabilityStatus.fromString(
        json['availability_status'] as String? ?? 'unavailable',
      ),
      serviceAreaId: json['service_area_id'] as String?,
      experienceYears: json['experience_years'] as int? ?? 0,
      verificationNotes: json['verification_notes'] as String?,
      approvedBy: json['approved_by'] as String?,
      approvedAt: json['approved_at'] != null
          ? DateTime.parse(json['approved_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
      fullName: name,
      phone: phone,
      email: email,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'profile_id': profileId,
      'verification_status': verificationStatus.value,
      'availability_status': availabilityStatus.value,
      'service_area_id': serviceAreaId,
      'experience_years': experienceYears,
      'verification_notes': verificationNotes,
    };
  }
}
