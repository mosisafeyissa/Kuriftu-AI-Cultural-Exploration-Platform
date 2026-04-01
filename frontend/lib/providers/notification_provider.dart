import 'package:flutter/foundation.dart';
import '../models/app_notification.dart';

class NotificationProvider extends ChangeNotifier {
  final List<AppNotification> _notifications = [
    AppNotification(
      id: 'welcome',
      title: 'Welcome to Kuriftu',
      message: 'Your journey into African heritage begins now.',
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
    ),
    AppNotification(
      id: 'discovery',
      title: 'New Artifacts Discovered',
      message: 'Explore the latest additions to our collection.',
      timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
    ),
  ];

  List<AppNotification> get notifications {
    final sorted = List<AppNotification>.from(_notifications);
    sorted.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return sorted;
  }

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  void addOrderNotification(String orderId, String artifactName) {
    final shortId = orderId.length > 6 ? orderId.substring(orderId.length - 6) : orderId;
    _notifications.add(AppNotification(
      id: 'order_$orderId',
      title: 'Order #$shortId Confirmed',
      message: 'Your $artifactName has been reserved.',
      timestamp: DateTime.now(),
    ));
    notifyListeners();
  }

  void markAllRead() {
    for (var i = 0; i < _notifications.length; i++) {
      if (!_notifications[i].isRead) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
      }
    }
    notifyListeners();
  }

  void markRead(String id) {
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx != -1 && !_notifications[idx].isRead) {
      _notifications[idx] = _notifications[idx].copyWith(isRead: true);
      notifyListeners();
    }
  }
}
