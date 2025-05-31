import 'package:flutter/foundation.dart';
import 'package:push_bunnny/core/services/auth_service.dart';
import 'package:push_bunnny/core/services/notification_handler.dart';
import 'package:push_bunnny/core/services/storage_service.dart';

class AppInitializer {
  static Future<void> initialize() async {
    try {
      debugPrint('🚀 Initializing Push Bunny App...');

      // Initialize Firestore storage service (no actual initialization needed)
      await StorageService.instance.initialize();
      debugPrint('✅ Firestore storage ready');

      // Initialize auth and get/create user
      await AuthService.instance.initialize();
      debugPrint('✅ Auth initialized');

      // Initialize notification handling
      await NotificationHandler.instance.initialize();
      debugPrint('✅ Notifications initialized');

      debugPrint('🎉 App initialization complete!');
    } catch (e) {
      debugPrint('❌ App initialization failed: $e');
      rethrow;
    }
  }
}
