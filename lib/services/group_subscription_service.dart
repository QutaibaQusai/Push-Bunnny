import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:push_bunnny/auth_service.dart';
import 'package:push_bunnny/models/group_subscription_model.dart';
import 'package:push_bunnny/services/hive_database_service.dart';

class GroupSubscriptionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final AuthService _authService = AuthService();
  final HiveDatabaseService _hiveService = HiveDatabaseService();
  final Connectivity _connectivity = Connectivity();

  // Get current user ID (now using persistent UUID)
  Future<String> get _userId async => await _authService.getUserId();

  // Check if device is online
  Future<bool> get isOnline async {
    final result = await _connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }

  // Get all groups
  Stream<QuerySnapshot> getAllGroups() {
    return _firestore.collection('groups').snapshots();
  }

  // Get groups the user is subscribed to
  Stream<List<GroupSubscriptionModel>> getUserSubscribedGroups() async* {
    final userId = await _userId;
    
    // First emit from local storage immediately
    yield _hiveService.getGroupSubscriptionsForUser(userId);
    
    // Then try to get from Firestore if online
    if (await isOnline) {
      try {
        await for (QuerySnapshot snapshot in _firestore
            .collection('users')
            .doc(userId)
            .collection('subscriptions')
            .orderBy('subscribedAt', descending: true)
            .snapshots()) {
          
          final List<GroupSubscriptionModel> subscriptions = [];
          for (var doc in snapshot.docs) {
            final subscription = GroupSubscriptionModel.fromFirestore(doc);
            subscriptions.add(subscription);
            
            // Save to local storage
            await _hiveService.saveGroupSubscription(subscription, userId);
          }
          
          yield subscriptions;
        }
      } catch (e) {
        debugPrint('Error getting subscriptions from Firestore: $e');
        yield _hiveService.getGroupSubscriptionsForUser(userId);
      }
    }
  }

  // Check if a group exists
  Future<bool> groupExists(String groupId) async {
    if (!(await isOnline)) return false;
    
    final doc = await _firestore.collection('groups').doc(groupId).get();
    return doc.exists;
  }

  // Create a new group
  Future<void> createGroup(String groupId, String groupName) async {
    if (!(await isOnline)) {
      throw Exception('Cannot create group: offline');
    }
    
    // Sanitize the groupId for FCM topics (alphanumeric and underscores only)
    String sanitizedGroupId = groupId.replaceAll(RegExp(r'[^\w]'), '_');
    final userId = await _userId;

    await _firestore.collection('groups').doc(sanitizedGroupId).set({
      'name': groupName,
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': userId,
      'memberCount': 1,
    });
  }

  // Subscribe to a group
  Future<void> subscribeToGroup(String groupId, String groupName) async {
    try {
      // Sanitize the groupId for FCM topics (alphanumeric and underscores only)
      String sanitizedGroupId = groupId.replaceAll(RegExp(r'[^\w]'), '_');
      final userId = await _userId;
      final fcmToken = await _messaging.getToken();

      // Create the subscription model
      final subscription = GroupSubscriptionModel(
        id: sanitizedGroupId,
        name: groupName,
        subscribedAt: DateTime.now(),
      );
      
      // Save to local storage first
      await _hiveService.saveGroupSubscription(subscription, userId);
      
      // If online, update Firestore
      if (await isOnline) {
        // Check if group exists, if not create it
        bool exists = await groupExists(sanitizedGroupId);
        if (!exists) {
          await createGroup(sanitizedGroupId, groupName);
        } else {
          // Increment member count if group already exists
          await _firestore.collection('groups').doc(sanitizedGroupId).update({
            'memberCount': FieldValue.increment(1),
          });
        }

        // Subscribe to Firebase topic for this group
        await _messaging.subscribeToTopic(sanitizedGroupId);
        debugPrint('Subscribed to FCM topic: $sanitizedGroupId');

        // Save subscription in user's data
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

        // Also store the user's FCM token in the group members
        if (fcmToken != null) {
          await _firestore
              .collection('groups')
              .doc(sanitizedGroupId)
              .collection('members')
              .doc(userId)
              .set({
                'userId': userId,
                'fcmToken': fcmToken,
                'joinedAt': FieldValue.serverTimestamp(),
              });
        }
      }
    } catch (e) {
      debugPrint('Error subscribing to group: $e');
      rethrow;
    }
  }

  // Unsubscribe from a group
  Future<void> unsubscribeFromGroup(String groupId) async {
    try {
      // Sanitize the groupId for FCM topics (alphanumeric and underscores only)
      String sanitizedGroupId = groupId.replaceAll(RegExp(r'[^\w]'), '_');
      final userId = await _userId;

      // Delete from local storage first
      await _hiveService.deleteGroupSubscription(sanitizedGroupId, userId);
      
      // If online, update Firestore
      if (await isOnline) {
        // Unsubscribe from Firebase topic
        await _messaging.unsubscribeFromTopic(sanitizedGroupId);
        debugPrint('Unsubscribed from FCM topic: $sanitizedGroupId');

        // Remove from user's subscriptions
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('subscriptions')
            .doc(sanitizedGroupId)
            .delete();

        // Remove user from group members and decrement count
        await _firestore
            .collection('groups')
            .doc(sanitizedGroupId)
            .collection('members')
            .doc(userId)
            .delete();

        await _firestore.collection('groups').doc(sanitizedGroupId).update({
          'memberCount': FieldValue.increment(-1),
        });
      }
    } catch (e) {
      debugPrint('Error unsubscribing from group: $e');
      rethrow;
    }
  }

  // Check if user is subscribed to a group
  Future<bool> isSubscribedToGroup(String groupId) async {
    // Sanitize the groupId for FCM topics (alphanumeric and underscores only)
    String sanitizedGroupId = groupId.replaceAll(RegExp(r'[^\w]'), '_');
    final userId = await _userId;
    
    // First check local storage
    final isSubscribedLocally = _hiveService.isSubscribedToGroup(sanitizedGroupId, userId);
    
    // If found in local storage, return true
    if (isSubscribedLocally) return true;
    
    // If online, check Firestore
    if (await isOnline) {
      try {
        final doc = await _firestore
            .collection('users')
            .doc(userId)
            .collection('subscriptions')
            .doc(sanitizedGroupId)
            .get();
            
        // If found in Firestore, save to local storage
        if (doc.exists) {
          final subscription = GroupSubscriptionModel.fromFirestore(doc);
          await _hiveService.saveGroupSubscription(subscription, userId);
          return true;
        }
      } catch (e) {
        debugPrint('Error checking subscription in Firestore: $e');
      }
    }
    
    return false;
  }
}