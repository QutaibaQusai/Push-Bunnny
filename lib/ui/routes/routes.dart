// lib/ui/routes/routes.dart
import 'package:flutter/material.dart';
import 'package:push_bunnny/core/utils/page_transition.dart';
import 'package:push_bunnny/ui/screens/about_screen.dart';
import 'package:push_bunnny/ui/screens/notification_history_screen.dart';
import 'package:push_bunnny/ui/screens/settings_screen.dart';


class AppRouter {
  // Global navigator key
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  
  // Named routes
  static const String home = '/';
  static const String notifications = '/notifications';
  static const String settings = '/settings';
  static const String about = '/about';
  
  // Route map for use with MaterialApp
  static Map<String, WidgetBuilder> routes = {
    home: (context) => const NotificationHistoryScreen(),
    notifications: (context) => const NotificationHistoryScreen(),
  };
  
  // Navigate to notification history screen
  static void navigateToNotificationHistory() {
    navigatorKey.currentState?.pushNamedAndRemoveUntil(
      notifications,
      (route) => false,
    );
  }
  
  // Navigate to settings screen with right-to-left transition
  static void navigateToSettings() {
    navigatorKey.currentState?.push(
      AppRouteTransitions.rightToLeftTransition(const SettingsScreen())
    );
  }
  
  // Navigate to about screen with right-to-left transition
  static void navigateToAbout() {
    navigatorKey.currentState?.push(
      AppRouteTransitions.rightToLeftTransition(const AboutScreen())
    );
  }
}