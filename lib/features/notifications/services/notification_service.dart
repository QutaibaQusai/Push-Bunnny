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

  // Notification channel for Android with max importance
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

  // Store processed notification ids to prevent duplicates
  final Set<String> _processedNotificationIds = {};

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
    final DarwinInitializationSettings iOSSettings =
        DarwinInitializationSettings(
          requestSoundPermission: true,
          requestBadgePermission: true,
          requestAlertPermission: true,
          // Remove the deprecated onDidReceiveLocalNotification parameter
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

    // Create notification channel on Android with max importance
    await _createNotificationChannel();
  }

  Future<void> _createNotificationChannel() async {
    if (Platform.isAndroid) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(_channel);

      debugPrint('Android notification channel created with max importance');
    }
  }

  Future<void> _requestPermissions() async {
    // Request permission for iOS
    if (Platform.isIOS) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
            critical: true, // Request critical alerts for higher priority
          );

      // For iOS 10+ set presentation options
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true, // Shows the notification banner when in foreground
        badge: true, // Updates the app's badge count
        sound: true, // Plays a sound
      );
    }

    // Request FCM permissions with higher priority options
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: true, // Uses provisional authorization on iOS
      criticalAlert:
          true, // Request critical alert permission for high priority
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

    // Enable delivering messages in the background
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

    // Android notification details with max priority for heads-up display
    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
          visibility:
              NotificationVisibility.public, // Make visible on lock screen
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
          ticker: notification.title, // For accessibility services
          fullScreenIntent: true, // This is critical for heads-up display
          category: AndroidNotificationCategory.message, // Set as message type
        );

    // iOS notification details with critical alert option
    final DarwinNotificationDetails iOSDetails = DarwinNotificationDetails(
      presentAlert: true, // Shows the notification banner
      presentBadge: true, // Updates the app's badge count
      presentSound: true, // Plays a sound
      sound: 'default', // Use the default sound
      badgeNumber: 1, // Set badge number
      threadIdentifier: isGroupNotification ? groupId : null,
      interruptionLevel:
          InterruptionLevel.active, // High priority interruption level
      categoryIdentifier: "message", // Set as message category
    );

    // Combined platform-specific details
    final NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iOSDetails,
    );

    // Generate a unique ID for this notification based on the message ID
    final notificationId = message.messageId?.hashCode ?? notification.hashCode;

    // Show the notification
    await _localNotifications.show(
      notificationId,
      notification.title,
      notification.body,
      platformDetails,
      payload: message.data['payload'] ?? message.messageId,
    );

    debugPrint(
      'Local notification displayed with title: ${notification.title}',
    );
  }

  // Check if we've already processed this notification
  bool _hasProcessedNotification(String messageId) {
    return _processedNotificationIds.contains(messageId);
  }

  // Mark a notification as processed
  void _markNotificationAsProcessed(String messageId) {
    _processedNotificationIds.add(messageId);

    // Limit the set size to prevent memory issues
    if (_processedNotificationIds.length > 100) {
      _processedNotificationIds.remove(_processedNotificationIds.first);
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final messageId =
        message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString();
    debugPrint('Handling foreground message: $messageId');

    // Check if we've already processed this notification
    if (_hasProcessedNotification(messageId)) {
      debugPrint('Skipping already processed notification: $messageId');
      return;
    }

    // Mark as processed
    _markNotificationAsProcessed(messageId);

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

    // Check if we've already processed this notification
    if (_hasProcessedNotification(messageId)) {
      debugPrint('Skipping already processed notification: $messageId');
      return;
    }

    // Mark as processed
    _markNotificationAsProcessed(messageId);

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

    // Check if we've already processed this notification
    if (_hasProcessedNotification(messageId)) {
      debugPrint('Skipping already processed notification: $messageId');
      return;
    }

    // Mark as processed
    _markNotificationAsProcessed(messageId);

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

  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');

    // If payload contains messageId, process it accordingly
    if (response.payload != null) {
      // Navigate to notification history
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

  // Future<void> resetBadgeCount() async {
  //   if (Platform.isIOS) {
  //     // Use the correct method to reset badge count
  //     await _localNotifications
  //         .resolvePlatformSpecificImplementation<
  //           IOSFlutterLocalNotificationsPlugin
  //         >()
  //         ?.clearBadgeNumber();
  //   }
  // }

  void dispose() {
    _onMessageController.close();
  }
}
