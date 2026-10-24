import 'package:ethan_ui/ethan_ui.dart';
import 'package:flutter/material.dart';
import 'package:health_notes/models/check_in_metric.dart';
import 'package:health_notes/ui/check_in_metric_appearance.dart';

class const CheckInTrendsLegend({
  required final List<String> metrics,
  required final List<CheckInMetric> userMetrics,
  required final Set<String> hiddenMetrics,
  required final ValueChanged<String> onMetricToggled,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return EChartLegend(
      entries: [
        for (final metricName in metrics)
          if (_metricNamed(metricName) case final metric?)
            _entry(metricName, metric),
      ],
    );
  }

  CheckInMetric? _metricNamed(String metricName) {
    for (final metric in userMetrics) {
      if (metric.name == metricName) return metric;
    }
    return null;
  }

  EChartLegendEntry _entry(String metricName, CheckInMetric metric) {
    final isHidden = hiddenMetrics.contains(metricName);
    final color = isHidden ? EColors.textMuted : metric.color;
    return EChartLegendEntry(
      swatch: Icon(metric.icon, size: 14, color: color),
      label: metricName,
      labelStyle: EText.caption.copyWith(
        color: metric.color,
        fontWeight: FontWeight.w500,
      ),
      dimmed: isHidden,
      onActivated: () => onMetricToggled(metricName),
    );
  }
}
