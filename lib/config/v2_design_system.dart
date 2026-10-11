import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myrandomlibrary/config/themes/app_theme_palette.dart';

// Color palette
abstract final class V2Colors {
  static AppThemePalette _active = AppThemePalette.mainLight;

  /// Palette every token below resolves to.
  static AppThemePalette get active => _active;

  static void use(AppThemePalette palette) => _active = palette;

  // Backgrounds and surfaces
  static Color get background => _active.background;
  static Color get surface => _active.surface;
  static Color get surfaceWarm => _active.surfaceWarm;
  static Color get surfaceAlt => _active.surfaceAlt;
  static Color get surfaceMuted => _active.surfaceMuted;
  static Color get surfaceTimer => _active.surfaceTimer;
  static Color get shimmerBase => _active.shimmerBase;
  static Color get borderDialog => _active.borderDialog;
  static Color get buttonText => _active.buttonText;

  // Brand colors
  static Color get primary => _active.primary;
  static Color get primaryAlt => _active.primaryAlt;
  static Color get secondary => _active.secondary;

  // Text colors
  static Color get textPrimary => _active.textPrimary;
  static Color get textStrong => _active.textStrong;
  static Color get textSecondary => _active.textSecondary;
  static Color get textSubtle => _active.textSubtle;
  static Color get textMuted => _active.textMuted;
  static Color get textMutedAlt => _active.textMutedAlt;

  // Borders, dividers, and controls
  static Color get border => _active.border;
  static Color get borderStrong => _active.borderStrong;
  static Color get borderNeutral => _active.borderNeutral;
  static Color get borderInput => _active.borderInput;
  static Color get borderSoft => _active.borderSoft;
  static Color get divider => _active.divider;
  static Color get chip => _active.chip;
  static Color get control => _active.control;
  static Color get error => _active.error;
  static Color get success => _active.success;
  static Color get successBackground => _active.successBackground;
  static Color get successBorder => _active.successBorder;
  static Color get warning => _active.warning;
  static Color get warningBackground => _active.warningBackground;
  static Color get warningBorder => _active.warningBorder;
  static Color get disabled => _active.disabled;

  // Theme-only tokens
  static Color get onPrimary => _active.onPrimary;
  static Color get navBarBackground => _active.navBarBackground;
  static Color get searchBackground => _active.searchBackground;
  static Color get chipSelected => _active.chipSelected;
  static Color get chipText => _active.chipText;
  static Color get chipTextSelected => _active.chipTextSelected;
  static Color get cardTitle => _active.cardTitle;
  static Color get cardMeta => _active.cardMeta;
  static Color get navActiveIcon => _active.navActiveIcon;
  static Color get navInactiveIcon => _active.navInactiveIcon;
  static Color get filterFabIcon => _active.filterFabIcon;
  static Color get rating => _active.rating;
  static Color get saga => _active.saga;
  static Color get fabShadow => _active.fabShadow;
  static Color get filterFabShadow => _active.filterFabShadow;
}

// Spacing scale
abstract final class V2Spacing {
  static const xxs = 2.0;
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const screen = 16.0;
  static const section = 24.0;
  static const field = 14.0;
  static const card = 16.0;
}

// Corner radii
abstract final class V2Radii {
  static const input = 8.0;
  static const card = 12.0;
  static const cardLarge = 16.0;
  static const dialog = 20.0;
  static const icon = 8.0;
  static const pill = 999.0;
}

// Size scale
abstract final class V2Sizes {
  static const iconSmall = 16.0;
  static const icon = 20.0;
  static const iconLarge = 24.0;
  static const control = 48.0;
  static const progress = 4.0;
}

// Durations and motion curves
abstract final class V2Motion {
  static const fast = Duration(milliseconds: 150);
  static const normal = Duration(milliseconds: 250);
  static const slow = Duration(milliseconds: 400);
  static const curve = Curves.easeInOut;
}

// Typography styles
abstract final class V2Typography {
  static const family = 'Manrope';
  static TextStyle get pageTitle => TextStyle(
    fontFamily: family,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: V2Colors.primary,
  );
  static TextStyle get sectionTitle => TextStyle(
    fontFamily: family,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: V2Colors.primary,
  );
  static TextStyle get cardTitle => TextStyle(
    fontFamily: family,
    fontSize: 19,
    fontWeight: FontWeight.w600,
    color: V2Colors.primary,
    height: 1.25,
  );
  static TextStyle get title => TextStyle(
    fontFamily: family,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: V2Colors.textPrimary,
  );
  static TextStyle get body => TextStyle(
    fontFamily: family,
    fontSize: 14,
    color: V2Colors.textPrimary,
  );
  static TextStyle get bodySmall => TextStyle(
    fontFamily: family,
    fontSize: 13,
    color: V2Colors.textSecondary,
  );
  static TextStyle get label => TextStyle(
    fontFamily: family,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: V2Colors.textSecondary,
  );
  static TextStyle get caption => TextStyle(
    fontFamily: family,
    fontSize: 12,
    color: V2Colors.textMuted,
  );
  static TextStyle get metadata => TextStyle(
    fontFamily: family,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: .5,
    color: V2Colors.textSubtle,
  );
  static TextStyle get button => TextStyle(
    fontFamily: family,
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );
  static TextStyle get overline => TextStyle(
    fontFamily: family,
    fontSize: 11,
    fontWeight: FontWeight.w800,
    letterSpacing: .55,
    color: V2Colors.textMutedAlt,
  );

