import 'package:ethan_ui/ethan_ui.dart';
import 'package:flutter/material.dart';
import 'package:health_notes/models/check_in_metric.dart';
import 'package:health_notes/ui/check_in_metric_appearance.dart';
import 'package:health_notes/theme/spacing.dart';

class const CheckInMetricsSection({
  required final Map<String, int> selectedMetrics,
  required final List<CheckInMetric> userMetrics,
  required final void Function(String metricName, int rating) onRatingChanged,
  required final void Function(String metricName) onMetricRemoved,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ECard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your Ratings', style: EText.headline.small),
          VSpace.m,
          ...selectedMetrics.entries.map(_metricRatingSelector),
        ],
      ),
    );
  }

  Widget _metricRatingSelector(MapEntry<String, int> entry) {
    final metricName = entry.key;
    final rating = entry.value;
    final metric = userMetrics.firstWhere(
      (m) => m.name == metricName,
      orElse: () => throw Exception('Metric not found: $metricName'),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sliderMetadata(metric, rating, metricName),
        _ratingSliderRow(metricName, rating),
        VSpace.sm,
      ],
    );
  }

  Widget _sliderMetadata(CheckInMetric metric, int rating, String metricName) {
    return Row(
      children: [
        CheckInMetricRatingPill(metric: metric, rating: rating),
        HSpace.m,
        Icon(metric.icon, size: 20, color: EColors.textPrimary),
        HSpace.sm,
        Expanded(child: Text(metric.name, style: EText.label.large)),
        IconButton(
          tooltip: 'Remove metric',
          onPressed: () => onMetricRemoved(metricName),
          icon: Icon(
            Icons.cancel,
            color: EColors.danger.withValues(alpha: .7),
            size: 20,
          ),
        ),
      ],
    );
  }

  Widget _ratingSliderRow(String metricName, int rating) {
    return Row(
      children: [
        Text('1', style: EText.body.small.tertiary),
        Expanded(
          child: Slider(
            value: rating.toDouble(),
            min: 1,
            max: 10,
            divisions: 9,
            onChanged: (value) => onRatingChanged(metricName, value.round()),
          ),
        ),
        Text('10', style: EText.body.small.tertiary),
      ],
    );
  }
}

class const CheckInMetricRatingPill({
  required final CheckInMetric metric,
  required final int rating,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ratingColor = metric.type.improvementColor(rating);
    return SizedBox(
      width: 40,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: ratingColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            '$rating',
            style: EText.body.small.copyWith(
              color: ratingColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class const CheckInMetricsEmptyState() extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ECard(
      child: Column(
        children: [
          const Icon(Icons.bar_chart, size: 48, color: EColors.textMuted),
          VSpace.m,
          Text('No metrics available', style: EText.headline.small),
          VSpace.s,
          Text(
            'Add some metrics to start tracking your health',
            style: EText.body.medium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class const CheckInMetricsErrorState({
  required final Object error,
  required final VoidCallback onRetry,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.warning_amber,
            size: 48,
            color: EColors.danger,
          ),
          VSpace.m,
          Text('Failed to load metrics', style: EText.headline.small),
          VSpace.s,
          Text(
            error.toString(),
            style: EText.body.medium,
            textAlign: TextAlign.center,
          ),
          VSpace.m,
          FilledButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
