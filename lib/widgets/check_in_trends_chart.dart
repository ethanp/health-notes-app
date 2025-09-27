import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:health_notes/models/check_in.dart';
import 'package:health_notes/models/check_in_metric.dart';
import 'package:health_notes/theme/app_theme.dart';
import 'package:intl/intl.dart';

class CheckInTrendsChart extends StatefulWidget {
  final List<CheckIn> checkIns;
  final List<CheckInMetric> userMetrics;
  final int maxDataPoints;

  const CheckInTrendsChart({
    super.key,
    required this.checkIns,
    required this.userMetrics,
    this.maxDataPoints = 30,
  });

  @override
  State<CheckInTrendsChart> createState() => _CheckInTrendsChartState();
}

class _CheckInTrendsChartState extends State<CheckInTrendsChart> {
  final Set<String> _hiddenMetrics = <String>{};

  void _toggleMetric(String metric) {
    setState(() {
      if (_hiddenMetrics.contains(metric)) {
        _hiddenMetrics.remove(metric);
      } else {
        _hiddenMetrics.add(metric);
      }
    });
  }

  CheckInMetric? _getUserMetricByName(String name) {
    try {
      return widget.userMetrics.firstWhere((m) => m.name == name);
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.checkIns.isEmpty) {
      return Container(
        height: 450,
        decoration: AppTheme.primaryCard,
        child: Center(
          child: Text(
            'No check-in data available',
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.textTertiary),
          ),
        ),
      );
    }

