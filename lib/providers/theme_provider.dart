import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeMode { light, dark, system }

enum LightThemeVariant { warmEarth, vibrantSunset, softPastel, deepOcean, custom }

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
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final themeModeString = prefs.getString('theme_mode') ?? 'system';
    _themeMode = AppThemeMode.values.firstWhere(
      (mode) => mode.toString() == 'AppThemeMode.$themeModeString',
      orElse: () => AppThemeMode.system,
    );
    
    final lightVariantString = prefs.getString('light_theme_variant') ?? 'warmEarth';
    _lightThemeVariant = LightThemeVariant.values.firstWhere(
      (variant) => variant.toString() == 'LightThemeVariant.$lightVariantString',
      orElse: () => LightThemeVariant.warmEarth,
    );
    
    final darkVariantString = prefs.getString('dark_theme_variant') ?? 'mysticPurple';
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
    await prefs.setString('light_theme_variant', variant.toString().split('.').last);
  }
  
  Future<void> setDarkThemeVariant(DarkThemeVariant variant) async {
    _darkThemeVariant = variant;
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('dark_theme_variant', variant.toString().split('.').last);
  }
  
  Future<void> setCustomLightColors(Color primary, Color secondary, Color tertiary) async {
    _customLightPrimary = primary;
    _customLightSecondary = secondary;
    _customLightTertiary = tertiary;
    _lightThemeVariant = LightThemeVariant.custom;
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('custom_light_primary', primary.value);
    await prefs.setInt('custom_light_secondary', secondary.value);
    await prefs.setInt('custom_light_tertiary', tertiary.value);
    await prefs.setString('light_theme_variant', 'custom');
  }
  
  Future<void> setCustomDarkColors(Color primary, Color secondary, Color tertiary) async {
    _customDarkPrimary = primary;
    _customDarkSecondary = secondary;
    _customDarkTertiary = tertiary;
    _darkThemeVariant = DarkThemeVariant.custom;
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('custom_dark_primary', primary.value);
    await prefs.setInt('custom_dark_secondary', secondary.value);
    await prefs.setInt('custom_dark_tertiary', tertiary.value);
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
          background: const Color(0xFFfafafa),
          error: const Color(0xFFba1a1a),
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onTertiary: Colors.white,
          onSurface: Colors.black87,
          onBackground: Colors.black87,
          onError: Colors.white,
        );
      case LightThemeVariant.vibrantSunset:
        return ColorScheme.light(
          primary: const Color(0xFFef476f),
          secondary: const Color(0xFFf78c6b),
          tertiary: const Color(0xFFffd166),
          surface: const Color(0xFFffffff),
          background: const Color(0xFFfafafa),
          error: const Color(0xFFba1a1a),
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onTertiary: Colors.black87,
          onSurface: Colors.black87,
          onBackground: Colors.black87,
          onError: Colors.white,
        );
      case LightThemeVariant.softPastel:
        return ColorScheme.light(
          primary: const Color(0xFFc8a8e9),
          secondary: const Color(0xFFe3aadd),
          tertiary: const Color(0xFFf5bcba),
          surface: const Color(0xFFffffff),
          background: const Color(0xFFf4e7fb),
          error: const Color(0xFFba1a1a),
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onTertiary: Colors.white,
          onSurface: Colors.black87,
          onBackground: Colors.black87,
          onError: Colors.white,
        );
      case LightThemeVariant.deepOcean:
        return ColorScheme.light(
          primary: const Color(0xFF14919b),
          secondary: const Color(0xFF0ad1c8),
          tertiary: const Color(0xFF45dfb1),
          surface: const Color(0xFFffffff),
          background: const Color(0xFFfafafa),
          error: const Color(0xFFba1a1a),
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onTertiary: Colors.white,
          onSurface: Colors.black87,
          onBackground: Colors.black87,
          onError: Colors.white,
        );
      case LightThemeVariant.custom:
        return ColorScheme.light(
          primary: _customLightPrimary,
          secondary: _customLightSecondary,
          tertiary: _customLightTertiary,
          surface: const Color(0xFFffffff),
          background: const Color(0xFFfafafa),
          error: const Color(0xFFba1a1a),
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onTertiary: Colors.white,
          onSurface: Colors.black87,
          onBackground: Colors.black87,
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
          background: const Color(0xFF121212),
          error: const Color(0xFFcf6679),
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onTertiary: Colors.black87,
          onSurface: Colors.white,
          onBackground: Colors.white,
          onError: Colors.black,
        );
      case DarkThemeVariant.deepSea:
        return ColorScheme.dark(
          primary: const Color(0xFF0c7075),
          secondary: const Color(0xFF0f969c),
          tertiary: const Color(0xFF6da5c0),
          surface: const Color(0xFF1a1a1a),
          background: const Color(0xFF05161a),
          error: const Color(0xFFcf6679),
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onTertiary: Colors.white,
          onSurface: Colors.white,
          onBackground: Colors.white,
          onError: Colors.black,
        );
      case DarkThemeVariant.warmAutumn:
        return ColorScheme.dark(
          primary: const Color(0xFF662549),
          secondary: const Color(0xFFae445a),
          tertiary: const Color(0xFFf39f5a),
          surface: const Color(0xFF1a1a1a),
          background: const Color(0xFF1d1a39),
          error: const Color(0xFFcf6679),
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onTertiary: Colors.white,
          onSurface: Colors.white,
          onBackground: Colors.white,
          onError: Colors.black,
        );
      case DarkThemeVariant.custom:
        return ColorScheme.dark(
          primary: _customDarkPrimary,
          secondary: _customDarkSecondary,
          tertiary: _customDarkTertiary,
          surface: const Color(0xFF1a1a1a),
          background: const Color(0xFF121212),
          error: const Color(0xFFcf6679),
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onTertiary: Colors.white,
          onSurface: Colors.white,
          onBackground: Colors.white,
          onError: Colors.black,
        );
    }
  }

  ThemeData get lightTheme {
    final colorScheme = _getLightColorScheme();
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: Brightness.light,
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      iconTheme: IconThemeData(
        color: colorScheme.primary,
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: colorScheme.primary.withOpacity(0.2),
        labelTextStyle: MaterialStateProperty.all(
          TextStyle(fontSize: 12, color: colorScheme.onSurface),
        ),
      ),
    );
  }

  ThemeData get darkTheme {
    final colorScheme = _getDarkColorScheme();
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      iconTheme: IconThemeData(
        color: colorScheme.primary,
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: colorScheme.primary.withOpacity(0.2),
        labelTextStyle: MaterialStateProperty.all(
          TextStyle(fontSize: 12, color: colorScheme.onSurface),
        ),
      ),
    );
  }
}
