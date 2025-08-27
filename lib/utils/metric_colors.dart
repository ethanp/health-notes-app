import 'package:flutter/cupertino.dart';
import 'package:health_notes/theme/app_theme.dart';

/// Centralized mapping of metric names to their corresponding colors
/// for consistency across the app
class MetricColors {
  // Define the order of metrics for consistent display throughout the app
  static const List<String> metricOrder = [
    'Anxiety',
    'Nausea',
    'Poop Scale',
    'Energy Level',
    'Pain Level',
    'Mood',
    'Sleep Quality',
    'Stress Level',
    'Appetite',
    'Focus',
  ];

  static final Map<String, Color> colors = {
    'Anxiety': AppTheme.primary,
    'Nausea': AppTheme.secondary,
    'Poop Scale': AppTheme.accent,
    'Energy Level': AppTheme.accentWarm,
    'Pain Level': AppTheme.destructive,
    'Mood': AppTheme.successColor,
    'Sleep Quality': AppTheme.warning,
    'Stress Level': CupertinoColors.systemPurple,
    'Appetite': CupertinoColors.systemTeal,
    'Focus': CupertinoColors.systemIndigo,
  };

  /// Get the color for a given metric name, with a fallback to primary
  static Color getColor(String metricName) {
    return colors[metricName] ?? AppTheme.primary;
  }

  /// Get all colors in the order they should be used for multiple metrics
  static List<Color> getColorPalette() {
    return [
      AppTheme.primary,
      AppTheme.secondary,
      AppTheme.accent,
      AppTheme.accentWarm,
      AppTheme.successColor,
      AppTheme.warning,
      AppTheme.destructive,
      CupertinoColors.systemPurple,
      CupertinoColors.systemTeal,
      CupertinoColors.systemIndigo,
    ];
  }

  /// Get a color from the palette by index (for when we have more metrics than predefined colors)
  static Color getColorByIndex(int index) {
    final palette = getColorPalette();
    return palette[index % palette.length];
  }

  /// Sort metrics in the consistent order defined for the app
  static List<String> sortMetrics(List<String> metrics) {
    final sortedMetrics = <String>[];

    // Add metrics in the defined order if they exist in the input list
    for (final metric in metricOrder) {
      if (metrics.contains(metric)) {
        sortedMetrics.add(metric);
      }
    }

    // Add any remaining metrics that aren't in the defined order
    for (final metric in metrics) {
      if (!sortedMetrics.contains(metric)) {
        sortedMetrics.add(metric);
      }
    }

    return sortedMetrics;
  }
}
