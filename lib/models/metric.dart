import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/cupertino.dart';
import 'package:health_notes/theme/app_theme.dart';

part 'metric.freezed.dart';
part 'metric.g.dart';

@freezed
abstract class Metric with _$Metric {
  const factory Metric({required String name, required MetricType type}) =
      _Metric;

  factory Metric.fromJson(Map<String, dynamic> json) => _$MetricFromJson(json);

  /// Get all available metrics
  static List<Metric> get all =>
      _metricConfigs.map((config) => config.toMetric).toList();

  /// Get all metric names in order
  static List<String> get allNames =>
      _metricConfigs.map((config) => config.name).toList();

  /// Get metric by name
  static Metric? fromName(String name) {
    final config = _getConfig(name);
    return config?.toMetric;
  }

  /// Get all metrics sorted in the consistent order defined for the app
  static List<Metric> get sortedAll {
    return _metricConfigs.map((config) => config.toMetric).toList();
  }

  /// Sort a list of metric names in the consistent order defined for the app
  static List<String> sortMetricNames(List<String> metricNames) {
    final sortedMetrics = <String>[];

    // Add metrics in the defined order if they exist in the input list
    for (final config in _metricConfigs) {
      if (metricNames.contains(config.name)) {
        sortedMetrics.add(config.name);
      }
    }

    // Add any remaining metrics that aren't in the defined order
    for (final metricName in metricNames) {
      if (!sortedMetrics.contains(metricName)) {
        sortedMetrics.add(metricName);
      }
    }

    return sortedMetrics;
  }

  /// Get all colors in the order they should be used for multiple metrics
  static List<Color> get colorPalette => [
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

  /// Get a color from the palette by index (for when we have more metrics than predefined colors)
  static Color getColorByIndex(int index) {
    final palette = colorPalette;
    return palette[index % palette.length];
  }

  // Internal configuration list
  static const List<MetricConfig> _metricConfigs = [
    MetricConfig(
      name: 'Anxiety',
      type: MetricType.lowerIsBetter,
      color: AppTheme.primary,
      icon: CupertinoIcons.heart,
    ),
    MetricConfig(
      name: 'Nausea',
      type: MetricType.lowerIsBetter,
      color: AppTheme.secondary,
      icon: CupertinoIcons.drop,
    ),
    MetricConfig(
      name: 'Poop Scale',
      type: MetricType.middleIsBest,
      color: AppTheme.accent,
      icon: CupertinoIcons.circle_fill,
    ),
    MetricConfig(
      name: 'Energy Level',
      type: MetricType.higherIsBetter,
      color: AppTheme.accentWarm,
      icon: CupertinoIcons.bolt_fill,
    ),
    MetricConfig(
      name: 'Pain Level',
      type: MetricType.lowerIsBetter,
      color: AppTheme.destructive,
      icon: CupertinoIcons.heart_fill,
    ),
    MetricConfig(
      name: 'Mood',
      type: MetricType.higherIsBetter,
      color: AppTheme.successColor,
      icon: CupertinoIcons.heart,
    ),
    MetricConfig(
      name: 'Sleep Quality',
      type: MetricType.higherIsBetter,
      color: AppTheme.warning,
      icon: CupertinoIcons.bed_double_fill,
    ),
    MetricConfig(
      name: 'Stress Level',
      type: MetricType.lowerIsBetter,
      color: CupertinoColors.systemPurple,
      icon: CupertinoIcons.exclamationmark_octagon,
    ),
    MetricConfig(
      name: 'Appetite',
      type: MetricType.middleIsBest,
      color: CupertinoColors.systemTeal,
      icon: CupertinoIcons.cart_fill,
    ),
    MetricConfig(
      name: 'Focus',
      type: MetricType.higherIsBetter,
      color: CupertinoColors.systemIndigo,
      icon: CupertinoIcons.eye_fill,
    ),
  ];

  // Internal helper method
  static MetricConfig? _getConfig(String metricName) {
    try {
      return _metricConfigs.firstWhere((config) => config.name == metricName);
    } catch (e) {
      return null;
    }
  }
}

enum MetricType {
  lowerIsBetter,
  middleIsBest,
  higherIsBetter;

  /// Returns true if the rating is in a "good" state for this metric type
  bool isRatingInGoodState(int rating) {
    return switch (this) {
      MetricType.lowerIsBetter => rating <= 3,
      MetricType.middleIsBest => rating >= 4 && rating <= 7,
      MetricType.higherIsBetter => rating >= 8,
    };
  }

  /// Returns the appropriate color for a check-in rating based on the metric type
  Color getRatingColor(int rating) {
    return switch (this) {
      MetricType.lowerIsBetter => switch (rating) {
        <= 3 => CupertinoColors.systemGreen,
        <= 6 => CupertinoColors.systemYellow,
        <= 8 => CupertinoColors.systemOrange,
        _ => CupertinoColors.systemRed,
      },
      MetricType.middleIsBest => switch (rating) {
        1 || 10 => CupertinoColors.systemRed,
        2 || 3 || 8 || 9 => CupertinoColors.systemYellow,
        _ => CupertinoColors.systemGreen, // 4-7
      },
      MetricType.higherIsBetter => switch (rating) {
        <= 3 => CupertinoColors.systemRed,
        <= 5 => CupertinoColors.systemOrange,
        <= 7 => CupertinoColors.systemYellow,
        _ => CupertinoColors.systemGreen,
      },
    };
  }

  /// Returns a human-readable description of what this metric type means
  String get description {
    return switch (this) {
      MetricType.lowerIsBetter => 'Lower values are better',
      MetricType.middleIsBest => 'Middle values (4-7) are optimal',
      MetricType.higherIsBetter => 'Higher values are better',
    };
  }
}

extension MetricExtensions on Metric {
  /// Returns true if the rating is in a "good" state for this metric
  bool isRatingInGoodState(int rating) => type.isRatingInGoodState(rating);

  /// Returns the display name for this metric
  String get displayName => name;

  /// Returns the color associated with this metric
  Color get color => Metric._getConfig(name)?.color ?? AppTheme.primary;

  /// Returns the icon associated with this metric
  IconData get icon => Metric._getConfig(name)?.icon ?? CupertinoIcons.circle;

  /// Returns the appropriate color for a check-in rating based on the metric type
  Color getRatingColor(int rating) => type.getRatingColor(rating);

  /// Returns a human-readable description of what this metric type means
  String get typeDescription => type.description;

  /// Returns the index of this metric in the sorted list
  int get sortIndex {
    final config = Metric._getConfig(name);
    if (config == null) return 999; // Put unknown metrics at the end
    return Metric._metricConfigs.indexOf(config);
  }

  /// Returns true if this metric is valid (exists in the configuration)
  bool get isValid => Metric._getConfig(name) != null;
}

/// Configuration for all available metrics
class MetricConfig {
  final String name;
  final MetricType type;
  final Color color;
  final IconData icon;

  const MetricConfig({
    required this.name,
    required this.type,
    required this.color,
    required this.icon,
  });

  /// Creates a Metric instance from this config
  Metric get toMetric => Metric(name: name, type: type);
}
