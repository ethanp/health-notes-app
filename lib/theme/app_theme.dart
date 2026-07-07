import 'package:flutter/cupertino.dart';

/// Core color palette for the Health Notes app
/// Following professional UI/UX patterns with semantic color naming
class AppColors {
  // Primary colors
  static const Color primary = Color(0xFF6B73FF); // Warm purple-blue
  static const Color primaryLight = Color(0xFF8B93FF);
  static const Color primaryDark = Color(0xFF4A52E0);

  // Secondary colors
  static const Color secondary = Color(0xFF64B5F6); // Calming blue
  static const Color accent = Color(0xFF81C784); // Soothing green
  static const Color accentWarm = Color(0xFFFFB74D); // Warm orange

  // Status colors
  static const Color destructive = Color(0xFFE57373); // Softer red
  static const Color success = Color(0xFF81C784); // Calming green
  static const Color warning = Color(0xFFFFB74D); // Warm orange

  // Background colors
  static const Color backgroundPrimary = Color(0xFF1A1B2E); // Deep blue-grey
  static const Color backgroundSecondary = Color(
    0xFF252A3A,
  ); // Warmer secondary
  static const Color backgroundTertiary = Color(0xFF2F3542); // Elevated surface
  static const Color backgroundQuaternary = Color(
    0xFF3A4151,
  ); // Higher elevation
  static const Color backgroundQuinary = Color(0xFF4A5568); // Highest elevation

  // Text colors
  static const Color textPrimary = Color(0xFFF8FAFC); // Almost white
  static const Color textSecondary = Color(0xFFE2E8F0); // Soft white
  static const Color textTertiary = Color(0xFFCBD5E1); // Muted white
  static const Color textQuaternary = Color(0xFF94A3B8); // Very muted

  // Activity intensity colors (for calendars and visualizations)
  static const Color activityNone = Color(0xFFE8F5E8); // Very light green
  static const Color activityLight = Color(0xFFC8E6C9); // Light green
  static const Color activityMedium = Color(0xFFA5D6A7); // Medium light green
  static const Color activityStrong = Color(0xFF66BB6A); // Strong green
  static const Color activityDeep = Color(0xFF4CAF50); // Deep green

  // Calendar-specific colors
  static const Color todayBorder = Color(0xFF9E9464); // Subtle yellow-grey
}

/// Typography system for consistent text styling.
///
/// Composable API: a size scale returns a [TextStyle]; color/weight/size
/// modifiers are chainable extension getters on [TextStyle] (see
/// [AppTextModifiers]). Example: `AppText.body.small.systemGrey.semibold`.
class AppText {
  static const body = _BodyScale();
  static const headline = _HeadlineScale();
  static const label = _LabelScale();

  static TextStyle get caption => const TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textTertiary,
    height: 1.4,
    letterSpacing: 0.1,
  );

  static TextStyle get input => body.medium;

  static TextStyle get inputPlaceholder => input.quaternary;

  static TextStyle get error => const TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.destructive,
    height: 1.4,
    letterSpacing: 0.1,
  );

  static TextStyle get navTitle => const TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.3,
    letterSpacing: 0.1,
  );

  static TextStyle get buttonPrimary => const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: CupertinoColors.white,
    height: 1.4,
    letterSpacing: 0.1,
  );

  static TextStyle get buttonSecondary =>
      buttonPrimary.withColor(AppColors.primary);

  static TextStyle get metricTypeSelected => body.small
      .withColor(CupertinoColors.systemBlue.withValues(alpha: 0.8))
      .size(12);

  static TextStyle get metricTypeUnselected =>
      body.small.withColor(CupertinoColors.white.withValues(alpha: 0.7)).size(12);
}

class _HeadlineScale {
  const _HeadlineScale();

  /// Canonical headline look without a fixed size; used by [size].
  static const _base = TextStyle(
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.3,
    letterSpacing: -0.3,
  );

  TextStyle get large => _base.copyWith(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.5,
  );

  TextStyle get medium => _base.copyWith(fontSize: 24);

  TextStyle get small =>
      _base.copyWith(fontSize: 20, height: 1.4, letterSpacing: -0.2);

  /// Headline style at an arbitrary size.
  TextStyle size(double fontSize) => _base.copyWith(fontSize: fontSize);
}

class _BodyScale {
  const _BodyScale();

  /// Canonical body look without a fixed size; used by [size].
  static const _base = TextStyle(
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
    height: 1.5,
    letterSpacing: 0.1,
  );

  TextStyle get large => _base.copyWith(fontSize: 18);

  TextStyle get medium => _base.copyWith(fontSize: 16);

  TextStyle get small =>
      _base.copyWith(fontSize: 14, color: AppColors.textSecondary);

  /// Body style at an arbitrary size.
  TextStyle size(double fontSize) => _base.copyWith(fontSize: fontSize);
}

class _LabelScale {
  const _LabelScale();

  /// Canonical label look without a fixed size; used by [size].
  static const _base = TextStyle(
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    height: 1.4,
    letterSpacing: 0.1,
  );

  TextStyle get large =>
      _base.copyWith(fontSize: 16, fontWeight: FontWeight.w600);

  TextStyle get medium => _base.copyWith(fontSize: 14);

  TextStyle get small =>
      _base.copyWith(fontSize: 12, color: AppColors.textSecondary);

  /// Label style at an arbitrary size.
  TextStyle size(double fontSize) => _base.copyWith(fontSize: fontSize);
}

