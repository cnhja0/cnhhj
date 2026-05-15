import '../models/app_notification.dart';

abstract class NotificationRepository {
  Future<List<AppNotification>> list(String userId);
  Stream<List<AppNotification>> watch(String userId);
  Future<int> unreadCount(String userId);
  Future<void> markAsRead(String notificationId);
  Future<void> markAllAsRead(String userId);
}
