import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:push_bunnny/auth_service.dart';
import 'package:push_bunnny/migration_helper.dart';
import 'package:push_bunnny/repositories/notification_repository.dart.dart';
import 'package:push_bunnny/screens/notification_history_screen.dart';
import 'package:push_bunnny/services/data_sync_servic.dart';
import 'package:push_bunnny/services/hive_database_service.dart';
import 'firebase_options.dart';

// Global navigator key
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize Hive for background handler
  final hiveService = HiveDatabaseService();
  await hiveService.initHive();

  // Save notification to Firestore even when app is in background
  await saveNotificationToFirestore(message, 'background');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase first
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Set up background message handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Initialize Hive for local storage
  final hiveService = HiveDatabaseService();
  await hiveService.initHive();

  // Initialize AuthService to ensure we have a user ID ready
  final authService = AuthService();
  final userId = await authService.getUserId();

  // Set up token refresh listener and update the device info
  authService.setupTokenRefreshListener();
  await authService.updateDeviceInfo();

  // Perform migration if needed
  await MigrationHelper.migrateUserData(userId);

  // Initialize notification repository
  final notificationRepository = NotificationRepository();
  await notificationRepository.initialize();

  // Initialize data sync service for offline support
  final dataSyncService = DataSyncService();
  await dataSyncService.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(debugShowCheckedModeBanner: false, navigatorKey: navigatorKey, title: 'Push Bunny', theme: ThemeData(primarySwatch: Colors.orange, visualDensity: VisualDensity.adaptivePlatformDensity, appBarTheme: const AppBarTheme(backgroundColor: Colors.transparent, elevation: 0)), home: NotificationHistoryScreen());
  }
}
