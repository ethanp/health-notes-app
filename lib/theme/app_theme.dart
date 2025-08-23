import 'package:flutter/cupertino.dart';

class AppTheme {
  static const CupertinoThemeData lightTheme = CupertinoThemeData(
    brightness: Brightness.light,
    primaryColor: CupertinoColors.systemBlue,
    scaffoldBackgroundColor: CupertinoColors.systemBackground,
    barBackgroundColor: CupertinoColors.systemGrey6,
    textTheme: CupertinoTextThemeData(
      primaryColor: CupertinoColors.systemBlue,
      textStyle: TextStyle(color: CupertinoColors.label),
    ),
  );

  static const CupertinoThemeData darkTheme = CupertinoThemeData(
    brightness: Brightness.dark,
    primaryColor: CupertinoColors.systemBlue,
    scaffoldBackgroundColor: CupertinoColors.systemBackground,
    barBackgroundColor: CupertinoColors.systemGrey6,
    textTheme: CupertinoTextThemeData(
      primaryColor: CupertinoColors.systemBlue,
      textStyle: TextStyle(color: CupertinoColors.label),
    ),
  );

  static const TextStyle displayLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: CupertinoColors.label,
  );

  static const TextStyle displayMedium = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: CupertinoColors.label,
  );

  static const TextStyle displaySmall = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: CupertinoColors.label,
  );

  static const TextStyle headlineLarge = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: CupertinoColors.label,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: CupertinoColors.label,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: CupertinoColors.label,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    color: CupertinoColors.label,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    color: CupertinoColors.label,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    color: CupertinoColors.label,
  );

  static const TextStyle labelLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: CupertinoColors.white,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: CupertinoColors.label,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: CupertinoColors.label,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    color: CupertinoColors.systemGrey,
  );

  static const TextStyle captionSecondary = TextStyle(
    fontSize: 12,
    color: CupertinoColors.systemGrey2,
  );

  static const TextStyle subtitle = TextStyle(
    fontSize: 16,
    color: CupertinoColors.systemGrey,
  );

  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: CupertinoColors.white,
  );

  static const TextStyle buttonSecondary = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: CupertinoColors.systemBlue,
  );

  static const TextStyle input = TextStyle(
    fontSize: 16,
    color: CupertinoColors.label,
  );

  static const TextStyle inputPlaceholder = TextStyle(
    fontSize: 16,
    color: CupertinoColors.systemGrey,
  );

  static const TextStyle error = TextStyle(
    fontSize: 14,
    color: CupertinoColors.destructiveRed,
  );

  static const TextStyle success = TextStyle(
    fontSize: 14,
    color: CupertinoColors.systemGreen,
  );

  static const TextStyle warning = TextStyle(
    fontSize: 14,
    color: CupertinoColors.systemOrange,
  );

  static const TextStyle info = TextStyle(
    fontSize: 14,
    color: CupertinoColors.systemBlue,
  );
}
