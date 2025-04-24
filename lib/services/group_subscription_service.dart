import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

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
        .snapshots();
  }

  // Check if a group exists
  Future<bool> groupExists(String groupId) async {
    final doc = await _firestore.collection('groups').doc(groupId).get();
    return doc.exists;
  }

  // Create a new group
  Future<void> createGroup(String groupId, String groupName) async {
    await _firestore.collection('groups').doc(groupId).set({
      'name': groupName,
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': _userId,
    });
  }

  // Subscribe to a group
 Future<void> subscribeToGroup(String groupId, String groupName) async {
    // Check if group exists, if not create it
    bool exists = await groupExists(groupId);
    if (!exists) {
      await createGroup(groupId, groupName);
    }

    // Subscribe to Firebase topic for this group
    await _messaging.subscribeToTopic(groupId);

    // Save subscription in user's data
    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('subscriptions')
        .doc(groupId)
        .set({
          'groupId': groupId,
          'groupName': groupName,  
          'subscribedAt': FieldValue.serverTimestamp(),
        });
  }
  // Unsubscribe from a group
  Future<void> unsubscribeFromGroup(String groupId) async {
    // Unsubscribe from Firebase topic
    await _messaging.unsubscribeFromTopic(groupId);

    // Remove from user's subscriptions
    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('subscriptions')
        .doc(groupId)
        .delete();
  }

  // Check if user is subscribed to a group
  Future<bool> isSubscribedToGroup(String groupId) async {
    final doc =
        await _firestore
            .collection('users')
            .doc(_userId)
            .collection('subscriptions')
            .doc(groupId)
            .get();
    return doc.exists;
  }
  
}
