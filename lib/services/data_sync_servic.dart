import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive/hive.dart';
import 'package:push_bunnny/auth_service.dart';
import 'package:push_bunnny/models/notification_model.dart';
import 'package:push_bunnny/models/hive_notification_model.dart';
import 'package:push_bunnny/services/hive_database_service.dart';

/// Service to handle syncing data between local Hive database and Firestore
class DataSyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final HiveDatabaseService _hiveService = HiveDatabaseService();
  final AuthService _authService = AuthService();
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  bool _isSyncing = false;

  // Singleton pattern
  static final DataSyncService _instance = DataSyncService._internal();

  factory DataSyncService() {
    return _instance;
  }

  DataSyncService._internal();

  /// Initialize the sync service and listen for connectivity changes
  Future<void> initialize() async {
    _listenForConnectivityChanges();
  }

  /// Dispose resources
  void dispose() {
    _connectivitySubscription?.cancel();
  }

  /// Listen for connectivity changes to trigger sync when device comes online
  void _listenForConnectivityChanges() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((result) async {
      // When device comes online, perform sync
      if (result != ConnectivityResult.none) {
        await syncData();
      }
    });
  }

  /// Sync data between local storage and Firestore
  Future<void> syncData() async {
    if (_isSyncing) return; // Prevent multiple syncs at once
    _isSyncing = true;

    try {
      debugPrint('Starting data synchronization...');
      
      // Get current user ID
      final userId = await _authService.getUserId();
      
      // Check for unsynced notifications in Hive
      await _syncUnsyncedNotifications(userId);
      
      // Check for notifications in Firestore that aren't in local storage
      await _syncMissingNotifications(userId);
      
      debugPrint('Data synchronization completed');
    } catch (e) {
      debugPrint('Error during data synchronization: $e');
    } finally {
      _isSyncing = false;
    }
  }

  /// Sync notifications that are in local storage but not in Firestore
  Future<void> _syncUnsyncedNotifications(String userId) async {
    try {
      // Get all unsynced notifications from Hive
      final box = Hive.box<HiveNotificationModel>(HiveDatabaseService.notificationsBoxName);
      final unsyncedNotifications = box.values.where((notification) => 
          notification.userId == userId && 
          !notification.isSynced
      ).toList();
      
      if (unsyncedNotifications.isEmpty) {
        debugPrint('No unsynced notifications to upload');
        return;
      }
      
      debugPrint('Found ${unsyncedNotifications.length} unsynced notifications');
      
      // Upload each unsynced notification to Firestore
      for (var notification in unsyncedNotifications) {
        try {
          // Create the notification data for Firestore
          final notificationData = {
            'title': notification.title,
            'body': notification.body,
            'imageUrl': notification.imageUrl,
            'timestamp': notification.timestamp,
            'userId': notification.userId,
            'groupId': notification.groupId,
            'groupName': notification.groupName,
            'isRead': notification.isRead,
            'readAt': notification.readAt,
          };
          
          // Upload to Firestore
          DocumentReference doc = await _firestore.collection('notifications').add(notificationData);
          
          // Update the local notification with the new ID and mark as synced
          final updatedNotification = HiveNotificationModel(
            id: doc.id,
            userId: notification.userId,
            title: notification.title,
            body: notification.body,
            timestamp: notification.timestamp,
            imageUrl: notification.imageUrl,
            groupId: notification.groupId,
            groupName: notification.groupName,
            isRead: notification.isRead,
            readAt: notification.readAt,
            isSynced: true,
          );
          
          // Save to Hive
          await box.put(doc.id, updatedNotification);
          
          // Delete the old unsynced notification
          await box.delete(notification.id);
          
          debugPrint('Synced notification to Firestore: ${doc.id}');
        } catch (e) {
          debugPrint('Error uploading notification to Firestore: $e');
        }
      }
    } catch (e) {
      debugPrint('Error syncing unsynced notifications: $e');
    }
  }

  /// Sync notifications that are in Firestore but not in local storage
  Future<void> _syncMissingNotifications(String userId) async {
    try {
      // Get timestamp of the oldest notification in local storage
      final box = Hive.box<HiveNotificationModel>(HiveDatabaseService.notificationsBoxName);
      final localNotifications = box.values.where((n) => n.userId == userId).toList();
      
      // If no local notifications, get all from Firestore
      if (localNotifications.isEmpty) {
        await _fetchAllNotifications(userId);
        return;
      }
      
      // Get notifications from Firestore that might be missing
      final firestoreNotifications = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .get();
      
      int newCount = 0;
      
      // Check each Firestore notification
      for (var doc in firestoreNotifications.docs) {
        final String docId = doc.id;
        
        // Check if this notification is already in local storage
        if (!box.containsKey(docId)) {
          // Not in local storage, save it
          final data = doc.data();
          final notification = NotificationModel(
            id: docId,
            userId: data['userId'] ?? userId,
            title: data['title'] ?? 'Notification',
            body: data['body'] ?? '',
            timestamp: data['timestamp']?.toDate() ?? DateTime.now(),
            imageUrl: data['imageUrl'],
            groupId: data['groupId'],
            groupName: data['groupName'],
            isRead: data['isRead'] ?? false,
            readAt: data['readAt']?.toDate(),
          );
          
          await _hiveService.saveNotification(notification);
          newCount++;
        }
      }
      
      debugPrint('Downloaded $newCount new notifications from Firestore');
    } catch (e) {
      debugPrint('Error syncing missing notifications: $e');
    }
  }

  /// Fetch all notifications for a user from Firestore
  Future<void> _fetchAllNotifications(String userId) async {
    try {
      final firestoreNotifications = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .get();
      
      debugPrint('Fetching all ${firestoreNotifications.docs.length} notifications from Firestore');
      
      for (var doc in firestoreNotifications.docs) {
        final notification = NotificationModel.fromFirestore(doc);
        await _hiveService.saveNotification(notification);
      }
    } catch (e) {
      debugPrint('Error fetching all notifications: $e');
    }
  }

  /// Manual sync trigger for the UI
  Future<bool> manualSync() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        return false; // Device is offline
      }
      
      await syncData();
      return true;
    } catch (e) {
      debugPrint('Error during manual sync: $e');
      return false;
    }
  }
}