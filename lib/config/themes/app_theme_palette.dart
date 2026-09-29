import 'package:flutter/material.dart';
import 'package:myrandomlibrary/config/themes/main_light_theme_colors.dart';
import 'package:myrandomlibrary/config/themes/main_dark_theme_colors.dart';
import 'package:myrandomlibrary/config/themes/ocean_light_theme_colors.dart';
import 'package:myrandomlibrary/config/themes/ocean_dark_theme_colors.dart';
import 'package:myrandomlibrary/config/themes/warm_earth_light_theme_colors.dart';
import 'package:myrandomlibrary/config/themes/warm_earth_dark_theme_colors.dart';
import 'package:myrandomlibrary/config/themes/royal_light_theme_colors.dart';
import 'package:myrandomlibrary/config/themes/royal_dark_theme_colors.dart';

/// A theme's full color palette, with the same roles as the `*ThemeColors` classes.
class AppThemePalette {
  const AppThemePalette({
    required this.background,
    required this.navBarBackground,
    required this.surface,
    required this.searchBackground,
    required this.chipBackground,
    required this.selectedChipBackground,
    required this.filterFabBackground,
    required this.primary,
    required this.onPrimary,
    required this.primaryShadow,
    required this.appTitle,
    required this.cardTitle,
    required this.cardMetaText,
    required this.chipText,
    required this.selectedChipText,
    required this.searchText,
    required this.divider,
    required this.cardBorder,
    required this.chipBorder,
    required this.selectedChipBorder,
    required this.searchBorder,
    required this.filterFabBorder,
    required this.navActiveIndicator,
    required this.navActiveIcon,
    required this.navInactiveIcon,
    required this.filterFabIcon,
    required this.sagaIcon,
    required this.ratingIcon,
    required this.cardShadow,
    required this.filterFabShadow,
  });

  final Color background;
  final Color navBarBackground;
  final Color surface;
  final Color searchBackground;
  final Color chipBackground;
  final Color selectedChipBackground;
  final Color filterFabBackground;
  final Color primary;
  final Color onPrimary;
  final Color primaryShadow;
  final Color appTitle;
  final Color cardTitle;
  final Color cardMetaText;
  final Color chipText;
  final Color selectedChipText;
  final Color searchText;
  final Color divider;
  final Color cardBorder;
  final Color chipBorder;
  final Color selectedChipBorder;
  final Color searchBorder;
  final Color filterFabBorder;
  final Color navActiveIndicator;
  final Color navActiveIcon;
  final Color navInactiveIcon;
  final Color filterFabIcon;
  final Color sagaIcon;
  final Color ratingIcon;
  final Color cardShadow;
  final Color filterFabShadow;

  static const mainLight = AppThemePalette(
    background: MainLightThemeColors.background,
    navBarBackground: MainLightThemeColors.navBarBackground,
    surface: MainLightThemeColors.surface,
    searchBackground: MainLightThemeColors.searchBackground,
    chipBackground: MainLightThemeColors.chipBackground,
    selectedChipBackground: MainLightThemeColors.selectedChipBackground,
    filterFabBackground: MainLightThemeColors.filterFabBackground,
    primary: MainLightThemeColors.primary,
    onPrimary: MainLightThemeColors.onPrimary,
    primaryShadow: MainLightThemeColors.primaryShadow,
    appTitle: MainLightThemeColors.appTitle,
    cardTitle: MainLightThemeColors.cardTitle,
    cardMetaText: MainLightThemeColors.cardMetaText,
    chipText: MainLightThemeColors.chipText,
    selectedChipText: MainLightThemeColors.selectedChipText,
    searchText: MainLightThemeColors.searchText,
    divider: MainLightThemeColors.divider,
    cardBorder: MainLightThemeColors.cardBorder,
    chipBorder: MainLightThemeColors.chipBorder,
    selectedChipBorder: MainLightThemeColors.selectedChipBorder,
    searchBorder: MainLightThemeColors.searchBorder,
    filterFabBorder: MainLightThemeColors.filterFabBorder,
    navActiveIndicator: MainLightThemeColors.navActiveIndicator,
    navActiveIcon: MainLightThemeColors.navActiveIcon,
    navInactiveIcon: MainLightThemeColors.navInactiveIcon,
    filterFabIcon: MainLightThemeColors.filterFabIcon,
    sagaIcon: MainLightThemeColors.sagaIcon,
    ratingIcon: MainLightThemeColors.ratingIcon,
    cardShadow: MainLightThemeColors.cardShadow,
    filterFabShadow: MainLightThemeColors.filterFabShadow,
  );

