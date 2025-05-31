import 'package:flutter/material.dart';
import 'package:push_bunnny/ui/screens/about_screen.dart';
import 'package:push_bunnny/ui/screens/notifications_screen.dart';
import 'package:push_bunnny/ui/screens/settings_screen.dart';


class AppRouter {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  // Route names
  static const String notifications = '/';
  static const String settings = '/settings';
  static const String about = '/about';

  // Route map
  static Map<String, WidgetBuilder> get routes => {
    notifications: (context) => const NotificationsScreen(),
    settings: (context) => const SettingsScreen(),
    about: (context) => const AboutScreen(),
  };

  // Navigation methods
  static void navigateToNotifications() {
    navigatorKey.currentState?.pushNamedAndRemoveUntil(
      notifications,
      (route) => false,
    );
  }

  static void navigateToSettings() {
    navigatorKey.currentState?.push(
      _createSlideTransition(const SettingsScreen()),
    );
  }

  static void navigateToAbout() {
    navigatorKey.currentState?.push(
      _createSlideTransition(const AboutScreen()),
    );
  }

  static void pop() {
    navigatorKey.currentState?.pop();
  }

  // Custom slide transition
  static Route<T> _createSlideTransition<T extends Object?>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: 300),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.ease;

        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }
}
