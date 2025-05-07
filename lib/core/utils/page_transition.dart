import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';

class AppRouteTransitions {
  /// Creates a right to left transition for secondary screens
  static Route<dynamic> rightToLeftTransition(Widget page) {
    return PageTransition(
      type: PageTransitionType.rightToLeft,
      child: page,
      duration: const Duration(milliseconds: 300),
      reverseDuration: const Duration(milliseconds: 300),
    );
  }
  
  /// Creates a standard material transition for main screens
  static Route<dynamic> defaultTransition(Widget page) {
    return MaterialPageRoute(
      builder: (context) => page,
    );
  }
}