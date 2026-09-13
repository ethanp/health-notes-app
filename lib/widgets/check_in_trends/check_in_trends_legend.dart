import 'package:ethan_ui/ethan_ui.dart';
import 'package:flutter/material.dart';
import 'package:health_notes/models/check_in_metric.dart';
import 'package:health_notes/theme/app_theme.dart';
import 'package:health_notes/ui/check_in_metric_appearance.dart';
import 'package:health_notes/theme/spacing.dart';

class const CheckInTrendsLegend({
  required final List<String> metrics,
  required final List<CheckInMetric> userMetrics,
  required final Set<String> hiddenMetrics,
  required final ValueChanged<String> onMetricToggled,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: metrics
          .map(
            (metric) => CheckInTrendsLegendItem(
              metricName: metric,
              userMetrics: userMetrics,
              isHidden: hiddenMetrics.contains(metric),
              onToggled: () => onMetricToggled(metric),
            ),
          )
          .toList(),
    );
  }
}

class const CheckInTrendsLegendItem({
  required final String metricName,
  required final List<CheckInMetric> userMetrics,
  required final bool isHidden,
  required final VoidCallback onToggled,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    CheckInMetric? metricObj;
    for (final metric in userMetrics) {
      if (metric.name == metricName) {
        metricObj = metric;
        break;
      }
    }
    if (metricObj == null) return const SizedBox.shrink();

    final color = metricObj.color;
    return GestureDetector(
      onTap: onToggled,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isHidden
              ? EColors.backgroundLift
              : color.withValues(alpha: 0.08),
          border: Border.all(
            color: isHidden
                ? EColors.surfaceRaised
                : color.withValues(alpha: 0.2),
          ),
          borderRadius: BorderRadius.circular(AppRadius.large),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              metricObj.icon,
              size: 14,
              color: isHidden ? EColors.textTertiary : color,
            ),
            HSpace.of(5),
            Text(
              metricName,
              style: EText.body.small.copyWith(
                color: isHidden ? EColors.textTertiary : color,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
