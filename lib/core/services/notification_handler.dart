import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:push_bunnny/core/services/auth_service.dart';
import 'package:push_bunnny/core/services/storage_service.dart';
import 'package:push_bunnny/features/notifications/models/notification_model.dart';
import 'package:push_bunnny/ui/navigation/app_router.dart';


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
    // Foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Background tap (app in background)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // App launched from terminated state
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      await _handleMessageOpenedApp(initialMessage);
    }

    debugPrint('📱 Message handlers setup complete');
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('📨 Foreground message received: ${message.messageId}');
    
    await _saveNotification(message, 'foreground');
    
    // Show local notification on Android (iOS handles automatically)
    if (!Platform.isIOS) {
      await _showLocalNotification(message);
    }
  }

  Future<void> _handleMessageOpenedApp(RemoteMessage message) async {
    debugPrint('📱 Message opened app: ${message.messageId}');
    
    await _saveNotification(message, 'background');
    
    // Navigate to notifications screen
    AppRouter.navigateToNotifications();
  }

  static Future<void> handleBackgroundMessage(RemoteMessage message) async {
    debugPrint('🔔 Background message received: ${message.messageId}');
    
    // Initialize required services for background processing
    await StorageService.instance.initialize();
    await AuthService.instance.initialize();
    
    await instance._saveNotification(message, 'background');
  }

  Future<void> _saveNotification(RemoteMessage message, String appState) async {
    try {
      final userId = AuthService.instance.userId;
      if (userId == null) return;

      final messageId = message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString();
      
      // Check for duplicates
      if (await StorageService.instance.notificationExists(messageId)) {
        debugPrint('⚠️ Duplicate notification ignored: $messageId');
        return;
      }

      final notification = NotificationModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        messageId: messageId,
        title: message.notification?.title ?? message.data['title'] ?? 'Notification',
        body: message.notification?.body ?? message.data['body'] ?? '',
        timestamp: DateTime.now(),
        isRead: false,
        appState: appState,
        data: message.data,
      );

      await StorageService.instance.saveNotification(notification);
      debugPrint('✅ Notification saved: ${notification.id}');
    } catch (e) {
      debugPrint('❌ Failed to save notification: $e');
    }
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