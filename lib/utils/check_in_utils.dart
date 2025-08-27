import 'package:flutter/cupertino.dart';
import 'package:health_notes/utils/metric_colors.dart';

class CheckInUtils {
  /// Returns the appropriate color for a check-in rating based on the metric type.
  ///
  /// Different health metrics have different "good" ranges:
  /// - Lower is better: Pain Level, Stress Level, Anxiety, Nausea
  /// - Middle is best: Appetite, Poop Scale
  /// - Higher is better: Energy Level, Mood, Sleep Quality, Focus
  static Color getRatingColor(int rating, String metricName) {
    // Metrics where lower values are better
    const lowerIsBetter = {'Pain Level', 'Stress Level', 'Anxiety', 'Nausea'};

    // Metrics where middle range is best
    const middleIsBest = {'Appetite', 'Poop Scale'};

    if (lowerIsBetter.contains(metricName)) {
      // For lower-is-better metrics: 1-3 = green, 4-6 = yellow, 7-8 = orange, 9-10 = red
      return switch (rating) {
        <= 3 => CupertinoColors.systemGreen,
        <= 6 => CupertinoColors.systemYellow,
        <= 8 => CupertinoColors.systemOrange,
        _ => CupertinoColors.systemRed,
      };
    } else if (middleIsBest.contains(metricName)) {
      // For middle-is-best metrics: 4-7 = green, 2-3 or 8-9 = yellow, 1 or 10 = red
      return switch (rating) {
        1 || 10 => CupertinoColors.systemRed,
        2 || 3 || 8 || 9 => CupertinoColors.systemYellow,
        _ => CupertinoColors.systemGreen, // 4-7
      };
    } else {
      // Default: higher is better (original logic)
      return switch (rating) {
        <= 3 => CupertinoColors.systemRed,
        <= 5 => CupertinoColors.systemOrange,
        <= 7 => CupertinoColors.systemYellow,
        _ => CupertinoColors.systemGreen,
      };
    }
  }

  /// Returns the consistent color for a metric name
  static Color getMetricColor(String metricName) {
    return MetricColors.getColor(metricName);
  }
}
