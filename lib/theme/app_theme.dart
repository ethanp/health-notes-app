import 'package:ethan_ui/ethan_ui.dart';
import 'package:flutter/material.dart';

class AppSpacing() {
  static const double xs = 4.0;
  static const double s = 8.0;
  static const double sm = 12.0;
  static const double m = 16.0;
  static const double l = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

class AppRadius() {
  static const double xs = 2.0;
  static const double small = 8.0;
  static const double medium = 12.0;
  static const double large = 16.0;
  static const double extraLarge = 24.0;
}

class AppAnimation() {
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration medium = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);

  static const Curve curve = Curves.easeInOutCubic;
  static const Curve slideCurve = Curves.easeOutQuart;
}

class AppComponents() {
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [EColors.accent, EColors.accentGlow],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [EColors.backgroundLift, EColors.surface],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient elevatedGradient = LinearGradient(
    colors: [EColors.surface, EColors.surfaceRaised],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static List<BoxShadow> _shadow({
    required double alpha,
    required double blurRadius,
    required double dy,
  }) => [
    BoxShadow(
      color: Colors.black.withValues(alpha: alpha),
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

  static BoxDecoration tintedDecoration(
    Color color, {
    double radius = AppRadius.medium,
  }) => _surface(
    gradient: _tintGradient(color),
    radius: radius,
    border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
  );

  static BoxDecoration tintedSolidDecoration(
    Color color, {
    double radius = AppRadius.medium,
    double borderWidth = 1,
  }) => _surface(
    color: color.withValues(alpha: 0.15),
    radius: radius,
    border: borderWidth > 0
        ? Border.all(color: color.withValues(alpha: 0.3), width: borderWidth)
        : null,
  );

  static BoxDecoration get primaryCard => _surface(
    gradient: cardGradient,
    border: Border.all(color: EColors.border, width: 0.25),
    boxShadow: subtleShadow,
  );

  static BoxDecoration get elevatedCard =>
      _surface(gradient: elevatedGradient, boxShadow: mediumShadow);

  static BoxDecoration get primaryButton =>
      _surface(gradient: primaryGradient, boxShadow: subtleShadow);

  static BoxDecoration get secondaryButton => _surface(
    color: EColors.surface,
    border: Border.all(color: EColors.accent.withValues(alpha: 0.3), width: 1),
    boxShadow: subtleShadow,
  );

  static BoxDecoration get inputField => _surface(
    color: EColors.surface,
    border: Border.all(color: EColors.surfaceRaised, width: 1),
    boxShadow: subtleShadow,
  );

  static BoxDecoration get searchField => _surface(
    color: EColors.surface,
    radius: AppRadius.large,
    border: Border.all(color: EColors.surfaceRaised, width: 1),
    boxShadow: subtleShadow,
  );

  static BoxDecoration get filterChip =>
      tintedDecoration(EColors.accent, radius: AppRadius.large);

  static BoxDecoration get activeFilterChip => _surface(
    gradient: primaryGradient,
    radius: AppRadius.large,
    boxShadow: subtleShadow,
  );

  static BoxDecoration get statusCard => tintedDecoration(EColors.success);

  static BoxDecoration get primaryCardWithBorder => _surface(
    gradient: cardGradient,
    border: Border.all(color: EColors.textSecondary.withValues(alpha: 0.1)),
    boxShadow: subtleShadow,
  );
}
