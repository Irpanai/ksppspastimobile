import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService _service = NotificationService();

  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _errorMessage;
  String _activeFilter = 'all';

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get activeFilter => _activeFilter;

  Future<void> fetchNotifications({bool refresh = false, String? filter}) async {
    if (filter != null) {
      _activeFilter = filter;
    }

    if (!refresh && _notifications.isNotEmpty) {
      // Background silent sync
    } else {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      final filterParam = _activeFilter == 'all' ? null : _activeFilter;
      final res = await _service.getNotifications(filter: filterParam);
      _notifications = res.notifications;
      _unreadCount = res.unreadCount;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      if (kDebugMode) {
        print('NotificationProvider fetch error: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setFilter(String filter) {
    if (_activeFilter != filter) {
      _activeFilter = filter;
      fetchNotifications(refresh: true);
    }
  }

  Future<void> markAsRead(NotificationModel notif) async {
    if (notif.isRead) return;

    // Optimistic update
    final index = _notifications.indexWhere((n) => n.id == notif.id);
    if (index != -1) {
      _notifications[index] = notif.copyWith(isRead: true);
      if (_unreadCount > 0) _unreadCount--;
      notifyListeners();
    }

    try {
      final updatedUnread = await _service.markAsRead(notif.id);
      _unreadCount = updatedUnread;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error marking notification as read: $e');
      }
    }
  }

  Future<void> markAllAsRead() async {
    if (_unreadCount == 0) return;

    // Optimistic update
    _unreadCount = 0;
    _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
    notifyListeners();

    try {
      await _service.markAllAsRead();
    } catch (e) {
      if (kDebugMode) {
        print('Error marking all notifications as read: $e');
      }
      // Re-fetch to sync
      fetchNotifications(refresh: true);
    }
  }

  Future<void> deleteNotification(NotificationModel notif) async {
    final wasUnread = !notif.isRead;
    _notifications.removeWhere((n) => n.id == notif.id);
    if (wasUnread && _unreadCount > 0) {
      _unreadCount--;
    }
    notifyListeners();

    try {
      final updatedUnread = await _service.deleteNotification(notif.id);
      _unreadCount = updatedUnread;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting notification: $e');
      }
    }
  }
}