  static const mainDark = AppThemePalette(
    background: MainDarkThemeColors.background,
    navBarBackground: MainDarkThemeColors.navBarBackground,
    surface: MainDarkThemeColors.surface,
    searchBackground: MainDarkThemeColors.searchBackground,
    chipBackground: MainDarkThemeColors.chipBackground,
    selectedChipBackground: MainDarkThemeColors.selectedChipBackground,
    filterFabBackground: MainDarkThemeColors.filterFabBackground,
    primary: MainDarkThemeColors.primary,
    onPrimary: MainDarkThemeColors.onPrimary,
    primaryShadow: MainDarkThemeColors.primaryShadow,
    appTitle: MainDarkThemeColors.appTitle,
    cardTitle: MainDarkThemeColors.cardTitle,
    cardMetaText: MainDarkThemeColors.cardMetaText,
    chipText: MainDarkThemeColors.chipText,
    selectedChipText: MainDarkThemeColors.selectedChipText,
    searchText: MainDarkThemeColors.searchText,
    divider: MainDarkThemeColors.divider,
    cardBorder: MainDarkThemeColors.cardBorder,
    chipBorder: MainDarkThemeColors.chipBorder,
    selectedChipBorder: MainDarkThemeColors.selectedChipBorder,
    searchBorder: MainDarkThemeColors.searchBorder,
    filterFabBorder: MainDarkThemeColors.filterFabBorder,
    navActiveIndicator: MainDarkThemeColors.navActiveIndicator,
    navActiveIcon: MainDarkThemeColors.navActiveIcon,
    navInactiveIcon: MainDarkThemeColors.navInactiveIcon,
    filterFabIcon: MainDarkThemeColors.filterFabIcon,
    sagaIcon: MainDarkThemeColors.sagaIcon,
    ratingIcon: MainDarkThemeColors.ratingIcon,
    cardShadow: MainDarkThemeColors.cardShadow,
    filterFabShadow: MainDarkThemeColors.filterFabShadow,
  );

  static const oceanLight = AppThemePalette(
    background: OceanLightThemeColors.background,
    navBarBackground: OceanLightThemeColors.navBarBackground,
    surface: OceanLightThemeColors.surface,
    searchBackground: OceanLightThemeColors.searchBackground,
    chipBackground: OceanLightThemeColors.chipBackground,
    selectedChipBackground: OceanLightThemeColors.selectedChipBackground,
    filterFabBackground: OceanLightThemeColors.filterFabBackground,
    primary: OceanLightThemeColors.primary,
    onPrimary: OceanLightThemeColors.onPrimary,
    primaryShadow: OceanLightThemeColors.primaryShadow,
    appTitle: OceanLightThemeColors.appTitle,
    cardTitle: OceanLightThemeColors.cardTitle,
    cardMetaText: OceanLightThemeColors.cardMetaText,
    chipText: OceanLightThemeColors.chipText,
    selectedChipText: OceanLightThemeColors.selectedChipText,
    searchText: OceanLightThemeColors.searchText,
    divider: OceanLightThemeColors.divider,
    cardBorder: OceanLightThemeColors.cardBorder,
    chipBorder: OceanLightThemeColors.chipBorder,
    selectedChipBorder: OceanLightThemeColors.selectedChipBorder,
    searchBorder: OceanLightThemeColors.searchBorder,
    filterFabBorder: OceanLightThemeColors.filterFabBorder,
    navActiveIndicator: OceanLightThemeColors.navActiveIndicator,
    navActiveIcon: OceanLightThemeColors.navActiveIcon,
    navInactiveIcon: OceanLightThemeColors.navInactiveIcon,
    filterFabIcon: OceanLightThemeColors.filterFabIcon,
    sagaIcon: OceanLightThemeColors.sagaIcon,
    ratingIcon: OceanLightThemeColors.ratingIcon,
    cardShadow: OceanLightThemeColors.cardShadow,
    filterFabShadow: OceanLightThemeColors.filterFabShadow,
  );

