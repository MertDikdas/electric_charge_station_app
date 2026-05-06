import '../api/api_client.dart';
import '../models/notification.dart';
import 'json_helpers.dart';

class NotificationService {
  NotificationService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<AppNotification> createNotification({
    required int userId,
    required String title,
    required String message,
    String notificationType = 'INFO',
  }) async {
    return AppNotification.fromJson(
      parseObject(
        await _apiClient.post(
          '/notifications',
          body: {
            'user_id': userId,
            'title': title,
            'message': message,
            'notification_type': notificationType,
          },
        ),
      ),
    );
  }

  Future<List<AppNotification>> getNotifications({
    bool? unreadOnly,
  }) async {
    return parseList(
      await _apiClient.get(
        '/notifications',
        queryParameters: {'unread_only': unreadOnly?.toString()},
      ),
      AppNotification.fromJson,
    );
  }

  Future<List<AppNotification>> getAllNotifications() async {
    return parseList(
      await _apiClient.get('/notifications/all'),
      AppNotification.fromJson,
    );
  }

  Future<AppNotification> getNotification(int notificationId) async {
    return AppNotification.fromJson(
      parseObject(await _apiClient.get('/notifications/$notificationId')),
    );
  }

  Future<AppNotification> markNotificationAsRead(int notificationId) async {
    return AppNotification.fromJson(
      parseObject(
        await _apiClient.patch('/notifications/$notificationId/read'),
      ),
    );
  }

  Future<void> deleteNotification(int notificationId) {
    return _apiClient.delete('/notifications/$notificationId');
  }
}
