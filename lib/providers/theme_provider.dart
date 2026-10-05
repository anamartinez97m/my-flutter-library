import 'package:flutter/material.dart';
import 'package:myrandomlibrary/config/v2_design_system.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeMode { light, dark, system }

enum LightThemeVariant {
  warmEarth,
  vibrantSunset,
  softPastel,
  deepOcean,
  custom,
}

enum DarkThemeVariant { mysticPurple, deepSea, warmAutumn, custom }

class ThemeProvider with ChangeNotifier {
  AppThemeMode _themeMode = AppThemeMode.system;
  LightThemeVariant _lightThemeVariant = LightThemeVariant.warmEarth;
  DarkThemeVariant _darkThemeVariant = DarkThemeVariant.mysticPurple;

  // Custom colors (3 colors: primary, secondary, tertiary)
  Color _customLightPrimary = const Color(0xFFa36361);
  Color _customLightSecondary = const Color(0xFFd3a29d);
  Color _customLightTertiary = const Color(0xFFe8b298);

  Color _customDarkPrimary = const Color(0xFF854f6c);
  Color _customDarkSecondary = const Color(0xFF522b5b);
  Color _customDarkTertiary = const Color(0xFFdfb6b2);

  AppThemeMode get themeMode => _themeMode;
  LightThemeVariant get lightThemeVariant => _lightThemeVariant;
  DarkThemeVariant get darkThemeVariant => _darkThemeVariant;

  // Getters for custom colors
  Color get customLightPrimary => _customLightPrimary;
  Color get customLightSecondary => _customLightSecondary;
  Color get customLightTertiary => _customLightTertiary;

  Color get customDarkPrimary => _customDarkPrimary;
  Color get customDarkSecondary => _customDarkSecondary;
  Color get customDarkTertiary => _customDarkTertiary;

  ThemeProvider() {
    reloadFromPreferences();
  }

  Future<void> reloadFromPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final themeModeString = prefs.getString('theme_mode') ?? 'system';
    _themeMode = AppThemeMode.values.firstWhere(
      (mode) => mode.toString() == 'AppThemeMode.$themeModeString',
      orElse: () => AppThemeMode.system,
    );

    final lightVariantString =
        prefs.getString('light_theme_variant') ?? 'warmEarth';
    _lightThemeVariant = LightThemeVariant.values.firstWhere(
      (variant) =>
          variant.toString() == 'LightThemeVariant.$lightVariantString',
      orElse: () => LightThemeVariant.warmEarth,
    );

    final darkVariantString =
        prefs.getString('dark_theme_variant') ?? 'mysticPurple';
    _darkThemeVariant = DarkThemeVariant.values.firstWhere(
      (variant) => variant.toString() == 'DarkThemeVariant.$darkVariantString',
      orElse: () => DarkThemeVariant.mysticPurple,
    );

    // Load custom light colors if they exist
    final customLightPrimaryInt = prefs.getInt('custom_light_primary');
    if (customLightPrimaryInt != null) {
      _customLightPrimary = Color(customLightPrimaryInt);
    }
    final customLightSecondaryInt = prefs.getInt('custom_light_secondary');
    if (customLightSecondaryInt != null) {
      _customLightSecondary = Color(customLightSecondaryInt);
    }
    final customLightTertiaryInt = prefs.getInt('custom_light_tertiary');
    if (customLightTertiaryInt != null) {
      _customLightTertiary = Color(customLightTertiaryInt);
    }

    // Load custom dark colors if they exist
    final customDarkPrimaryInt = prefs.getInt('custom_dark_primary');
    if (customDarkPrimaryInt != null) {
      _customDarkPrimary = Color(customDarkPrimaryInt);
    }
    final customDarkSecondaryInt = prefs.getInt('custom_dark_secondary');
    if (customDarkSecondaryInt != null) {
      _customDarkSecondary = Color(customDarkSecondaryInt);
    }
    final customDarkTertiaryInt = prefs.getInt('custom_dark_tertiary');
    if (customDarkTertiaryInt != null) {
      _customDarkTertiary = Color(customDarkTertiaryInt);
    }

