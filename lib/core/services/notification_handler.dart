import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:push_bunnny/ui/navigation/app_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class NotificationHandler {
  static final NotificationHandler instance = NotificationHandler._();
  NotificationHandler._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  // High importance channel for Android
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important notifications.',
    importance: Importance.max,
    playSound: true,
    enableLights: true,
    enableVibration: true,
    showBadge: true,
  );

  Future<void> initialize() async {
    await _initializeLocalNotifications();
    await _requestPermissions();
    await _setupMessageHandlers();
    
    // Clear notifications when app starts in foreground
    await _clearNotificationsOnForeground();
  }

  Future<void> _initializeLocalNotifications() async {
    // Android settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS settings
    const iosSettings = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create Android notification channel
    if (Platform.isAndroid) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);
    }

    debugPrint('🔔 Local notifications initialized');
  }

  Future<void> _requestPermissions() async {
    if (Platform.isIOS) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
            critical: true,
          );
    }

    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: true,
      criticalAlert: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('✅ Notification permissions granted');
    } else {
      debugPrint('❌ Notification permissions denied');
    }

    // iOS foreground presentation options
    if (Platform.isIOS) {
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  Future<void> _setupMessageHandlers() async {
    // Foreground messages - show local notification
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Background tap (app in background) - navigate to notifications
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // App launched from terminated state - navigate to notifications
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      await _handleMessageOpenedApp(initialMessage);
    }

    debugPrint('📱 Message handlers setup complete');
  }

  // NEW: Clear notifications when app comes to foreground
  Future<void> _clearNotificationsOnForeground() async {
    try {
      final token = await getToken();
      if (token != null) {
        await _clearServerNotifications(token);
        await _clearLocalNotifications();
        debugPrint('🧹 Notifications cleared on app foreground');
      }
    } catch (e) {
      debugPrint('❌ Failed to clear notifications: $e');
    }
  }

  // NEW: Clear notifications from server
  Future<void> _clearServerNotifications(String token) async {
    try {
      // Replace with your actual server endpoint
      const String serverUrl = 'YOUR_SERVER_URL/clear-notifications';
      
      final response = await http.post(
        Uri.parse(serverUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'token': token,
          'userId': 'USER_ID_HERE', // You might need to get this from your auth system
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('✅ Server notifications cleared');
      } else {
        debugPrint('❌ Failed to clear server notifications: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error clearing server notifications: $e');
      rethrow;
    }
  }

  // NEW: Clear local notifications
  Future<void> _clearLocalNotifications() async {
    try {
      await _localNotifications.cancelAll();
      debugPrint('✅ Local notifications cleared');
    } catch (e) {
      debugPrint('❌ Failed to clear local notifications: $e');
    }
  }

  // NEW: Method to manually clear notifications (can be called from UI)
  Future<void> clearAllNotifications() async {
    await _clearNotificationsOnForeground();
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('📨 Foreground message received: ${message.messageId}');
    
    // DON'T show local notification when app is in foreground
    // The user can already see the app content, so no need for duplicate notification
    
    // Optional: Update UI or refresh data instead
    // Example: You could trigger a refresh of your notifications screen
    // or update a badge count in your app
    
    debugPrint('🔔 Foreground message handled without showing notification');
  }

  Future<void> _handleMessageOpenedApp(RemoteMessage message) async {
    debugPrint('📱 Message opened app: ${message.messageId}');
    
    // Clear notifications when user taps on them
    await _clearNotificationsOnForeground();
    
    // Navigate to notifications
    AppRouter.navigateToNotifications();
  }

  // Simple background handler - no saving needed (server handles it)
  static Future<void> handleBackgroundMessage(RemoteMessage message) async {
    debugPrint('🔔 Background message received: ${message.messageId}');
    // No need to save - server already saved to Firestore
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final data = message.data;
    final isGroup = data['type'] == 'group';

    final androidDetails = AndroidNotificationDetails(
      _channel.id,
      _channel.name,
      channelDescription: _channel.description,
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      icon: '@mipmap/ic_launcher',
      styleInformation: BigTextStyleInformation(
        notification.body ?? '',
        contentTitle: notification.title,
      ),
      groupKey: isGroup ? data['id'] : null,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'default',
      interruptionLevel: InterruptionLevel.active,
    );

    var platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final notificationId = message.messageId?.hashCode ?? notification.hashCode;

    await _localNotifications.show(
      notificationId,
      notification.title,
      notification.body,
      platformDetails,
      payload: message.messageId,
    );

    debugPrint('🔔 Local notification shown');
  }

  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('👆 Notification tapped: ${response.payload}');
    // Clear notifications when tapped
    _clearNotificationsOnForeground();
    AppRouter.navigateToNotifications();
  }

  // Group subscription methods
  Future<void> subscribeToGroup(String groupId) async {
    try {
      await _messaging.subscribeToTopic(groupId);
      debugPrint('✅ Subscribed to group: $groupId');
    } catch (e) {
      debugPrint('❌ Failed to subscribe to group: $e');
      rethrow;
    }
  }

  Future<void> unsubscribeFromGroup(String groupId) async {
    try {
      await _messaging.unsubscribeFromTopic(groupId);
      debugPrint('✅ Unsubscribed from group: $groupId');
    } catch (e) {
      debugPrint('❌ Failed to unsubscribe from group: $e');
      rethrow;
    }
  }

  Future<String?> getToken() async {
    return await _messaging.getToken();
  }
}