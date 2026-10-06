import 'package:flutter/material.dart';

// Ocean LightTheme color palette.
// Same tokens as V2Colors (lib/config/v2_design_system.dart) so the two can be
// swapped; values come from the Figma "Ocean LightTheme" frame.
// Tokens marked "derived" have no counterpart in that frame; status colors and
// `disabled` reuse the V2Colors values.
abstract final class V2OceanLightColors {
  // Backgrounds and surfaces
  static const background = Color(0xFFF9F9FC);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceWarm = Color(0xFFFFFFFF);
  static const surfaceAlt = Color(0xFFFFFFFF);
  static const surfaceMuted = Color(0xFFE8E8EA);
  static const surfaceTimer = Color(0xFFE8E8EA);
  static const shimmerBase = Color(0xFFE2E2E5);
  static const borderDialog = Color(0xFFC1C8C9);
  static const buttonText = Color(0xFFFFFFFF);

  // Brand colors
  static const primary = Color(0xFF00666E);
  static const primaryAlt = Color(0xFF1C686F);
  static const secondary = Color(0xFF00666E);

  // Text colors
  static const textPrimary = Color(0xFF1A1C1E);
  static const textStrong = Color(0xFF1A1C1E);
  static const textSecondary = Color(0xFF3D494A);
  static const textSubtle = Color(0xCC1A1C1E); // derived
  static const textMuted = Color(0xB33D494A); // derived
  static const textMutedAlt = Color(0x993D494A); // derived

  // Borders, dividers, and controls
  static const border = Color(0xFFC1C8C9);
  static const borderStrong = Color(0xFF1A1C1E); // derived
  static const borderNeutral = Color(0xFFC1C8C9);
  static const borderInput = Color(0xFF575D5E);
  static const borderSoft = Color(0x33BDC9CA);
  static const divider = Color(0xFFE2E2E5);
  static const chip = Color(0xFFFFFFFF);
  static const control = Color(0xFF6FD6E0);
  static const error = Color(0xFFBA1A1A); // derived
  static const success = Color(0xFF059669); // derived
  static const successBackground = Color(0xFFECFDF5); // derived
  static const successBorder = Color(0xFFA7F3D0); // derived
  static const warning = Color(0xFF7A4D00); // derived
  static const warningBackground = Color(0xFFFFF4D9); // derived
  static const warningBorder = Color(0xFFE5C46B); // derived
  static const disabled = Color(0xFFB8B0B3); // derived

  // Ocean LightTheme-only colors (no V2Colors equivalent)
  static const onPrimary = Color(0xFFFFFFFF);
  static const navBarBackground = Color(0xCCF9F9FC);
  static const searchBackground = Color(0xFFFFFFFF);
  static const chipSelected = Color(0xFF00666E);
  static const chipText = Color(0xFF3D494A);
  static const chipTextSelected = Color(0xFFFFFFFF);
  static const cardTitle = Color(0xFF00666E);
  static const cardMeta = Color(0xFF1C686F);
  static const navActiveIcon = Color(0xFF00666E);
  static const navInactiveIcon = Color(0xFF1C686F);
  static const filterFabIcon = Color(0xFF1A1C1E);
  static const rating = Color(0xFFCA8A04);
  static const saga = Color(0xB300666E);
  static const fabShadow = Color(0x2600666E);
  static const filterFabShadow = Color(0x1A000000);
}

// Ocean LightTheme shadow recipes, mirroring V2Shadows.
abstract final class V2OceanLightShadows {
  static const subtle = [
    BoxShadow(color: Color(0x0A000000), blurRadius: 6, offset: Offset(0, 3)),
  ];
  static const card = [
    BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 2)),
  ];
}
