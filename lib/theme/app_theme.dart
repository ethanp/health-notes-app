import 'package:flutter/cupertino.dart';

/// Core color palette for the Health Notes app
/// Following professional UI/UX patterns with semantic color naming
class AppColors {
  // Primary Brand Colors
  static const Color primary = Color(0xFF6B73FF); // Warm purple-blue
  static const Color primaryLight = Color(0xFF8B93FF);
  static const Color primaryDark = Color(0xFF4A52E0);

  // Secondary Colors
  static const Color secondary = Color(0xFF64B5F6); // Calming blue
  static const Color accent = Color(0xFF81C784); // Soothing green
  static const Color accentWarm = Color(0xFFFFB74D); // Warm orange

  // Semantic Colors
  static const Color destructive = Color(0xFFE57373); // Softer red
  static const Color success = Color(0xFF81C784); // Calming green
  static const Color warning = Color(0xFFFFB74D); // Warm orange

  // Background Colors (elevation hierarchy)
  static const Color backgroundPrimary = Color(0xFF1A1B2E); // Deep blue-grey
  static const Color backgroundSecondary = Color(
    0xFF252A3A,
  ); // Warmer secondary
  static const Color backgroundTertiary = Color(0xFF2F3542); // Elevated surface
  static const Color backgroundQuaternary = Color(
    0xFF3A4151,
  ); // Higher elevation
  static const Color backgroundQuinary = Color(0xFF4A5568); // Highest elevation

  // Text Colors (readability hierarchy)
  static const Color textPrimary = Color(0xFFF8FAFC); // Almost white
  static const Color textSecondary = Color(0xFFE2E8F0); // Soft white
  static const Color textTertiary = Color(0xFFCBD5E1); // Muted white
  static const Color textQuaternary = Color(0xFF94A3B8); // Very muted
}