    notifyListeners();
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', mode.toString().split('.').last);
  }

  Future<void> setLightThemeVariant(LightThemeVariant variant) async {
    _lightThemeVariant = variant;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'light_theme_variant',
      variant.toString().split('.').last,
    );
  }

  Future<void> setDarkThemeVariant(DarkThemeVariant variant) async {
    _darkThemeVariant = variant;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'dark_theme_variant',
      variant.toString().split('.').last,
    );
  }

  Future<void> setCustomLightColors(
    Color primary,
    Color secondary,
    Color tertiary,
  ) async {
    _customLightPrimary = primary;
    _customLightSecondary = secondary;
    _customLightTertiary = tertiary;
    _lightThemeVariant = LightThemeVariant.custom;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('custom_light_primary', primary.toARGB32());
    await prefs.setInt('custom_light_secondary', secondary.toARGB32());
    await prefs.setInt('custom_light_tertiary', tertiary.toARGB32());
    await prefs.setString('light_theme_variant', 'custom');
  }

  Future<void> setCustomDarkColors(
    Color primary,
    Color secondary,
    Color tertiary,
  ) async {
    _customDarkPrimary = primary;
    _customDarkSecondary = secondary;
    _customDarkTertiary = tertiary;
    _darkThemeVariant = DarkThemeVariant.custom;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('custom_dark_primary', primary.toARGB32());
    await prefs.setInt('custom_dark_secondary', secondary.toARGB32());
    await prefs.setInt('custom_dark_tertiary', tertiary.toARGB32());
    await prefs.setString('dark_theme_variant', 'custom');
  }

  ColorScheme _getLightColorScheme() {
    switch (_lightThemeVariant) {
      case LightThemeVariant.warmEarth:
        return ColorScheme.light(
          primary: const Color(0xFFa36361),
          secondary: const Color(0xFFd3a29d),
          tertiary: const Color(0xFFe8b298),
          surface: const Color(0xFFffffff),
          error: const Color(0xFFba1a1a),
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onTertiary: Colors.white,
          onSurface: Colors.black87,
          onError: Colors.white,
        );
      case LightThemeVariant.vibrantSunset:
        return ColorScheme.light(
          primary: const Color(0xFFef476f),
          secondary: const Color(0xFFf78c6b),
          tertiary: const Color(0xFFffd166),
          surface: const Color(0xFFffffff),
          error: const Color(0xFFba1a1a),
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onTertiary: Colors.black87,
          onSurface: Colors.black87,
          onError: Colors.white,
        );
      case LightThemeVariant.softPastel:
        return ColorScheme.light(
          primary: const Color(0xFFc8a8e9),
          secondary: const Color(0xFFe3aadd),
          tertiary: const Color(0xFFf5bcba),
          surface: const Color(0xFFffffff),
          error: const Color(0xFFba1a1a),
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onTertiary: Colors.white,
          onSurface: Colors.black87,
          onError: Colors.white,
        );
      case LightThemeVariant.deepOcean:
        return ColorScheme.light(
          primary: const Color(0xFF14919b),
          secondary: const Color(0xFF0ad1c8),
          tertiary: const Color(0xFF45dfb1),
          surface: const Color(0xFFffffff),
          error: const Color(0xFFba1a1a),
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onTertiary: Colors.white,
          onSurface: Colors.black87,
          onError: Colors.white,
        );
      case LightThemeVariant.custom:
        return ColorScheme.light(
          primary: _customLightPrimary,
          secondary: _customLightSecondary,
          tertiary: _customLightTertiary,
          surface: const Color(0xFFffffff),
          error: const Color(0xFFba1a1a),
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onTertiary: Colors.white,
          onSurface: Colors.black87,
          onError: Colors.white,
        );
    }
  }

  ColorScheme _getDarkColorScheme() {
    switch (_darkThemeVariant) {
      case DarkThemeVariant.mysticPurple:
        return ColorScheme.dark(
          primary: const Color(0xFF854f6c),
          secondary: const Color(0xFF522b5b),
          tertiary: const Color(0xFFdfb6b2),
          surface: const Color(0xFF1a1a1a),
          error: const Color(0xFFcf6679),
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onTertiary: Colors.black87,
          onSurface: Colors.white,
          onError: Colors.black,
        );
      case DarkThemeVariant.deepSea:
        return ColorScheme.dark(
          primary: const Color(0xFF0c7075),
          secondary: const Color(0xFF0f969c),
          tertiary: const Color(0xFF6da5c0),
          surface: const Color(0xFF1a1a1a),
          error: const Color(0xFFcf6679),
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onTertiary: Colors.white,
          onSurface: Colors.white,
          onError: Colors.black,
        );
      case DarkThemeVariant.warmAutumn:
        return ColorScheme.dark(
          primary: const Color(0xFF662549),
          secondary: const Color(0xFFae445a),
          tertiary: const Color(0xFFf39f5a),
          surface: const Color(0xFF1a1a1a),
          error: const Color(0xFFcf6679),
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onTertiary: Colors.white,
          onSurface: Colors.white,
          onError: Colors.black,
        );
      case DarkThemeVariant.custom:
        return ColorScheme.dark(
          primary: _customDarkPrimary,
          secondary: _customDarkSecondary,
          tertiary: _customDarkTertiary,
          surface: const Color(0xFF1a1a1a),
          error: const Color(0xFFcf6679),
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onTertiary: Colors.white,
          onSurface: Colors.white,
          onError: Colors.black,
        );
    }
  }

  ThemeData get lightTheme => V2DesignSystem.theme(
    _getLightColorScheme(),
    brightness: Brightness.light,
  );

  ThemeData get darkTheme =>
      V2DesignSystem.theme(_getDarkColorScheme(), brightness: Brightness.dark);
}
