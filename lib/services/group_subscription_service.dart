import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

class GroupSubscriptionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // Get current user ID or use anonymous if not logged in
  String get _userId => _auth.currentUser?.uid ?? 'anonymous';

  // Get all groups
  Stream<QuerySnapshot> getAllGroups() {
    return _firestore.collection('groups').snapshots();
  }

  // Get groups the user is subscribed to
  Stream<QuerySnapshot> getUserSubscribedGroups() {
    return _firestore
        .collection('users')
        .doc(_userId)
        .collection('subscriptions')
        .orderBy('subscribedAt', descending: true)
        .snapshots();
  }

  // Check if a group exists
  Future<bool> groupExists(String groupId) async {
    final doc = await _firestore.collection('groups').doc(groupId).get();
    return doc.exists;
  }

  // Create a new group
  Future<void> createGroup(String groupId, String groupName) async {
    // Sanitize the groupId for FCM topics (alphanumeric and underscores only)
    String sanitizedGroupId = groupId.replaceAll(RegExp(r'[^\w]'), '_');
    
    await _firestore.collection('groups').doc(sanitizedGroupId).set({
      'name': groupName,
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': _userId,
      'memberCount': 1,
    });
  }

  // Subscribe to a group
  Future<void> subscribeToGroup(String groupId, String groupName) async {
    try {
      // Sanitize the groupId for FCM topics (alphanumeric and underscores only)
      String sanitizedGroupId = groupId.replaceAll(RegExp(r'[^\w]'), '_');
      
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
          .doc(_userId)
          .collection('subscriptions')
          .doc(sanitizedGroupId)
          .set({
            'groupId': sanitizedGroupId,
            'groupName': groupName,  
            'subscribedAt': FieldValue.serverTimestamp(),
          });
          
      // Also store the user's FCM token in the group members
      String? token = await _messaging.getToken();
      if (token != null) {
        await _firestore
            .collection('groups')
            .doc(sanitizedGroupId)
            .collection('members')
            .doc(_userId)
            .set({
              'userId': _userId,
              'fcmToken': token,
              'joinedAt': FieldValue.serverTimestamp(),
            });
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
      
      // Unsubscribe from Firebase topic
      await _messaging.unsubscribeFromTopic(sanitizedGroupId);
      debugPrint('Unsubscribed from FCM topic: $sanitizedGroupId');

      // Remove from user's subscriptions
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('subscriptions')
          .doc(sanitizedGroupId)
          .delete();
          
      // Remove user from group members and decrement count
      await _firestore
          .collection('groups')
          .doc(sanitizedGroupId)
          .collection('members')
          .doc(_userId)
          .delete();
          
      await _firestore
          .collection('groups')
          .doc(sanitizedGroupId)
          .update({
            'memberCount': FieldValue.increment(-1),
          });
    } catch (e) {
      debugPrint('Error unsubscribing from group: $e');
      rethrow;
    }
  }

  // Check if user is subscribed to a group
  Future<bool> isSubscribedToGroup(String groupId) async {
    // Sanitize the groupId for FCM topics (alphanumeric and underscores only)
    String sanitizedGroupId = groupId.replaceAll(RegExp(r'[^\w]'), '_');
    
    final doc =
        await _firestore
            .collection('users')
            .doc(_userId)
            .collection('subscriptions')
            .doc(sanitizedGroupId)
            .get();
    return doc.exists;
  }
}