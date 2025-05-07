import 'dart:async';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:push_bunnny/features/auth/services/auth_service.dart';
import 'package:push_bunnny/features/notifications/repositories/notification_repository.dart';
import 'package:push_bunnny/ui/routes/routes.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final NotificationRepository _repository = NotificationRepository();
  final AuthService _authService = AuthService();

  // Notification channel for Android
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important notifications.',
    importance: Importance.max,
    playSound: true,
    enableLights: true,
  );

  // Stream controller for new notifications
  final _onMessageController = StreamController<RemoteMessage>.broadcast();
  Stream<RemoteMessage> get onMessage => _onMessageController.stream;

  Future<void> initialize() async {
    await _initLocalNotifications();
    await _requestPermissions();
    await _configureFirebaseMessaging();
  }

  Future<void> _initLocalNotifications() async {
    // Android initialization settings with high importance
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings with proper alert permissions
    // Updated to remove the problematic parameter
    final DarwinInitializationSettings
    iOSSettings = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
      // Removed the onDidReceiveLocalNotification parameter that was causing the error
    );

    // Combined initialization settings
    final InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iOSSettings,
    );

    // Initialize the plugin with callback for notification taps
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channel on Android with high importance
    await _createNotificationChannel();
  }

  Future<void> _createNotificationChannel() async {
    if (Platform.isAndroid) {
      // Set the channel to max importance to ensure it shows as a pop-up
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'high_importance_channel',
        'High Importance Notifications',
        description: 'This channel is used for important notifications.',
        importance: Importance.max,
        playSound: true,
        enableLights: true,
        enableVibration: true,
        showBadge: true,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(channel);

      debugPrint('Android notification channel created with max importance');
    }
  }

  Future<void> _requestPermissions() async {
    // Request permission for iOS with provisional permission option
    if (Platform.isIOS) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
            critical: true,
          );

      // For iOS 10+ we need to set presentation options
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true, // Shows the notification banner when in foreground
        badge: true, // Updates the app's badge count
        sound: true, // Plays a sound
      );
    }

    // Request FCM permissions with provisional option
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: true, // Uses provisional authorization on iOS
      criticalAlert: true, // Request critical alert permission
      announcement: true, // Request announcement capability
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('Notification permissions granted');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      debugPrint('Provisional notification permissions granted');
    } else {
      debugPrint('Notification permissions declined');
    }
  }

  Future<void> _configureFirebaseMessaging() async {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle when app is opened via a notification when in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Check for initial message (app opened from terminated state)
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      await _handleInitialMessage(initialMessage);
    }

    // Enable delivering messages in the background - essential for background notifications
    if (Platform.isIOS) {
      // For iOS
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
            alert: true,
            badge: true,
            sound: true,
          );
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    // Check if this is a group notification
    final isGroupNotification = message.data['groupId'] != null;
    final String groupId = message.data['groupId'] ?? 'default_group';
    final String groupName = message.data['groupName'] ?? 'Notifications';

    // Android notification details with max priority
    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'high_importance_channel',
          'High Importance Notifications',
          channelDescription:
              'This channel is used for important notifications.',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
          icon: '@mipmap/ic_launcher',
          largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          styleInformation: BigTextStyleInformation(
            notification.body ?? '',
            contentTitle: notification.title,
            summaryText: isGroupNotification ? groupName : notification.title,
          ),
          // Group settings for Android
          groupKey: isGroupNotification ? groupId : null,
          setAsGroupSummary: isGroupNotification,
          groupAlertBehavior: GroupAlertBehavior.all,
          playSound: true,
          enableLights: true,
          enableVibration: true,
          fullScreenIntent: true, // This helps with pop-up visibility
        );

    // iOS notification details with critical alert option
    final DarwinNotificationDetails iOSDetails = DarwinNotificationDetails(
      presentAlert: true, // Shows the notification banner
      presentBadge: true, // Updates the app's badge count
      presentSound: true, // Plays a sound
      sound: 'default', // Use the default sound
      badgeNumber: 1, // Set badge number
      // Group settings for iOS
      threadIdentifier: isGroupNotification ? groupId : null,
      interruptionLevel:
          InterruptionLevel.active, // High priority interruption level
    );

    // Combined platform-specific details
    final NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iOSDetails,
    );

    // Show the notification
    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      platformDetails,
      payload: message.data['payload'] ?? message.messageId,
    );
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final messageId =
        message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString();
    debugPrint('Handling foreground message: $messageId');

    // Forward to the message stream
    _onMessageController.add(message);

    // Save to repository
    final userId = _authService.userId;
    if (userId != null) {
      await _repository.saveNotification(
        message: message,
        userId: userId,
        appState: 'foreground',
      );
    }

    // Show local notification
    await _showLocalNotification(message);
  }

  Future<void> _handleMessageOpenedApp(RemoteMessage message) async {
    final messageId =
        message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString();
    debugPrint('Handling message opened app: $messageId');

    // Save to repository
    final userId = _authService.userId;
    if (userId != null) {
      await _repository.saveNotification(
        message: message,
        userId: userId,
        appState: 'background',
      );
    }

    // Navigate to notification history
    AppRouter.navigateToNotificationHistory();
  }

  Future<void> _handleInitialMessage(RemoteMessage message) async {
    final messageId =
        message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString();
    debugPrint('Handling initial message: $messageId');

    // Save to repository
    final userId = _authService.userId;
    if (userId != null) {
      await _repository.saveNotification(
        message: message,
        userId: userId,
        appState: 'terminated',
      );
    }

    // Update the app's last active timestamp
    await _authService.updateLastActive();

    // Navigate to notification history
    AppRouter.navigateToNotificationHistory();
  }

  void _onDidReceiveLocalNotification(
    int id,
    String? title,
    String? body,
    String? payload,
  ) {
    debugPrint('Received iOS local notification: $title');
    // This is only called on iOS versions < 10
  }

  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');

    // If payload contains messageId, process it accordingly
    if (response.payload != null) {
      // Here you can handle navigation or other actions
      // when notification is tapped
      AppRouter.navigateToNotificationHistory();
    }
  }

  Future<String?> getToken() async {
    return await _messaging.getToken();
  }

  Future<void> subscribeToTopic(String topic) async {
    final sanitizedTopic = _sanitizeTopicName(topic);
    await _messaging.subscribeToTopic(sanitizedTopic);
    debugPrint('Subscribed to topic: $sanitizedTopic');
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    final sanitizedTopic = _sanitizeTopicName(topic);
    await _messaging.unsubscribeFromTopic(sanitizedTopic);
    debugPrint('Unsubscribed from topic: $sanitizedTopic');
  }

  String _sanitizeTopicName(String topic) {
    // FCM topics can only contain: letters (a-zA-Z), numbers (0-9), underscores (_), and hyphens (-)
    return topic.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
  }

  Future<void> resetBadgeCount() async {
    if (Platform.isIOS) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
    }
  }

  void dispose() {
    _onMessageController.close();
  }
}
