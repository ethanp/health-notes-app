import 'package:flutter/cupertino.dart';

class AppTheme {
  static const Color primary = Color(0xFF6B73FF); // Warm purple-blue
  static const Color primaryLight = Color(0xFF8B93FF);
  static const Color primaryDark = Color(0xFF4A52E0);

  static const Color secondary = Color(0xFF64B5F6); // Calming blue
  static const Color accent = Color(0xFF81C784); // Soothing green
  static const Color accentWarm = Color(0xFFFFB74D); // Warm orange

  static const Color destructive = Color(0xFFE57373); // Softer red
  static const Color successColor = Color(0xFF81C784); // Calming green
  static const Color warning = Color(0xFFFFB74D); // Warm orange

  static const Color backgroundPrimary = Color(0xFF1A1B2E); // Deep blue-grey
  static const Color backgroundSecondary = Color(
    0xFF252A3A,
  ); // Warmer secondary
  static const Color backgroundTertiary = Color(0xFF2F3542); // Elevated surface
  static const Color backgroundQuaternary = Color(
    0xFF3A4151,
  ); // Higher elevation
  static const Color backgroundQuinary = Color(0xFF4A5568); // Highest elevation

  static const Color textPrimary = Color(0xFFF8FAFC); // Almost white
  static const Color textSecondary = Color(0xFFE2E8F0); // Soft white
  static const Color textTertiary = Color(0xFFCBD5E1); // Muted white
  static const Color textQuaternary = Color(0xFF94A3B8); // Very muted

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [backgroundPrimary, backgroundSecondary],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [backgroundSecondary, backgroundTertiary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient elevatedGradient = LinearGradient(
    colors: [backgroundTertiary, backgroundQuaternary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static List<BoxShadow> get subtleShadow => [
    BoxShadow(
      color: CupertinoColors.black.withValues(alpha: 0.1),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get mediumShadow => [
    BoxShadow(
      color: CupertinoColors.black.withValues(alpha: 0.15),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get strongShadow => [
    BoxShadow(
      color: CupertinoColors.black.withValues(alpha: 0.2),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
  ];

  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusExtraLarge = 24.0;

  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;

  static const CupertinoThemeData darkTheme = CupertinoThemeData(
    brightness: Brightness.dark,
    primaryColor: primary,
    scaffoldBackgroundColor: backgroundPrimary,
    barBackgroundColor: backgroundSecondary,
    textTheme: CupertinoTextThemeData(
      primaryColor: primary,
      textStyle: TextStyle(color: textPrimary),
    ),
  );

  static BoxDecoration get primaryCard => BoxDecoration(
    gradient: cardGradient,
    borderRadius: BorderRadius.circular(radiusMedium),
    boxShadow: subtleShadow,
  );

  static BoxDecoration get elevatedCard => BoxDecoration(
    gradient: elevatedGradient,
    borderRadius: BorderRadius.circular(radiusMedium),
    boxShadow: mediumShadow,
  );

  static BoxDecoration get primaryButton => BoxDecoration(
    gradient: primaryGradient,
    borderRadius: BorderRadius.circular(radiusMedium),
    boxShadow: subtleShadow,
  );

  static BoxDecoration get secondaryButton => BoxDecoration(
    color: backgroundTertiary,
    borderRadius: BorderRadius.circular(radiusMedium),
    border: Border.all(color: primary.withValues(alpha: 0.3), width: 1),
    boxShadow: subtleShadow,
  );

  static BoxDecoration get inputField => BoxDecoration(
    color: backgroundTertiary,
    borderRadius: BorderRadius.circular(radiusMedium),
    border: Border.all(color: backgroundQuaternary, width: 1),
    boxShadow: subtleShadow,
  );

  static BoxDecoration get searchField => BoxDecoration(
    color: backgroundTertiary,
    borderRadius: BorderRadius.circular(radiusLarge),
    border: Border.all(color: backgroundQuaternary, width: 1),
    boxShadow: subtleShadow,
  );

  static BoxDecoration get filterChip => BoxDecoration(
    gradient: LinearGradient(
      colors: [primary.withValues(alpha: 0.1), primary.withValues(alpha: 0.05)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.circular(radiusLarge),
    border: Border.all(color: primary.withValues(alpha: 0.2), width: 1),
  );

  static BoxDecoration get activeFilterChip => BoxDecoration(
    gradient: primaryGradient,
    borderRadius: BorderRadius.circular(radiusLarge),
    boxShadow: subtleShadow,
  );

  static BoxDecoration get statusCard => BoxDecoration(
    gradient: LinearGradient(
      colors: [
        successColor.withValues(alpha: 0.1),
        successColor.withValues(alpha: 0.05),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.circular(radiusMedium),
    border: Border.all(color: successColor.withValues(alpha: 0.2), width: 1),
  );

  static TextStyle textStyle(
    double fontSize,
    FontWeight fontWeight,
    Color color, {
    double? height,
    double? letterSpacing,
  }) => TextStyle(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
  );

  static TextStyle get headlineLarge => textStyle(
    32,
    FontWeight.w700,
    textPrimary,
    height: 1.2,
    letterSpacing: -0.5,
  );

  static TextStyle get headlineMedium => textStyle(
    24,
    FontWeight.w600,
    textPrimary,
    height: 1.3,
    letterSpacing: -0.3,
  );

  static TextStyle get headlineSmall => textStyle(
    20,
    FontWeight.w600,
    textPrimary,
    height: 1.4,
    letterSpacing: -0.2,
  );

  static TextStyle get bodyLarge => textStyle(
    18,
    FontWeight.normal,
    textPrimary,
    height: 1.5,
    letterSpacing: 0.1,
  );

  static TextStyle get bodyMedium => textStyle(
    16,
    FontWeight.normal,
    textPrimary,
    height: 1.5,
    letterSpacing: 0.1,
  );

  static TextStyle get bodySmall => textStyle(
    14,
    FontWeight.normal,
    textSecondary,
    height: 1.5,
    letterSpacing: 0.1,
  );

  static TextStyle get labelLarge => textStyle(
    16,
    FontWeight.w600,
    textPrimary,
    height: 1.4,
    letterSpacing: 0.1,
  );

  static TextStyle get labelMedium => textStyle(
    14,
    FontWeight.w500,
    textPrimary,
    height: 1.4,
    letterSpacing: 0.1,
  );

  static TextStyle get labelSmall => textStyle(
    12,
    FontWeight.w500,
    textSecondary,
    height: 1.4,
    letterSpacing: 0.1,
  );

  static TextStyle get caption => textStyle(
    12,
    FontWeight.normal,
    textTertiary,
    height: 1.4,
    letterSpacing: 0.1,
  );

  static TextStyle get captionSecondary => textStyle(
    12,
    FontWeight.normal,
    textQuaternary,
    height: 1.4,
    letterSpacing: 0.1,
  );

  static TextStyle get buttonPrimary => textStyle(
    16,
    FontWeight.w600,
    CupertinoColors.white,
    height: 1.4,
    letterSpacing: 0.1,
  );

  static TextStyle get buttonSecondary =>
      textStyle(16, FontWeight.w600, primary, height: 1.4, letterSpacing: 0.1);

  static TextStyle get input => textStyle(
    16,
    FontWeight.normal,
    textPrimary,
    height: 1.5,
    letterSpacing: 0.1,
  );

  static TextStyle get inputPlaceholder => textStyle(
    16,
    FontWeight.normal,
    textQuaternary,
    height: 1.5,
    letterSpacing: 0.1,
  );

  static TextStyle get error => textStyle(
    14,
    FontWeight.normal,
    destructive,
    height: 1.4,
    letterSpacing: 0.1,
  );

  static TextStyle get success => textStyle(
    14,
    FontWeight.normal,
    successColor,
    height: 1.4,
    letterSpacing: 0.1,
  );

  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationMedium = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);

  static const Curve animationCurve = Curves.easeInOutCubic;
  static const Curve bounceCurve = Curves.elasticOut;
  static const Curve slideCurve = Curves.easeOutQuart;
}