    final metrics = widget.checkIns.map((c) => c.metricName).toSet().toList()
      ..sort(); // Sort alphabetically

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.primaryCard.copyWith(
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Trends',
            style: AppTheme.headlineSmall.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          improvementZonesIndicator(),
          const SizedBox(height: 12),
          splitCharts(metrics),
        ],
      ),
    );
  }

  Widget legendForType(MetricType type, List<String> metrics) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: metrics.map((metric) => legendItem(metric)).toList(),
    );
  }

  Widget legendItem(String metric) {
    final metricObj = _getUserMetricByName(metric);
    if (metricObj == null) return const SizedBox.shrink();

    final color = metricObj.color;
    final isHidden = _hiddenMetrics.contains(metric);

    return GestureDetector(
      onTap: () => _toggleMetric(metric),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isHidden
              ? AppTheme.backgroundSecondary
              : color.withValues(alpha: 0.08),
          border: Border.all(
            color: isHidden
                ? AppTheme.backgroundQuaternary
                : color.withValues(alpha: 0.2),
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              metricObj.icon,
              size: 14,
              color: isHidden ? AppTheme.textTertiary : color,
            ),
            const SizedBox(width: 5),
            Text(
              metric,
              style: AppTheme.bodySmall.copyWith(
                color: isHidden ? AppTheme.textTertiary : color,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTypeDisplayName(MetricType type) {
    return switch (type) {
      MetricType.lowerIsBetter => 'Lower is Better',
      MetricType.middleIsBest => 'Middle is Best',
      MetricType.higherIsBetter => 'Higher is Better',
    };
  }

  Widget improvementZonesIndicator() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGreen.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: CupertinoColors.systemGreen.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            CupertinoIcons.info_circle,
            size: 14,
            color: CupertinoColors.systemGreen,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Green zones: 0-3 (Lower is Better), 4-7 (Middle is Best), 8-10 (Higher is Better)',
              style: AppTheme.bodySmall.copyWith(
                color: CupertinoColors.systemGreen,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget splitCharts(List<String> metrics) {
    final groupedMetrics = _groupMetricsByType(metrics);

    return Column(
      children: groupedMetrics.entries.map((entry) {
        final type = entry.key;
        final typeMetrics = entry.value;

        return chartSection(type, typeMetrics);
      }).toList(),
    );
  }

  Map<MetricType, List<String>> _groupMetricsByType(List<String> metrics) {
    final groupedMetrics = <MetricType, List<String>>{};
    for (final metric in metrics) {
      final metricObj = _getUserMetricByName(metric);
      if (metricObj == null) continue;

      final type = metricObj.type;
      if (groupedMetrics[type] == null) {
        groupedMetrics[type] = <String>[];
      }
      groupedMetrics[type]!.add(metric);
    }
    return groupedMetrics;
  }

  Widget chartSection(MetricType type, List<String> typeMetrics) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _getTypeDisplayName(type),
          style: AppTheme.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 6),
        legendForType(type, typeMetrics),
        const SizedBox(height: 6),
        SizedBox(height: 100, child: singleChart(typeMetrics, type)),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget singleChart(List<String> metrics, MetricType metricType) {
    if (widget.checkIns.isEmpty) {
      return noDataContainer();
    }

    final metricData = _prepareMetricData(metrics);
    final sortedDates = _getSortedDates(metricData);

    return LineChart(
      LineChartData(
        gridData: chartGridData(),
        titlesData: chartTitlesData(sortedDates),
        borderData: chartBorderData(),
        minX: 0,
        maxX: (sortedDates.length - 1).toDouble(),
        minY: 0,
        maxY: 10,
        backgroundColor: AppTheme.backgroundPrimary.withValues(alpha: 0.02),
        lineBarsData: lineBarsData(metrics, metricData, sortedDates),
        lineTouchData: chartTouchData(metrics),
      ),
      duration: Duration.zero,
    );
  }

  Widget noDataContainer() {
    return Container(
      decoration: AppTheme.primaryCard,
      child: Center(
        child: Text(
          'No data',
          style: AppTheme.bodySmall.copyWith(color: AppTheme.textTertiary),
        ),
      ),
    );
  }

  Map<String, List<CheckIn>> _prepareMetricData(List<String> metrics) {
    final metricData = <String, List<CheckIn>>{};

    for (final metric in metrics) {
      final metricCheckIns =
          widget.checkIns
              .where((checkIn) => checkIn.metricName == metric)
              .toList()
            ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

      if (metricCheckIns.length > widget.maxDataPoints) {
        metricData[metric] = metricCheckIns.sublist(
          metricCheckIns.length - widget.maxDataPoints,
        );
      } else {
        metricData[metric] = metricCheckIns;
      }
    }
    return metricData;
  }

  List<DateTime> _getSortedDates(Map<String, List<CheckIn>> metricData) {
    final allDates = <DateTime>{};
    for (final checkIns in metricData.values) {
      for (final checkIn in checkIns) {
        allDates.add(
          DateTime(
            checkIn.dateTime.year,
            checkIn.dateTime.month,
            checkIn.dateTime.day,
          ),
        );
      }
    }

    final sortedDates = allDates.toList()..sort();

    if (sortedDates.length > widget.maxDataPoints) {
      sortedDates.removeRange(0, sortedDates.length - widget.maxDataPoints);
    }
    return sortedDates;
  }

  FlGridData chartGridData() {
    return FlGridData(
      show: true,
      drawVerticalLine: true,
      horizontalInterval: 2,
      verticalInterval: 1,
      getDrawingHorizontalLine: (value) {
        return FlLine(
          color: AppTheme.backgroundQuaternary.withValues(alpha: 0.3),
          strokeWidth: 0.5,
        );
      },
      getDrawingVerticalLine: (value) {
        return FlLine(
          color: AppTheme.backgroundQuaternary.withValues(alpha: 0.3),
          strokeWidth: 0.5,
        );
      },
    );
  }

  FlTitlesData chartTitlesData(List<DateTime> sortedDates) {
    return FlTitlesData(
      show: true,
      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      bottomTitles: bottomTitles(sortedDates),
      leftTitles: leftTitles(),
    );
  }

  AxisTitles bottomTitles(List<DateTime> sortedDates) {
    return AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 18,
        interval: 1,
        getTitlesWidget: (double value, TitleMeta meta) {
          if (value.toInt() >= 0 && value.toInt() < sortedDates.length) {
            final date = sortedDates[value.toInt()];
            return SideTitleWidget(
              meta: meta,
              child: Text(
                DateFormat('MMM d').format(date),
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.textSecondary,
                  fontSize: 9,
                ),
              ),
            );
          }
          return const Text('');
        },
      ),
    );
  }

  AxisTitles leftTitles() {
    return AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        interval: 2,
        getTitlesWidget: (double value, TitleMeta meta) {
          return Text(
            value.toInt().toString(),
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.textSecondary,
              fontSize: 9,
            ),
          );
        },
        reservedSize: 25,
      ),
    );
  }

  FlBorderData chartBorderData() {
    return FlBorderData(
      show: true,
      border: Border.all(
        color: AppTheme.backgroundQuaternary.withValues(alpha: 0.4),
        width: 0.5,
      ),
    );
  }

  List<LineChartBarData> lineBarsData(
    List<String> metrics,
    Map<String, List<CheckIn>> metricData,
    List<DateTime> sortedDates,
  ) {
    return metrics
        .asMap()
        .entries
        .where((entry) => !_hiddenMetrics.contains(entry.value))
        .map((entry) {
          final metric = entry.value;
          final metricObj = _getUserMetricByName(metric);
          if (metricObj == null) {
            return LineChartBarData(spots: []);
          }

          final color = metricObj.color;
          final metricCheckIns = metricData[metric]!;
          final spots = chartSpots(metricCheckIns, sortedDates);

          return LineChartBarData(
            spots: spots,
            isCurved: true,
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: 1.0),
                color.withValues(alpha: 0.8),
              ],
            ),
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: chartDotData(color),
            belowBarData: chartAreaData(color),
          );
        })
        .toList();
  }

  List<FlSpot> chartSpots(
    List<CheckIn> metricCheckIns,
    List<DateTime> sortedDates,
  ) {
    final spots = <FlSpot>[];
    for (int i = 0; i < sortedDates.length; i++) {
      final date = sortedDates[i];
      final checkIn = metricCheckIns
          .where(
            (c) =>
                c.dateTime.year == date.year &&
                c.dateTime.month == date.month &&
                c.dateTime.day == date.day,
          )
          .firstOrNull;

      if (checkIn != null) {
        spots.add(FlSpot(i.toDouble(), checkIn.rating.toDouble()));
      }
    }
    return spots;
  }

  FlDotData chartDotData(Color color) {
    return FlDotData(
      show: true,
      getDotPainter: (spot, percent, barData, index) {
        return FlDotCirclePainter(
          radius: 3,
          color: color,
          strokeWidth: 1,
          strokeColor: CupertinoColors.white,
        );
      },
    );
  }

  BarAreaData chartAreaData(Color color) {
    return BarAreaData(
      show: true,
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withValues(alpha: 0.08),
          color.withValues(alpha: 0.02),
          color.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.7, 1.0],
      ),
    );
  }

  LineTouchData chartTouchData(List<String> metrics) {
    return LineTouchData(
      enabled: true,
      touchTooltipData: LineTouchTooltipData(
        getTooltipColor: (spot) => AppTheme.backgroundSecondary,
        fitInsideHorizontally: true,
        fitInsideVertically: true,
        getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
          return touchedBarSpots.map((touchedSpot) {
            final visibleMetrics = metrics
                .where((m) => !_hiddenMetrics.contains(m))
                .toList();
            final metric = visibleMetrics[touchedSpot.barIndex];
            final metricObj = _getUserMetricByName(metric);
            if (metricObj == null) return null;

            final rating = touchedSpot.y.toInt();

            return LineTooltipItem(
              '$metric: $rating',
              AppTheme.bodySmall.copyWith(
                color: metricObj.color,
                fontWeight: FontWeight.w600,
                fontSize: 10,
              ),
            );
          }).toList();
        },
      ),
    );
  }
}
