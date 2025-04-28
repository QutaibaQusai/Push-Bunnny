import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:push_bunnny/constants/app_colors.dart';

class AppFonts {
  // Font sizes remain the same
  static const double heading1 = 18.0;
  static const double heading2 = 16.0;
  static const double heading3 = 14.0;
  static const double bodyLarge = 14.0;
  static const double bodyMedium = 12.0;
  static const double bodySmall = 11.0;
  static const double caption = 10.0;
  static const double small = 9.0;

  // Font weights remain the same
  static const FontWeight bold = FontWeight.w700;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight regular = FontWeight.w400;

  // Line heights remain the same
  static const double lineHeightTight = 1.15;
  static const double lineHeightNormal = 1.25;
  static const double lineHeightRelaxed = 1.4;

  // Letter spacing remains the same
  static const double letterSpacingTight = -0.3;
  static const double letterSpacingNormal = -0.2;
  static const double letterSpacingWide = 0.0;

  // App bar title
  static TextStyle get appBarTitle => GoogleFonts.inter(
    fontSize: heading2,
    fontWeight: semiBold,
    letterSpacing: letterSpacingTight,
    color: Colors.white,
  );

  // Section title (e.g., "Notification Settings")
  static TextStyle get sectionTitle => GoogleFonts.inter(
    fontSize: bodyMedium,
    fontWeight: semiBold,
    letterSpacing: letterSpacingNormal,
    height: lineHeightTight,
    color: AppColors.primary,
  );

  // Card title (e.g., "Device Token")
  static TextStyle get cardTitle => GoogleFonts.inter(
    fontSize: bodyMedium,
    fontWeight: medium,
    letterSpacing: letterSpacingNormal,
    height: lineHeightTight,
    color: AppColors.textPrimary,
  );

  // Card subtitle (e.g., "Receive push notifications...")
  static TextStyle get cardSubtitle => GoogleFonts.inter(
    fontSize: bodySmall,
    fontWeight: regular,
    letterSpacing: letterSpacingNormal,
    height: lineHeightNormal,
    color: AppColors.textSecondary,
  );

  static TextStyle get copyButton => GoogleFonts.inter(
    fontSize: caption,
    fontWeight: semiBold,
    letterSpacing: letterSpacingTight,
  );

  // Snackbar text
  static TextStyle get snackBar => GoogleFonts.inter(
    fontSize: bodySmall,
    fontWeight: medium,
    letterSpacing: letterSpacingTight,
    color: Colors.white,
  );

  // Monospace token display
  static TextStyle get monospace => GoogleFonts.robotoMono(
    fontSize: bodySmall,
    height: lineHeightNormal,
    letterSpacing: letterSpacingTight,
    color: AppColors.textPrimary,
  );

  // Token hint (e.g., "Tap to copy your device token")
  static TextStyle get tokenHint => GoogleFonts.inter(
    fontSize: caption,
    fontWeight: regular,
    letterSpacing: letterSpacingTight,
    height: lineHeightNormal,
    color: AppColors.textTertiary,
  );

  // Timestamp for chat messages
  static TextStyle get timeStamp => GoogleFonts.inter(
    fontSize: caption,
    fontWeight: regular,
    color: AppColors.textTertiary,
    letterSpacing: letterSpacingNormal,
  );

  // Chat message text
  static TextStyle get chatMessageText => GoogleFonts.inter(
    fontSize: bodyMedium,
    fontWeight: regular,
    height: lineHeightNormal,
    color: AppColors.textPrimary,
    letterSpacing: letterSpacingNormal,
  );

  // Generic list item title
  static TextStyle get listItemTitle => GoogleFonts.inter(
    fontSize: bodyMedium,
    fontWeight: medium,
    height: lineHeightTight,
    letterSpacing: letterSpacingNormal,
    color: AppColors.textPrimary,
  );

  // Generic list item subtitle
  static TextStyle get listItemSubtitle => GoogleFonts.inter(
    fontSize: bodySmall,
    fontWeight: regular,
    height: lineHeightNormal,
    color: AppColors.textSecondary,
    letterSpacing: letterSpacingNormal,
  );
}
