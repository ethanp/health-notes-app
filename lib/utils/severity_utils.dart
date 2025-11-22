import 'package:flutter/cupertino.dart';
import 'package:health_notes/theme/app_theme.dart';

/// Centralized severity calculation and display logic
class SeverityUtils {
  static const int minSeverity = 1;
  static const int maxSeverity = 10;

  /// Calculate color for a given severity level (0-10)
  /// Uses HSL color space to create a gradient from green (low) to red (high)
  static Color colorForSeverity(int severity) {
    if (severity == 0) {
      return AppColors.backgroundPrimary.withValues(alpha: 0.3);
    }

    final normalized = (severity / maxSeverity).clamp(0.0, 1.0);
    final hue = (120 - (normalized * 120)).clamp(0.0, 360.0);
    final saturation = (30 + (normalized * 60)).clamp(0.0, 100.0);
    final lightness = (85 - (normalized * 50)).clamp(0.0, 100.0);

    return HSLColor.fromAHSL(
      1.0,
      hue,
      saturation / 100,
      lightness / 100,
    ).toColor();
  }

  /// Get human-readable description for severity level
  static String descriptionForSeverity(int severity) {
    const descriptions = {
      1: 'Very mild symptoms',
      2: 'Mild symptoms',
      3: 'Moderate symptoms',
      4: 'Moderately severe symptoms',
      5: 'Severe symptoms',
      6: 'Very severe symptoms',
      7: 'Extremely severe symptoms',
      8: 'Very extreme symptoms',
      9: 'Extremely intense symptoms',
      10: 'Maximum severity symptoms',
    };
    return descriptions[severity] ?? 'Unknown severity';
  }

  /// Check if severity value is within valid range
  static bool isValidSeverity(int severity) {
    return severity >= minSeverity && severity <= maxSeverity;
  }

  /// Get display text for severity (returns number as string or "Unknown")
  static String displayText(int severity) {
    return isValidSeverity(severity) || severity == 0
        ? severity.toString()
        : 'Unknown';
  }
}
