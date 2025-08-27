import 'package:flutter/cupertino.dart';

/// Centralized mapping of metric names to their corresponding icons
/// for consistency across the app
class MetricIcons {
  static final Map<String, IconData> icons = {
    'Anxiety': CupertinoIcons.heart,
    'Nausea': CupertinoIcons.drop,
    'Poop Scale': CupertinoIcons.circle_fill,
    'Energy Level': CupertinoIcons.bolt_fill,
    'Pain Level': CupertinoIcons.heart_fill,
    'Mood': CupertinoIcons.heart,
    'Sleep Quality': CupertinoIcons.bed_double_fill,
    'Stress Level': CupertinoIcons.exclamationmark_octagon,
    'Appetite': CupertinoIcons.cart_fill,
    'Focus': CupertinoIcons.eye_fill,
  };

  /// Get the icon for a given metric name, with a fallback to circle
  static IconData getIcon(String metricName) {
    return icons[metricName] ?? CupertinoIcons.circle;
  }
}
