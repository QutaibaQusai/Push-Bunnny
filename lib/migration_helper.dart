import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:push_bunnny/services/device_info_service.dart';

/// Helper class to migrate data from the old FCM token-based ID to the new UUID-based ID
class MigrationHelper {
  static const String _oldUserIdKey = 'user_id';
  static const String _migrationCompletedKey = 'migration_completed';

  static Future<void> migrateUserData(String newUserId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bool migrationCompleted =
          prefs.getBool(_migrationCompletedKey) ?? false;

      if (migrationCompleted) {
        debugPrint('Migration already completed');
        return;
      }

      // Get the old FCM token-based user ID
      final String? oldUserId = prefs.getString(_oldUserIdKey);
      if (oldUserId == null || oldUserId.isEmpty || oldUserId == newUserId) {
        // No old ID or same as new ID, just mark migration as completed
        await prefs.setBool(_migrationCompletedKey, true);
        return;
      }

      debugPrint(
        'Migrating data from old ID: $oldUserId to new ID: $newUserId',
      );

      // Migrate notifications
      await _migrateNotifications(oldUserId, newUserId);

      // Migrate subscriptions
      await _migrateSubscriptions(oldUserId, newUserId);

      // Migrate device token and info
      await _migrateDeviceInfo(oldUserId, newUserId);

      // Mark migration as completed
      await prefs.setBool(_migrationCompletedKey, true);
      debugPrint('Migration completed successfully');
    } catch (e) {
      debugPrint('Error during migration: $e');
    }
  }

  static Future<void> _migrateNotifications(
    String oldUserId,
    String newUserId,
  ) async {
    try {
      final notifications =
          await FirebaseFirestore.instance
              .collection('notifications')
              .where('userId', isEqualTo: oldUserId)
              .get();

      if (notifications.docs.isEmpty) {
        debugPrint('No notifications to migrate');
        return;
      }

      final batch = FirebaseFirestore.instance.batch();
      for (var doc in notifications.docs) {
        batch.update(doc.reference, {'userId': newUserId});
      }

      await batch.commit();
      debugPrint('Migrated ${notifications.docs.length} notifications');
    } catch (e) {
      debugPrint('Error migrating notifications: $e');
    }
  }

  static Future<void> _migrateSubscriptions(
    String oldUserId,
    String newUserId,
  ) async {
    try {
      // Get all subscriptions for the old user ID
      final subscriptions =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(oldUserId)
              .collection('subscriptions')
              .get();

      if (subscriptions.docs.isEmpty) {
        debugPrint('No subscriptions to migrate');
        return;
      }

      // Create batch operation
      final batch = FirebaseFirestore.instance.batch();

      // Copy each subscription to the new user ID
      for (var doc in subscriptions.docs) {
        final data = doc.data();
        final newDocRef = FirebaseFirestore.instance
            .collection('users')
            .doc(newUserId)
            .collection('subscriptions')
            .doc(doc.id);

        batch.set(newDocRef, data);
      }

      // Also update any group memberships
      for (var doc in subscriptions.docs) {
        final groupId = doc.id;
        final groupMemberRef = FirebaseFirestore.instance
            .collection('groups')
            .doc(groupId)
            .collection('members')
            .doc(oldUserId);

        final memberDoc = await groupMemberRef.get();
        if (memberDoc.exists) {
          final memberData = memberDoc.data() as Map<String, dynamic>;
          memberData['userId'] = newUserId;

          final newMemberRef = FirebaseFirestore.instance
              .collection('groups')
              .doc(groupId)
              .collection('members')
              .doc(newUserId);

          batch.set(newMemberRef, memberData);
          batch.delete(groupMemberRef);
        }
      }

      await batch.commit();
      debugPrint('Migrated ${subscriptions.docs.length} subscriptions');
    } catch (e) {
      debugPrint('Error migrating subscriptions: $e');
    }
  }

  static Future<void> _migrateDeviceInfo(
    String oldUserId,
    String newUserId,
  ) async {
    try {
      // Get current FCM token
      final fcmToken = await FirebaseMessaging.instance.getToken();

      // Get device info
      final deviceInfoService = DeviceInfoService();
      final deviceInfo = await deviceInfoService.getDeviceInfo();

      // Create user data map with device info
      final userData = {
        'userId': newUserId,
        'deviceToken': fcmToken,
        ...deviceInfo,
      };

      // Create or update the new user document with device info
      await FirebaseFirestore.instance
          .collection('users')
          .doc(newUserId)
          .set(userData, SetOptions(merge: true));

      debugPrint('Migrated device token and info');
    } catch (e) {
      debugPrint('Error migrating device info: $e');
    }
  }
}
