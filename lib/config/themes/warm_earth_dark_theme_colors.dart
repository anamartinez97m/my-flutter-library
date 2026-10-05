import 'package:flutter/material.dart';

// Warm Earth DarkTheme color palette.
// Same tokens as V2Colors (lib/config/v2_design_system.dart) so the two can be
// swapped; values come from the Figma "Warm Earth DarkTheme" frame.
// Tokens marked "derived" have no counterpart in that frame.
abstract final class V2WarmEarthDarkColors {
  // Backgrounds and surfaces
  static const background = Color(0xFF393E46);
  static const surface = Color(0xFF222831);
  static const surfaceWarm = Color(0xFF222831);
  static const surfaceAlt = Color(0xFF222831);
  static const surfaceMuted = Color(0xFF2C2928);
  static const surfaceTimer = Color(0xFF2C2928);
  static const shimmerBase = Color(0xFF373433);
  static const borderDialog = Color(0xFFD5C2BF);
  static const buttonText = Color(0xFF4E2423);

  // Brand colors
  static const primary = Color(0xFFD4BAB9);
  static const primaryAlt = Color(0xFFD7C2C0);
  static const secondary = Color(0xFFF8B6B3);

  // Text colors
  static const textPrimary = Color(0xFFD4BAB9);
  static const textStrong = Color(0xFFF4EEED);
  static const textSecondary = Color(0xFFD7C2C0);
  static const textSubtle = Color(0xCCD4BAB9); // derived
  static const textMuted = Color(0xB3D7C2C0); // derived
  static const textMutedAlt = Color(0x99D7C2C0); // derived

  // Borders, dividers, and controls
  static const border = Color(0xFFD5C2BF);
  static const borderStrong = Color(0xFFF4EEED); // derived
  static const borderNeutral = Color(0xFFD5C2BF);
  static const borderInput = Color(0xFFD5C2BF);
  static const borderSoft = Color(0x33524342);
  static const divider = Color(0xFF373433);
  static const chip = Color(0xFF222831);
  static const control = Color(0xFFF4EEED);
  static const error = Color(0xFFFFB4AB); // derived
  static const success = Color(0xFF34D399); // derived
  static const successBackground = Color(0xFF064E3B); // derived
  static const successBorder = Color(0xFF047857); // derived
  static const warning = Color(0xFFFFD27A); // derived
  static const warningBackground = Color(0xFF3D2E00); // derived
  static const warningBorder = Color(0xFF8A6D1F); // derived
  static const disabled = Color(0xFF6B6F76); // derived

  // Warm Earth DarkTheme-only colors (no V2Colors equivalent)
  static const onPrimary = Color(0xFF4E2423);
  static const navBarBackground = Color(0xCC393E46);
  static const searchBackground = Color(0xFF222831);
  static const chipSelected = Color(0xFFD4BAB9);
  static const chipText = Color(0xFFD7C2C0);
  static const chipTextSelected = Color(0xFF4E2423);
  static const cardTitle = Color(0xFFD4BAB9);
  static const cardMeta = Color(0xFFD4BAB9);
  static const navActiveIcon = Color(0xFFD4BAB9);
  static const navInactiveIcon = Color(0xFFD4BAB9);
  static const filterFabIcon = Color(0xFFE7E1DF);
  static const rating = Color(0xFFCA8A04);
  static const saga = Color(0xB3F8B6B3);
  static const fabShadow = Color(0x2643102B);
  static const filterFabShadow = Color(0x1A000000);
}

// Warm Earth DarkTheme shadow recipes, mirroring V2Shadows.
abstract final class V2WarmEarthDarkShadows {
  static const subtle = [
    BoxShadow(color: Color(0x0A000000), blurRadius: 6, offset: Offset(0, 3)),
  ];
  static const card = [
    BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 2)),
  ];
}
