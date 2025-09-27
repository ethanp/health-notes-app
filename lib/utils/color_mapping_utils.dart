import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:health_notes/models/check_in_metric.dart';

/// Utility class for color mapping based on metric semantics
class ColorMappingUtils {
  /// Maps a rating value to a color using a gradient from red to green
  /// Rating should be 1-10, where 1 = red and 10 = green
  static Color ratingToColor(int rating) {
    // Clamp rating to valid range
    final clampedRating = rating.clamp(1, 10);

    // Convert 1-10 scale to 0-1 scale for interpolation
    final normalizedValue = (clampedRating - 1) / 9.0;

    // Interpolate between red and green
    return Color.lerp(
      CupertinoColors.systemRed,
      CupertinoColors.systemGreen,
      normalizedValue,
    )!;
  }

  /// Maps a rating value to a color based on "lower is better" semantics
  /// Uses direct mapping: f(x) = x, so 1 = red, 10 = green
  static Color lowerIsBetterColor(int rating) {
    return ratingToColor(rating);
  }

  /// Maps a rating value to a color based on "higher is better" semantics
  /// Uses inverted mapping: g(x) = -x, so 1 = green, 10 = red
  static Color higherIsBetterColor(int rating) {
    // Invert the rating: 1 becomes 10, 10 becomes 1
    final invertedRating = 11 - rating;
    return ratingToColor(invertedRating);
  }

  /// Maps a rating value to a color based on "middle is best" semantics
  /// Uses triangular function: h(x) = (5 - |5-x|) * 2, so 5 = 10, 1 and 10 = 0
  /// This creates a gradient where middle values are green and extremes are red
  static Color middleIsBestColor(int rating) {
    // Apply the triangular function: (5 - |5-x|) * 2
    final transformedValue = (5 - (5 - rating).abs()) * 2;

    // Map to 1-10 scale for color interpolation
    // transformedValue ranges from 0 to 10, where 0 = red, 10 = green
    final colorRating = ((transformedValue / 10.0) * 9 + 1).round().clamp(
      1,
      10,
    );

    return ratingToColor(colorRating);
  }

  /// Creates a gradient color list for chart backgrounds
  /// Returns colors from red to green for the given metric type
  static List<Color> getBackgroundGradient(MetricType type) {
    switch (type) {
      case MetricType.lowerIsBetter:
        return [
          CupertinoColors.systemRed.withValues(alpha: 0.1),
          CupertinoColors.systemYellow.withValues(alpha: 0.1),
          CupertinoColors.systemGreen.withValues(alpha: 0.1),
        ];
      case MetricType.higherIsBetter:
        return [
          CupertinoColors.systemGreen.withValues(alpha: 0.1),
          CupertinoColors.systemYellow.withValues(alpha: 0.1),
          CupertinoColors.systemRed.withValues(alpha: 0.1),
        ];
      case MetricType.middleIsBest:
        return [
          CupertinoColors.systemRed.withValues(alpha: 0.1),
          CupertinoColors.systemYellow.withValues(alpha: 0.08),
          CupertinoColors.systemGreen.withValues(alpha: 0.1),
          CupertinoColors.systemYellow.withValues(alpha: 0.08),
          CupertinoColors.systemRed.withValues(alpha: 0.1),
        ];
    }
  }

  /// Creates gradient stops for the background gradient
  static List<double> getBackgroundGradientStops(MetricType type) {
    switch (type) {
      case MetricType.lowerIsBetter:
      case MetricType.higherIsBetter:
        return [0.0, 0.5, 1.0];
      case MetricType.middleIsBest:
        return [0.0, 0.25, 0.5, 0.75, 1.0];
    }
  }
}
