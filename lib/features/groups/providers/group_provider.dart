import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:push_bunnny/core/services/auth_service.dart';
import 'package:push_bunnny/core/services/notification_handler.dart';
import 'package:push_bunnny/core/services/storage_service.dart';
import 'package:push_bunnny/features/groups/models/group_model.dart';

class GroupProvider extends ChangeNotifier {
  List<GroupModel> _subscribedGroups = [];
  List<GroupModel> get subscribedGroups => _subscribedGroups;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  StreamSubscription<List<GroupModel>>? _groupsSubscription;
  String? _currentUserId;

  GroupProvider() {
    _initializeProvider();
  }

  Future<void> _initializeProvider() async {
    final userId = AuthService.instance.userId;
    if (userId != null) {
      _currentUserId = userId;
      _setupGroupsStream();
    }
  }

  void _setupGroupsStream() {
    if (_currentUserId == null) return;

    _isLoading = true;
    notifyListeners();

    _groupsSubscription?.cancel();
    
    _groupsSubscription = StorageService.instance
        .getSubscribedGroupsStream(_currentUserId!)
        .listen(
      (groups) {
        _subscribedGroups = groups;
        _isLoading = false;
        notifyListeners();
      },
      onError: (error) {
        debugPrint('❌ Error in groups stream: $error');
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<bool> subscribeToGroup(String groupId, String groupName) async {
    try {
      if (_currentUserId == null) throw Exception('User not authenticated');

      // Check if already subscribed
      if (await StorageService.instance.isSubscribedToGroup(_currentUserId!, groupId)) {
        throw Exception('Already subscribed to this group');
      }

      // Subscribe to FCM topic
      await NotificationHandler.instance.subscribeToGroup(groupId);

      // Save to Firestore
      final group = GroupModel(
        id: '${_currentUserId}_$groupId',
        userId: _currentUserId!,
        name: groupName,
        subscribedAt: DateTime.now(),
      );

      await StorageService.instance.saveGroup(group);
      
      // Stream will automatically update the UI
      debugPrint('✅ Subscribed to group: $groupId');
      return true;
    } catch (e) {
      debugPrint('❌ Failed to subscribe to group: $e');
      rethrow;
    }
  }

  Future<bool> unsubscribeFromGroup(String groupId) async {
    try {
      if (_currentUserId == null) throw Exception('User not authenticated');

      // Unsubscribe from FCM topic
      await NotificationHandler.instance.unsubscribeFromGroup(groupId);

      // Remove from Firestore
      final key = '${_currentUserId}_$groupId';
      await StorageService.instance.deleteGroup(_currentUserId!, key);

      // Stream will automatically update the UI
      debugPrint('✅ Unsubscribed from group: $groupId');
      return true;
    } catch (e) {
      debugPrint('❌ Failed to unsubscribe from group: $e');
      rethrow;
    }
  }

  Future<bool> isSubscribedToGroup(String groupId) async {
    try {
      if (_currentUserId == null) return false;

      return await StorageService.instance.isSubscribedToGroup(_currentUserId!, groupId);
    } catch (e) {
      debugPrint('❌ Failed to check group subscription: $e');
      return false;
    }
  }

  void refresh() {
    // With streams, manual refresh is not needed as data updates automatically
    // But we can reinitialize the stream if needed
    _setupGroupsStream();
  }

  // Update user ID if it changes (e.g., after login/logout)
  void updateUserId(String? newUserId) {
    if (_currentUserId != newUserId) {
      _currentUserId = newUserId;
      _subscribedGroups.clear();
      
      if (newUserId != null) {
        _setupGroupsStream();
      } else {
        _groupsSubscription?.cancel();
        _groupsSubscription = null;
      }
      
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _groupsSubscription?.cancel();
    super.dispose();
  }
}