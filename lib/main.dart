import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:push_bunnny/core/config/firebase_options.dart';
import 'package:push_bunnny/core/services/app_initializer.dart';
import 'package:push_bunnny/core/services/notification_handler.dart';
import 'package:push_bunnny/features/groups/providers/group_provider.dart';
import 'package:push_bunnny/features/notifications/providers/notification_provider.dart';
import 'package:push_bunnny/ui/app.dart';

// Simple background message handler - server handles saving
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationHandler.handleBackgroundMessage(message);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialize Firebase
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    
    // Set background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    
    // Initialize app services
    await AppInitializer.initialize();
    
  } catch (e) {
    debugPrint('❌ Error during app initialization: $e');
  }
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => GroupProvider()),
      ],
      child: const PushBunnyApp(),
    ),
  );
}