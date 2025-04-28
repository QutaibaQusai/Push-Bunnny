import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:push_bunnny/auth_service.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  // Get current user ID (now using persistent UUID)
  Future<String> get _userId async => await _authService.getUserId();

  // Get all notifications for the current user
  Stream<QuerySnapshot> getUserNotifications() async* {
    final userId = await _userId;
    debugPrint(
      'Getting notifications for user: ${userId.length > 10 ? userId.substring(0, 10) + '...' : userId}',
    );
    yield* _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Get notifications for a specific group
  Stream<QuerySnapshot> getGroupNotifications(String groupId) async* {
    final userId = await _userId;
    debugPrint('Filtering notifications for group: $groupId and user: ${userId.substring(0, 10)}...');
    
    // First try to filter by both userId and groupId if groupId exists in notifications
    try {
      // First check if any notifications exist with both fields
      final hasMatchingNotifications = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('groupId', isEqualTo: groupId)
          .limit(1)
          .get();
      
      // If we found matching notifications, use this filter
      if (hasMatchingNotifications.docs.isNotEmpty) {
        debugPrint('Found notifications with matching groupId: $groupId');
        yield* _firestore
            .collection('notifications')
            .where('userId', isEqualTo: userId)
            .where('groupId', isEqualTo: groupId)
            .orderBy('timestamp', descending: true)
            .snapshots();
        return;
      }
    } catch (e) {
      debugPrint('Error checking for group notifications: $e');
    }
    
    // If we got here, there are no notifications with matching groupId
    // Instead, check if this topic matches the notifications from field (for FCM topic messages)
    debugPrint('No exact groupId matches, checking topic messages...');
    
    try {
      // FCM topic messages have a 'from' field that looks like '/topics/your_topic_name'
      // Check if any notifications exist with matching topic
      final fromField = '/topics/$groupId';
      
      yield* _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('from', isEqualTo: fromField)
          .orderBy('timestamp', descending: true)
          .snapshots();
    } catch (e) {
      debugPrint('Error filtering by topic: $e');
      
      // As a fallback, return an empty collection
      yield* _firestore
          .collection('notifications')
          .where('userId', isEqualTo: 'no_matching_user_id_will_return_empty')
          .snapshots();
    }
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