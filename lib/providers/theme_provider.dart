import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:myrandomlibrary/config/themes/app_theme_palette.dart';
import 'package:myrandomlibrary/config/v2_design_system.dart';
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

    _applyPalette();
  }

  AppThemeMode _platformThemeMode() =>
      SchedulerBinding.instance.platformDispatcher.platformBrightness ==
              Brightness.dark
          ? AppThemeMode.dark
          : AppThemeMode.light;

  Future<void> setThemeMode(AppThemeMode mode) async {
    _themeMode = mode;
    _applyPalette();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', mode.name);
  }

  Future<void> setThemeFamily(AppThemeFamily family) async {
    _themeFamily = family;
    _applyPalette();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_family', family.name);
  }

  /// Points [V2Colors] at the active palette and rebuilds every widget, since
  /// screens read the tokens directly instead of through [Theme.of].
  void _applyPalette() {
    V2Colors.use(palette);
    notifyListeners();
    void rebuild(Element element) {
      element.markNeedsBuild();
      element.visitChildren(rebuild);
    }

    WidgetsBinding.instance.rootElement?.visitChildren(rebuild);
  }

  ColorScheme _colorScheme(AppThemePalette palette, Brightness brightness) {
    return ColorScheme.fromSeed(
      seedColor: palette.primary,
      brightness: brightness,
    ).copyWith(
      primary: palette.primary,
      onPrimary: palette.onPrimary,
      secondary: palette.cardMeta,
      secondaryContainer: palette.control,
      onSecondaryContainer: palette.navActiveIcon,
      surface: palette.background,
      onSurface: palette.cardTitle,
      onSurfaceVariant: palette.chipText,
      surfaceContainerLowest: palette.surface,
      surfaceContainerLow: palette.surface,
      surfaceContainer: palette.surface,
      outline: palette.borderNeutral,
      outlineVariant: palette.divider,
      shadow: const Color(0x0A000000),
    );
  }

  ThemeData _theme(AppThemePalette palette, Brightness brightness) {
    final previous = V2Colors.active;
    V2Colors.use(palette);
    try {
      return _buildTheme(palette, brightness);
    } finally {
      V2Colors.use(previous);
    }
  }

  ThemeData _buildTheme(AppThemePalette palette, Brightness brightness) {
    final colorScheme = _colorScheme(palette, brightness);
    final theme = V2DesignSystem.theme(colorScheme, brightness: brightness);
    return theme.copyWith(
      scaffoldBackgroundColor: palette.background,
      appBarTheme: theme.appBarTheme.copyWith(
        backgroundColor: palette.background,
        foregroundColor: palette.primary,
        iconTheme: IconThemeData(color: palette.primary),
      ),
      cardTheme: theme.cardTheme.copyWith(color: palette.surface),
    );
  }

  ThemeData get lightTheme =>
      _theme(_themeFamily.lightPalette, Brightness.light);

  ThemeData get darkTheme => _theme(_themeFamily.darkPalette, Brightness.dark);
}
