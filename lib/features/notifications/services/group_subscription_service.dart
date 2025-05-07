import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:push_bunnny/core/services/local_storage_service.dart';
import 'package:push_bunnny/core/utils/connectivity_helper.dart';
import 'package:push_bunnny/features/auth/services/auth_service.dart';
import 'package:push_bunnny/features/notifications/models/group_subscription_model.dart';
import 'package:push_bunnny/features/notifications/services/notification_service.dart';

class GroupSubscriptionService {
  static final GroupSubscriptionService _instance =
      GroupSubscriptionService._internal();
  factory GroupSubscriptionService() => _instance;
  GroupSubscriptionService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocalStorageService _storage = LocalStorageService();
  final ConnectivityHelper _connectivity = ConnectivityHelper();
  final AuthService _authService = AuthService();
  final NotificationService _notificationService = NotificationService();

  // Get all available groups
  Stream<List<Map<String, dynamic>>> getAllGroups() {
    return _firestore.collection('groups').orderBy('name').snapshots().map((
      snapshot,
    ) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  // Get subscribed groups for current user
  Stream<List<GroupSubscriptionModel>> getUserSubscribedGroups() async* {
    final userId = _authService.userId;
    if (userId == null) {
      yield [];
      return;
    }

    if (_connectivity.isOnline) {
      // If online, use Firestore stream
      yield* _firestore
          .collection('users')
          .doc(userId)
          .collection('subscriptions')
          .orderBy('subscribedAt', descending: true)
          .snapshots()
          .map((snapshot) {
            final subscriptions =
                snapshot.docs.map((doc) {
                  final subscription = GroupSubscriptionModel.fromFirestore(
                    doc,
                  );

                  // Save to local storage
                  _storage.saveSubscription(userId, subscription.id, {
                    'id': subscription.id,
                    'name': subscription.name,
                    'subscribedAt': subscription.subscribedAt.toIso8601String(),
                  });

                  return subscription;
                }).toList();

            return subscriptions;
          });
    } else {
      // If offline, use local storage
      final localSubscriptions =
          _storage.getSubscriptions(userId).map((data) {
            return GroupSubscriptionModel.fromMap(data);
          }).toList();

      yield localSubscriptions;
    }
  }

  // Subscribe to a group
  Future<void> subscribeToGroup(String groupId, String groupName) async {
    try {
      final userId = _authService.userId;
      if (userId == null) {
        throw Exception('User is not authenticated');
      }

      // Sanitize group ID
      final sanitizedGroupId = _sanitizeGroupId(groupId);

      // Subscribe to FCM topic
      await _notificationService.subscribeToTopic(sanitizedGroupId);

      // Save to local storage first
      await _storage.saveSubscription(userId, sanitizedGroupId, {
        'id': sanitizedGroupId,
        'name': groupName,
        'subscribedAt': DateTime.now().toIso8601String(),
      });

      if (await _connectivity.checkConnectivity()) {
        // Check if group exists
        final groupDoc =
            await _firestore.collection('groups').doc(sanitizedGroupId).get();

        if (!groupDoc.exists) {
          // Create group if it doesn't exist
          await _firestore.collection('groups').doc(sanitizedGroupId).set({
            'name': groupName,
            'createdAt': FieldValue.serverTimestamp(),
            'createdBy': userId,
            'memberCount': 1,
          });
        } else {
          // Increment member count if group exists
          await _firestore.collection('groups').doc(sanitizedGroupId).update({
            'memberCount': FieldValue.increment(1),
          });
        }

        // Add subscription to user document
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('subscriptions')
            .doc(sanitizedGroupId)
            .set({
              'groupId': sanitizedGroupId,
              'groupName': groupName,
              'subscribedAt': FieldValue.serverTimestamp(),
            });

        // Add user to group members collection
        await _firestore
            .collection('groups')
            .doc(sanitizedGroupId)
            .collection('members')
            .doc(userId)
            .set({'userId': userId, 'joinedAt': FieldValue.serverTimestamp()});

        debugPrint('Subscribed to group: $sanitizedGroupId');
      } else {
        debugPrint('Device offline, subscription saved to local storage only');
      }
    } catch (e) {
      debugPrint('Error subscribing to group: $e');
      rethrow;
    }
  }

  // Unsubscribe from a group
  Future<void> unsubscribeFromGroup(String groupId) async {
    try {
      final userId = _authService.userId;
      if (userId == null) {
        throw Exception('User is not authenticated');
      }

      // Sanitize group ID
      final sanitizedGroupId = _sanitizeGroupId(groupId);

      // Unsubscribe from FCM topic
      await _notificationService.unsubscribeFromTopic(sanitizedGroupId);

      // Remove from local storage first
      await _storage.deleteSubscription(userId, sanitizedGroupId);

      if (await _connectivity.checkConnectivity()) {
        // Remove subscription from user document
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('subscriptions')
            .doc(sanitizedGroupId)
            .delete();

        // Remove user from group members collection
        await _firestore
            .collection('groups')
            .doc(sanitizedGroupId)
            .collection('members')
            .doc(userId)
            .delete();

        // Decrement member count
        await _firestore.collection('groups').doc(sanitizedGroupId).update({
          'memberCount': FieldValue.increment(-1),
        });

        debugPrint('Unsubscribed from group: $sanitizedGroupId');
      } else {
        debugPrint(
          'Device offline, subscription removed from local storage only',
        );
      }
    } catch (e) {
      debugPrint('Error unsubscribing from group: $e');
      rethrow;
    }
  }

  // Check if user is subscribed to a group
  Future<bool> isSubscribedToGroup(String groupId) async {
    try {
      final userId = _authService.userId;
      if (userId == null) {
        return false;
      }

      // Sanitize group ID
      final sanitizedGroupId = _sanitizeGroupId(groupId);

      // Check local storage first
      if (_storage.isSubscribed(userId, sanitizedGroupId)) {
        return true;
      }

      // If online, check Firestore
      if (await _connectivity.checkConnectivity()) {
        final doc =
            await _firestore
                .collection('users')
                .doc(userId)
                .collection('subscriptions')
                .doc(sanitizedGroupId)
                .get();

        return doc.exists;
      }

      return false;
    } catch (e) {
      debugPrint('Error checking subscription status: $e');
      return false;
    }
  }

  // Helper to sanitize group ID
  String _sanitizeGroupId(String groupId) {
    // Ensure group ID only contains alphanumeric characters and underscores
    return groupId.replaceAll(RegExp(r'[^\w]'), '_');
  }
}
