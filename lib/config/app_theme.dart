import 'package:flutter/material.dart';

/// Application theme configuration with consistent spacing and styles
class AppTheme {
  // Spacing constants
  static const double spacingXSmall = 4.0;
  static const double spacingSmall = 8.0;
  static const double spacingMedium = 12.0;
  static const double spacingLarge = 16.0;
  static const double spacingXLarge = 24.0;
  static const double spacingXXLarge = 32.0;

  // Card properties
  static const double cardElevation = 2.0;
  static const double cardBorderRadius = 12.0;

  // Icon sizes
  static const double iconSizeSmall = 20.0;
  static const double iconSizeMedium = 24.0;
  static const double iconSizeLarge = 36.0;

  // Colors
  static const Color primaryColor = Colors.deepPurple;
  static const Color accentColor = Colors.purpleAccent;
  static const Color errorColor = Colors.red;
  static const Color successColor = Colors.green;

  // Text styles
  static TextStyle? headlineLarge(BuildContext context) =>
      Theme.of(context).textTheme.headlineLarge;

  static TextStyle? headlineMedium(BuildContext context) =>
      Theme.of(context).textTheme.headlineMedium;

  static TextStyle? headlineSmall(BuildContext context) =>
      Theme.of(context).textTheme.headlineSmall;

  static TextStyle? titleLarge(BuildContext context) =>
      Theme.of(context).textTheme.titleLarge;

  static TextStyle? titleMedium(BuildContext context) =>
      Theme.of(context).textTheme.titleMedium;

  static TextStyle? titleSmall(BuildContext context) =>
      Theme.of(context).textTheme.titleSmall;

  static TextStyle? bodyLarge(BuildContext context) =>
      Theme.of(context).textTheme.bodyLarge;

  static TextStyle? bodyMedium(BuildContext context) =>
      Theme.of(context).textTheme.bodyMedium;

  static TextStyle? bodySmall(BuildContext context) =>
      Theme.of(context).textTheme.bodySmall;

  // Common widget styles
  static EdgeInsets get cardPadding =>
      const EdgeInsets.all(spacingLarge);

  static EdgeInsets get cardMargin =>
      const EdgeInsets.symmetric(
        horizontal: spacingLarge,
        vertical: spacingSmall,
      );

  static EdgeInsets get screenPadding =>
      const EdgeInsets.all(spacingLarge);

  static EdgeInsets get sectionPadding =>
      const EdgeInsets.symmetric(
        horizontal: spacingLarge,
        vertical: spacingMedium,
      );

  static SizedBox get verticalSpaceXSmall =>
      const SizedBox(height: spacingXSmall);

  static SizedBox get verticalSpaceSmall =>
      const SizedBox(height: spacingSmall);

  static SizedBox get verticalSpaceMedium =>
      const SizedBox(height: spacingMedium);

  static SizedBox get verticalSpaceLarge =>
      const SizedBox(height: spacingLarge);

  static SizedBox get verticalSpaceXLarge =>
      const SizedBox(height: spacingXLarge);

  static SizedBox get verticalSpaceXXLarge =>
      const SizedBox(height: spacingXXLarge);

  static SizedBox get horizontalSpaceXSmall =>
      const SizedBox(width: spacingXSmall);

  static SizedBox get horizontalSpaceSmall =>
      const SizedBox(width: spacingSmall);

  static SizedBox get horizontalSpaceMedium =>
      const SizedBox(width: spacingMedium);

  static SizedBox get horizontalSpaceLarge =>
      const SizedBox(width: spacingLarge);

  // Card decoration
  static ShapeBorder get cardShape =>
      RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(cardBorderRadius),
      );

  // Input decoration
  static InputDecoration inputDecoration({
    required String labelText,
    IconData? prefixIcon,
    String? hintText,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      border: const OutlineInputBorder(),
      prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
    );
  }

  // Snackbar
  static SnackBar successSnackBar(String message) {
    return SnackBar(
      content: Text(message),
      backgroundColor: successColor,
      duration: const Duration(seconds: 3),
    );
  }

  static SnackBar errorSnackBar(String message) {
    return SnackBar(
      content: Text(message),
      backgroundColor: errorColor,
      duration: const Duration(seconds: 5),
    );
  }

  static SnackBar infoSnackBar(String message, {Duration? duration}) {
    return SnackBar(
      content: Text(message),
      duration: duration ?? const Duration(seconds: 3),
    );
  }
}