/// Typography system for consistent text styling
/// Pre-configured text styles eliminate the need for repetitive copyWith calls
class AppTypography {
  // Base text styles (foundational styles)
  static TextStyle get headlineLarge => const TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.2,
    letterSpacing: -0.5,
  );

  static TextStyle get headlineMedium => headlineLarge.copyWith(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: -0.3,
  );

  static TextStyle get headlineSmall =>
      headlineMedium.copyWith(fontSize: 20, height: 1.4, letterSpacing: -0.2);

  static TextStyle get bodyLarge => const TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
    height: 1.5,
    letterSpacing: 0.1,
  );

  static TextStyle get bodyMedium => bodyLarge.copyWith(fontSize: 16);

  static TextStyle get bodySmall =>
      bodyMedium.copyWith(fontSize: 14, color: AppColors.textSecondary);

  static TextStyle get labelLarge => const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.4,
    letterSpacing: 0.1,
  );

  static TextStyle get labelMedium =>
      labelLarge.copyWith(fontSize: 14, fontWeight: FontWeight.w500);

  static TextStyle get labelSmall =>
      labelMedium.copyWith(fontSize: 12, color: AppColors.textSecondary);

  static TextStyle get caption => const TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textTertiary,
    height: 1.4,
    letterSpacing: 0.1,
  );

  static TextStyle get captionSecondary =>
      caption.copyWith(color: AppColors.textQuaternary);

  // Semantic text styles
  static TextStyle get buttonPrimary => const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: CupertinoColors.white,
    height: 1.4,
    letterSpacing: 0.1,
  );

  static TextStyle get buttonSecondary =>
      buttonPrimary.copyWith(color: AppColors.primary);

  static TextStyle get input => const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
    height: 1.5,
    letterSpacing: 0.1,
  );

  static TextStyle get inputPlaceholder =>
      input.copyWith(color: AppColors.textQuaternary);

  static TextStyle get error => const TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.destructive,
    height: 1.4,
    letterSpacing: 0.1,
  );

  static TextStyle get success => const TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.success,
    height: 1.4,
    letterSpacing: 0.1,
  );

  // Navigation and system UI
  static TextStyle get navTitleTextStyle => const TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.3,
    letterSpacing: 0.1,
  );

  static TextStyle get baseTextStyle => const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
    height: 1.5,
    letterSpacing: 0.1,
  );

  // System UI color variants (commonly used)
  static TextStyle get bodySmallSystemGrey =>
      bodySmall.copyWith(color: CupertinoColors.systemGrey);

  static TextStyle get bodyMediumSystemGrey =>
      bodyMedium.copyWith(color: CupertinoColors.systemGrey);

  static TextStyle get bodySmallSystemGreySemibold =>
      bodySmallSystemGrey.copyWith(fontWeight: FontWeight.w600);

  static TextStyle get bodyMediumSystemGreySemibold =>
      bodyMediumSystemGrey.copyWith(fontWeight: FontWeight.w600);

  // White text variants (for dark backgrounds)
  static TextStyle get bodySmallWhite =>
      bodySmall.copyWith(color: CupertinoColors.white);

  static TextStyle get bodyMediumWhite =>
      bodyMedium.copyWith(color: CupertinoColors.white);

  static TextStyle get bodyMediumWhiteSemibold =>
      bodyMediumWhite.copyWith(fontWeight: FontWeight.w600);

  static TextStyle get headlineSmallWhite =>
      headlineSmall.copyWith(color: CupertinoColors.white);

  // Tertiary color variants (muted text)
  static TextStyle get bodySmallTertiary =>
      bodySmall.copyWith(color: AppColors.textTertiary);

  static TextStyle get bodyMediumTertiary =>
      bodyMedium.copyWith(color: AppColors.textTertiary);

  // Semibold weight variants
  static TextStyle get bodyMediumSemibold =>
      bodyMedium.copyWith(fontWeight: FontWeight.w600);

  static TextStyle get bodyMediumSemiboldBlue =>
      bodyMediumSemibold.copyWith(color: CupertinoColors.systemBlue);

  // Bold variants
  static TextStyle get bodySmallWhiteBold =>
      bodySmallWhite.copyWith(fontWeight: FontWeight.bold);

  // Additional essential variants (commonly used)
  static TextStyle get bodyLargeSecondary =>
      bodyLarge.copyWith(color: AppColors.textSecondary);

  static TextStyle get bodyMediumPrimary =>
      bodyMedium.copyWith(color: AppColors.textPrimary);

  static TextStyle get bodySmallSecondary =>
      bodySmall.copyWith(color: AppColors.textSecondary);

  static TextStyle get bodySmallPrimary =>
      bodySmall.copyWith(color: AppColors.textPrimary);

  static TextStyle get labelLargePrimary =>
      labelLarge.copyWith(color: AppColors.textPrimary);

  static TextStyle get labelMediumWhite =>
      labelMedium.copyWith(color: CupertinoColors.white);

  static TextStyle get labelMediumSecondary =>
      labelMedium.copyWith(color: AppColors.textSecondary);

  static TextStyle get labelMediumSystemGreySemibold =>
      bodySmallSystemGrey.copyWith(fontWeight: FontWeight.w600);

  static TextStyle get bodySmallGreenSmall =>
      bodySmall.copyWith(color: CupertinoColors.systemGreen, fontSize: 10);

  static TextStyle get bodySmallSemiboldPrimary => bodySmall.copyWith(
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    fontSize: 13,
  );

  static TextStyle get bodySmallSecondarySmall =>
      bodySmallSecondary.copyWith(fontSize: 9);

  static TextStyle get bodyMediumPrimarySemibold => bodyMedium.copyWith(
    fontWeight: FontWeight.w600,
    color: AppColors.primary,
  );

  static TextStyle get labelLargeWhiteSemibold =>
      bodyMediumWhite.copyWith(fontWeight: FontWeight.w600);

  // Button bold variants
  static TextStyle get buttonPrimaryBold =>
      buttonPrimary.copyWith(fontWeight: FontWeight.bold);

  static TextStyle get buttonPrimaryBoldSmall =>
      buttonPrimaryBold.copyWith(fontSize: 10);

  // Additional hierarchy variants
  static TextStyle get headlineSmallPrimary =>
      headlineSmall.copyWith(color: AppColors.textPrimary);

  static TextStyle get bodyLargePrimary =>
      bodyLarge.copyWith(color: AppColors.textPrimary);

  static TextStyle get bodyMediumSecondary =>
      bodyMedium.copyWith(color: AppColors.textSecondary);

  static TextStyle get captionQuaternary =>
      caption.copyWith(color: AppColors.textQuaternary);

  // Metric type selection styles
  static TextStyle get metricTypeSelected => bodySmall.copyWith(
    color: CupertinoColors.systemBlue.withValues(alpha: 0.8),
    fontSize: 12,
  );

  static TextStyle get metricTypeUnselected => bodySmall.copyWith(
    color: CupertinoColors.white.withValues(alpha: 0.7),
    fontSize: 12,
  );
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

  // Component decorations
  static BoxDecoration get primaryCard => BoxDecoration(
    gradient: cardGradient,
    borderRadius: BorderRadius.circular(AppRadius.medium),
    boxShadow: subtleShadow,
  );

  static BoxDecoration get elevatedCard => BoxDecoration(
    gradient: elevatedGradient,
    borderRadius: BorderRadius.circular(AppRadius.medium),
    boxShadow: mediumShadow,
  );

  static BoxDecoration get primaryButton => BoxDecoration(
    gradient: primaryGradient,
    borderRadius: BorderRadius.circular(AppRadius.medium),
    boxShadow: subtleShadow,
  );

  static BoxDecoration get secondaryButton => BoxDecoration(
    color: AppColors.backgroundTertiary,
    borderRadius: BorderRadius.circular(AppRadius.medium),
    border: Border.all(
      color: AppColors.primary.withValues(alpha: 0.3),
      width: 1,
    ),
    boxShadow: subtleShadow,
  );

  static BoxDecoration get inputField => BoxDecoration(
    color: AppColors.backgroundTertiary,
    borderRadius: BorderRadius.circular(AppRadius.medium),
    border: Border.all(color: AppColors.backgroundQuaternary, width: 1),
    boxShadow: subtleShadow,
  );

  static BoxDecoration get searchField => BoxDecoration(
    color: AppColors.backgroundTertiary,
    borderRadius: BorderRadius.circular(AppRadius.large),
    border: Border.all(color: AppColors.backgroundQuaternary, width: 1),
    boxShadow: subtleShadow,
  );

  static BoxDecoration get filterChip => BoxDecoration(
    gradient: LinearGradient(
      colors: [
        AppColors.primary.withValues(alpha: 0.1),
        AppColors.primary.withValues(alpha: 0.05),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.circular(AppRadius.large),
    border: Border.all(
      color: AppColors.primary.withValues(alpha: 0.2),
      width: 1,
    ),
  );

  static BoxDecoration get activeFilterChip => BoxDecoration(
    gradient: primaryGradient,
    borderRadius: BorderRadius.circular(AppRadius.large),
    boxShadow: subtleShadow,
  );

  static BoxDecoration get statusCard => BoxDecoration(
    gradient: LinearGradient(
      colors: [
        AppColors.success.withValues(alpha: 0.1),
        AppColors.success.withValues(alpha: 0.05),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.circular(AppRadius.medium),
    border: Border.all(
      color: AppColors.success.withValues(alpha: 0.2),
      width: 1,
    ),
  );

  static BoxDecoration get primaryCardWithBorder => BoxDecoration(
    gradient: cardGradient,
    borderRadius: BorderRadius.circular(AppRadius.medium),
    border: Border.all(
      color: AppColors.textSecondary.withValues(alpha: 0.1),
      width: 1,
    ),
    boxShadow: subtleShadow,
  );
}
