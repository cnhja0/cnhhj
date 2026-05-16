import '../models/app_notification.dart';

abstract class NotificationRepository {
  Future<List<AppNotification>> list(String userId);
  Stream<List<AppNotification>> watch(String userId);
  Future<int> unreadCount(String userId);
  Future<void> markAsRead(String notificationId);
  Future<void> markAllAsRead(String userId);

  /// Cria uma nova notificação para [userId]. Chamado pelos outros
  /// repositórios em eventos relevantes (aceitar booking, nova mensagem,
  /// review recebida etc.) para que o app "viva" em runtime.
  Future<AppNotification> create(AppNotification notification);
}