  static const oceanDark = AppThemePalette(
    background: OceanDarkThemeColors.background,
    navBarBackground: OceanDarkThemeColors.navBarBackground,
    surface: OceanDarkThemeColors.surface,
    searchBackground: OceanDarkThemeColors.searchBackground,
    chipBackground: OceanDarkThemeColors.chipBackground,
    selectedChipBackground: OceanDarkThemeColors.selectedChipBackground,
    filterFabBackground: OceanDarkThemeColors.filterFabBackground,
    primary: OceanDarkThemeColors.primary,
    onPrimary: OceanDarkThemeColors.onPrimary,
    primaryShadow: OceanDarkThemeColors.primaryShadow,
    appTitle: OceanDarkThemeColors.appTitle,
    cardTitle: OceanDarkThemeColors.cardTitle,
    cardMetaText: OceanDarkThemeColors.cardMetaText,
    chipText: OceanDarkThemeColors.chipText,
    selectedChipText: OceanDarkThemeColors.selectedChipText,
    searchText: OceanDarkThemeColors.searchText,
    divider: OceanDarkThemeColors.divider,
    cardBorder: OceanDarkThemeColors.cardBorder,
    chipBorder: OceanDarkThemeColors.chipBorder,
    selectedChipBorder: OceanDarkThemeColors.selectedChipBorder,
    searchBorder: OceanDarkThemeColors.searchBorder,
    filterFabBorder: OceanDarkThemeColors.filterFabBorder,
    navActiveIndicator: OceanDarkThemeColors.navActiveIndicator,
    navActiveIcon: OceanDarkThemeColors.navActiveIcon,
    navInactiveIcon: OceanDarkThemeColors.navInactiveIcon,
    filterFabIcon: OceanDarkThemeColors.filterFabIcon,
    sagaIcon: OceanDarkThemeColors.sagaIcon,
    ratingIcon: OceanDarkThemeColors.ratingIcon,
    cardShadow: OceanDarkThemeColors.cardShadow,
    filterFabShadow: OceanDarkThemeColors.filterFabShadow,
  );

