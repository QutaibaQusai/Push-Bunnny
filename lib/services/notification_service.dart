import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:push_bunnny/auth_service.dart';
import 'package:push_bunnny/models/notification_model.dart';
import 'package:push_bunnny/services/hive_database_service.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
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

  // Get all notifications for the current user
  Stream<List<NotificationModel>> getUserNotifications() async* {
    final userId = await _userId;
    debugPrint(
      'Getting notifications for user: ${userId.length > 10 ? userId.substring(0, 10) + '...' : userId}',
    );

    // First emit from local storage immediately
    yield _hiveService.getNotificationsForUser(userId);

    // Then try to get from Firestore if online
    if (await isOnline) {
      try {
        // Listen to Firestore stream
        await for (QuerySnapshot snapshot in _firestore
            .collection('notifications')
            .where('userId', isEqualTo: userId)
            .orderBy('timestamp', descending: true)
            .snapshots()) {
          
          // Convert to notification models
          final List<NotificationModel> notifications = [];
          for (var doc in snapshot.docs) {
            final notification = NotificationModel.fromFirestore(doc);
            notifications.add(notification);
            
            // Save to local storage
            await _hiveService.saveNotification(notification);
          }
          
          yield notifications;
        }
      } catch (e) {
        debugPrint('Error getting notifications from Firestore: $e');
        // On error, return local data
        yield _hiveService.getNotificationsForUser(userId);
      }
    }
  }

  // Get notifications for a specific group
  Stream<List<NotificationModel>> getGroupNotifications(String groupId) async* {
    final userId = await _userId;
    debugPrint('Filtering notifications for group: $groupId and user: ${userId.substring(0, 10)}...');
    
    // First emit from local storage immediately
    yield _hiveService.getNotificationsForGroup(userId, groupId);
    
    // Then try to get from Firestore if online
    if (await isOnline) {
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
          
          await for (QuerySnapshot snapshot in _firestore
              .collection('notifications')
              .where('userId', isEqualTo: userId)
              .where('groupId', isEqualTo: groupId)
              .orderBy('timestamp', descending: true)
              .snapshots()) {
            
            // Convert to notification models
            final List<NotificationModel> notifications = [];
            for (var doc in snapshot.docs) {
              final notification = NotificationModel.fromFirestore(doc);
              notifications.add(notification);
              
              // Save to local storage
              await _hiveService.saveNotification(notification);
            }
            
            yield notifications;
          }
        } else {
          // Try to use from field
          debugPrint('No exact groupId matches, checking topic messages...');
          final fromField = '/topics/$groupId';
          
          await for (QuerySnapshot snapshot in _firestore
              .collection('notifications')
              .where('userId', isEqualTo: userId)
              .where('from', isEqualTo: fromField)
              .orderBy('timestamp', descending: true)
              .snapshots()) {
            
            // Convert to notification models
            final List<NotificationModel> notifications = [];
            for (var doc in snapshot.docs) {
              final notification = NotificationModel.fromFirestore(doc);
              notifications.add(notification);
              
              // Save to local storage
              await _hiveService.saveNotification(notification);
            }
            
            yield notifications;
          }
        }
      } catch (e) {
        debugPrint('Error getting group notifications from Firestore: $e');
        // On error, return local data
        yield _hiveService.getNotificationsForGroup(userId, groupId);
      }
    }
  }

  // Delete a notification
  Future<void> deleteNotification(String docId) async {
    // First delete from local storage
    await _hiveService.deleteNotification(docId);
    
    // Then delete from Firestore if online
    if (await isOnline) {
      try {
        await _firestore.collection('notifications').doc(docId).delete();
      } catch (e) {
        debugPrint('Error deleting notification from Firestore: $e');
      }
    }
  }

  // Mark a notification as read
  Future<void> markNotificationAsRead(String docId) async {
    // First mark as read in local storage
    await _hiveService.markNotificationAsRead(docId);
    
    // Then update Firestore if online
    if (await isOnline) {
      try {
        await _firestore.collection('notifications').doc(docId).update({
          'isRead': true,
          'readAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        debugPrint('Error marking notification as read in Firestore: $e');
      }
    }
  }
  
  // Delete all notifications for the current user
  Future<void> deleteAllNotifications() async {
    final userId = await _userId;
    
    // First delete from local storage
    await _hiveService.deleteAllNotifications(userId);
    
    // Then delete from Firestore if online
    if (await isOnline) {
      try {
        final notifications = await _firestore
            .collection('notifications')
            .where('userId', isEqualTo: userId)
            .get();
            
        // Delete in batches
        final batch = _firestore.batch();
        for (var doc in notifications.docs) {
          batch.delete(doc.reference);
        }
        
        await batch.commit();
      } catch (e) {
        debugPrint('Error deleting all notifications from Firestore: $e');
      }
    }
  }
}