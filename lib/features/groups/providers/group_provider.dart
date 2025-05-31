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

  GroupProvider() {
    _loadSubscribedGroups();
  }

  Future<void> _loadSubscribedGroups() async {
    _isLoading = true;
    notifyListeners();

    try {
      final userId = AuthService.instance.userId;
      if (userId != null) {
        _subscribedGroups = await StorageService.instance.getSubscribedGroups(userId);
      }
    } catch (e) {
      debugPrint('❌ Failed to load subscribed groups: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> subscribeToGroup(String groupId, String groupName) async {
    try {
      final userId = AuthService.instance.userId;
      if (userId == null) throw Exception('User not authenticated');

      // Check if already subscribed
      if (await StorageService.instance.isSubscribedToGroup(userId, groupId)) {
        throw Exception('Already subscribed to this group');
      }

      // Subscribe to FCM topic
      await NotificationHandler.instance.subscribeToGroup(groupId);

      // Save to local storage
      final group = GroupModel(
        id: '${userId}_$groupId',
        userId: userId,
        name: groupName,
        subscribedAt: DateTime.now(),
      );

      await StorageService.instance.saveGroup(group);
      
      // Update local state
      _subscribedGroups.add(group);
      _subscribedGroups.sort((a, b) => b.subscribedAt.compareTo(a.subscribedAt));
      notifyListeners();

      debugPrint('✅ Subscribed to group: $groupId');
      return true;
    } catch (e) {
      debugPrint('❌ Failed to subscribe to group: $e');
      rethrow;
    }
  }

  Future<bool> unsubscribeFromGroup(String groupId) async {
    try {
      final userId = AuthService.instance.userId;
      if (userId == null) throw Exception('User not authenticated');

      // Unsubscribe from FCM topic
      await NotificationHandler.instance.unsubscribeFromGroup(groupId);

      // Remove from local storage
      final key = '${userId}_$groupId';
      await StorageService.instance.deleteGroup(key);

      // Update local state
      _subscribedGroups.removeWhere((group) => group.id == key);
      notifyListeners();

      debugPrint('✅ Unsubscribed from group: $groupId');
      return true;
    } catch (e) {
      debugPrint('❌ Failed to unsubscribe from group: $e');
      rethrow;
    }
  }

  Future<bool> isSubscribedToGroup(String groupId) async {
    try {
      final userId = AuthService.instance.userId;
      if (userId == null) return false;

      return await StorageService.instance.isSubscribedToGroup(userId, groupId);
    } catch (e) {
      debugPrint('❌ Failed to check group subscription: $e');
      return false;
    }
  }

  void refresh() {
    _loadSubscribedGroups();
  }
}