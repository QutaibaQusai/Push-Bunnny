import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:push_bunnny/models/hive_notification_model.dart';
import 'package:push_bunnny/models/hive_group_subscription_model.dart';
import 'package:push_bunnny/models/notification_model.dart';
import 'package:push_bunnny/models/group_subscription_model.dart';

class HiveDatabaseService {
  static const String notificationsBoxName = 'notifications';
  static const String subscriptionsBoxName = 'subscriptions';
  static final HiveDatabaseService _instance = HiveDatabaseService._internal();

  factory HiveDatabaseService() {
    return _instance;
  }

  HiveDatabaseService._internal();

  /// Initialize Hive
  Future<void> initHive() async {
    try {
      final appDocumentDir = await getApplicationDocumentsDirectory();
      await Hive.initFlutter(appDocumentDir.path);
      
      // Register adapters
      Hive.registerAdapter(HiveNotificationModelAdapter());
      Hive.registerAdapter(HiveGroupSubscriptionModelAdapter());
      
      // Open boxes
      await Hive.openBox<HiveNotificationModel>(notificationsBoxName);
      await Hive.openBox<HiveGroupSubscriptionModel>(subscriptionsBoxName);
      
      debugPrint('Hive initialized successfully');
    } catch (e) {
      debugPrint('Error initializing Hive: $e');
    }
  }

  // Notifications methods
  
  /// Save a notification to local storage
  Future<void> saveNotification(NotificationModel notification) async {
    try {
      final box = Hive.box<HiveNotificationModel>(notificationsBoxName);
      final hiveNotification = HiveNotificationModel.fromNotificationModel(notification);
      
      await box.put(notification.id, hiveNotification);
      debugPrint('Notification saved to Hive: ${notification.id}');
    } catch (e) {
      debugPrint('Error saving notification to Hive: $e');
    }
  }

  /// Get all notifications for a user
  List<NotificationModel> getNotificationsForUser(String userId) {
    try {
      final box = Hive.box<HiveNotificationModel>(notificationsBoxName);
      
      final notifications = box.values
          .where((notification) => notification.userId == userId)
          .map((hiveNotification) => hiveNotification.toNotificationModel())
          .toList();
      
      // Sort by timestamp in descending order (newest first)
      notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      return notifications;
    } catch (e) {
      debugPrint('Error getting notifications from Hive: $e');
      return [];
    }
  }

  /// Get notifications for a specific group
  List<NotificationModel> getNotificationsForGroup(String userId, String groupId) {
    try {
      final box = Hive.box<HiveNotificationModel>(notificationsBoxName);
      
      final notifications = box.values
          .where((notification) => 
              notification.userId == userId && 
              (notification.groupId == groupId || notification.groupName == groupId))
          .map((hiveNotification) => hiveNotification.toNotificationModel())
          .toList();
      
      // Sort by timestamp in descending order (newest first)
      notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      return notifications;
    } catch (e) {
      debugPrint('Error getting group notifications from Hive: $e');
      return [];
    }
  }

  /// Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      final box = Hive.box<HiveNotificationModel>(notificationsBoxName);
      await box.delete(notificationId);
      debugPrint('Notification deleted from Hive: $notificationId');
    } catch (e) {
      debugPrint('Error deleting notification from Hive: $e');
    }
  }

  /// Mark a notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      final box = Hive.box<HiveNotificationModel>(notificationsBoxName);
      final notification = box.get(notificationId);
      
      if (notification != null) {
        notification.isRead = true;
        notification.readAt = DateTime.now();
        await notification.save();
        debugPrint('Notification marked as read in Hive: $notificationId');
      }
    } catch (e) {
      debugPrint('Error marking notification as read in Hive: $e');
    }
  }

  /// Delete all notifications for a user
  Future<void> deleteAllNotifications(String userId) async {
    try {
      final box = Hive.box<HiveNotificationModel>(notificationsBoxName);
      
      // Get keys of notifications to delete
      final keysToDelete = box.values
          .where((notification) => notification.userId == userId)
          .map((notification) => notification.id)
          .toList();
      
      // Delete notifications
      for (var key in keysToDelete) {
        await box.delete(key);
      }
      
      debugPrint('Deleted ${keysToDelete.length} notifications for user: $userId');
    } catch (e) {
      debugPrint('Error deleting all notifications: $e');
    }
  }

  // Group subscription methods
  
  /// Save a group subscription to local storage
  Future<void> saveGroupSubscription(GroupSubscriptionModel subscription, String userId) async {
    try {
      final box = Hive.box<HiveGroupSubscriptionModel>(subscriptionsBoxName);
      final hiveSubscription = HiveGroupSubscriptionModel.fromGroupSubscriptionModel(subscription);
      
      // We'll use userId-groupId as the key to ensure uniqueness
      final key = '${userId}-${subscription.id}';
      await box.put(key, hiveSubscription);
      
      debugPrint('Group subscription saved to Hive: ${subscription.id}');
    } catch (e) {
      debugPrint('Error saving group subscription to Hive: $e');
    }
  }

  /// Get all group subscriptions for a user
  List<GroupSubscriptionModel> getGroupSubscriptionsForUser(String userId) {
    try {
      final box = Hive.box<HiveGroupSubscriptionModel>(subscriptionsBoxName);
      
      final subscriptions = box.values
          .where((subscription) => subscription.key.toString().startsWith('$userId-'))
          .map((hiveSubscription) => hiveSubscription.toGroupSubscriptionModel())
          .toList();
      
      // Sort by subscribedAt in descending order (newest first)
      subscriptions.sort((a, b) => b.subscribedAt.compareTo(a.subscribedAt));
      
      return subscriptions;
    } catch (e) {
      debugPrint('Error getting group subscriptions from Hive: $e');
      return [];
    }
  }

  /// Delete a group subscription
  Future<void> deleteGroupSubscription(String groupId, String userId) async {
    try {
      final box = Hive.box<HiveGroupSubscriptionModel>(subscriptionsBoxName);
      final key = '$userId-$groupId';
      
      await box.delete(key);
      debugPrint('Group subscription deleted from Hive: $groupId');
    } catch (e) {
      debugPrint('Error deleting group subscription from Hive: $e');
    }
  }

  /// Check if a user is subscribed to a group
  bool isSubscribedToGroup(String groupId, String userId) {
    try {
      final box = Hive.box<HiveGroupSubscriptionModel>(subscriptionsBoxName);
      final key = '$userId-$groupId';
      
      return box.containsKey(key);
    } catch (e) {
      debugPrint('Error checking subscription in Hive: $e');
      return false;
    }
  }
}