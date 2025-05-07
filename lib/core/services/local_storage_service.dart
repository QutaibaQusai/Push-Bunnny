import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:push_bunnny/features/notifications/models/notification_model.dart';

/// Custom Hive adapter for Firestore Timestamp
class TimestampAdapter extends TypeAdapter<Timestamp> {
  @override
  final int typeId = 1;

  @override
  Timestamp read(BinaryReader reader) {
    final seconds = reader.readInt();
    final nanoseconds = reader.readInt();
    return Timestamp(seconds, nanoseconds);
  }

  @override
  void write(BinaryWriter writer, Timestamp obj) {
    writer.writeInt(obj.seconds);
    writer.writeInt(obj.nanoseconds);
  }
}

class LocalStorageService {
  static final LocalStorageService _instance = LocalStorageService._internal();
  factory LocalStorageService() => _instance;
  LocalStorageService._internal();

  static const String notificationsBoxName = 'notifications';
  static const String userPrefsBoxName = 'user_prefs';
  static const String subscriptionsBoxName = 'subscriptions';

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      await Hive.initFlutter(appDocDir.path);

      // Register adapters if using custom Hive objects
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(TimestampAdapter());
      }

      // Open boxes
      await Hive.openBox<Map<dynamic, dynamic>>(notificationsBoxName);
      await Hive.openBox<Map<dynamic, dynamic>>(subscriptionsBoxName);
      await Hive.openBox<Map<dynamic, dynamic>>(userPrefsBoxName);

      _isInitialized = true;
      debugPrint('LocalStorageService initialized successfully');
    } catch (e) {
      debugPrint('Error initializing LocalStorageService: $e');
      rethrow;
    }
  }

  // Notifications methods
  Future<void> saveNotification(NotificationModel notification) async {
    try {
      final box = Hive.box<Map<dynamic, dynamic>>(notificationsBoxName);
      
      // Ensure timestamp is always saved as ISO8601 string for consistency
      final notificationMap = notification.toMap();
      
      await box.put(notification.id, notificationMap);
      debugPrint('Notification saved to local storage: ${notification.id}');
    } catch (e) {
      debugPrint('Error saving notification to local storage: $e');
    }
  }

  Future<void> updateNotification(
    String id,
    Map<String, dynamic> updates,
  ) async {
    try {
      final box = Hive.box<Map<dynamic, dynamic>>(notificationsBoxName);
      final notification = box.get(id);

      if (notification != null) {
        // Handle timestamp conversions for updates
        if (updates.containsKey('readAt') && updates['readAt'] is Timestamp) {
          updates['readAt'] = (updates['readAt'] as Timestamp).toDate().toIso8601String();
        }
        
        notification.addAll(updates);
        await box.put(id, notification);
        debugPrint('Notification updated: $id');
      }
    } catch (e) {
      debugPrint('Error updating notification in local storage: $e');
    }
  }

  Future<void> deleteNotification(String id) async {
    try {
      final box = Hive.box<Map<dynamic, dynamic>>(notificationsBoxName);
      await box.delete(id);
      debugPrint('Notification deleted: $id');
    } catch (e) {
      debugPrint('Error deleting notification from local storage: $e');
    }
  }

  List<NotificationModel> getNotificationsForUser(String userId) {
    try {
      final box = Hive.box<Map<dynamic, dynamic>>(notificationsBoxName);
      final notifications =
          box.values
              .where((notification) => notification['userId'] == userId)
              .map(
                (data) =>
                    NotificationModel.fromMap(Map<String, dynamic>.from(data)),
              )
              .toList();

      // Sort by timestamp (newest first)
      notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      return notifications;
    } catch (e) {
      debugPrint('Error getting notifications from local storage: $e');
      return [];
    }
  }

  List<NotificationModel> getNotificationsForGroup(
    String userId,
    String groupId,
  ) {
    try {
      final box = Hive.box<Map<dynamic, dynamic>>(notificationsBoxName);
      final notifications =
          box.values
              .where(
                (notification) =>
                    notification['userId'] == userId &&
                    notification['groupId'] == groupId,
              )
              .map(
                (data) =>
                    NotificationModel.fromMap(Map<String, dynamic>.from(data)),
              )
              .toList();

      // Sort by timestamp (newest first)
      notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      return notifications;
    } catch (e) {
      debugPrint('Error getting group notifications from local storage: $e');
      return [];
    }
  }

  Future<void> deleteAllNotifications(String userId) async {
    try {
      final box = Hive.box<Map<dynamic, dynamic>>(notificationsBoxName);
      final keysToDelete =
          box.keys.where((key) {
            final notification = box.get(key);
            return notification != null && notification['userId'] == userId;
          }).toList();

      for (var key in keysToDelete) {
        await box.delete(key);
      }
      debugPrint('All notifications deleted for user: $userId');
    } catch (e) {
      debugPrint('Error deleting all notifications from local storage: $e');
    }
  }

 
