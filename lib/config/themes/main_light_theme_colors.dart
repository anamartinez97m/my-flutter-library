import 'package:flutter/material.dart';

// Main LightTheme color palette (the original v2 design system values).
// Same tokens as the other theme palettes so they can be swapped.
abstract final class V2MainLightColors {
  // Backgrounds and surfaces
  static const background = Color(0xFFFDF8F6);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceWarm = Color(0xFFFFFCFA);
  static const surfaceAlt = Color(0xFFFFFBFA);
  static const surfaceMuted = Color(0xFFF5F3F2);
  static const surfaceTimer = Color(0xFFF7F3F0);
  static const shimmerBase = Color(0xFFF2E8E3);
  static const borderDialog = Color(0xFFDDD9D7);
  static const buttonText = Color(0xFFD68DAC);

  // Brand colors
  static const primary = Color(0xFF43102B);
  static const primaryAlt = Color(0xFF5D2641);
  static const secondary = Color(0xFF894B67);

  // Text colors
  static const textPrimary = Color(0xFF1C1B1A);
  static const textStrong = Color(0xFF270008);
  static const textSecondary = Color(0xFF514348);
  static const textSubtle = Color(0xFF5F5E5C);
  static const textMuted = Color(0xFF76656B);
  static const textMutedAlt = Color(0xFF7A6A71);

  // Borders, dividers, and controls
  static const border = Color(0xFFD5C2C7);
  static const borderStrong = Color(0xFF27231E);
  static const borderNeutral = Color(0xFFCEC5BE);
  static const borderInput = Color(0xFF6B7280);
  static const borderSoft = Color(0xFFE8E2DE);
  static const divider = Color(0xFFE6E2DF);
  static const chip = Color(0xFFF2EDEB);
  static const control = Color(0xFFECE7E5);
  static const error = Color(0xFFBA1A1A);
  static const success = Color(0xFF059669);
  static const successBackground = Color(0xFFECFDF5);
  static const successBorder = Color(0xFFA7F3D0);
  static const warning = Color(0xFF7A4D00);
  static const warningBackground = Color(0xFFFFF4D9);
  static const warningBorder = Color(0xFFE5C46B);
  static const disabled = Color(0xFFB8B0B3);

  // Main LightTheme-only colors (no V2Colors equivalent)
  static const onPrimary = Color(0xFFFFFFFF);
  static const navBarBackground = Color(0xCCFDF8F6);
  static const searchBackground = Color(0xFFFFFFFF);
  static const chipSelected = Color(0xE643102B);
  static const chipText = Color(0xFF514348);
  static const chipTextSelected = Color(0xFFFFFFFF);
  static const cardTitle = Color(0xFF1C1B1A);
  static const cardMeta = Color(0xFF5F5E5C);
  static const navActiveIcon = Color(0xFF43102B);
  static const navInactiveIcon = Color(0xFF514348);
  static const filterFabIcon = Color(0xFF43102B);
  static const rating = Color(0xFFCA8A04);
  static const saga = Color(0xB3D68DAC);
  static const fabShadow = Color(0x2643102B);
  static const filterFabShadow = Color(0x1A000000);
}
