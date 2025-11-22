import 'package:flutter/cupertino.dart';
import 'package:health_notes/models/check_in_metric.dart';
import 'package:health_notes/constants/chart_constants.dart';

/// Utility class for color mapping based on metric semantics
class ColorMappingUtils {
  /// Maps a rating value to a color using a gradient from red to green
  /// Rating should be 1-10, where 1 = red and 10 = green
  static Color ratingToColor(int rating) {
    final clampedRating = rating.clamp(1, 10);
    final normalizedValue = (clampedRating - 1) / 9.0;
    return Color.lerp(
      CupertinoColors.systemRed,
      CupertinoColors.systemGreen,
      normalizedValue,
    )!;
  }

  /// Maps a rating value to a color based on "lower is better" semantics
  /// Uses inverted mapping: f(x) = -x, so 1 = green (good), 10 = red (bad)
  static Color lowerIsBetterColor(int rating) {
    final invertedRating = 11 - rating;
    return ratingToColor(invertedRating);
  }

  /// Maps a rating value to a color based on "higher is better" semantics
  /// Uses direct mapping: g(x) = x, so 1 = red (bad), 10 = green (good)
  static Color higherIsBetterColor(int rating) {
    return ratingToColor(rating);
  }

  /// Maps a rating value to a color based on "middle is best" semantics
  /// Uses triangular function: h(x) = (5 - |5-x|) * 2, so 5 = 10, 1 and 10 = 0
  /// This creates a gradient where middle values are green and extremes are red
  static Color middleIsBestColor(int rating) {
    final transformedValue = (5 - (5 - rating).abs()) * 2;
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
          CupertinoColors.systemGreen.withValues(alpha: 0.1), // Extend into label area
        ];
      case MetricType.higherIsBetter:
        return [
          CupertinoColors.systemGreen.withValues(alpha: 0.1),
          CupertinoColors.systemYellow.withValues(alpha: 0.1),
          CupertinoColors.systemRed.withValues(alpha: 0.1),
          CupertinoColors.systemRed.withValues(alpha: 0.1), // Extend into label area
        ];
      case MetricType.middleIsBest:
        return [
          CupertinoColors.systemRed.withValues(alpha: 0.1),
          CupertinoColors.systemYellow.withValues(alpha: 0.08),
          CupertinoColors.systemGreen.withValues(alpha: 0.1),
          CupertinoColors.systemYellow.withValues(alpha: 0.08),
          CupertinoColors.systemRed.withValues(alpha: 0.1),
          CupertinoColors.systemRed.withValues(alpha: 0.1), // Extend into label area
        ];
    }
  }

  /// Creates gradient stops for the background gradient
  /// Stops are adjusted to account for the bottom axis label area
  /// Uses shared chart dimension constants
  static List<double> getBackgroundGradientStops(MetricType type) {
    switch (type) {
      case MetricType.lowerIsBetter:
      case MetricType.higherIsBetter:
        return [
          0.0,
          0.5 * kChartPlotAreaRatio,      // Middle of plot area
          1.0 * kChartPlotAreaRatio,      // Bottom of plot area
          1.0,                             // Extend final color to bottom of container
        ];
      case MetricType.middleIsBest:
        return [
          0.0,
          0.25 * kChartPlotAreaRatio,
          0.5 * kChartPlotAreaRatio,
          0.75 * kChartPlotAreaRatio,
          1.0 * kChartPlotAreaRatio,      // Bottom of plot area
          1.0,                             // Extend final color to bottom of container
        ];
    }
  }
}