bool hasNotificationWithMessageId(String messageId) {
  try {
    final box = Hive.box<Map<dynamic, dynamic>>(notificationsBoxName);
    
    // Use a more thorough approach to check all notifications
    for (var notification in box.values) {
      if (notification != null) {
        final msgId = notification['messageId'];
        if (msgId != null && msgId == messageId) {
          return true;
        }
      }
    }
    
    return false;
  } catch (e) {
    debugPrint('Error checking notification by messageId: $e');
    // If there's an error, return false to be safe (may cause duplicate, but better than missing)
    return false;
  }
}


  // User preferences methods
  Future<void> saveUserId(String userId) async {
    try {
      final box = Hive.box<Map<dynamic, dynamic>>(userPrefsBoxName);
      final userPrefs = box.get('userPrefs') ?? {};
      userPrefs['userId'] = userId;
      await box.put('userPrefs', userPrefs);
    } catch (e) {
      debugPrint('Error saving userId to local storage: $e');
    }
  }

  String? getUserId() {
    try {
      final box = Hive.box<Map<dynamic, dynamic>>(userPrefsBoxName);
      final userPrefs = box.get('userPrefs');
      return userPrefs?['userId'] as String?;
    } catch (e) {
      debugPrint('Error getting userId from local storage: $e');
      return null;
    }
  }

  // Group subscription methods
  Future<void> saveSubscription(
    String userId,
    String groupId,
    Map<String, dynamic> data,
  ) async {
    try {
      final box = Hive.box<Map<dynamic, dynamic>>(subscriptionsBoxName);
      final key = '${userId}_$groupId';
      await box.put(key, data);
    } catch (e) {
      debugPrint('Error saving subscription to local storage: $e');
    }
  }

  Future<void> deleteSubscription(String userId, String groupId) async {
    try {
      final box = Hive.box<Map<dynamic, dynamic>>(subscriptionsBoxName);
      final key = '${userId}_$groupId';
      await box.delete(key);
    } catch (e) {
      debugPrint('Error deleting subscription from local storage: $e');
    }
  }

  List<Map<String, dynamic>> getSubscriptions(String userId) {
    try {
      final box = Hive.box<Map<dynamic, dynamic>>(subscriptionsBoxName);
      final subscriptions =
          box.keys
              .where((key) => key.toString().startsWith('${userId}_'))
              .map((key) {
                final data = box.get(key);
                if (data != null) {
                  return Map<String, dynamic>.from(data);
                }
                return null;
              })
              .where((data) => data != null)
              .cast<Map<String, dynamic>>()
              .toList();

      return subscriptions;
    } catch (e) {
      debugPrint('Error getting subscriptions from local storage: $e');
      return [];
    }
  }

  bool isSubscribed(String userId, String groupId) {
    try {
      final box = Hive.box<Map<dynamic, dynamic>>(subscriptionsBoxName);
      final key = '${userId}_$groupId';
      return box.containsKey(key);
    } catch (e) {
      debugPrint('Error checking subscription in local storage: $e');
      return false;
    }
  }

  // Get notification by messageId
  NotificationModel? getNotificationByMessageId(String messageId) {
    try {
      final box = Hive.box<Map<dynamic, dynamic>>(notificationsBoxName);

      // Find the notification that matches the messageId
      for (var notification in box.values) {
        if (notification['messageId'] == messageId) {
          return NotificationModel.fromMap(
            Map<String, dynamic>.from(notification),
          );
        }
      }

      // If no matching notification is found, return null
      return null;
    } catch (e) {
      debugPrint('Error getting notification by messageId: $e');
      return null;
    }
  }
}