import 'package:flutter/material.dart';

// Main DarkTheme color palette.
// Same tokens as V2Colors (lib/config/v2_design_system.dart) so the two can be
// swapped; values come from the Figma "Main DarkTheme" frame.
// Tokens marked "derived" have no counterpart in that frame.
abstract final class V2MainDarkColors {
  // Backgrounds and surfaces
  static const background = Color(0xFF393E46);
  static const surface = Color(0xFF222831);
  static const surfaceWarm = Color(0xFF222831);
  static const surfaceAlt = Color(0xFF222831);
  static const surfaceMuted = Color(0xFF2A2A29);
  static const surfaceTimer = Color(0xFF2A2A29);
  static const shimmerBase = Color(0xFF2A2D33);
  static const borderDialog = Color(0xFFD0C4BE);
  static const buttonText = Color(0xFF4D213A);

  // Brand colors
  static const primary = Color(0xFFB9A2AB);
  static const primaryAlt = Color(0xFFD4C2C8);
  static const secondary = Color(0xFFF6B5D4);

  // Text colors
  static const textPrimary = Color(0xFFE4E4E7);
  static const textStrong = Color(0xFFEDE7E9);
  static const textSecondary = Color(0xFFD4C2C8);
  static const textSubtle = Color(0xCCE4E4E7); // derived
  static const textMuted = Color(0xB3D4C2C8); // derived
  static const textMutedAlt = Color(0x99D4C2C8); // derived

  // Borders, dividers, and controls
  static const border = Color(0xFFD0C4BE);
  static const borderStrong = Color(0xFFEDE7E9); // derived
  static const borderNeutral = Color(0xFFD0C4BE);
  static const borderInput = Color(0xFFD1C5BF);
  static const borderSoft = Color(0x33504348);
  static const divider = Color(0xFF2A2D33);
  static const chip = Color(0xFF222831);
  static const control = Color(0xFFEDE7E9);
  static const error = Color(0xFFFFB4AB); // derived
  static const success = Color(0xFF34D399); // derived
  static const successBackground = Color(0xFF064E3B); // derived
  static const successBorder = Color(0xFF047857); // derived
  static const warning = Color(0xFFFFD27A); // derived
  static const warningBackground = Color(0xFF3D2E00); // derived
  static const warningBorder = Color(0xFF8A6D1F); // derived
  static const disabled = Color(0xFF6B6F76); // derived

  // Main DarkTheme-only colors (no V2Colors equivalent)
  static const onPrimary = Color(0xFF4D213A);
  static const navBarBackground = Color(0xCC393E46);
  static const searchBackground = Color(0xFF222831);
  static const chipSelected = Color(0xFFB9A2AB);
  static const chipText = Color(0xFFD4C2C8);
  static const chipTextSelected = Color(0xFF4D213A);
  static const cardTitle = Color(0xFFB9A2AB);
  static const cardMeta = Color(0xFFE4E4E7);
  static const navActiveIcon = Color(0xFFB9A2AB);
  static const navInactiveIcon = Color(0xFFB9A2AB);
  static const filterFabIcon = Color(0xFFB9A2AB);
  static const rating = Color(0xFFCA8A04);
  static const saga = Color(0xB3F6B5D4);
  static const fabShadow = Color(0x2643102B);
  static const filterFabShadow = Color(0x1A000000);
}

// Main DarkTheme shadow recipes, mirroring V2Shadows.
abstract final class V2MainDarkShadows {
  static const subtle = [
    BoxShadow(color: Color(0x0A000000), blurRadius: 6, offset: Offset(0, 3)),
  ];
  static const card = [
    BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 2)),
  ];
}
