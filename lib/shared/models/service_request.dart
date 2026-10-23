/// Order status enum matching PostgreSQL enum/checks
enum OrderStatus {
  requested('requested', 'Requested'),
  reviewing('reviewing', 'In Review'),
  assigned('assigned', 'Provider Assigned'),
  accepted('accepted', 'Accepted'),
  travelling('travelling', 'En Route'),
  inProgress('in_progress', 'In Progress'),
  completed('completed', 'Completed'),
  cancelled('cancelled', 'Cancelled'),
  disputed('disputed', 'Disputed');

  final String value;
  final String label;

  const OrderStatus(this.value, this.label);

  static OrderStatus fromString(String val) {
    for (final status in OrderStatus.values) {
      if (status.value == val) return status;
    }
    return OrderStatus.requested;
  }

  bool get isCancellable =>
      this == OrderStatus.requested ||
      this == OrderStatus.reviewing ||
      this == OrderStatus.assigned;

  bool get isActive =>
      this != OrderStatus.completed &&
      this != OrderStatus.cancelled &&
      this != OrderStatus.disputed;
}

/// Service request model corresponding to public.service_requests table
class ServiceRequest {
  final String id;
  final String customerId;
  final String categoryId;
  final String? categoryName;
  final String serviceAreaId;
  final String description;
  final String addressLine;
  final String pincode;
  final double? latitude;
  final double? longitude;
  final DateTime? scheduledAt;
  final OrderStatus status;
  final int? quotedPriceMinor;
  final int? finalPriceMinor;
  final String? customerNotes;
  final String? photoStoragePath;
  final String? cancellationReason;
  final String? cancelledBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ServiceRequest({
    required this.id,
    required this.customerId,
    required this.categoryId,
    this.categoryName,
    required this.serviceAreaId,
    required this.description,
    required this.addressLine,
    required this.pincode,
    this.latitude,
    this.longitude,
    this.scheduledAt,
    this.status = OrderStatus.requested,
    this.quotedPriceMinor,
    this.finalPriceMinor,
    this.customerNotes,
    this.photoStoragePath,
    this.cancellationReason,
    this.cancelledBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ServiceRequest.fromJson(Map<String, dynamic> json) {
    return ServiceRequest(
      id: json['id'] as String,
      customerId: json['customer_id'] as String,
      categoryId: json['category_id'] as String,
      categoryName: json['service_categories'] != null
          ? (json['service_categories'] as Map<String, dynamic>)['name']
                as String?
          : json['category_name'] as String?,
      serviceAreaId: json['service_area_id'] as String,
      description: json['description'] as String,
      addressLine: json['address_line'] as String,
      pincode: json['pincode'] as String,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      scheduledAt: json['scheduled_at'] != null
          ? DateTime.parse(json['scheduled_at'] as String)
          : null,
      status: OrderStatus.fromString(json['status'] as String? ?? 'requested'),
      quotedPriceMinor: json['quoted_price_minor'] as int?,
      finalPriceMinor: json['final_price_minor'] as int?,
      customerNotes: json['customer_notes'] as String?,
      photoStoragePath: json['photo_storage_path'] as String?,
      cancellationReason: json['cancellation_reason'] as String?,
      cancelledBy: json['cancelled_by'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'category_id': categoryId,
      'service_area_id': serviceAreaId,
      'description': description,
      'address_line': addressLine,
      'pincode': pincode,
      'latitude': latitude,
      'longitude': longitude,
      'scheduled_at': scheduledAt?.toIso8601String(),
      'status': status.value,
      'quoted_price_minor': quotedPriceMinor,
      'final_price_minor': finalPriceMinor,
      'customer_notes': customerNotes,
      'photo_storage_path': photoStoragePath,
      'cancellation_reason': cancellationReason,
    };
  }
}
