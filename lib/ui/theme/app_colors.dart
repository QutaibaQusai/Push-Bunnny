import 'package:flutter/material.dart';

class AppColors {
  // Primary colors
  static const primary = Color(0xFFFF8000); // Warm orange
  static const secondary = Color(0xFFFFB300); // Golden yellow
  static const accent = Color(0xFFFFF176); // Light yellow

  // Background colors
  static const background = Color(0xFFFFFDF7); // Warm white
  static const card = Color(0xFFFFFFFF); // Pure white
  static const surface = Color(0xFFFAFAFA); // Light gray

  // Text colors
  static const textPrimary = Color(0xFF2A2A2A); // Soft black
  static const textSecondary = Color(0xFF525252); // Medium gray
  static const textTertiary = Color(0xFF767676); // Light gray

  // Status colors
  static const success = Color(0xFF4CAF50); // Green
  static const error = Color(0xFFE57373); // Soft red
  static const warning = Color(0xFFFFB74D); // Orange
  static const info = Color(0xFF64B5F6); // Blue

  // Shadow and overlay
  static const shadow = Color(0xFFFFEFD6); // Warm shadow
  static const overlay = Color(0x80000000); // Semi-transparent black

  // Gradients
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

  // Helper methods for opacity variants
  static Color primaryWithOpacity(double opacity) => primary.withOpacity(opacity);
  static Color secondaryWithOpacity(double opacity) => secondary.withOpacity(opacity);
  static Color accentWithOpacity(double opacity) => accent.withOpacity(opacity);
}