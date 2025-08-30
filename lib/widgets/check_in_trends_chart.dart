import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:health_notes/models/check_in.dart';
import 'package:health_notes/models/metric.dart';
import 'package:health_notes/theme/app_theme.dart';
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
    final metrics = Metric.sortMetricNames(
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
      height: 600,
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
          // Legend organized by MetricType
          _buildLegendByType(metrics),
          const SizedBox(height: 16),
          // Chart
          Expanded(
            child: AnimatedOpacity(
              opacity: 1.0,
              duration: const Duration(milliseconds: 500),
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    horizontalInterval: 2,
                    verticalInterval: 1,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: AppTheme.backgroundQuaternary.withValues(
                          alpha: 0.3,
                        ),
                        strokeWidth: 0.5,
                      );
                    },
                    getDrawingVerticalLine: (value) {
                      return FlLine(
                        color: AppTheme.backgroundQuaternary.withValues(
                          alpha: 0.3,
                        ),
                        strokeWidth: 0.5,
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
                        reservedSize: 30,
                        interval: 1,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          if (value.toInt() >= 0 &&
                              value.toInt() < sortedDates.length) {
                            final date = sortedDates[value.toInt()];
                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              child: Text(
                                DateFormat('MMM d').format(date),
                                style: AppTheme.bodySmall.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 2,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          return Text(
                            value.toInt().toString(),
                            style: AppTheme.bodySmall.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          );
                        },
                        reservedSize: 42,
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(
                      color: AppTheme.backgroundQuaternary.withValues(
                        alpha: 0.4,
                      ),
                      width: 0.5,
                    ),
                  ),
                  minX: 0,
                  maxX: (sortedDates.length - 1).toDouble(),
                  minY: 0,
                  maxY: 10,
                  backgroundColor: AppTheme.backgroundPrimary.withValues(
                    alpha: 0.02,
                  ),
                  lineBarsData: metrics
                      .asMap()
                      .entries
                      .where((entry) => !_hiddenMetrics.contains(entry.value))
                      .map((entry) {
                        final metric = entry.value;
                        final metricObj = Metric.fromName(metric);
                        if (metricObj == null)
                          return LineChartBarData(spots: []);

                        final color = metricObj.color;
                        final metricCheckIns = metricData[metric]!;

                        // Create spots for this metric
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
                            spots.add(
                              FlSpot(i.toDouble(), checkIn.rating.toDouble()),
                            );
                          }
                        }

                        return LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          gradient: LinearGradient(
                            colors: [
                              color.withValues(alpha: 1.0),
                              color.withValues(alpha: 0.8),
                            ],
                          ),
                          barWidth: 4,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) {
                              return FlDotCirclePainter(
                                radius: 5,
                                color: color,
                                strokeWidth: 3,
                                strokeColor: CupertinoColors.white,
                              );
                            },
                          ),
                          belowBarData: BarAreaData(
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
                          ),
                        );
                      })
                      .toList(),
                  lineTouchData: LineTouchData(
                    enabled: true,
                    touchTooltipData: LineTouchTooltipData(
                      tooltipRoundedRadius: 12,
                      tooltipPadding: const EdgeInsets.all(12),
                      tooltipMargin: 12,
                      getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                        return touchedBarSpots.map((touchedSpot) {
                          final date = sortedDates[touchedSpot.x.toInt()];

                          // Get visible metrics for tooltip mapping
                          final visibleMetrics = metrics
                              .where((m) => !_hiddenMetrics.contains(m))
                              .toList();
                          final metric = visibleMetrics[touchedSpot.barIndex];
                          final metricObj = Metric.fromName(metric);
                          if (metricObj == null) return null;

                          final color = metricObj.color;

                          return LineTooltipItem(
                            '$metric: ${touchedSpot.y.toInt()}\n${DateFormat('MMM d, y').format(date)}',
                            AppTheme.bodyMedium.copyWith(
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
          ),
        ],
      ),
    );
  }

  Widget _buildLegendByType(List<String> metrics) {
    final groupedMetrics = <MetricType, List<String>>{};
    for (final metric in metrics) {
      final metricObj = Metric.fromName(metric);
      if (metricObj == null) continue;

      final type = metricObj.type;
      if (groupedMetrics[type] == null) {
        groupedMetrics[type] = <String>[];
      }
      groupedMetrics[type]!.add(metric);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: groupedMetrics.entries.map((entry) {
        final type = entry.key;
        final typeMetrics = entry.value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getTypeDisplayName(type),
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: typeMetrics.map((metric) {
                final metricObj = Metric.fromName(metric);
                if (metricObj == null) return const SizedBox.shrink();

                final color = metricObj.color;
                final isHidden = _hiddenMetrics.contains(metric);

                return GestureDetector(
                  onTap: () => _toggleMetric(metric),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
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
              }).toList(),
            ),
            const SizedBox(height: 12),
          ],
        );
      }).toList(),
    );
  }

  String _getTypeDisplayName(MetricType type) {
    return switch (type) {
      MetricType.lowerIsBetter => 'Lower is Better',
      MetricType.middleIsBest => 'Middle is Best',
      MetricType.higherIsBetter => 'Higher is Better',
    };
  }
}
