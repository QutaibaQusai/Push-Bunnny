import 'dart:io';

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
Future<void> saveNotification({
  required RemoteMessage message,
  required String userId,
  required String appState,
}) async {
  try {
    final String messageId = message.messageId ?? 
                         DateTime.now().millisecondsSinceEpoch.toString();
    
    if (_storage.hasNotificationWithMessageId(messageId)) {
      debugPrint('Notification with messageId $messageId already exists. Skipping save.');
      return;
    }
    
    final notification = message.notification;
    final data = message.data;
    
    final String title = notification?.title ?? data['title'] ?? 'Notification';
    final String body = notification?.body ?? data['body'] ?? '';

  String? imageUrl;
    
    if (Platform.isAndroid) {
      imageUrl = notification?.android?.imageUrl ?? data['imageUrl'];
    } else if (Platform.isIOS) {
      imageUrl = notification?.apple?.imageUrl ?? data['imageUrl'];
    } else {
      imageUrl = data['imageUrl'];
    }   
        final String? link = data['link']; // Extract link from data
    
    // Extract group info (if any)
    final String? groupId = _extractGroupId(message);
    final String? groupName = data['groupName'] ?? groupId;
    
    final Map<String, dynamic> combinedData = {...data};
    combinedData['messageId'] = messageId;
    
  
    final notificationModel = NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(), 
      userId: userId,
      title: title,
      body: body,
      timestamp: DateTime.now(), 
      imageUrl: imageUrl,
      groupId: groupId,
      groupName: groupName,
      isRead: false,
      data: combinedData,
      messageId: messageId, // Store message ID for deduplication
      link: link, // Add link to the model
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
        'messageId': messageId, 
        'link': link, 
      };
      
      firestoreData.addAll(data);
      
      final docRef = await _firestore.collection('notifications').add(firestoreData);
      
      final updatedModel = notificationModel.copyWith(id: docRef.id);
      
      await _storage.saveNotification(updatedModel);
      
      await _storage.deleteNotification(notificationModel.id);
      
      debugPrint('Notification saved to Firestore with ID: ${docRef.id} and messageId: $messageId');
    } else {
      debugPrint('Device offline, notification saved to local storage only, messageId: $messageId');
    }
  } catch (e) {
    debugPrint('Error saving notification: $e');
  }
}

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
 String? _extractGroupId(RemoteMessage message) {
  // Always prioritize explicit groupId from data
  if (message.data.containsKey('groupId')) {
    return message.data['groupId'];
  }

  // Fallback: Android may populate this
  if (message.from != null && message.from!.startsWith('/topics/')) {
    return message.from!.substring(8); // remove '/topics/'
  }

  return null;
}

}