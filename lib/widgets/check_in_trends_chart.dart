import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:health_notes/models/check_in.dart';
import 'package:health_notes/theme/app_theme.dart';
import 'package:health_notes/utils/metric_colors.dart';
import 'package:health_notes/utils/metric_icons.dart';
import 'package:intl/intl.dart';

class CheckInTrendsChart extends StatefulWidget {
  final List<CheckIn> checkIns;
  final int maxDataPoints;

  const CheckInTrendsChart({
    super.key,
    required this.checkIns,
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

    // Get unique metrics and their data, sorted consistently
    final metrics = MetricColors.sortMetrics(
      widget.checkIns.map((c) => c.metricName).toSet().toList(),
    );
    final metricData = <String, List<CheckIn>>{};

    for (final metric in metrics) {
      final metricCheckIns =
          widget.checkIns
              .where((checkIn) => checkIn.metricName == metric)
              .toList()
            ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

      // Limit data points for better performance
      if (metricCheckIns.length > widget.maxDataPoints) {
        metricData[metric] = metricCheckIns.sublist(
          metricCheckIns.length - widget.maxDataPoints,
        );
      } else {
        metricData[metric] = metricCheckIns;
      }
    }

    // Get all unique dates across all metrics
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

    // Limit to maxDataPoints most recent dates
    if (sortedDates.length > widget.maxDataPoints) {
      sortedDates.removeRange(0, sortedDates.length - widget.maxDataPoints);
    }

    return Container(
      height: 450,
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.primaryCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                CupertinoIcons.chart_bar_alt_fill,
                size: 20,
                color: AppTheme.textPrimary,
              ),
              const SizedBox(width: 8),
              Text('Check-in Trends', style: AppTheme.labelLarge),
            ],
          ),
          const SizedBox(height: 16),

          // Legend
          Container(
            constraints: const BoxConstraints(maxHeight: 120),
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 12,
                runSpacing: 8,
                children: metrics.asMap().entries.map((entry) {
                  final metric = entry.value;
                  final color = MetricColors.getColor(metric);
                  final isHidden = _hiddenMetrics.contains(metric);

                  return GestureDetector(
                    onTap: () => _toggleMetric(metric),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isHidden
                            ? AppTheme.backgroundTertiary
                            : color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isHidden
                              ? AppTheme.textTertiary
                              : color.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            MetricIcons.getIcon(metric),
                            size: 12,
                            color: isHidden ? AppTheme.textTertiary : color,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            metric,
                            style: AppTheme.bodySmall.copyWith(
                              color: isHidden ? AppTheme.textTertiary : color,
                              fontWeight: FontWeight.w500,
                              decoration: isHidden
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Chart
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 2,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: AppTheme.backgroundTertiary,
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: (sortedDates.length / 5).ceil().toDouble(),
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= sortedDates.length) {
                          return const Text('');
                        }
                        final date = sortedDates[value.toInt()];
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            DateFormat('MMM d').format(date),
                            style: AppTheme.bodySmall.copyWith(
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 2,
                      reservedSize: 50,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.textPrimary,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(
                    color: AppTheme.backgroundTertiary,
                    width: 1,
                  ),
                ),
                minX: 0,
                maxX: (sortedDates.length - 1).toDouble(),
                minY: 0,
                maxY: 10,
                lineBarsData: metrics
                    .asMap()
                    .entries
                    .where((entry) => !_hiddenMetrics.contains(entry.value))
                    .map((entry) {
                      final metric = entry.value;
                      final color = MetricColors.getColor(metric);
                      final metricCheckIns = metricData[metric]!;

                      // Create spots for this metric
                      final spots = <FlSpot>[];
                      for (int i = 0; i < sortedDates.length; i++) {
                        final date = sortedDates[i];
                        final checkIn = metricCheckIns
                            .where(
                              (c) =>
                                  DateTime(
                                    c.dateTime.year,
                                    c.dateTime.month,
                                    c.dateTime.day,
                                  ) ==
                                  date,
                            )
                            .lastOrNull;

                        if (checkIn != null) {
                          spots.add(
                            FlSpot(i.toDouble(), checkIn.rating.toDouble()),
                          );
                        }
                      }

                      return LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        color: color,
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) {
                            return FlDotCirclePainter(
                              radius: 4,
                              color: color,
                              strokeWidth: 2,
                              strokeColor: CupertinoColors.white,
                            );
                          },
                        ),
                        belowBarData: BarAreaData(show: false),
                      );
                    })
                    .toList(),
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    tooltipRoundedRadius: 8,
                    tooltipPadding: const EdgeInsets.all(8),
                    tooltipMargin: 8,
                    getTooltipItems: (touchedSpots) {
                      // Get visible metrics for tooltip mapping
                      final visibleMetrics = metrics
                          .where((m) => !_hiddenMetrics.contains(m))
                          .toList();

                      return touchedSpots.map((touchedSpot) {
                        final metric = visibleMetrics[touchedSpot.barIndex];
                        final color = MetricColors.getColor(metric);
                        final date = sortedDates[touchedSpot.x.toInt()];

                        return LineTooltipItem(
                          '$metric: ${touchedSpot.y.toInt()}\n${DateFormat('MMM d, y').format(date)}',
                          AppTheme.bodySmall.copyWith(
                            color: color,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
