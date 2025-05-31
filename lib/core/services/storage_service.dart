import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:push_bunnny/features/groups/models/group_model.dart';
import 'package:push_bunnny/features/notifications/models/notification_model.dart';

class StorageService {
  static final StorageService instance = StorageService._();
  StorageService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collections
  static const String _usersCollection = 'users';
  static const String _notificationsCollection = 'notifications';
  static const String _groupsCollection = 'groups';

  Future<void> initialize() async {
    // No initialization needed for Firestore
    debugPrint('📦 Firestore storage initialized');
  }

  // User methods
  Future<void> saveUserId(String userId) async {
    try {
      await _firestore.collection(_usersCollection).doc(userId).set({
        'createdAt': FieldValue.serverTimestamp(),
        'lastActive': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint('💾 User ID saved: $userId');
    } catch (e) {
      debugPrint('❌ Failed to save user ID: $e');
      rethrow;
    }
  }

  Future<String?> getUserId() async {
    // This will be handled by AuthService now
    return null;
  }

  // Notification methods
  Future<void> saveNotification(NotificationModel notification) async {
    try {
      await _firestore
          .collection(_usersCollection)
          .doc(notification.userId)
          .collection(_notificationsCollection)
          .doc(notification.id)
          .set(notification.toMap());
      debugPrint('💾 Notification saved: ${notification.id}');
    } catch (e) {
      debugPrint('❌ Failed to save notification: $e');
      rethrow;
    }
  }

  Future<List<NotificationModel>> getNotifications(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_notificationsCollection)
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => NotificationModel.fromMap({
                ...doc.data(),
                'id': doc.id,
              }))
          .toList();
    } catch (e) {
      debugPrint('❌ Failed to get notifications: $e');
      return [];
    }
  }

  Future<List<NotificationModel>> getGroupNotifications(String userId, String groupId) async {
    try {
      final snapshot = await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_notificationsCollection)
          .where('data.type', isEqualTo: 'group')
          .where('data.id', isEqualTo: groupId)
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => NotificationModel.fromMap({
                ...doc.data(),
                'id': doc.id,
              }))
          .toList();
    } catch (e) {
      debugPrint('❌ Failed to get group notifications: $e');
      return [];
    }
  }

  Future<void> markNotificationAsRead(String userId, String notificationId) async {
    try {
      await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_notificationsCollection)
          .doc(notificationId)
          .update({
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });
      debugPrint('✅ Notification marked as read: $notificationId');
    } catch (e) {
      debugPrint('❌ Failed to mark notification as read: $e');
      rethrow;
    }
  }

  Future<void> deleteNotification(String userId, String notificationId) async {
    try {
      await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_notificationsCollection)
          .doc(notificationId)
          .delete();
      debugPrint('🗑️ Notification deleted: $notificationId');
    } catch (e) {
      debugPrint('❌ Failed to delete notification: $e');
      rethrow;
    }
  }

  Future<void> deleteAllNotifications(String userId) async {
    try {
      final batch = _firestore.batch();
      final snapshot = await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_notificationsCollection)
          .get();

      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      debugPrint('🗑️ All notifications deleted for user: $userId');
    } catch (e) {
      debugPrint('❌ Failed to delete all notifications: $e');
      rethrow;
    }
  }

  Future<bool> notificationExists(String userId, String messageId) async {
    try {
      final snapshot = await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_notificationsCollection)
          .where('messageId', isEqualTo: messageId)
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      debugPrint('❌ Failed to check notification existence: $e');
      return false;
    }
  }

  // Group methods
  Future<void> saveGroup(GroupModel group) async {
    try {
      await _firestore
          .collection(_usersCollection)
          .doc(group.userId)
          .collection(_groupsCollection)
          .doc(group.id)
          .set(group.toMap());
      debugPrint('💾 Group saved: ${group.id}');
    } catch (e) {
      debugPrint('❌ Failed to save group: $e');
      rethrow;
    }
  }

  Future<List<GroupModel>> getSubscribedGroups(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_groupsCollection)
          .orderBy('subscribedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => GroupModel.fromMap({
                ...doc.data(),
                'id': doc.id,
              }))
          .toList();
    } catch (e) {
      debugPrint('❌ Failed to get subscribed groups: $e');
      return [];
    }
  }

  Future<void> deleteGroup(String userId, String groupId) async {
    try {
      await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_groupsCollection)
          .doc(groupId)
          .delete();
      debugPrint('🗑️ Group deleted: $groupId');
    } catch (e) {
      debugPrint('❌ Failed to delete group: $e');
      rethrow;
    }
  }

  Future<bool> isSubscribedToGroup(String userId, String groupId) async {
    try {
      final doc = await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_groupsCollection)
          .doc('${userId}_$groupId')
          .get();

      return doc.exists;
    } catch (e) {
      debugPrint('❌ Failed to check group subscription: $e');
      return false;
    }
  }

  // Real-time listeners
  Stream<List<NotificationModel>> getNotificationsStream(String userId) {
    return _firestore
        .collection(_usersCollection)
        .doc(userId)
        .collection(_notificationsCollection)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationModel.fromMap({
                  ...doc.data(),
                  'id': doc.id,
                }))
            .toList());
  }

  Stream<List<GroupModel>> getSubscribedGroupsStream(String userId) {
    return _firestore
        .collection(_usersCollection)
        .doc(userId)
        .collection(_groupsCollection)
        .orderBy('subscribedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => GroupModel.fromMap({
                  ...doc.data(),
                  'id': doc.id,
                }))
            .toList());
  }
}