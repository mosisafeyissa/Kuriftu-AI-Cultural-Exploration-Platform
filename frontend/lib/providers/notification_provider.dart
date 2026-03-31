import 'package:flutter/foundation.dart';
import '../models/app_notification.dart';
import '../services/api_service.dart';

class NotificationProvider extends ChangeNotifier {
  List<AppNotification> _notifications = [];

  NotificationProvider() {
    refresh();
  }

  Future<void> refresh() async {
    try {
      final rawData = await ApiService.getNotifications();
      _notifications = rawData.map((e) => AppNotification(
        id: e['id'].toString(),
        title: e['title'] ?? '',
        message: e['message'] ?? '',
        timestamp: DateTime.parse(e['created_at']),
        isRead: e['is_read'] ?? false,
      )).toList();
      notifyListeners();
    } catch (e) {
      debugPrint("Error fetching notifications: $e");
    }
  }

  List<AppNotification> get notifications {
    final sorted = List<AppNotification>.from(_notifications);
    sorted.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return sorted;
  }

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  void addOrderNotification(String orderId, String artifactName) {
    refresh(); // Refresh from backend which now generates the AI notification
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
