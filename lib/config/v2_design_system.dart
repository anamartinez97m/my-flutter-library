import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Color palette
abstract final class V2Colors {
  // Backgrounds and surfaces
  static const background = Color(0xFFFDF8F6);
  static const surface = Colors.white;
  static const surfaceWarm = Color(0xFFFFFCFA);
  static const surfaceAlt = Color(0xFFFFFBFA);
  static const surfaceMuted = Color(0xFFF5F3F2);
  static const surfaceTimer = Color(0xFFF7F3F0);
  static const shimmerBase = Color(0xFFF2E8E3);
  static const borderDialog = Color(0xFFDDD9D7);
  static const buttonText = Color(0xFFD68DAC);

  // Brand colors
  static const primary = Color(0xFF43102B);
  static const primaryAlt = Color(0xFF5D2641);
  static const secondary = Color(0xFF894B67);

  // Text colors
  static const textPrimary = Color(0xFF1C1B1A);
  static const textStrong = Color(0xFF270008);
  static const textSecondary = Color(0xFF514348);
  static const textSubtle = Color(0xFF5F5E5C);
  static const textMuted = Color(0xFF76656B);
  static const textMutedAlt = Color(0xFF7A6A71);

  // Borders, dividers, and controls
  static const border = Color(0xFFD5C2C7);
  static const borderStrong = Color(0xFF27231E);
  static const borderNeutral = Color(0xFFCEC5BE);
  static const borderInput = Color(0xFF6B7280);
  static const borderSoft = Color(0xFFE8E2DE);
  static const divider = Color(0xFFE6E2DF);
  static const chip = Color(0xFFF2EDEB);
  static const control = Color(0xFFECE7E5);
  static const error = Color(0xFFBA1A1A);
  static const success = Color(0xFF059669);
  static const successBackground = Color(0xFFECFDF5);
  static const successBorder = Color(0xFFA7F3D0);
  static const warning = Color(0xFF7A4D00);
  static const warningBackground = Color(0xFFFFF4D9);
  static const warningBorder = Color(0xFFE5C46B);
  static const disabled = Color(0xFFB8B0B3);
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
  static const pageTitle = TextStyle(
    fontFamily: family,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: V2Colors.primary,
  );
  static const sectionTitle = TextStyle(
    fontFamily: family,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: V2Colors.primary,
  );
  static const cardTitle = TextStyle(
    fontFamily: family,
    fontSize: 19,
    fontWeight: FontWeight.w600,
    color: V2Colors.primary,
    height: 1.25,
  );
  static const title = TextStyle(
    fontFamily: family,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: V2Colors.textPrimary,
  );
  static const body = TextStyle(
    fontFamily: family,
    fontSize: 14,
    color: V2Colors.textPrimary,
  );
  static const bodySmall = TextStyle(
    fontFamily: family,
    fontSize: 13,
    color: V2Colors.textSecondary,
  );
  static const label = TextStyle(
    fontFamily: family,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: V2Colors.textSecondary,
  );
  static const caption = TextStyle(
    fontFamily: family,
    fontSize: 12,
    color: V2Colors.textMuted,
  );
  static const metadata = TextStyle(
    fontFamily: family,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: .5,
    color: V2Colors.textSubtle,
  );
  static const button = TextStyle(
    fontFamily: family,
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );
  static const overline = TextStyle(
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
  static const systemOverlay = SystemUiOverlayStyle(
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
        borderSide: const BorderSide(color: V2Colors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(V2Radii.input),
        borderSide: const BorderSide(color: V2Colors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(V2Radii.input),
        borderSide: const BorderSide(color: V2Colors.error, width: 1.5),
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

  static const chipTheme = ChipThemeData(
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

  static const bannerTheme = MaterialBannerThemeData(
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
        iconTheme: const IconThemeData(color: V2Colors.primary),
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
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: V2Colors.primary,
        foregroundColor: Colors.white,
      ),
      iconTheme: const IconThemeData(color: V2Colors.primary),
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
          borderSide: const BorderSide(color: V2Colors.primary, width: 1.5),
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
      dividerTheme: const DividerThemeData(
        color: V2Colors.divider,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
