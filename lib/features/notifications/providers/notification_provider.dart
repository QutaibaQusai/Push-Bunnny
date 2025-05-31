import 'dart:async';
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

  StreamSubscription<List<NotificationModel>>? _notificationsSubscription;
  String? _currentUserId;

  NotificationProvider() {
    _initializeProvider();
  }

  Future<void> _initializeProvider() async {
    final userId = AuthService.instance.userId;
    if (userId != null) {
      _currentUserId = userId;
      _setupNotificationsStream();
    }
  }

  void _setupNotificationsStream() {
    if (_currentUserId == null) return;

    _isLoading = true;
    notifyListeners();

    _notificationsSubscription?.cancel();
    
    _notificationsSubscription = StorageService.instance
        .getNotificationsStream(_currentUserId!)
        .listen(
      (notifications) {
        _notifications = _selectedGroupId == null
            ? notifications
            : notifications.where((n) => 
                n.type == 'group' && n.targetId == _selectedGroupId).toList();
        
        _isLoading = false;
        notifyListeners();
      },
      onError: (error) {
        debugPrint('❌ Error in notifications stream: $error');
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  void selectGroup(String? groupId) {
    if (_selectedGroupId == groupId) return;
    
    _selectedGroupId = groupId;
    _setupNotificationsStream(); // Refresh with filter
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      if (_currentUserId == null) return;
      
      await StorageService.instance.markNotificationAsRead(_currentUserId!, notificationId);
      // Stream will automatically update the UI
      debugPrint('✅ Notification marked as read: $notificationId');
    } catch (e) {
      debugPrint('❌ Failed to mark notification as read: $e');
      rethrow;
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      if (_currentUserId == null) return;
      
      await StorageService.instance.deleteNotification(_currentUserId!, notificationId);
      // Stream will automatically update the UI
      debugPrint('✅ Notification deleted: $notificationId');
    } catch (e) {
      debugPrint('❌ Failed to delete notification: $e');
      rethrow;
    }
  }

  Future<void> deleteAllNotifications() async {
    try {
      if (_currentUserId == null) return;
      
      await StorageService.instance.deleteAllNotifications(_currentUserId!);
      // Stream will automatically update the UI
      debugPrint('✅ All notifications deleted');
    } catch (e) {
      debugPrint('❌ Failed to delete all notifications: $e');
      rethrow;
    }
  }

  void refresh() {
    // With streams, manual refresh is not needed as data updates automatically
    // But we can reinitialize the stream if needed
    _setupNotificationsStream();
  }

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  // Update user ID if it changes (e.g., after login/logout)
  void updateUserId(String? newUserId) {
    if (_currentUserId != newUserId) {
      _currentUserId = newUserId;
      _notifications.clear();
      
      if (newUserId != null) {
        _setupNotificationsStream();
      } else {
        _notificationsSubscription?.cancel();
        _notificationsSubscription = null;
      }
      
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _notificationsSubscription?.cancel();
    super.dispose();
  }
}