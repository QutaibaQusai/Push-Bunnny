import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppFonts {
  // Font sizes
  static const double heading1 = 18.0;
  static const double heading2 = 16.0;
  static const double heading3 = 14.0;
  static const double bodyLarge = 14.0;
  static const double bodyMedium = 12.0;
  static const double bodySmall = 11.0;
  static const double caption = 10.0;
  static const double small = 9.0;

  // Font weights
  static const FontWeight bold = FontWeight.w700;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight regular = FontWeight.w400;

  // Line heights
  static const double lineHeightTight = 1.15;
  static const double lineHeightNormal = 1.25;
  static const double lineHeightRelaxed = 1.4;

  // Letter spacing
  static const double letterSpacingTight = -0.3;
  static const double letterSpacingNormal = -0.2;
  static const double letterSpacingWide = 0.0;

  // App bar title
  static TextStyle get appBarTitle => GoogleFonts.inter(
    fontSize: heading2,
    fontWeight: medium,
    letterSpacing: letterSpacingTight,
    color: Colors.white,
  );

  // Section title (e.g., "Notification Settings")
  static TextStyle get sectionTitle => GoogleFonts.inter(
    fontSize: bodyMedium,
    fontWeight: medium,
    letterSpacing: letterSpacingNormal,
    height: lineHeightTight,
    color: const Color(0xFF075E54),
  );

  // Card title (e.g., "Device Token")
  static TextStyle get cardTitle => GoogleFonts.inter(
    fontSize: bodyMedium,
    fontWeight: medium,
    letterSpacing: letterSpacingNormal,
    height: lineHeightTight,
    color: Colors.black87,
  );

  // Card subtitle (e.g., "Receive push notifications...")
  static TextStyle get cardSubtitle => GoogleFonts.inter(
    fontSize: bodySmall,
    fontWeight: regular,
    letterSpacing: letterSpacingNormal,
    height: lineHeightNormal,
    color: Colors.grey.shade600,
  );

  // Copy button style (e.g., "Copy", "Copied")
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
  );

  // Token hint (e.g., "Tap to copy your device token")
  static TextStyle get tokenHint => GoogleFonts.inter(
    fontSize: caption,
    fontWeight: regular,
    letterSpacing: letterSpacingTight,
    height: lineHeightNormal,
    color: Colors.grey.shade500,
  );

  // Timestamp for chat messages
  static TextStyle get timeStamp => GoogleFonts.inter(
    fontSize: caption,
    fontWeight: regular,
    color: Colors.grey.shade600,
    letterSpacing: letterSpacingNormal,
  );

  // Chat message text
  static TextStyle get chatMessageText => GoogleFonts.inter(
    fontSize: bodyMedium,
    fontWeight: regular,
    height: lineHeightNormal,
    color: Colors.black87,
    letterSpacing: letterSpacingNormal,
  );

  // Generic list item title
  static TextStyle get listItemTitle => GoogleFonts.inter(
    fontSize: bodyMedium,
    fontWeight: medium,
    height: lineHeightTight,
    letterSpacing: letterSpacingNormal,
    color: Colors.black87,
  );

  // Generic list item subtitle
  static TextStyle get listItemSubtitle => GoogleFonts.inter(
    fontSize: bodySmall,
    fontWeight: regular,
    height: lineHeightNormal,
    color: Colors.grey.shade600,
    letterSpacing: letterSpacingNormal,
  );
}