  static const warmEarthLight = AppThemePalette(
    background: WarmEarthLightThemeColors.background,
    navBarBackground: WarmEarthLightThemeColors.navBarBackground,
    surface: WarmEarthLightThemeColors.surface,
    searchBackground: WarmEarthLightThemeColors.searchBackground,
    chipBackground: WarmEarthLightThemeColors.chipBackground,
    selectedChipBackground: WarmEarthLightThemeColors.selectedChipBackground,
    filterFabBackground: WarmEarthLightThemeColors.filterFabBackground,
    primary: WarmEarthLightThemeColors.primary,
    onPrimary: WarmEarthLightThemeColors.onPrimary,
    primaryShadow: WarmEarthLightThemeColors.primaryShadow,
    appTitle: WarmEarthLightThemeColors.appTitle,
    cardTitle: WarmEarthLightThemeColors.cardTitle,
    cardMetaText: WarmEarthLightThemeColors.cardMetaText,
    chipText: WarmEarthLightThemeColors.chipText,
    selectedChipText: WarmEarthLightThemeColors.selectedChipText,
    searchText: WarmEarthLightThemeColors.searchText,
    divider: WarmEarthLightThemeColors.divider,
    cardBorder: WarmEarthLightThemeColors.cardBorder,
    chipBorder: WarmEarthLightThemeColors.chipBorder,
    selectedChipBorder: WarmEarthLightThemeColors.selectedChipBorder,
    searchBorder: WarmEarthLightThemeColors.searchBorder,
    filterFabBorder: WarmEarthLightThemeColors.filterFabBorder,
    navActiveIndicator: WarmEarthLightThemeColors.navActiveIndicator,
    navActiveIcon: WarmEarthLightThemeColors.navActiveIcon,
    navInactiveIcon: WarmEarthLightThemeColors.navInactiveIcon,
    filterFabIcon: WarmEarthLightThemeColors.filterFabIcon,
    sagaIcon: WarmEarthLightThemeColors.sagaIcon,
    ratingIcon: WarmEarthLightThemeColors.ratingIcon,
    cardShadow: WarmEarthLightThemeColors.cardShadow,
    filterFabShadow: WarmEarthLightThemeColors.filterFabShadow,
  );

  static const warmEarthDark = AppThemePalette(
    background: WarmEarthDarkThemeColors.background,
    navBarBackground: WarmEarthDarkThemeColors.navBarBackground,
    surface: WarmEarthDarkThemeColors.surface,
    searchBackground: WarmEarthDarkThemeColors.searchBackground,
    chipBackground: WarmEarthDarkThemeColors.chipBackground,
    selectedChipBackground: WarmEarthDarkThemeColors.selectedChipBackground,
    filterFabBackground: WarmEarthDarkThemeColors.filterFabBackground,
    primary: WarmEarthDarkThemeColors.primary,
    onPrimary: WarmEarthDarkThemeColors.onPrimary,
    primaryShadow: WarmEarthDarkThemeColors.primaryShadow,
    appTitle: WarmEarthDarkThemeColors.appTitle,
    cardTitle: WarmEarthDarkThemeColors.cardTitle,
    cardMetaText: WarmEarthDarkThemeColors.cardMetaText,
    chipText: WarmEarthDarkThemeColors.chipText,
    selectedChipText: WarmEarthDarkThemeColors.selectedChipText,
    searchText: WarmEarthDarkThemeColors.searchText,
    divider: WarmEarthDarkThemeColors.divider,
    cardBorder: WarmEarthDarkThemeColors.cardBorder,
    chipBorder: WarmEarthDarkThemeColors.chipBorder,
    selectedChipBorder: WarmEarthDarkThemeColors.selectedChipBorder,
    searchBorder: WarmEarthDarkThemeColors.searchBorder,
    filterFabBorder: WarmEarthDarkThemeColors.filterFabBorder,
    navActiveIndicator: WarmEarthDarkThemeColors.navActiveIndicator,
    navActiveIcon: WarmEarthDarkThemeColors.navActiveIcon,
    navInactiveIcon: WarmEarthDarkThemeColors.navInactiveIcon,
    filterFabIcon: WarmEarthDarkThemeColors.filterFabIcon,
    sagaIcon: WarmEarthDarkThemeColors.sagaIcon,
    ratingIcon: WarmEarthDarkThemeColors.ratingIcon,
    cardShadow: WarmEarthDarkThemeColors.cardShadow,
    filterFabShadow: WarmEarthDarkThemeColors.filterFabShadow,
  );

