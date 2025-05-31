import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:push_bunnny/ui/theme/app_colors.dart';

class AppTextStyles {
  // Font sizes
  static const double h1 = 24.0;
  static const double h2 = 20.0;
  static const double h3 = 18.0;
  static const double bodyLarge = 16.0;
  static const double bodyMedium = 14.0;
  static const double bodySmall = 12.0;
  static const double caption = 11.0;

  // Font weights
  static const FontWeight bold = FontWeight.w700;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight regular = FontWeight.w400;

  // App bar
  static TextStyle get appBarTitle => GoogleFonts.inter(
        fontSize: h2,
        fontWeight: semiBold,
        color: Colors.white,
        letterSpacing: -0.3,
      );

  // Headings
  static TextStyle get heading1 => GoogleFonts.inter(
        fontSize: h1,
        fontWeight: bold,
        color: AppColors.textPrimary,
        letterSpacing: -0.5,
      );

  static TextStyle get heading2 => GoogleFonts.inter(
        fontSize: h2,
        fontWeight: semiBold,
        color: AppColors.textPrimary,
        letterSpacing: -0.3,
      );

  static TextStyle get heading3 => GoogleFonts.inter(
        fontSize: h3,
        fontWeight: medium,
        color: AppColors.textPrimary,
        letterSpacing: -0.2,
      );

  // Body text
  static TextStyle get bodyLargeStyle => GoogleFonts.inter(
        fontSize: bodyLarge,
        fontWeight: regular,
        color: AppColors.textPrimary,
        height: 1.4,
      );

  static TextStyle get bodyMediumStyle => GoogleFonts.inter(
        fontSize: bodyMedium,
        fontWeight: regular,
        color: AppColors.textSecondary,
        height: 1.3,
      );

  static TextStyle get bodySmallStyle => GoogleFonts.inter(
        fontSize: bodySmall,
        fontWeight: regular,
        color: AppColors.textTertiary,
        height: 1.2,
      );

  // Special styles


  static TextStyle get button => GoogleFonts.inter(
        fontSize: bodyMedium,
        fontWeight: semiBold,
        letterSpacing: 0.5,
      );

  static TextStyle get chipText => GoogleFonts.inter(
        fontSize: bodySmall,
        fontWeight: medium,
      );

  // Card styles
  static TextStyle get cardTitle => GoogleFonts.inter(
        fontSize: bodyMedium,
        fontWeight: medium,
        color: AppColors.textPrimary,
      );

  static TextStyle get cardSubtitle => GoogleFonts.inter(
        fontSize: bodySmall,
        fontWeight: regular,
        color: AppColors.textSecondary,
      );

  // Notification specific
  static TextStyle get notificationTitle => GoogleFonts.inter(
        fontSize: bodyMedium,
        fontWeight: medium,
        color: AppColors.textPrimary,
      );

  static TextStyle get notificationBody => GoogleFonts.inter(
        fontSize: bodySmall,
        fontWeight: regular,
        color: AppColors.textSecondary,
        height: 1.4,
      );

  static TextStyle get timestamp => GoogleFonts.inter(
        fontSize: caption,
        fontWeight: regular,
        color: AppColors.textTertiary,
      );

  // Monospace for tokens
  static TextStyle get monospace => GoogleFonts.robotoMono(
        fontSize: bodySmall,
        fontWeight: regular,
        color: AppColors.textPrimary,
        height: 1.3,
      );
}