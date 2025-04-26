import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _userId => _auth.currentUser?.uid ?? 'anonymous';

  // Get all notifications for the current user
  Stream<QuerySnapshot> getUserNotifications() {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: _userId)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Get notifications for a specific group
  Stream<QuerySnapshot> getGroupNotifications(String groupId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: _userId)
        .where('groupId', isEqualTo: groupId)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Delete a notification
  Future<void> deleteNotification(String docId) async {
    await _firestore.collection('notifications').doc(docId).delete();
  }

  // Mark a notification as read
  Future<void> markNotificationAsRead(String docId) async {
    await _firestore.collection('notifications').doc(docId).update({
      'isRead': true,
      'readAt': FieldValue.serverTimestamp(),
    });
  }
}