import 'package:flutter/material.dart';

/// Central design tokens for the new (v2) UI.
///
/// Update values here to change the new design everywhere it is used.
class NewUiDesignTokens {
  // ── Brand / primary palette ───────────────────────────────────────────────
  static const Color primary = Color(0xFF43102B);
  static const Color primaryDark = Color(0xFF5D2641);
  static const Color primaryAccent = Color(0xFFD68DAC);
  static const Color labelText = Color(0xCC43102B);

  // ── Backgrounds and surfaces ──────────────────────────────────────────────
  static const Color background = Color(0xFFFDF8F6);
  static const Color surface = Colors.white;
  static const Color surfaceMuted = Color(0xFFF5F3F2);
  static const Color surfaceLight = Color(0xFFF2EDEB);
  static const Color surfaceCream = Color(0xFFF7F3F0);
  static const Color activeBackground = Color(0xFFECE7E5);

  // ── Text colors ───────────────────────────────────────────────────────────
  static const Color textHighEmphasis = Color(0xFF1C1B1A);
  static const Color textPrimary = Color(0xFF43102B);
  static const Color textSecondary = Color(0xFF514348);
  static const Color textMuted = Color(0xFF5F5E5C);
  static const Color textLight = Color(0xFF837378);

  // ── Borders, dividers and separators ──────────────────────────────────────
  static const Color border = Color(0xFFD5C2C7);
  static const Color borderLight = Color(0xFFCEC5BE);
  static const Color borderFaint = Color(0x4DCEC5BE);
  static const Color borderSubtle = Color(0x1A27231E);
  static const Color inputBorder = Color(0xFF27231E);
  static const Color inputBorderMuted = Color(0xFF6B7280);
  static const Color divider = Color(0xFFE6E2DF);

  // ── Component colors ──────────────────────────────────────────────────────
  static const Color progressBackground = Color(0xFFE6E2DF);
  static const Color badgeBackground = Color(0xFFF2EDEB);
  static const Color clubMemberAvatar = Color(0xFFFEB0D0);
  static const Color placeholderLetter = Color(0xFFD68DAC);
  static const Color clearButton = Color(0xFFE6E2DF);
  static const Color actionBorder = Color(0xFFE6E2DF);
  static const Color shadowColor = Color(0x0A000000);

  // ── Font ──────────────────────────────────────────────────────────────────
  static const String fontFamilyPrimary = 'Manrope';

  // ── Font sizes ────────────────────────────────────────────────────────────
  static const double fontSize9 = 9.0;
  static const double fontSize10 = 10.0;
  static const double fontSize11 = 11.0;
  static const double fontSize12 = 12.0;
  static const double fontSize13 = 13.0;
  static const double fontSize14 = 14.0;
  static const double fontSize16 = 16.0;
  static const double fontSize18 = 18.0;
  static const double fontSize19 = 19.0;
  static const double fontSize20 = 20.0;

  // ── Font weights ──────────────────────────────────────────────────────────
  static const FontWeight fontWeightRegular = FontWeight.w400;
  static const FontWeight fontWeightMedium = FontWeight.w500;
  static const FontWeight fontWeightSemibold = FontWeight.w600;
  static const FontWeight fontWeightBold = FontWeight.w700;

  // ── Border radii ──────────────────────────────────────────────────────────
  static const double radiusXSmall = 4.0;
  static const double radiusSmall = 6.0;
  static const double radiusMedium = 8.0;
  static const double radiusLarge = 12.0;
  static const double radiusPill = 9999.0;

  // ── Spacing ───────────────────────────────────────────────────────────────
  static const double space2 = 2.0;
  static const double space4 = 4.0;
  static const double space6 = 6.0;
  static const double space8 = 8.0;
  static const double space9 = 9.0;
  static const double space12 = 12.0;
  static const double space13 = 13.0;
  static const double space16 = 16.0;
  static const double space17 = 17.0;
  static const double space20 = 20.0;
  static const double space24 = 24.0;
  static const double space25 = 25.0;
  static const double space30 = 30.0;
  static const double space32 = 32.0;
  static const double space40 = 40.0;

  // ── Elevations / shadows ──────────────────────────────────────────────────
  static const BoxShadow cardShadow = BoxShadow(
    color: shadowColor,
    blurRadius: 12,
    offset: Offset(0, 4),
  );

  static const BoxShadow tileShadow = BoxShadow(
    color: shadowColor,
    blurRadius: 6,
    offset: Offset(0, 4),
  );
}
