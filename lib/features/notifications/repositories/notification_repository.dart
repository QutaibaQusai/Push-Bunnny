import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:push_bunnny/core/services/local_storage_service.dart';
import 'package:push_bunnny/core/utils/connectivity_helper.dart';
import 'package:push_bunnny/features/notifications/models/notification_model.dart';


class NotificationRepository {
  static final NotificationRepository _instance = NotificationRepository._internal();
  factory NotificationRepository() => _instance;
  NotificationRepository._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocalStorageService _storage = LocalStorageService();
  final ConnectivityHelper _connectivity = ConnectivityHelper();
  
// lib/features/notifications/repositories/notification_repository.dart (updated for saveNotification method)

Future<void> saveNotification({
  required RemoteMessage message,
  required String userId,
  required String appState,
}) async {
  try {
    // Extract messageId - this is the key for preventing duplicates
    final String messageId = message.messageId ?? 
                           DateTime.now().millisecondsSinceEpoch.toString();
    
    // Check if this notification already exists in local storage
    if (_storage.hasNotificationWithMessageId(messageId)) {
      debugPrint('Notification with messageId $messageId already exists. Skipping save.');
      return;
    }
    
    // Extract notification data
    final notification = message.notification;
    final data = message.data;
    
    // Create notification model
    final String title = notification?.title ?? data['title'] ?? 'Notification';
    final String body = notification?.body ?? data['body'] ?? '';
    final String? imageUrl = notification?.android?.imageUrl ?? data['imageUrl'];
    
    // Extract group info (if any)
    final String? groupId = _extractGroupId(message);
    final String? groupName = data['groupName'] ?? groupId;
    
    // Create a combined data map that includes the messageId
    final Map<String, dynamic> combinedData = {...data};
    combinedData['messageId'] = messageId;
    
    // Create notification model with current DateTime for local storage
    // This avoids the Timestamp issue
    final notificationModel = NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(), // Temp ID for local storage
      userId: userId,
      title: title,
      body: body,
      timestamp: DateTime.now(), // Use DateTime.now() instead of Timestamp
      imageUrl: imageUrl,
      groupId: groupId,
      groupName: groupName,
      isRead: false,
      data: combinedData,
      messageId: messageId, // Store message ID for deduplication
    );
    
    // Save to local storage first
    await _storage.saveNotification(notificationModel);
    debugPrint('Notification saved to local storage with messageId: $messageId');
    
    // Save to Firestore if online
    if (await _connectivity.checkConnectivity()) {
      // Prepare Firestore data
      final firestoreData = {
        'userId': userId,
        'title': title,
        'body': body,
        'timestamp': FieldValue.serverTimestamp(),
        'imageUrl': imageUrl,
        'groupId': groupId,
        'groupName': groupName,
        'isRead': false,
        'appState': appState,
        'messageId': messageId, // Include messageId for deduplication
      };
      
      // Add all data from message.data
      firestoreData.addAll(data);
      
      // Save to Firestore
      final docRef = await _firestore.collection('notifications').add(firestoreData);
      
      // Create updated model with Firestore ID
      final updatedModel = notificationModel.copyWith(id: docRef.id);
      
      // Update local storage with Firestore ID
      await _storage.saveNotification(updatedModel);
      
      // Delete temporary notification
      await _storage.deleteNotification(notificationModel.id);
      
      debugPrint('Notification saved to Firestore with ID: ${docRef.id} and messageId: $messageId');
    } else {
      debugPrint('Device offline, notification saved to local storage only, messageId: $messageId');
    }
  } catch (e) {
    debugPrint('Error saving notification: $e');
  }
}
 
  // Get all notifications for a user
  Stream<List<NotificationModel>> getUserNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          final notifications = snapshot.docs.map((doc) {
            final notification = NotificationModel.fromFirestore(doc);
            
            // Save to local storage
            _storage.saveNotification(notification);
            
            return notification;
          }).toList();
          
          return notifications;
        });
  }
  
  // Get notifications for a specific group
  Stream<List<NotificationModel>> getGroupNotifications(String userId, String groupId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('groupId', isEqualTo: groupId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          final notifications = snapshot.docs.map((doc) {
            final notification = NotificationModel.fromFirestore(doc);
            
            // Save to local storage
            _storage.saveNotification(notification);
            
            return notification;
          }).toList();
          
          return notifications;
        });
  }
  
  // Get local notifications if offline
  List<NotificationModel> getLocalNotifications(String userId) {
    return _storage.getNotificationsForUser(userId);
  }
  
  // Get local group notifications if offline
  List<NotificationModel> getLocalGroupNotifications(String userId, String groupId) {
    return _storage.getNotificationsForGroup(userId, groupId);
  }
  
  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      // Update in local storage first
      await _storage.updateNotification(notificationId, {
        'isRead': true,
        'readAt': DateTime.now().toIso8601String(),
      });
      
      // Update in Firestore if online
      if (await _connectivity.checkConnectivity()) {
        await _firestore.collection('notifications').doc(notificationId).update({
          'isRead': true,
          'readAt': FieldValue.serverTimestamp(),
        });
        
        debugPrint('Notification marked as read in Firestore: $notificationId');
      } else {
        debugPrint('Device offline, notification marked as read in local storage only');
      }
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }
  
  // Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      // Delete from local storage first
      await _storage.deleteNotification(notificationId);
      
      // Delete from Firestore if online
      if (await _connectivity.checkConnectivity()) {
        await _firestore.collection('notifications').doc(notificationId).delete();
        
        debugPrint('Notification deleted from Firestore: $notificationId');
      } else {
        debugPrint('Device offline, notification deleted from local storage only');
      }
    } catch (e) {
      debugPrint('Error deleting notification: $e');
    }
  }
  
  // Delete all notifications for a user
  Future<void> deleteAllNotifications(String userId) async {
    try {
      // Delete from local storage first
      await _storage.deleteAllNotifications(userId);
      
      // Delete from Firestore if online
      if (await _connectivity.checkConnectivity()) {
        // Get all notifications for user
        final querySnapshot = await _firestore
            .collection('notifications')
            .where('userId', isEqualTo: userId)
            .get();
        
        // Delete in batches
        final batch = _firestore.batch();
        for (var doc in querySnapshot.docs) {
          batch.delete(doc.reference);
        }
        
        await batch.commit();
        
        debugPrint('All notifications deleted from Firestore for user: $userId');
      } else {
        debugPrint('Device offline, notifications deleted from local storage only');
      }
    } catch (e) {
      debugPrint('Error deleting all notifications: $e');
    }
  }
  
  // Extract group ID from a message
  String? _extractGroupId(RemoteMessage message) {
    // Check if message is from a topic
    if (message.from != null && message.from!.startsWith('/topics/')) {
      return message.from!.substring(8); // Remove '/topics/' prefix
    }
    
    // Check data payload for explicit group info
    if (message.data.containsKey('groupId')) {
      return message.data['groupId'];
    }
    
    return null;
  }
}