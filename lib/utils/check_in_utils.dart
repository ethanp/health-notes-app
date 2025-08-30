import 'package:flutter/cupertino.dart';
import 'package:health_notes/models/metric.dart';

class CheckInUtils {
  /// Returns the appropriate color for a check-in rating based on the metric type.
  ///
  /// Different health metrics have different "good" ranges:
  /// - Lower is better: Pain Level, Stress Level, Anxiety, Nausea
  /// - Middle is best: Appetite, Poop Scale
  /// - Higher is better: Energy Level, Mood, Sleep Quality, Focus
  static Color getRatingColor(int rating, String metricName) {
    final metric = Metric.fromName(metricName);
    return metric?.getRatingColor(rating) ?? CupertinoColors.systemGrey;
  }

  /// Returns the consistent color for a metric name
  static Color getMetricColor(String metricName) {
    final metric = Metric.fromName(metricName);
    return metric?.color ?? CupertinoColors.systemGrey;
  }
}
