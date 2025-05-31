import 'package:flutter/foundation.dart';
import 'package:push_bunnny/core/services/auth_service.dart';
import 'package:push_bunnny/core/services/storage_service.dart';
import 'package:push_bunnny/features/notifications/models/notification_model.dart';


class NotificationProvider extends ChangeNotifier {
  List<NotificationModel> _notifications = [];
  List<NotificationModel> get notifications => _notifications;

  String? _selectedGroupId;
  String? get selectedGroupId => _selectedGroupId;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  NotificationProvider() {
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    _isLoading = true;
    notifyListeners();

    try {
      final userId = AuthService.instance.userId;
      if (userId != null) {
        if (_selectedGroupId != null) {
          _notifications = await StorageService.instance.getGroupNotifications(userId, _selectedGroupId!);
        } else {
          _notifications = await StorageService.instance.getNotifications(userId);
        }
      }
    } catch (e) {
      debugPrint('❌ Failed to load notifications: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  void selectGroup(String? groupId) {
    if (_selectedGroupId == groupId) return;
    
    _selectedGroupId = groupId;
    _loadNotifications();
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await StorageService.instance.markNotificationAsRead(notificationId);
      
      // Update local state
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(
          isRead: true,
          readAt: DateTime.now(),
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ Failed to mark notification as read: $e');
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      await StorageService.instance.deleteNotification(notificationId);
      _notifications.removeWhere((n) => n.id == notificationId);
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Failed to delete notification: $e');
    }
  }

  Future<void> deleteAllNotifications() async {
    try {
      final userId = AuthService.instance.userId;
      if (userId != null) {
        await StorageService.instance.deleteAllNotifications(userId);
        _notifications.clear();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ Failed to delete all notifications: $e');
    }
  }

  void refresh() {
    _loadNotifications();
  }

  int get unreadCount => _notifications.where((n) => !n.isRead).length;
}