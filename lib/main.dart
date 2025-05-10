import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:push_bunnny/core/config/firebase_options.dart';
import 'package:push_bunnny/core/services/local_storage_service.dart';
import 'package:push_bunnny/core/utils/snackbar_helper.dart';
import 'package:push_bunnny/features/auth/services/auth_service.dart';
import 'package:push_bunnny/features/notifications/providers/notification_provider.dart';
import 'package:push_bunnny/features/notifications/repositories/notification_repository.dart';
import 'package:push_bunnny/features/notifications/services/notification_service.dart';
import 'package:push_bunnny/ui/routes/routes.dart';
import 'package:push_bunnny/ui/screens/about_screen.dart';
import 'package:push_bunnny/ui/screens/notification_history_screen.dart';
import 'package:push_bunnny/ui/screens/settings_screen.dart';
import 'package:push_bunnny/ui/theme/app_theme.dart';

// Background message handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    final String messageId =
        message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString();
    debugPrint('Background message received: $messageId');

    // Check if this is a group notification
    final bool isGroupNotification = message.data.containsKey('groupId');
    if (isGroupNotification) {
      debugPrint(
        'Background message is a group notification for group: ${message.data['groupId']}',
      );
    }

    // Initialize local storage
    final storageService = LocalStorageService();
    await storageService.initialize();

    // Check for duplicate notifications before saving
    if (storageService.hasNotificationWithMessageId(messageId)) {
      debugPrint(
        'Background message already exists in storage, skipping: $messageId',
      );
      return;
    }

    // Get userId
    final authService = AuthService();
    await authService.initialize();
    final userId = authService.userId;

    if (userId != null) {
      // Save notification
      final repository = NotificationRepository();
      await repository.saveNotification(
        message: message,
        userId: userId,
        appState: 'background',
      );

      debugPrint('Background notification saved for userId: $userId');
    }
  } catch (e) {
    debugPrint('Error in background message handler: $e');
  }
}

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Set up background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialize services in correct order
  final storageService = LocalStorageService();
  await storageService.initialize();

  final authService = AuthService();
  await authService.initialize();

  final notificationService = NotificationService();
  await notificationService.initialize();

  // Log current FCM token for debugging
  final token = await FirebaseMessaging.instance.getToken();
  debugPrint('FCM Token: ${token?.substring(0, 10)}...');

  // Configure route names
  AppRouter.routes = {
    // Don't include home route since we're using 'home' in MaterialApp
    AppRouter.notifications: (context) => const NotificationHistoryScreen(),
    AppRouter.settings: (context) => const SettingsScreen(),
    AppRouter.about: (context) => const AboutScreen(),
  };

  // Add debug logs
  debugPrint('App initialized successfully');

  // Run the app
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Push Bunny',
      theme: AppTheme.lightTheme,
      navigatorKey: AppRouter.navigatorKey,
            scaffoldMessengerKey: SnackbarHelper.scaffoldMessengerKey, 

      home: const NotificationHistoryScreen(),
      routes: AppRouter.routes,
    );
  }
}
