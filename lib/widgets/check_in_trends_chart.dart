import 'package:ethan_ui/ethan_ui.dart';
import 'package:flutter/material.dart';
import 'package:health_notes/constants/chart_constants.dart';
import 'package:health_notes/models/check_in.dart';
import 'package:health_notes/models/check_in_metric.dart';
import 'package:health_notes/models/date_range_filter.dart';
import 'package:health_notes/theme/spacing.dart';
import 'package:health_notes/widgets/check_in_trends/check_in_trends_chrome.dart';
import 'package:health_notes/widgets/check_in_trends/check_in_trends_legend.dart';
import 'package:health_notes/widgets/check_in_trends/check_in_trends_line_chart.dart';

class const CheckInTrendsChart({
  required final List<CheckIn> checkIns,
  required final List<CheckInMetric> userMetrics,
}) extends StatefulWidget {
  @override
  State<CheckInTrendsChart> createState() => _CheckInTrendsChartState();
}

class _CheckInTrendsChartState() extends State<CheckInTrendsChart> {
  final Set<String> _hiddenMetrics = <String>{};
  DateRangeFilter _selectedDateRange = DateRangeFilter.sixtyDays;

  void _toggleMetric(String metric) {
    setState(() {
      if (_hiddenMetrics.contains(metric)) {
        _hiddenMetrics.remove(metric);
      } else {
        _hiddenMetrics.add(metric);
      }
    });
  }

  CheckInMetric? _userMetricByName(String name) {
    for (final metric in widget.userMetrics) {
      if (metric.name == name) return metric;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.checkIns.isEmpty) return const CheckInTrendsEmptyState();

    final metrics = _sortedMetricNames();
    return CheckInTrendsChrome(
      header: Text('Trends', style: EText.headline.small),
      dateRangeSelector: CheckInTrendsDateRangeSelector(
        selectedDateRange: _selectedDateRange,
        onDateRangeSelected: (filter) {
          setState(() => _selectedDateRange = filter);
        },
      ),
      indicator: const CheckInTrendsImprovementZones(),
      charts: _splitCharts(metrics),
    );
  }

  List<String> _sortedMetricNames() {
    final metrics = widget.checkIns.map((c) => c.metricName).toSet().toList();
    metrics.sort();
    return metrics;
  }

  Widget _splitCharts(List<String> metrics) {
    final groupedMetrics = _groupMetricsByType(metrics);
    return Column(
      children: groupedMetrics.entries.map((entry) {
        return _chartSection(entry.key, entry.value);
      }).toList(),
    );
  }

  Map<MetricType, List<String>> _groupMetricsByType(List<String> metrics) {
    final groupedMetrics = <MetricType, List<String>>{};
    for (final metric in metrics) {
      final metricObj = _userMetricByName(metric);
      if (metricObj == null) continue;
      groupedMetrics.putIfAbsent(metricObj.type, () => <String>[]).add(metric);
    }
    return groupedMetrics;
  }

  Widget _chartSection(MetricType type, List<String> typeMetrics) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          type.valuePreferenceTitle,
          style: EText.body.small.semibold.primary.size(13),
        ),
        VSpace.of(6),
        CheckInTrendsLegend(
          metrics: typeMetrics,
          userMetrics: widget.userMetrics,
          hiddenMetrics: _hiddenMetrics,
          onMetricToggled: _toggleMetric,
        ),
        VSpace.of(6),
        SizedBox(
          height: kChartTotalHeight,
          child: CheckInTrendsLineChart(
            checkIns: widget.checkIns,
            userMetrics: widget.userMetrics,
            hiddenMetrics: _hiddenMetrics,
            dateRange: _selectedDateRange,
            metrics: typeMetrics,
            metricType: type,
          ),
        ),
        VSpace.sm,
      ],
    );
  }
}
