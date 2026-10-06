import 'package:flutter/material.dart';

// Royal DarkTheme color palette.
// Same tokens as V2Colors (lib/config/v2_design_system.dart) so the two can be
// swapped; values come from the Figma "Royal DarkTheme" frame.
// Tokens marked "derived" have no counterpart in that frame.
abstract final class V2RoyalDarkColors {
  // Backgrounds and surfaces
  static const background = Color(0xFF393E46);
  static const surface = Color(0xFF222831);
  static const surfaceWarm = Color(0xFF222831);
  static const surfaceAlt = Color(0xFF222831);
  static const surfaceMuted = Color(0xFF090D14);
  static const surfaceTimer = Color(0xFF090D14);
  static const shimmerBase = Color(0xFF8FA4D6);
  static const borderDialog = Color(0xFFE2E5EA);
  static const buttonText = Color(0xFF7185B5);

  // Brand colors
  static const primary = Color(0xFFC4CAD6);
  static const primaryAlt = Color(0xFFE2E5EA);
  static const secondary = Color(0xFFE2E5EA);

  // Text colors
  static const textPrimary = Color(0xFFC4CAD6);
  static const textStrong = Color(0xFFEAEBEF);
  static const textSecondary = Color(0xFFE2E5EA);
  static const textSubtle = Color(0xCCC4CAD6); // derived
  static const textMuted = Color(0xB3E2E5EA); // derived
  static const textMutedAlt = Color(0x99E2E5EA); // derived

  // Borders, dividers, and controls
  static const border = Color(0xFFE2E5EA);
  static const borderStrong = Color(0xFFEAEBEF); // derived
  static const borderNeutral = Color(0xFFE2E5EA);
  static const borderInput = Color(0xFFE2E5EA);
  static const borderSoft = Color(0x33191E27);
  static const divider = Color(0xFF8FA4D6);
  static const chip = Color(0xFF0F131A);
  static const control = Color(0xFFEAEBEF);
  static const error = Color(0xFFFFB4AB); // derived
  static const success = Color(0xFF34D399); // derived
  static const successBackground = Color(0xFF064E3B); // derived
  static const successBorder = Color(0xFF047857); // derived
  static const warning = Color(0xFFFFD27A); // derived
  static const warningBackground = Color(0xFF3D2E00); // derived
  static const warningBorder = Color(0xFF8A6D1F); // derived
  static const disabled = Color(0xFF6B6F76); // derived

  // Royal DarkTheme-only colors (no V2Colors equivalent)
  static const onPrimary = Color(0xFF7185B5);
  static const navBarBackground = Color(0xFF393E46);
  static const searchBackground = Color(0xFF393E46);
  static const chipSelected = Color(0xFFE2E5EA);
  static const chipText = Color(0xFFE2E5EA);
  static const chipTextSelected = Color(0xFF2E3A59);
  static const cardTitle = Color(0xFFC4CAD6);
  static const cardMeta = Color(0xFFC4CAD6);
  static const navActiveIcon = Color(0xFFC4CAD6);
  static const navInactiveIcon = Color(0xFFC4CAD6);
  static const filterFabIcon = Color(0xCCF0F2F7);
  static const rating = Color(0xFFE2E5EA);
  static const saga = Color(0xB3E2E5EA);
  static const fabShadow = Color(0x2643102B);
  static const filterFabShadow = Color(0x1A000000);
}

// Royal DarkTheme shadow recipes, mirroring V2Shadows.
abstract final class V2RoyalDarkShadows {
  static const subtle = [
    BoxShadow(color: Color(0x0A000000), blurRadius: 6, offset: Offset(0, 3)),
  ];
  static const card = [
    BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 2)),
  ];
}
