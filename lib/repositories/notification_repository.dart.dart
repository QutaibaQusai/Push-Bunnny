import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:push_bunnny/auth_service.dart';
import 'package:push_bunnny/models/notification_model.dart';
import 'package:push_bunnny/services/hive_database_service.dart';
import 'package:push_bunnny/screens/notification_history_screen.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../main.dart';

// Notification channel definition (accessible at top level)
const AndroidNotificationChannel channel = AndroidNotificationChannel('high_importance_channel', 'High Importance Notifications', importance: Importance.max, playSound: true);

Future<void> saveNotificationToFirestore(RemoteMessage message, String appState) async {
  try {
    // Get user ID from AuthService (now using persistent UUID)
    final authService = AuthService();
    final userId = await authService.getUserId();

    // Get FCM token for device identification
    final fcmToken = await FirebaseMessaging.instance.getToken();

    // Extract group information from the message
    String? groupId;
    String? groupName;

    // Check if the message is from a topic
    if (message.from != null && message.from!.startsWith('/topics/')) {
      // Extract the topic name from the 'from' field (remove '/topics/' prefix)
      groupId = message.from!.substring(8);
      groupName = groupId; // Use the groupId as the name if not specified

      debugPrint('Message from topic: $groupId');
    }

    // Check data payload for explicit group info (this overrides topic-based extraction)
    if (message.data.containsKey('groupId')) {
      groupId = message.data['groupId'];
      groupName = message.data['groupName'] ?? groupId;
      debugPrint('Message has explicit group info: $groupId - $groupName');
    }

    // Create the notification data
    final notificationData = {
      'title': message.notification?.title ?? 'No title',
      'body': message.notification?.body ?? 'No body',
      'imageUrl': message.notification?.android?.imageUrl,
      'link': message.data['link'],
      'timestamp': FieldValue.serverTimestamp(),
      'userId': userId, // Using the persistent UUID
      'fcmToken': fcmToken, // Store the FCM token as a separate field
      'appState': appState,
      'from': message.from,
      'groupId': groupId,
      'groupName': groupName,
      'isRead': false,
    };

    // Create a NotificationModel instance for local storage
    final localNotification = NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(), // Temporary ID for local storage
      userId: userId,
      title: notificationData['title'] as String,
      body: notificationData['body'] as String,
      timestamp: DateTime.now(),
      imageUrl: notificationData['imageUrl'] as String?,
      groupId: notificationData['groupId'] as String?,
      groupName: notificationData['groupName'] as String?,
      isRead: false,
    );

    // Save to local storage first
    final hiveService = HiveDatabaseService();
    await hiveService.saveNotification(localNotification);

    // Check if online before saving to Firestore
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult != ConnectivityResult.none) {
      // Save to Firestore
      final doc = await FirebaseFirestore.instance.collection('notifications').add(notificationData);

      // Update the local notification with the Firestore ID
      final updatedNotification = NotificationModel(id: doc.id, userId: localNotification.userId, title: localNotification.title, body: localNotification.body, timestamp: localNotification.timestamp, imageUrl: localNotification.imageUrl, groupId: localNotification.groupId, groupName: localNotification.groupName, isRead: localNotification.isRead);

      // Update in local storage with the correct ID
      await hiveService.saveNotification(updatedNotification);

      // Delete the temporary notification
      await hiveService.deleteNotification(localNotification.id);

      // Update the device token in the user's document
      if (fcmToken != null) {
        await FirebaseFirestore.instance.collection('users').doc(userId).update({'deviceToken': fcmToken});
      }

      debugPrint('Notification saved to Firestore and local storage with groupId: $groupId, from: ${message.from}');
    } else {
      debugPrint('Device offline. Notification saved to local storage only with groupId: $groupId, from: ${message.from}');
    }
  } catch (e) {
    debugPrint('Error saving notification: $e');
  }
}

class NotificationRepository {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  final AuthService _authService = AuthService();
  final HiveDatabaseService _hiveService = HiveDatabaseService();
  String? _currentFcmToken;

  Future<void> initialize() async {
    // Request permissions
    await _requestNotificationPermissions();

    // Initialize local notifications
    await _setupLocalNotifications();

    // Get and print FCM token
    await _initializeFcmToken();

    // Setup message handlers
    _setupMessageHandlers();
  }

  Future<void> _requestNotificationPermissions() async {
    await _firebaseMessaging.requestPermission(alert: true, badge: true, sound: true);
  }

  Future<void> _setupLocalNotifications() async {
    // Create the notification channel for Android
    await _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(channel);

    // Configure initialization settings for both platforms
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iOSSettings = DarwinInitializationSettings(requestSoundPermission: true, requestBadgePermission: true, requestAlertPermission: true);

    const InitializationSettings settings = InitializationSettings(android: androidSettings, iOS: iOSSettings);

    await _notificationsPlugin.initialize(settings, onDidReceiveNotificationResponse: _handleNotificationTap);
  }

  void _handleNotificationTap(NotificationResponse response) {
    navigatorKey.currentState?.pushReplacement(MaterialPageRoute(builder: (_) => const NotificationHistoryScreen()));
  }

  Future<void> _initializeFcmToken() async {
    _currentFcmToken = await _getAndPrintToken();
    _setupTokenRefreshListener();
  }

  Future<String?> _getAndPrintToken() async {
    try {
      String? token = await _firebaseMessaging.getToken();
      debugPrint('FCM Token: $token');
      return token;
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
      return null;
    }
  }

  void _setupTokenRefreshListener() {
    _firebaseMessaging.onTokenRefresh.listen((newToken) async {
      debugPrint('FCM Token Refreshed: $newToken');
      _currentFcmToken = newToken;
    });
  }

  void _setupMessageHandlers() {
    // Foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // When app is opened from background/terminated state
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpened);

    // Background handler is registered in main.dart, not here

    // Check for initial message
    _checkInitialMessage();
  }

  Future<void> _checkInitialMessage() async {
    RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      await _saveNotification(initialMessage);
      _handleMessageOpened(initialMessage);
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    await _saveNotification(message);
    await _showLocalNotification(message);
  }

  Future<void> _handleMessageOpened(RemoteMessage message) async {
    navigatorKey.currentState?.pushReplacement(MaterialPageRoute(builder: (_) => const NotificationHistoryScreen()));
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    await _notificationsPlugin.show(message.notification.hashCode, message.notification?.title, message.notification?.body, NotificationDetails(android: AndroidNotificationDetails(channel.id, channel.name, importance: Importance.max, priority: Priority.high, icon: '@mipmap/ic_launcher'), iOS: const DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true)), payload: 'notification_history');
  }

  Future<void> _saveNotification(RemoteMessage message) async {
    await saveNotificationToFirestore(message, 'foreground');
  }

  String? get currentFcmToken => _currentFcmToken;
}
