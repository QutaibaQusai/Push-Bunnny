import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:push_bunnny/screens/notification_history_screen.dart';
import '../main.dart'; 

// Notification channel definition (accessible at top level)
const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'high_importance_channel',
  'High Importance Notifications',
  importance: Importance.max,
  playSound: true,
);

// Helper function that can be used from the background handler
Future<void> saveNotificationToFirestore(
  RemoteMessage message,
  String appState,
) async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    await FirebaseFirestore.instance.collection('notifications').add({
      'title': message.notification?.title ?? 'No title',
      'body': message.notification?.body ?? 'No body',
      'imageUrl': message.notification?.android?.imageUrl,
      'link': message.data['link'],
      'timestamp': FieldValue.serverTimestamp(),
      'userId': user?.uid ?? 'anonymous',
      'appState': appState,
    });
  } catch (e) {
    debugPrint('Error saving notification: $e');
  }
}

class NotificationRepository {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
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
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<void> _setupLocalNotifications() async {
    // Create the notification channel
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );

    await _notificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _handleNotificationTap,
    );
  }

  void _handleNotificationTap(NotificationResponse response) {
    navigatorKey.currentState?.pushReplacement(
      MaterialPageRoute(builder: (_) => const NotificationHistoryScreen()),
    );
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
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
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
    RemoteMessage? initialMessage =
        await _firebaseMessaging.getInitialMessage();
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
    navigatorKey.currentState?.pushReplacement(
      MaterialPageRoute(builder: (_) => const NotificationHistoryScreen()),
    );
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    await _notificationsPlugin.show(
      message.notification.hashCode,
      message.notification?.title,
      message.notification?.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      payload: 'notification_history',
    );
  }

  Future<void> _saveNotification(RemoteMessage message) async {
    await saveNotificationToFirestore(message, 'foreground');
  }

  String? get currentFcmToken => _currentFcmToken;
}