  static const royalLight = AppThemePalette(
    background: RoyalLightThemeColors.background,
    navBarBackground: RoyalLightThemeColors.navBarBackground,
    surface: RoyalLightThemeColors.surface,
    searchBackground: RoyalLightThemeColors.searchBackground,
    chipBackground: RoyalLightThemeColors.chipBackground,
    selectedChipBackground: RoyalLightThemeColors.selectedChipBackground,
    filterFabBackground: RoyalLightThemeColors.filterFabBackground,
    primary: RoyalLightThemeColors.primary,
    onPrimary: RoyalLightThemeColors.onPrimary,
    primaryShadow: RoyalLightThemeColors.primaryShadow,
    appTitle: RoyalLightThemeColors.appTitle,
    cardTitle: RoyalLightThemeColors.cardTitle,
    cardMetaText: RoyalLightThemeColors.cardMetaText,
    chipText: RoyalLightThemeColors.chipText,
    selectedChipText: RoyalLightThemeColors.selectedChipText,
    searchText: RoyalLightThemeColors.searchText,
    divider: RoyalLightThemeColors.divider,
    cardBorder: RoyalLightThemeColors.cardBorder,
    chipBorder: RoyalLightThemeColors.chipBorder,
    selectedChipBorder: RoyalLightThemeColors.selectedChipBorder,
    searchBorder: RoyalLightThemeColors.searchBorder,
    filterFabBorder: RoyalLightThemeColors.filterFabBorder,
    navActiveIndicator: RoyalLightThemeColors.navActiveIndicator,
    navActiveIcon: RoyalLightThemeColors.navActiveIcon,
    navInactiveIcon: RoyalLightThemeColors.navInactiveIcon,
    filterFabIcon: RoyalLightThemeColors.filterFabIcon,
    sagaIcon: RoyalLightThemeColors.sagaIcon,
    ratingIcon: RoyalLightThemeColors.ratingIcon,
    cardShadow: RoyalLightThemeColors.cardShadow,
    filterFabShadow: RoyalLightThemeColors.filterFabShadow,
  );

  static const royalDark = AppThemePalette(
    background: RoyalDarkThemeColors.background,
    navBarBackground: RoyalDarkThemeColors.navBarBackground,
    surface: RoyalDarkThemeColors.surface,
    searchBackground: RoyalDarkThemeColors.searchBackground,
    chipBackground: RoyalDarkThemeColors.chipBackground,
    selectedChipBackground: RoyalDarkThemeColors.selectedChipBackground,
    filterFabBackground: RoyalDarkThemeColors.filterFabBackground,
    primary: RoyalDarkThemeColors.primary,
    onPrimary: RoyalDarkThemeColors.onPrimary,
    primaryShadow: RoyalDarkThemeColors.primaryShadow,
    appTitle: RoyalDarkThemeColors.appTitle,
    cardTitle: RoyalDarkThemeColors.cardTitle,
    cardMetaText: RoyalDarkThemeColors.cardMetaText,
    chipText: RoyalDarkThemeColors.chipText,
    selectedChipText: RoyalDarkThemeColors.selectedChipText,
    searchText: RoyalDarkThemeColors.searchText,
    divider: RoyalDarkThemeColors.divider,
    cardBorder: RoyalDarkThemeColors.cardBorder,
    chipBorder: RoyalDarkThemeColors.chipBorder,
    selectedChipBorder: RoyalDarkThemeColors.selectedChipBorder,
    searchBorder: RoyalDarkThemeColors.searchBorder,
    filterFabBorder: RoyalDarkThemeColors.filterFabBorder,
    navActiveIndicator: RoyalDarkThemeColors.navActiveIndicator,
    navActiveIcon: RoyalDarkThemeColors.navActiveIcon,
    navInactiveIcon: RoyalDarkThemeColors.navInactiveIcon,
    filterFabIcon: RoyalDarkThemeColors.filterFabIcon,
    sagaIcon: RoyalDarkThemeColors.sagaIcon,
    ratingIcon: RoyalDarkThemeColors.ratingIcon,
    cardShadow: RoyalDarkThemeColors.cardShadow,
    filterFabShadow: RoyalDarkThemeColors.filterFabShadow,
  );
}
