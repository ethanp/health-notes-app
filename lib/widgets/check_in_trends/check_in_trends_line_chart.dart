import 'package:ethan_ui/ethan_ui.dart';
import 'package:ethan_utils/ethan_utils.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:health_notes/constants/chart_constants.dart';
import 'package:health_notes/models/check_in.dart';
import 'package:health_notes/models/check_in_metric.dart';
import 'package:health_notes/models/date_range_filter.dart';
import 'package:health_notes/theme/app_theme.dart';
import 'package:health_notes/ui/check_in_metric_appearance.dart';
import 'package:health_notes/utils/rating_color.dart';
import 'package:intl/intl.dart';

class const CheckInTrendsLineChart({
  required final List<CheckIn> checkIns,
  required final List<CheckInMetric> userMetrics,
  required final Set<String> hiddenMetrics,
  required final DateRangeFilter dateRange,
  required final List<String> metrics,
  required final MetricType metricType,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (checkIns.isEmpty) {
      return ECard(
        child: Center(child: Text('No data', style: EText.body.small.tertiary)),
      );
    }

    final metricData = _prepareMetricData();
    final sortedDates = _sortedDates(metricData);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: RatingColor.semanticBandsThroughPlotAndLabels(metricType),
          stops: RatingColor.plotThenLabelGutterStops(metricType),
        ),
        borderRadius: BorderRadius.circular(AppRadius.small),
      ),
      child: LineChart(
        LineChartData(
          gridData: _firstOfMonthVerticalLines(sortedDates),
          titlesData: _chartTitlesData(sortedDates),
          borderData: _chartBorderData(),
          minX: 0,
          maxX: (sortedDates.length - 1).toDouble(),
          minY: 1,
          maxY: 10,
          backgroundColor: Colors.transparent,
          lineBarsData: _lineBarsData(metricData, sortedDates),
          lineTouchData: _chartTouchData(),
          extraLinesData: ExtraLinesData(
            horizontalLines: [
              HorizontalLine(
                y: 1,
                color: Colors.white.withValues(alpha: 0.25),
                strokeWidth: 1,
              ),
              HorizontalLine(
                y: 5,
                color: Colors.white.withValues(alpha: 0.25),
                strokeWidth: 1,
              ),
              HorizontalLine(
                y: 10,
                color: Colors.white.withValues(alpha: 0.25),
                strokeWidth: 1,
              ),
            ],
          ),
        ),
        duration: Duration.zero,
      ),
    );
  }

  CheckInMetric? _userMetricByName(String name) {
    for (final metric in userMetrics) {
      if (metric.name == name) return metric;
    }
    return null;
  }

  Map<String, List<CheckIn>> _prepareMetricData() {
    final metricData = <String, List<CheckIn>>{};
    final filteredCheckIns = checkIns
        .where((checkIn) => dateRange.includesDate(checkIn.dateTime))
        .toList();

    for (final metric in metrics) {
      final metricCheckIns =
          filteredCheckIns
              .where((checkIn) => checkIn.metricName == metric)
              .toList()
            ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
      metricData[metric] = metricCheckIns;
    }
    return metricData;
  }

  List<DateTime> _sortedDates(Map<String, List<CheckIn>> metricData) {
    final allDates = <DateTime>{};
    for (final checkInsForMetric in metricData.values) {
      for (final checkIn in checkInsForMetric) {
        allDates.add(checkIn.dateTime.startOfDay);
      }
    }
    return allDates.toList()..sort();
  }

  FlGridData _firstOfMonthVerticalLines(List<DateTime> sortedDates) {
    return FlGridData(
      show: true,
      drawHorizontalLine: false,
      drawVerticalLine: true,
      verticalInterval: 1,
      getDrawingVerticalLine: (value) {
        final idx = value.toInt();
        if (idx < 0 || idx >= sortedDates.length) return FlLine(strokeWidth: 0);
        final date = sortedDates[idx];
        if (date.day != 1) return FlLine(strokeWidth: 0);
        return FlLine(
          color: Colors.white.withValues(alpha: 0.2),
          strokeWidth: 1,
        );
      },
    );
  }

  FlTitlesData _chartTitlesData(List<DateTime> sortedDates) {
    return FlTitlesData(
      show: true,
      rightTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 16,
          getTitlesWidget: (value, meta) => const Text(''),
        ),
      ),
      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      bottomTitles: _monthDayBottomTitles(sortedDates),
      leftTitles: _ratingExtentAndMidpointTitles(),
    );
  }

  AxisTitles _monthDayBottomTitles(List<DateTime> sortedDates) {
    final interval = (sortedDates.length / 6).ceilToDouble().clamp(
      1.0,
      double.infinity,
    );

    return AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: kChartBottomAxisReservedSize,
        interval: interval,
        getTitlesWidget: (double value, TitleMeta meta) {
          if (value.toInt() >= 0 && value.toInt() < sortedDates.length) {
            final date = sortedDates[value.toInt()];
            return SideTitleWidget(
              meta: meta,
              space: 4,
              child: Text(
                DateFormat('MMM d').format(date),
                style: EText.body.small.secondary
                    .size(9)
                    .copyWith(
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
              ),
            );
          }
          return const Text('');
        },
      ),
    );
  }

  AxisTitles _ratingExtentAndMidpointTitles() {
    return AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        interval: 1,
        getTitlesWidget: (double value, TitleMeta meta) {
          final v = value.toInt();
          if (v != 1 && v != 5 && v != 10) return const SizedBox.shrink();
          return SideTitleWidget(
            meta: meta,
            space: 4,
            child: Text(
              '$v',
              style: EText.body.small.secondary
                  .size(9)
                  .copyWith(
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
            ),
          );
        },
        reservedSize: 20,
      ),
    );
  }

  FlBorderData _chartBorderData() {
    return FlBorderData(
      show: true,
      border: Border.all(
        color: Colors.white.withValues(alpha: 0.15),
        width: 0.5,
      ),
    );
  }

  List<LineChartBarData> _lineBarsData(
    Map<String, List<CheckIn>> metricData,
    List<DateTime> sortedDates,
  ) {
    return metrics
        .asMap()
        .entries
        .where((entry) => !hiddenMetrics.contains(entry.value))
        .map((entry) {
          final metric = entry.value;
          final metricObj = _userMetricByName(metric);
          if (metricObj == null) {
            return LineChartBarData(spots: []);
          }

          final color = metricObj.color;
          final metricCheckIns = metricData[metric]!;
          return LineChartBarData(
            spots: _chartSpots(metricCheckIns, sortedDates),
            isCurved: true,
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: 1.0),
                color.withValues(alpha: 0.8),
              ],
            ),
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: _whiteRingedRatingDots(color),
            belowBarData: _fadeUnderRatingLine(color),
          );
        })
        .toList();
  }

  List<FlSpot> _chartSpots(
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

  FlDotData _whiteRingedRatingDots(Color color) {
    return FlDotData(
      show: true,
      getDotPainter: (spot, percent, barData, index) {
        return FlDotCirclePainter(
          radius: 3,
          color: color,
          strokeWidth: 1,
          strokeColor: Colors.white,
        );
      },
    );
  }

  BarAreaData _fadeUnderRatingLine(Color color) {
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

  LineTouchData _chartTouchData() {
    return LineTouchData(
      enabled: true,
      touchTooltipData: LineTouchTooltipData(
        getTooltipColor: (spot) => EColors.backgroundLift,
        fitInsideHorizontally: true,
        fitInsideVertically: true,
        getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
          return touchedBarSpots.map((touchedSpot) {
            final visibleMetrics = metrics
                .where((m) => !hiddenMetrics.contains(m))
                .toList();
            final metric = visibleMetrics[touchedSpot.barIndex];
            final metricObj = _userMetricByName(metric);
            if (metricObj == null) return null;

            final rating = touchedSpot.y.toInt();

            return LineTooltipItem(
              '$metric: $rating',
              EText.body.small.copyWith(
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
