import 'package:flutter/foundation.dart';
import '../models/app_notification.dart';
import '../services/api_service.dart';

class NotificationProvider extends ChangeNotifier {
  List<AppNotification> _notifications = [];
  bool _isLoading = false;
  bool _isAuthenticated = false;

  List<AppNotification> get notifications {
    final sorted = List<AppNotification>.from(_notifications);
    sorted.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return sorted;
  }

  int get unreadCount => _notifications.where((n) => !n.isRead).length;
  bool get isLoading => _isLoading;

  /// Called when auth state changes — loads or clears notifications
  void onAuthStateChanged(bool isAuthenticated) {
    _isAuthenticated = isAuthenticated;
    if (isAuthenticated) {
      loadNotifications();
    } else {
      _notifications = [];
      notifyListeners();
    }
  }

  /// Fetch all notifications from backend
  Future<void> loadNotifications() async {
    if (!_isAuthenticated) return;
    _isLoading = true;
    notifyListeners();
    try {
      _notifications = await ApiService.getNotifications();
    } catch (e) {
      debugPrint('[NotificationProvider] Load error: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  /// Mark all notifications as read (backend + local)
  Future<void> markAllRead() async {
    for (var i = 0; i < _notifications.length; i++) {
      if (!_notifications[i].isRead) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
      }
    }
    notifyListeners();
    await ApiService.markNotificationsRead();
  }

  /// Mark a specific notification as read
  Future<void> markRead(String id) async {
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx != -1 && !_notifications[idx].isRead) {
      _notifications[idx] = _notifications[idx].copyWith(isRead: true);
      notifyListeners();
      final intId = int.tryParse(id);
      if (intId != null) {
        await ApiService.markNotificationsRead(ids: [intId]);
      }
    }
  }

  /// Add an order notification locally and refresh from backend
  void addOrderNotification(String orderId, String artifactName) {
    final shortId = orderId.length > 6 ? orderId.substring(orderId.length - 6) : orderId;
    _notifications.insert(0, AppNotification(
      id: 'local_order_$orderId',
      notificationType: 'order_confirmed',
      title: 'Order #$shortId Confirmed',
      message: 'Your $artifactName has been reserved.',
      timestamp: DateTime.now(),
    ));
    notifyListeners();

    // Refresh from backend to get the server-created notification
    Future.delayed(const Duration(seconds: 1), () => loadNotifications());
  }
}
