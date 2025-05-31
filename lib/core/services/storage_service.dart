import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:push_bunnny/features/groups/models/group_model.dart';
import 'package:push_bunnny/features/notifications/models/notification_model.dart';


class StorageService {
  static final StorageService instance = StorageService._();
  StorageService._();

  static const String _userBox = 'user_data';
  static const String _notificationsBox = 'notifications';
  static const String _groupsBox = 'groups';

  Future<void> initialize() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    await Hive.initFlutter(appDocDir.path);
    
    // Open boxes
    await Hive.openBox(_userBox);
    await Hive.openBox<Map>(_notificationsBox);
    await Hive.openBox<Map>(_groupsBox);
    
    debugPrint('📦 Storage initialized');
  }

  // User methods
  Future<void> saveUserId(String userId) async {
    final box = Hive.box(_userBox);
    await box.put('userId', userId);
  }

  Future<String?> getUserId() async {
    final box = Hive.box(_userBox);
    return box.get('userId');
  }

  // Notification methods
  Future<void> saveNotification(NotificationModel notification) async {
    try {
      final box = Hive.box<Map>(_notificationsBox);
      await box.put(notification.id, notification.toMap());
      debugPrint('💾 Notification saved: ${notification.id}');
    } catch (e) {
      debugPrint('❌ Failed to save notification: $e');
    }
  }

  Future<List<NotificationModel>> getNotifications(String userId) async {
    try {
      final box = Hive.box<Map>(_notificationsBox);
      final notifications = <NotificationModel>[];
      
      for (final entry in box.values) {
        if (entry != null && entry['userId'] == userId) {
          notifications.add(NotificationModel.fromMap(Map<String, dynamic>.from(entry)));
        }
      }
      
      // Sort by timestamp (newest first)
      notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return notifications;
    } catch (e) {
      debugPrint('❌ Failed to get notifications: $e');
      return [];
    }
  }

  Future<List<NotificationModel>> getGroupNotifications(String userId, String groupId) async {
    try {
      final box = Hive.box<Map>(_notificationsBox);
      final notifications = <NotificationModel>[];
      
      for (final entry in box.values) {
        if (entry != null && 
            entry['userId'] == userId && 
            entry['data']?['type'] == 'group' &&
            entry['data']?['id'] == groupId) {
          notifications.add(NotificationModel.fromMap(Map<String, dynamic>.from(entry)));
        }
      }
      
      notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return notifications;
    } catch (e) {
      debugPrint('❌ Failed to get group notifications: $e');
      return [];
    }
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      final box = Hive.box<Map>(_notificationsBox);
      final notification = box.get(notificationId);
      
      if (notification != null) {
        notification['isRead'] = true;
        notification['readAt'] = DateTime.now().toIso8601String();
        await box.put(notificationId, notification);
        debugPrint('✅ Notification marked as read: $notificationId');
      }
    } catch (e) {
      debugPrint('❌ Failed to mark notification as read: $e');
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      final box = Hive.box<Map>(_notificationsBox);
      await box.delete(notificationId);
      debugPrint('🗑️ Notification deleted: $notificationId');
    } catch (e) {
      debugPrint('❌ Failed to delete notification: $e');
    }
  }

  Future<void> deleteAllNotifications(String userId) async {
    try {
      final box = Hive.box<Map>(_notificationsBox);
      final keysToDelete = <dynamic>[];
      
      for (final key in box.keys) {
        final notification = box.get(key);
        if (notification != null && notification['userId'] == userId) {
          keysToDelete.add(key);
        }
      }
      
      await box.deleteAll(keysToDelete);
      debugPrint('🗑️ All notifications deleted for user: $userId');
    } catch (e) {
      debugPrint('❌ Failed to delete all notifications: $e');
    }
  }

  Future<bool> notificationExists(String messageId) async {
    try {
      final box = Hive.box<Map>(_notificationsBox);
      
      for (final entry in box.values) {
        if (entry != null && entry['messageId'] == messageId) {
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('❌ Failed to check notification existence: $e');
      return false;
    }
  }

  // Group methods
  Future<void> saveGroup(GroupModel group) async {
    try {
      final box = Hive.box<Map>(_groupsBox);
      await box.put(group.id, group.toMap());
      debugPrint('💾 Group saved: ${group.id}');
    } catch (e) {
      debugPrint('❌ Failed to save group: $e');
    }
  }

  Future<List<GroupModel>> getSubscribedGroups(String userId) async {
    try {
      final box = Hive.box<Map>(_groupsBox);
      final groups = <GroupModel>[];
      
      for (final entry in box.values) {
        if (entry != null && entry['userId'] == userId) {
          groups.add(GroupModel.fromMap(Map<String, dynamic>.from(entry)));
        }
      }
      
      groups.sort((a, b) => b.subscribedAt.compareTo(a.subscribedAt));
      return groups;
    } catch (e) {
      debugPrint('❌ Failed to get subscribed groups: $e');
      return [];
    }
  }

  Future<void> deleteGroup(String groupId) async {
    try {
      final box = Hive.box<Map>(_groupsBox);
      await box.delete(groupId);
      debugPrint('🗑️ Group deleted: $groupId');
    } catch (e) {
      debugPrint('❌ Failed to delete group: $e');
    }
  }

  Future<bool> isSubscribedToGroup(String userId, String groupId) async {
    try {
      final box = Hive.box<Map>(_groupsBox);
      final key = '${userId}_$groupId';
      return box.containsKey(key);
    } catch (e) {
      debugPrint('❌ Failed to check group subscription: $e');
      return false;
    }
  }
}