/// Chainable color/weight/size modifiers for the [AppText] fluent API.
///
/// `withColor` is named to avoid colliding with `TextStyle.color`.
extension AppTextModifiers on TextStyle {
  TextStyle withColor(Color textColor) => copyWith(color: textColor);
  TextStyle size(double fontSize) => copyWith(fontSize: fontSize);
  TextStyle weight(FontWeight fontWeight) => copyWith(fontWeight: fontWeight);

  TextStyle get primary => withColor(AppColors.textPrimary);
  TextStyle get secondary => withColor(AppColors.textSecondary);
  TextStyle get tertiary => withColor(AppColors.textTertiary);
  TextStyle get quaternary => withColor(AppColors.textQuaternary);
  TextStyle get white => withColor(CupertinoColors.white);
  TextStyle get systemGrey => withColor(CupertinoColors.systemGrey);
  TextStyle get systemBlue => withColor(CupertinoColors.systemBlue);

  TextStyle get semibold => weight(FontWeight.w600);
  TextStyle get bold => weight(FontWeight.bold);
}

/// Spacing system for consistent layout
class AppSpacing {
  static const double xs = 4.0;
  static const double s = 8.0;
  static const double m = 16.0;
  static const double l = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

/// Border radius values for consistent component styling
class AppRadius {
  static const double small = 8.0;
  static const double medium = 12.0;
  static const double large = 16.0;
  static const double extraLarge = 24.0;
}

/// Animation durations and curves
class AppAnimation {
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration medium = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);

  static const Curve curve = Curves.easeInOutCubic;
  static const Curve slideCurve = Curves.easeOutQuart;
}

/// Pre-built component styles for consistent UI
class AppComponents {
  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [AppColors.primary, AppColors.primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [AppColors.backgroundPrimary, AppColors.backgroundSecondary],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [AppColors.backgroundSecondary, AppColors.backgroundTertiary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient elevatedGradient = LinearGradient(
    colors: [AppColors.backgroundTertiary, AppColors.backgroundQuaternary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Box shadows
  static List<BoxShadow> _shadow({
    required double alpha,
    required double blurRadius,
    required double dy,
  }) => [
    BoxShadow(
      color: CupertinoColors.black.withValues(alpha: alpha),
      blurRadius: blurRadius,
      offset: Offset(0, dy),
    ),
  ];

  static List<BoxShadow> get subtleShadow =>
      _shadow(alpha: 0.1, blurRadius: 8, dy: 2);

  static List<BoxShadow> get mediumShadow =>
      _shadow(alpha: 0.15, blurRadius: 12, dy: 4);

  static List<BoxShadow> get strongShadow =>
      _shadow(alpha: 0.2, blurRadius: 16, dy: 6);

  // Component decorations
  static BoxDecoration _surface({
    Gradient? gradient,
    Color? color,
    double radius = AppRadius.medium,
    BoxBorder? border,
    List<BoxShadow>? boxShadow,
  }) => BoxDecoration(
    gradient: gradient,
    color: color,
    borderRadius: BorderRadius.circular(radius),
    border: border,
    boxShadow: boxShadow,
  );

  static LinearGradient _tintGradient(Color color) => LinearGradient(
    colors: [color.withValues(alpha: 0.1), color.withValues(alpha: 0.05)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Soft accent-tinted surface (faint gradient fill plus a matching border),
  /// used for chips, badges, and status pills.
  static BoxDecoration tintedDecoration(
    Color color, {
    double radius = AppRadius.medium,
  }) => _surface(
    gradient: _tintGradient(color),
    radius: radius,
    border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
  );

  static BoxDecoration get primaryCard => _surface(
    gradient: cardGradient,
    border: BoxBorder.all(color: CupertinoColors.systemGrey, width: 0.25),
    boxShadow: subtleShadow,
  );

  static BoxDecoration get elevatedCard =>
      _surface(gradient: elevatedGradient, boxShadow: mediumShadow);

  static BoxDecoration get primaryButton =>
      _surface(gradient: primaryGradient, boxShadow: subtleShadow);

  static BoxDecoration get secondaryButton => _surface(
    color: AppColors.backgroundTertiary,
    border: Border.all(
      color: AppColors.primary.withValues(alpha: 0.3),
      width: 1,
    ),
    boxShadow: subtleShadow,
  );

  static BoxDecoration get inputField => _surface(
    color: AppColors.backgroundTertiary,
    border: Border.all(color: AppColors.backgroundQuaternary, width: 1),
    boxShadow: subtleShadow,
  );

  static BoxDecoration get searchField => _surface(
    color: AppColors.backgroundTertiary,
    radius: AppRadius.large,
    border: Border.all(color: AppColors.backgroundQuaternary, width: 1),
    boxShadow: subtleShadow,
  );

  static BoxDecoration get filterChip =>
      tintedDecoration(AppColors.primary, radius: AppRadius.large);

  static BoxDecoration get activeFilterChip => _surface(
    gradient: primaryGradient,
    radius: AppRadius.large,
    boxShadow: subtleShadow,
  );

  static BoxDecoration get statusCard => tintedDecoration(AppColors.success);

  static BoxDecoration get primaryCardWithBorder => _surface(
    gradient: cardGradient,
    border: Border.all(
      color: AppColors.textSecondary.withValues(alpha: 0.1),
      width: 1,
    ),
    boxShadow: subtleShadow,
  );
}
