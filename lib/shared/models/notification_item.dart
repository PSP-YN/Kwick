/// In-app notification item corresponding to public.notifications table
class NotificationItem {
  final String id;
  final String recipientId;
  final String notificationType;
  final String title;
  final String body;
  final String deliveryState;
  final Map<String, dynamic> payload;
  final DateTime createdAt;

  const NotificationItem({
    required this.id,
    required this.recipientId,
    required this.notificationType,
    required this.title,
    required this.body,
    this.deliveryState = 'pending',
    this.payload = const {},
    required this.createdAt,
  });

  bool get isRead => deliveryState == 'read';

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] as String,
      recipientId: json['recipient_id'] as String,
      notificationType: json['notification_type'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      deliveryState: json['delivery_state'] as String? ?? 'pending',
      payload: (json['payload'] as Map<String, dynamic>?) ?? {},
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }
}
