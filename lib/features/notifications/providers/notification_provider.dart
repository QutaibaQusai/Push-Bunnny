import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:push_bunnny/core/utils/connectivity_helper.dart';
import 'package:push_bunnny/features/auth/services/auth_service.dart';
import 'package:push_bunnny/features/notifications/models/notification_model.dart';
import 'package:push_bunnny/features/notifications/repositories/notification_repository.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationRepository _repository = NotificationRepository();
  final AuthService _authService = AuthService();
  final ConnectivityHelper _connectivity = ConnectivityHelper();

  List<NotificationModel> _notifications = [];
  List<NotificationModel> get notifications => _notifications;

  String? _selectedGroupId;
  String? get selectedGroupId => _selectedGroupId;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  StreamSubscription? _notificationSubscription;
  StreamSubscription? _connectivitySubscription;

  NotificationProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    _isLoading = true;
    notifyListeners();

    final userId = _authService.userId;
    if (userId != null) {
      // Listen for connectivity changes
      _connectivitySubscription = _connectivity.connectivityStream.listen(
        _onConnectivityChanged,
      );

      // Load notifications - add a forced refresh
      await _loadNotifications(userId, forceRefresh: true);
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadNotifications(
    String userId, {
    bool forceRefresh = false,
  }) async {
    _cancelNotificationSubscription();

    if (_connectivity.isOnline) {
      // If online, use Firestore stream
      if (_selectedGroupId != null) {
        _notificationSubscription = _repository
            .getGroupNotifications(userId, _selectedGroupId!)
            .listen(_updateNotifications);
      } else {
        _notificationSubscription = _repository
            .getUserNotifications(userId)
            .listen(_updateNotifications);
      }

      if (forceRefresh) {
        // Force an immediate update from local storage while waiting for Firestore
        if (_selectedGroupId != null) {
          _notifications = _repository.getLocalGroupNotifications(
            userId,
            _selectedGroupId!,
          );
        } else {
          _notifications = _repository.getLocalNotifications(userId);
        }
        notifyListeners();
      }
    } else {
      // If offline, use local storage
      if (_selectedGroupId != null) {
        _notifications = _repository.getLocalGroupNotifications(
          userId,
          _selectedGroupId!,
        );
      } else {
        _notifications = _repository.getLocalNotifications(userId);
      }
      notifyListeners();
    }
  }

  void _onConnectivityChanged(bool isOnline) {
    final userId = _authService.userId;
    if (userId != null) {
      _loadNotifications(userId);
    }
  }

  void _updateNotifications(List<NotificationModel> notifications) {
    _notifications = notifications;
    notifyListeners();
  }

  void setSelectedGroup(String? groupId) {
    if (_selectedGroupId == groupId) return;

    _selectedGroupId = groupId;

    final userId = _authService.userId;
    if (userId != null) {
      _loadNotifications(userId);
    }

    notifyListeners();
  }

  Future<void> markAsRead(String notificationId) async {
    await _repository.markAsRead(notificationId);

    // Update the local state
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(
        isRead: true,
        readAt: DateTime.now(),
      );
      notifyListeners();
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    await _repository.deleteNotification(notificationId);

    // Update the local state
    _notifications.removeWhere((n) => n.id == notificationId);
    notifyListeners();
  }

  Future<void> deleteAllNotifications() async {
    final userId = _authService.userId;
    if (userId != null) {
      await _repository.deleteAllNotifications(userId);

      // Update the local state
      _notifications = [];
      notifyListeners();
    }
  }

  void refreshNotifications() {
    final userId = _authService.userId;
    if (userId != null) {
      _loadNotifications(userId);
    }
  }

  void _cancelNotificationSubscription() {
    _notificationSubscription?.cancel();
    _notificationSubscription = null;
  }

  @override
  void dispose() {
    _cancelNotificationSubscription();
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}
