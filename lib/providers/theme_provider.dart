import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:myrandomlibrary/config/themes/app_theme_palette.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeMode { light, dark }

enum AppThemeFamily { main, ocean, warmEarth, royal }

extension AppThemeFamilyPalettes on AppThemeFamily {
  AppThemePalette get lightPalette {
    switch (this) {
      case AppThemeFamily.main:
        return AppThemePalette.mainLight;
      case AppThemeFamily.ocean:
        return AppThemePalette.oceanLight;
      case AppThemeFamily.warmEarth:
        return AppThemePalette.warmEarthLight;
      case AppThemeFamily.royal:
        return AppThemePalette.royalLight;
    }
  }

  AppThemePalette get darkPalette {
    switch (this) {
      case AppThemeFamily.main:
        return AppThemePalette.mainDark;
      case AppThemeFamily.ocean:
        return AppThemePalette.oceanDark;
      case AppThemeFamily.warmEarth:
        return AppThemePalette.warmEarthDark;
      case AppThemeFamily.royal:
        return AppThemePalette.royalDark;
    }
  }

  AppThemePalette paletteFor(AppThemeMode mode) =>
      mode == AppThemeMode.dark ? darkPalette : lightPalette;
}

class ThemeProvider with ChangeNotifier {
  AppThemeMode _themeMode = AppThemeMode.light;
  AppThemeFamily _themeFamily = AppThemeFamily.main;

  AppThemeMode get themeMode => _themeMode;
  AppThemeFamily get themeFamily => _themeFamily;

  /// Palette of the active theme family in the active mode.
  AppThemePalette get palette => _themeFamily.paletteFor(_themeMode);

  ThemeProvider() {
    reloadFromPreferences();
  }

  Future<void> reloadFromPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final themeModeString = prefs.getString('theme_mode');
    _themeMode = AppThemeMode.values.firstWhere(
      (mode) => mode.name == themeModeString,
      orElse: _platformThemeMode,
    );

    final themeFamilyString = prefs.getString('theme_family');
    _themeFamily = AppThemeFamily.values.firstWhere(
      (family) => family.name == themeFamilyString,
      orElse: () => AppThemeFamily.main,
    );

    notifyListeners();
  }

  AppThemeMode _platformThemeMode() =>
      SchedulerBinding.instance.platformDispatcher.platformBrightness ==
              Brightness.dark
          ? AppThemeMode.dark
          : AppThemeMode.light;

  Future<void> setThemeMode(AppThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', mode.name);
  }

  Future<void> setThemeFamily(AppThemeFamily family) async {
    _themeFamily = family;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_family', family.name);
  }

  ColorScheme _colorScheme(AppThemePalette palette, Brightness brightness) {
    return ColorScheme.fromSeed(
      seedColor: palette.primary,
      brightness: brightness,
    ).copyWith(
      primary: palette.primary,
      onPrimary: palette.onPrimary,
      secondary: palette.cardMetaText,
      secondaryContainer: palette.navActiveIndicator,
      onSecondaryContainer: palette.navActiveIcon,
      surface: palette.background,
      onSurface: palette.cardTitle,
      onSurfaceVariant: palette.chipText,
      surfaceContainerLowest: palette.surface,
      surfaceContainerLow: palette.surface,
      surfaceContainer: palette.surface,
      outline: palette.cardBorder,
      outlineVariant: palette.divider,
      shadow: palette.cardShadow,
    );
  }

  SnackBarThemeData get _snackBarTheme => SnackBarThemeData(
    backgroundColor: const Color(0xFF43102B),
    actionTextColor: Colors.white,
    disabledActionTextColor: Colors.white70,
    contentTextStyle: const TextStyle(
      fontFamily: 'Manrope',
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: Colors.white,
    ),
    behavior: SnackBarBehavior.floating,
    elevation: 6,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  );

  MaterialBannerThemeData get _materialBannerTheme =>
      const MaterialBannerThemeData(
        backgroundColor: Color(0xFF43102B),
        contentTextStyle: TextStyle(
          fontFamily: 'Manrope',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      );

  ThemeData get lightTheme {
    final palette = _themeFamily.lightPalette;
    final colorScheme = _colorScheme(palette, Brightness.light);
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: Brightness.light,
      scaffoldBackgroundColor: palette.background,
      snackBarTheme: _snackBarTheme,
      bannerTheme: _materialBannerTheme,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        iconTheme: IconThemeData(color: colorScheme.onPrimary),
        titleTextStyle: TextStyle(
          color: colorScheme.onPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: const StadiumBorder(),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: colorScheme.primary),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      iconTheme: IconThemeData(color: colorScheme.primary),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: colorScheme.primary.withValues(alpha: 0.2),
        labelTextStyle: WidgetStateProperty.all(
          TextStyle(fontSize: 12, color: colorScheme.onSurface),
        ),
      ),
    );
  }

  ThemeData get darkTheme {
    final palette = _themeFamily.darkPalette;
    final colorScheme = _colorScheme(palette, Brightness.dark);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: palette.background,
      snackBarTheme: _snackBarTheme,
      bannerTheme: _materialBannerTheme,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        iconTheme: IconThemeData(color: colorScheme.onPrimary),
        titleTextStyle: TextStyle(
          color: colorScheme.onPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: const StadiumBorder(),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: colorScheme.primary),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      iconTheme: IconThemeData(color: colorScheme.primary),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: colorScheme.primary.withValues(alpha: 0.2),
        labelTextStyle: WidgetStateProperty.all(
          TextStyle(fontSize: 12, color: colorScheme.onSurface),
        ),
      ),
    );
  }
}
