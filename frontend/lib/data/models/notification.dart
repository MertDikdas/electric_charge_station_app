class AppNotification {
  const AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.notificationType,
    required this.isRead,
    required this.createdAt,
  });

  final int id;
  final int userId;
  final String title;
  final String message;
  final String notificationType;
  final bool isRead;
  final String createdAt;

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: _asInt(json['id']),
      userId: _asInt(json['user_id'] ?? json['userId']),
      title: (json['title'] ?? '').toString(),
      message: (json['message'] ?? '').toString(),
      notificationType:
          (json['notification_type'] ?? json['notificationType'] ?? '')
              .toString(),
      isRead: json['is_read'] == true || json['isRead'] == true,
      createdAt: (json['created_at'] ?? json['createdAt'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'title': title,
      'message': message,
      'notification_type': notificationType,
    };
  }

  static int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
