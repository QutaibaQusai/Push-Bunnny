import 'package:flutter/material.dart';

class AppColors {
  // Refined color palette based on the rabbit logo
  static const primary = Color(0xFFFF8000); // Warm orange - less harsh
  static const secondary = Color(0xFFFFB300); // Golden yellow - softer
  static const accent = Color(0xFFFFF176); // Light yellow - for highlights

  // Softer background colors
  static const background = Color(
    0xFFFFFDF7,
  ); // Warm white - easier on the eyes
  static const card = Color(0xFFFFFFFF); // Pure white for content areas

  // Refined text colors for better readability
  static const textPrimary = Color(0xFF2A2A2A); // Soft black for primary text
  static const textSecondary = Color(
    0xFF525252,
  ); // Medium gray for secondary text
  static const textTertiary = Color(0xFF767676); // Light gray for tertiary text

  // Refined accent colors
  static const shadow = Color(0xFFFFEFD6); // Warmer shadow color
  static const success = Color(0xFF4CAF50); // Green for success states
  static const error = Color(0xFFE57373); // Soft red for errors

  // Sophisticated gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFFFD54F), Color(0xFFFF8A00)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient subtleGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFFFF8E8)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFFFFD54F), Color(0xFFFFB74D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Translucent colors for overlays and highlights
  static Color primaryLight = primary.withOpacity(0.12);
  static Color secondaryLight = secondary.withOpacity(0.15);
  static Color accentLight = accent.withOpacity(0.2);
}
