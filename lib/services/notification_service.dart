import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:push_bunnny/auth_service.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  // Get current user ID (now using FCM token)
  Future<String> get _userId async => await _authService.getUserId();

  // Get all notifications for the current user
  // Stream<QuerySnapshot> getUserNotifications() async* {
  //   final userId = await _userId;
  //   yield* _firestore
  //       .collection('notifications')
  //       .where('userId', isEqualTo: userId)
  //       .orderBy('timestamp', descending: true)
  //       .snapshots();
  // }
  Stream<QuerySnapshot> getUserNotifications() async* {
    final userId = await _userId;
    debugPrint(
      'Getting notifications for user: ${userId.length > 10 ? userId.substring(0, 10) + '...' : userId}',
    );
    // Simple query first - just get all notifications without filters to test
    yield* _firestore
        .collection('notifications')
        .limit(10) // Just get a few to test
        .snapshots();
  }

  // Get notifications for a specific group
  Stream<QuerySnapshot> getGroupNotifications(String groupId) async* {
    final userId = await _userId;
    yield* _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
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