  static TextTheme apply(TextTheme theme) => theme
      .apply(fontFamily: family)
      .copyWith(
        headlineLarge: theme.headlineLarge?.copyWith(
          fontFamily: family,
          fontSize: 24,
        ),
        headlineMedium: theme.headlineMedium?.copyWith(
          fontFamily: family,
          fontSize: 20,
        ),
        headlineSmall: theme.headlineSmall?.copyWith(
          fontFamily: family,
          fontSize: 18,
        ),
        titleLarge: theme.titleLarge?.copyWith(
          fontFamily: family,
          fontSize: 18,
        ),
        titleMedium: theme.titleMedium?.copyWith(
          fontFamily: family,
          fontSize: 16,
        ),
        titleSmall: theme.titleSmall?.copyWith(
          fontFamily: family,
          fontSize: 14,
        ),
        bodyLarge: theme.bodyLarge?.copyWith(fontFamily: family, fontSize: 14),
        bodyMedium: theme.bodyMedium?.copyWith(
          fontFamily: family,
          fontSize: 13,
        ),
        bodySmall: theme.bodySmall?.copyWith(fontFamily: family, fontSize: 12),
      );
}

// Shadow recipes
abstract final class V2Shadows {
  static const subtle = [
    BoxShadow(color: Color(0x0A000000), blurRadius: 6, offset: Offset(0, 3)),
  ];
  static const card = [
    BoxShadow(color: Color(0x0A5D2641), blurRadius: 10, offset: Offset(0, 2)),
  ];
}

// Reusable component styles and decorations
abstract final class V2Components {
  static SystemUiOverlayStyle get systemOverlay => SystemUiOverlayStyle(
    statusBarColor: V2Colors.background,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
  );

  static InputDecoration inputDecoration({
    required String label,
    IconData? icon,
    String? hint,
    Widget? suffix,
    bool softBorder = false,
  }) {
    final borderColor = softBorder ? V2Colors.border : V2Colors.borderInput;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(V2Radii.input),
      borderSide: BorderSide(color: borderColor),
    );
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon:
          icon == null
              ? null
              : Icon(icon, color: V2Colors.primary, size: V2Sizes.icon),
      suffixIcon: suffix,
      filled: true,
      fillColor: V2Colors.surface,
      border: border,
      enabledBorder: border,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(V2Radii.input),
        borderSide: BorderSide(color: V2Colors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(V2Radii.input),
        borderSide: BorderSide(color: V2Colors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(V2Radii.input),
        borderSide: BorderSide(color: V2Colors.error, width: 1.5),
      ),
      labelStyle: V2Typography.label.copyWith(color: V2Colors.primary),
      hintStyle: V2Typography.label.copyWith(color: V2Colors.primary),
      floatingLabelStyle: V2Typography.caption.copyWith(
        color: V2Colors.primary,
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: V2Spacing.lg,
        vertical: V2Spacing.field,
      ),
    );
  }

  static ChipThemeData get chipTheme => ChipThemeData(
    backgroundColor: V2Colors.chip,
    labelStyle: TextStyle(
      fontFamily: V2Typography.family,
      color: V2Colors.primary,
      fontSize: 12,
    ),
    deleteIconColor: V2Colors.textSecondary,
    side: BorderSide(color: V2Colors.border),
    shape: StadiumBorder(),
    padding: EdgeInsets.symmetric(horizontal: V2Spacing.xs),
  );

  static SnackBarThemeData get snackBarTheme => SnackBarThemeData(
    backgroundColor: V2Colors.primary,
    actionTextColor: Colors.white,
    disabledActionTextColor: Colors.white70,
    contentTextStyle: V2Typography.label.copyWith(color: Colors.white),
    behavior: SnackBarBehavior.floating,
    elevation: 6,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(V2Radii.card),
    ),
  );

  static MaterialBannerThemeData get bannerTheme => MaterialBannerThemeData(
    backgroundColor: V2Colors.primary,
    contentTextStyle: TextStyle(
      fontFamily: V2Typography.family,
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: Colors.white,
    ),
  );
}

// Full application theme builder
abstract final class V2DesignSystem {
  static ThemeData theme(
    ColorScheme colorScheme, {
    required Brightness brightness,
  }) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      fontFamily: V2Typography.family,
    );
    return base.copyWith(
      scaffoldBackgroundColor: V2Colors.background,
      textTheme: V2Typography.apply(base.textTheme),
      snackBarTheme: V2Components.snackBarTheme,
      bannerTheme: V2Components.bannerTheme,
      chipTheme: V2Components.chipTheme,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: V2Colors.background,
        foregroundColor: V2Colors.primary,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: V2Components.systemOverlay,
        iconTheme: IconThemeData(color: V2Colors.primary),
        titleTextStyle: V2Typography.sectionTitle,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: V2Colors.primary,
          foregroundColor: Colors.white,
          textStyle: V2Typography.button,
          padding: const EdgeInsets.symmetric(
            horizontal: V2Spacing.xl,
            vertical: V2Spacing.md,
          ),
          shape: const StadiumBorder(),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: V2Colors.primary,
          textStyle: V2Typography.button,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: V2Colors.primary,
        foregroundColor: Colors.white,
      ),
      iconTheme: IconThemeData(color: V2Colors.primary),
      cardTheme: CardThemeData(
        elevation: 2,
        color: V2Colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(V2Radii.card),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: V2Colors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(V2Radii.input),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(V2Radii.input),
          borderSide: BorderSide(color: V2Colors.primary, width: 1.5),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: V2Colors.primary.withValues(alpha: .2),
        labelTextStyle: WidgetStatePropertyAll(
          V2Typography.caption.copyWith(color: V2Colors.textPrimary),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: V2Colors.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(V2Radii.dialog),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: V2Colors.divider,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
