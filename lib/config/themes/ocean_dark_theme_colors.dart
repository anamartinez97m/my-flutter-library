import 'package:flutter/material.dart';

// Ocean DarkTheme color palette.
// Same tokens as V2Colors (lib/config/v2_design_system.dart) so the two can be
// swapped; values come from the Figma "Ocean DarkTheme" frame.
// Tokens marked "derived" have no counterpart in that frame.
abstract final class V2OceanDarkColors {
  // Backgrounds and surfaces
  static const background = Color(0xFF393E46);
  static const surface = Color(0xFF222831);
  static const surfaceWarm = Color(0xFF222831);
  static const surfaceAlt = Color(0xFF222831);
  static const surfaceMuted = Color(0xFF272A2C);
  static const surfaceTimer = Color(0xFF272A2C);
  static const shimmerBase = Color(0xFF323536);
  static const borderDialog = Color(0xFFBAC9CD);
  static const buttonText = Color(0xFF00363A);

  // Brand colors
  static const primary = Color(0xFFABC5C8);
  static const primaryAlt = Color(0xFFC5C6CB);
  static const secondary = Color(0xFF6AD6E0);

  // Text colors
  static const textPrimary = Color(0xFFABC5C8);
  static const textStrong = Color(0xFFEAF0F1);
  static const textSecondary = Color(0xFFC5C6CB);
  static const textSubtle = Color(0xCCABC5C8); // derived
  static const textMuted = Color(0xB3C5C6CB); // derived
  static const textMutedAlt = Color(0x99C5C6CB); // derived

  // Borders, dividers, and controls
  static const border = Color(0xFFBAC9CD);
  static const borderStrong = Color(0xFFEAF0F1); // derived
  static const borderNeutral = Color(0xFFBAC9CD);
  static const borderInput = Color(0xFFBAC9CD);
  static const borderSoft = Color(0x3345474B);
  static const divider = Color(0xFF323536);
  static const chip = Color(0xFF222831);
  static const control = Color(0xFFEAF0F1);
  static const error = Color(0xFFFFB4AB); // derived
  static const success = Color(0xFF34D399); // derived
  static const successBackground = Color(0xFF064E3B); // derived
  static const successBorder = Color(0xFF047857); // derived
  static const warning = Color(0xFFFFD27A); // derived
  static const warningBackground = Color(0xFF3D2E00); // derived
  static const warningBorder = Color(0xFF8A6D1F); // derived
  static const disabled = Color(0xFF6B6F76); // derived

  // Ocean DarkTheme-only colors (no V2Colors equivalent)
  static const onPrimary = Color(0xFF00363A);
  static const navBarBackground = Color(0xCC393E46);
  static const searchBackground = Color(0xFF222831);
  static const chipSelected = Color(0xFFABC5C8);
  static const chipText = Color(0xFFC5C6CB);
  static const chipTextSelected = Color(0xFF00363A);
  static const cardTitle = Color(0xFFABC5C8);
  static const cardMeta = Color(0xFFABC5C8);
  static const navActiveIcon = Color(0xFFABC5C8);
  static const navInactiveIcon = Color(0xFFABC5C8);
  static const filterFabIcon = Color(0xFFE1E3E4);
  static const rating = Color(0xFFCA8A04);
  static const saga = Color(0xB36AD6E0);
  static const fabShadow = Color(0x2600666E);
  static const filterFabShadow = Color(0x1A000000);
}

// Ocean DarkTheme shadow recipes, mirroring V2Shadows.
abstract final class V2OceanDarkShadows {
  static const subtle = [
    BoxShadow(color: Color(0x0A000000), blurRadius: 6, offset: Offset(0, 3)),
  ];
  static const card = [
    BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 2)),
  ];
}
