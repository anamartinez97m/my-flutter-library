import 'package:flutter/material.dart';

// Warm Earth LightTheme color palette.
// Same tokens as V2Colors (lib/config/v2_design_system.dart) so the two can be
// swapped; values come from the Figma "Warm Earth LightTheme" frame.
// Tokens marked "derived" have no counterpart in that frame; status colors and
// `disabled` reuse the V2Colors values.
abstract final class V2WarmEarthLightColors {
  // Backgrounds and surfaces
  static const background = Color(0xFFFCF9F8);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceWarm = Color(0xFFFFFFFF);
  static const surfaceAlt = Color(0xFFFFFFFF);
  static const surfaceMuted = Color(0xFFEAE7E7);
  static const surfaceTimer = Color(0xFFEAE7E7);
  static const shimmerBase = Color(0xFFE5E2E1);
  static const borderDialog = Color(0xFFD5C2BF);
  static const buttonText = Color(0xFFFFFFFF);

  // Brand colors
  static const primary = Color(0xFF864B4A);
  static const primaryAlt = Color(0xFF7C5450);
  static const secondary = Color(0xFF864B4A);

  // Text colors
  static const textPrimary = Color(0xFF1B1C1B);
  static const textStrong = Color(0xFF1B1C1B);
  static const textSecondary = Color(0xFF524342);
  static const textSubtle = Color(0xCC1B1C1B); // derived
  static const textMuted = Color(0xB3524342); // derived
  static const textMutedAlt = Color(0x99524342); // derived

  // Borders, dividers, and controls
  static const border = Color(0xFFD5C2BF);
  static const borderStrong = Color(0xFF1B1C1B); // derived
  static const borderNeutral = Color(0xFFD5C2BF);
  static const borderInput = Color(0xFF675957);
  static const borderSoft = Color(0x33D7C2C0);
  static const divider = Color(0xFFE5E2E1);
  static const chip = Color(0xFFFFFFFF);
  static const control = Color(0xFFFFB3B0);
  static const error = Color(0xFFBA1A1A); // derived
  static const success = Color(0xFF059669); // derived
  static const successBackground = Color(0xFFECFDF5); // derived
  static const successBorder = Color(0xFFA7F3D0); // derived
  static const warning = Color(0xFF7A4D00); // derived
  static const warningBackground = Color(0xFFFFF4D9); // derived
  static const warningBorder = Color(0xFFE5C46B); // derived
  static const disabled = Color(0xFFB8B0B3); // derived

  // Warm Earth LightTheme-only colors (no V2Colors equivalent)
  static const onPrimary = Color(0xFFFFFFFF);
  static const navBarBackground = Color(0xCCFCF9F8);
  static const searchBackground = Color(0xFFFFFFFF);
  static const chipSelected = Color(0xFF864B4A);
  static const chipText = Color(0xFF524342);
  static const chipTextSelected = Color(0xFFFFFFFF);
  static const cardTitle = Color(0xFF864B4A);
  static const cardMeta = Color(0xFF7C5450);
  static const navActiveIcon = Color(0xFF864B4A);
  static const navInactiveIcon = Color(0xFF7C5450);
  static const filterFabIcon = Color(0xFF1B1C1B);
  static const rating = Color(0xFF81716F);
  static const saga = Color(0xB3864B4A);
  static const fabShadow = Color(0x26864B4A);
  static const filterFabShadow = Color(0x1A000000);
}

// Warm Earth LightTheme shadow recipes, mirroring V2Shadows.
abstract final class V2WarmEarthLightShadows {
  static const subtle = [
    BoxShadow(color: Color(0x0A000000), blurRadius: 6, offset: Offset(0, 3)),
  ];
  static const card = [
    BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 2)),
  ];
}
