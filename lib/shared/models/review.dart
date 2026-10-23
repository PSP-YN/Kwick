/// Review model corresponding to public.reviews table
class Review {
  final String id;
  final String customerId;
  final String requestId;
  final String providerId;
  final int rating;
  final String? comment;
  final String moderationStatus;
  final DateTime createdAt;

  const Review({
    required this.id,
    required this.customerId,
    required this.requestId,
    required this.providerId,
    required this.rating,
    this.comment,
    this.moderationStatus = 'published',
    required this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] as String,
      customerId: json['customer_id'] as String,
      requestId: json['request_id'] as String,
      providerId: json['provider_id'] as String,
      rating: json['rating'] as int,
      comment: json['comment'] as String?,
      moderationStatus: json['moderation_status'] as String? ?? 'published',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'request_id': requestId,
      'provider_id': providerId,
      'rating': rating,
      'comment': comment,
    };
  }
}
