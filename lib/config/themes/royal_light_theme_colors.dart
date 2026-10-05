import 'package:flutter/material.dart';

// Royal LightTheme color palette.
// Same tokens as V2Colors (lib/config/v2_design_system.dart) so the two can be
// swapped; values come from the Figma "Royal LightTheme" frame.
// Tokens marked "derived" have no counterpart in that frame; status colors and
// `disabled` reuse the V2Colors values.
abstract final class V2RoyalLightColors {
  // Backgrounds and surfaces
  static const background = Color(0xFFF9F9FF);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceWarm = Color(0xFFFFFFFF);
  static const surfaceAlt = Color(0xFFFFFFFF);
  static const surfaceMuted = Color(0xFFE2E8F8);
  static const surfaceTimer = Color(0xFFE2E8F8);
  static const shimmerBase = Color(0xFFDCE2F3);
  static const borderDialog = Color(0xFFC6C6CE);
  static const buttonText = Color(0xFFFFFFFF);

  // Brand colors
  static const primary = Color(0xFF2E3A59);
  static const primaryAlt = Color(0xFF3F4859);
  static const secondary = Color(0xFF182442);

  // Text colors
  static const textPrimary = Color(0xFF151C27);
  static const textStrong = Color(0xFF151C27);
  static const textSecondary = Color(0xFF45464E);
  static const textSubtle = Color(0xCC151C27); // derived
  static const textMuted = Color(0xB345464E); // derived
  static const textMutedAlt = Color(0x9945464E); // derived

  // Borders, dividers, and controls
  static const border = Color(0xFFC6C6CE);
  static const borderStrong = Color(0xFF151C27); // derived
  static const borderNeutral = Color(0xFFC6C6CE);
  static const borderInput = Color(0xFFC6C6CE);
  static const borderSoft = Color(0x33C6C6CE);
  static const divider = Color(0xFFDCE2F3);
  static const chip = Color(0xFFFFFFFF);
  static const control = Color(0xFFBAC6EC);
  static const error = Color(0xFFBA1A1A); // derived
  static const success = Color(0xFF059669); // derived
  static const successBackground = Color(0xFFECFDF5); // derived
  static const successBorder = Color(0xFFA7F3D0); // derived
  static const warning = Color(0xFF7A4D00); // derived
  static const warningBackground = Color(0xFFFFF4D9); // derived
  static const warningBorder = Color(0xFFE5C46B); // derived
  static const disabled = Color(0xFFB8B0B3); // derived

  // Royal LightTheme-only colors (no V2Colors equivalent)
  static const onPrimary = Color(0xFFFFFFFF);
  static const navBarBackground = Color(0xCCF9F9FF);
  static const searchBackground = Color(0xFFFFFFFF);
  static const chipSelected = Color(0xFF2E3A59);
  static const chipText = Color(0xFF45464E);
  static const chipTextSelected = Color(0xFFFFFFFF);
  static const cardTitle = Color(0xFF182442);
  static const cardMeta = Color(0xFF3F4859);
  static const navActiveIcon = Color(0xFF182442);
  static const navInactiveIcon = Color(0xFF3F4859);
  static const filterFabIcon = Color(0xFF151C27);
  static const rating = Color(0xFF3F4859);
  static const saga = Color(0xB3182442);
  static const fabShadow = Color(0x26182442);
  static const filterFabShadow = Color(0x1A000000);
}

// Royal LightTheme shadow recipes, mirroring V2Shadows.
abstract final class V2RoyalLightShadows {
  static const subtle = [
    BoxShadow(color: Color(0x0A000000), blurRadius: 6, offset: Offset(0, 3)),
  ];
  static const card = [
    BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 2)),
  ];
}
