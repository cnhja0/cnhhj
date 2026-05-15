import 'dart:async';

import '../../models/app_notification.dart';
import '../notification_repository.dart';
import '_seed.dart';

class MockNotificationRepository implements NotificationRepository {
  final StreamController<String> _changes = StreamController<String>.broadcast();

  @override
  Future<List<AppNotification>> list(String userId) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    return _forUser(userId);
  }

  @override
  Stream<List<AppNotification>> watch(String userId) async* {
    yield _forUser(userId);
    await for (final _ in _changes.stream) {
      yield _forUser(userId);
    }
  }

  @override
  Future<int> unreadCount(String userId) async {
    await Future<void>.delayed(const Duration(milliseconds: 80));
    return _forUser(userId).where((AppNotification n) => n.isUnread).length;
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    final int idx = MockState.instance.notifications.indexWhere(
      (AppNotification n) => n.id == notificationId,
    );
    if (idx == -1) return;
    final AppNotification cur = MockState.instance.notifications[idx];
    if (cur.readAt != null) return;
    MockState.instance.notifications[idx] =
        cur.copyWith(readAt: DateTime.now());
    _changes.add(notificationId);
  }

  @override
  Future<void> markAllAsRead(String userId) async {
    final DateTime now = DateTime.now();
    for (int i = 0; i < MockState.instance.notifications.length; i++) {
      final AppNotification n = MockState.instance.notifications[i];
      if (n.userId == userId && n.readAt == null) {
        MockState.instance.notifications[i] = n.copyWith(readAt: now);
      }
    }
    _changes.add(userId);
  }

  List<AppNotification> _forUser(String userId) {
    final List<AppNotification> filtered = MockState.instance.notifications
        .where((AppNotification n) => n.userId == userId)
        .toList()
      ..sort((AppNotification a, AppNotification b) =>
          b.createdAt.compareTo(a.createdAt));
    return filtered;
  }
}
