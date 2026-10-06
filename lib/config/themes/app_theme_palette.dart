import 'package:flutter/material.dart';
import 'package:myrandomlibrary/config/themes/main_dark_theme_colors.dart';
import 'package:myrandomlibrary/config/themes/ocean_dark_theme_colors.dart';
import 'package:myrandomlibrary/config/themes/ocean_light_theme_colors.dart';
import 'package:myrandomlibrary/config/themes/royal_dark_theme_colors.dart';
import 'package:myrandomlibrary/config/themes/royal_light_theme_colors.dart';
import 'package:myrandomlibrary/config/themes/warm_earth_dark_theme_colors.dart';
import 'package:myrandomlibrary/config/themes/warm_earth_light_theme_colors.dart';
import 'package:myrandomlibrary/config/v2_design_system.dart';

class AppThemePalette {
  const AppThemePalette({
    required this.background,
    required this.surface,
    required this.primary,
    required this.onPrimary,
    required this.cardTitle,
    required this.cardMetaText,
    required this.chipText,
    required this.divider,
    required this.cardBorder,
    required this.navActiveIndicator,
    required this.navActiveIcon,
    required this.cardShadow,
  });

  final Color background;
  final Color surface;
  final Color primary;
  final Color onPrimary;
  final Color cardTitle;
  final Color cardMetaText;
  final Color chipText;
  final Color divider;
  final Color cardBorder;
  final Color navActiveIndicator;
  final Color navActiveIcon;
  final Color cardShadow;

  static const mainLight = AppThemePalette(
    background: V2Colors.background,
    surface: V2Colors.surface,
    primary: V2Colors.primary,
    onPrimary: Colors.white,
    cardTitle: V2Colors.textPrimary,
    cardMetaText: V2Colors.textSubtle,
    chipText: V2Colors.textSecondary,
    divider: V2Colors.divider,
    cardBorder: V2Colors.borderNeutral,
    navActiveIndicator: V2Colors.control,
    navActiveIcon: V2Colors.primary,
    cardShadow: Color(0x0A000000),
  );

  static const mainDark = AppThemePalette(
    background: V2MainDarkColors.background,
    surface: V2MainDarkColors.surface,
    primary: V2MainDarkColors.primary,
    onPrimary: V2MainDarkColors.onPrimary,
    cardTitle: V2MainDarkColors.cardTitle,
    cardMetaText: V2MainDarkColors.cardMeta,
    chipText: V2MainDarkColors.chipText,
    divider: V2MainDarkColors.divider,
    cardBorder: V2MainDarkColors.borderNeutral,
    navActiveIndicator: V2MainDarkColors.control,
    navActiveIcon: V2MainDarkColors.navActiveIcon,
    cardShadow: Color(0x0A000000),
  );

  static const oceanLight = AppThemePalette(
    background: V2OceanLightColors.background,
    surface: V2OceanLightColors.surface,
    primary: V2OceanLightColors.primary,
    onPrimary: V2OceanLightColors.onPrimary,
    cardTitle: V2OceanLightColors.cardTitle,
    cardMetaText: V2OceanLightColors.cardMeta,
    chipText: V2OceanLightColors.chipText,
    divider: V2OceanLightColors.divider,
    cardBorder: V2OceanLightColors.borderNeutral,
    navActiveIndicator: V2OceanLightColors.control,
    navActiveIcon: V2OceanLightColors.navActiveIcon,
    cardShadow: Color(0x0A000000),
  );

  static const oceanDark = AppThemePalette(
    background: V2OceanDarkColors.background,
    surface: V2OceanDarkColors.surface,
    primary: V2OceanDarkColors.primary,
    onPrimary: V2OceanDarkColors.onPrimary,
    cardTitle: V2OceanDarkColors.cardTitle,
    cardMetaText: V2OceanDarkColors.cardMeta,
    chipText: V2OceanDarkColors.chipText,
    divider: V2OceanDarkColors.divider,
    cardBorder: V2OceanDarkColors.borderNeutral,
    navActiveIndicator: V2OceanDarkColors.control,
    navActiveIcon: V2OceanDarkColors.navActiveIcon,
    cardShadow: Color(0x0A000000),
  );

  static const warmEarthLight = AppThemePalette(
    background: V2WarmEarthLightColors.background,
    surface: V2WarmEarthLightColors.surface,
    primary: V2WarmEarthLightColors.primary,
    onPrimary: V2WarmEarthLightColors.onPrimary,
    cardTitle: V2WarmEarthLightColors.cardTitle,
    cardMetaText: V2WarmEarthLightColors.cardMeta,
    chipText: V2WarmEarthLightColors.chipText,
    divider: V2WarmEarthLightColors.divider,
    cardBorder: V2WarmEarthLightColors.borderNeutral,
    navActiveIndicator: V2WarmEarthLightColors.control,
    navActiveIcon: V2WarmEarthLightColors.navActiveIcon,
    cardShadow: Color(0x0A000000),
  );

  static const warmEarthDark = AppThemePalette(
    background: V2WarmEarthDarkColors.background,
    surface: V2WarmEarthDarkColors.surface,
    primary: V2WarmEarthDarkColors.primary,
    onPrimary: V2WarmEarthDarkColors.onPrimary,
    cardTitle: V2WarmEarthDarkColors.cardTitle,
    cardMetaText: V2WarmEarthDarkColors.cardMeta,
    chipText: V2WarmEarthDarkColors.chipText,
    divider: V2WarmEarthDarkColors.divider,
    cardBorder: V2WarmEarthDarkColors.borderNeutral,
    navActiveIndicator: V2WarmEarthDarkColors.control,
    navActiveIcon: V2WarmEarthDarkColors.navActiveIcon,
    cardShadow: Color(0x0A000000),
  );

  static const royalLight = AppThemePalette(
    background: V2RoyalLightColors.background,
    surface: V2RoyalLightColors.surface,
    primary: V2RoyalLightColors.primary,
    onPrimary: V2RoyalLightColors.onPrimary,
    cardTitle: V2RoyalLightColors.cardTitle,
    cardMetaText: V2RoyalLightColors.cardMeta,
    chipText: V2RoyalLightColors.chipText,
    divider: V2RoyalLightColors.divider,
    cardBorder: V2RoyalLightColors.borderNeutral,
    navActiveIndicator: V2RoyalLightColors.control,
    navActiveIcon: V2RoyalLightColors.navActiveIcon,
    cardShadow: Color(0x0A000000),
  );

  static const royalDark = AppThemePalette(
    background: V2RoyalDarkColors.background,
    surface: V2RoyalDarkColors.surface,
    primary: V2RoyalDarkColors.primary,
    onPrimary: V2RoyalDarkColors.onPrimary,
    cardTitle: V2RoyalDarkColors.cardTitle,
    cardMetaText: V2RoyalDarkColors.cardMeta,
    chipText: V2RoyalDarkColors.chipText,
    divider: V2RoyalDarkColors.divider,
    cardBorder: V2RoyalDarkColors.borderNeutral,
    navActiveIndicator: V2RoyalDarkColors.control,
    navActiveIcon: V2RoyalDarkColors.navActiveIcon,
    cardShadow: Color(0x0A000000),
  );
}
