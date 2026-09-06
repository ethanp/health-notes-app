import 'package:ethan_ui/ethan_ui.dart';
import 'package:flutter/material.dart';

class SymptomSeverity() {
  static const int min = 1;
  static const int max = 10;

  static Color hslGreenToRed(int severity) {
    if (severity == 0) {
      return EColors.background.withValues(alpha: 0.3);
    }

    final normalized = (severity / max).clamp(0.0, 1.0);
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

  static String intensityCaption(int severity) {
    const captions = {
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
    return captions[severity] ?? 'Unknown severity';
  }

  static bool isValid(int severity) =>
      severity >= min && severity <= max;

  static Color fourBucketGreenYellowOrangeRed(int severity) {
    if (severity <= 3) return EColors.success;
    if (severity <= 5) return EColors.warning;
    if (severity <= 7) return Colors.orange;
    return EColors.danger;
  }

  static String displayDigit(int severity) {
    return isValid(severity) || severity == 0
        ? severity.toString()
        : 'Unknown';
  }
}
