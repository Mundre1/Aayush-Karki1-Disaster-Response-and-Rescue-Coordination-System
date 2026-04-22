import 'package:flutter/foundation.dart';
import 'models/notification_model.dart';
import 'notification_service.dart';
import '../../core/services/socket_service.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService _service = NotificationService();
  final SocketService _socketService = SocketService();

  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _errorMessage;

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  NotificationProvider() {
    _initSocketListener();
  }

  void _initSocketListener() {
    _socketService.onNotification((data) {
      try {
        debugPrint('Received notification: $data');
        final notification = NotificationModel.fromJson(data);

        // Add to list if it's new
        if (!_notifications.any((n) => n.notificationId == notification.notificationId)) {
          _notifications.insert(0, notification);
        }

        if (!notification.isRead) {
          _unreadCount++;
        }
        notifyListeners();
      } catch (e) {
        debugPrint('Error parsing notification socket data: $e');
      }
    });
  }

  Future<void> loadNotifications({bool refresh = false}) async {
    if (refresh) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      final data = await _service.getNotifications(limit: 50);
      final List<dynamic> list = data['notifications'];
      _notifications = list.map((e) => NotificationModel.fromJson(e)).toList();

      // Update unread count from this data if possible, or fetch separately to be accurate
      // The backend returns total count of filtered items.
      // If we didn't filter by isRead, we don't know unread count from this call unless we count them locally (which is only for the page).
      // So best to call updateUnreadCount separately.
      await updateUnreadCount();

      _isLoading = false;
      _errorMessage = null;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  Future<void> updateUnreadCount() async {
     try {
       // Fetch only 1 to get total unread count from pagination metadata
       final data = await _service.getNotifications(isRead: false, limit: 1);
       if (data['pagination'] != null) {
         _unreadCount = data['pagination']['total'];
         notifyListeners();
       }
     } catch (e) {
       debugPrint('Error fetching unread count: $e');
     }
  }

  Future<void> markAsRead(int notificationId) async {
    try {
      final updated = await _service.markAsRead(notificationId);
      final index = _notifications.indexWhere((n) => n.notificationId == notificationId);
      if (index != -1) {
        // Create a new list to ensure UI updates
        final updatedList = List<NotificationModel>.from(_notifications);

        // Only decrement unread count if it was previously unread
        if (!updatedList[index].isRead && _unreadCount > 0) {
          _unreadCount--;
        }

        updatedList[index] = updated;
        _notifications = updatedList;

        notifyListeners();
      }
    } catch (e) {
       debugPrint('Error marking as read: $e');
       _errorMessage = 'Failed to mark as read';
       notifyListeners();
    }
  }

  Future<void> markAllAsRead() async {
     try {
       await _service.markAllAsRead();
       // Reload to get fresh state
       await loadNotifications(refresh: true);
     } catch (e) {
       debugPrint('Error marking all as read: $e');
       _errorMessage = 'Failed to mark all as read';
       notifyListeners();
     }
  }

  @override
  void dispose() {
    _socketService.offNotification();
    super.dispose();
  }
}
