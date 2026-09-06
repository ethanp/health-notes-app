import 'package:ethan_ui/ethan_ui.dart';
import 'package:flutter/material.dart';
import 'package:health_notes/models/check_in_metric.dart';
import 'package:health_notes/constants/chart_constants.dart';

class RatingColor() {
  static Color redToGreen(int rating) {
    final clampedRating = rating.clamp(1, 10);
    final normalizedValue = (clampedRating - 1) / 9.0;
    return Color.lerp(EColors.danger, EColors.success, normalizedValue)!;
  }

  static Color lowerIsBetter(int rating) {
    final invertedRating = 11 - rating;
    return redToGreen(invertedRating);
  }

  static Color higherIsBetter(int rating) => redToGreen(rating);

  static Color middleIsBest(int rating) {
    final transformedValue = (5 - (5 - rating).abs()) * 2;
    final colorRating = ((transformedValue / 10.0) * 9 + 1).round().clamp(
      1,
      10,
    );
    return redToGreen(colorRating);
  }

  static List<Color> semanticBandsThroughPlotAndLabels(MetricType type) {
    switch (type) {
      case MetricType.lowerIsBetter:
        return [
          EColors.danger.withValues(alpha: 0.1),
          EColors.warning.withValues(alpha: 0.1),
          EColors.success.withValues(alpha: 0.1),
          EColors.success.withValues(alpha: 0.1),
        ];
      case MetricType.higherIsBetter:
        return [
          EColors.success.withValues(alpha: 0.1),
          EColors.warning.withValues(alpha: 0.1),
          EColors.danger.withValues(alpha: 0.1),
          EColors.danger.withValues(alpha: 0.1),
        ];
      case MetricType.middleIsBest:
        return [
          EColors.danger.withValues(alpha: 0.1),
          EColors.warning.withValues(alpha: 0.08),
          EColors.success.withValues(alpha: 0.1),
          EColors.warning.withValues(alpha: 0.08),
          EColors.danger.withValues(alpha: 0.1),
          EColors.danger.withValues(alpha: 0.1),
        ];
    }
  }

  static List<double> plotThenLabelGutterStops(MetricType type) {
    switch (type) {
      case MetricType.lowerIsBetter:
      case MetricType.higherIsBetter:
        return [
          0.0,
          0.5 * kChartPlotAreaRatio,
          1.0 * kChartPlotAreaRatio,
          1.0,
        ];
      case MetricType.middleIsBest:
        return [
          0.0,
          0.25 * kChartPlotAreaRatio,
          0.5 * kChartPlotAreaRatio,
          0.75 * kChartPlotAreaRatio,
          1.0 * kChartPlotAreaRatio,
          1.0,
        ];
    }
  }
}
