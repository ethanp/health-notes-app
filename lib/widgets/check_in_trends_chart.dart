import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:health_notes/models/check_in.dart';
import 'package:health_notes/theme/app_theme.dart';
import 'package:intl/intl.dart';

class CheckInTrendsChart extends StatelessWidget {
  final List<CheckIn> checkIns;
  final String metricName;
  final int maxDataPoints;

  const CheckInTrendsChart({
    super.key,
    required this.checkIns,
    required this.metricName,
    this.maxDataPoints = 30,
  });

  @override
  Widget build(BuildContext context) {
    final filteredCheckIns =
        checkIns.where((checkIn) => checkIn.metricName == metricName).toList()
          ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    if (filteredCheckIns.isEmpty) {
      return Container(
        height: 200,
        decoration: AppTheme.primaryCard,
        child: Center(
          child: Text(
            'No data for $metricName',
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.textTertiary),
          ),
        ),
      );
    }

    // Limit data points for better performance
    final limitedCheckIns = filteredCheckIns.length > maxDataPoints
        ? filteredCheckIns.sublist(filteredCheckIns.length - maxDataPoints)
        : filteredCheckIns;

    final spots = limitedCheckIns.asMap().entries.map((entry) {
      final index = entry.key;
      final checkIn = entry.value;
      return FlSpot(index.toDouble(), checkIn.rating.toDouble());
    }).toList();

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.primaryCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(metricName, style: AppTheme.labelLarge),
          const SizedBox(height: 8),
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
                      reservedSize: 30,
                      interval: (limitedCheckIns.length / 5).ceil().toDouble(),
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= limitedCheckIns.length) {
                          return const Text('');
                        }
                        final checkIn = limitedCheckIns[value.toInt()];
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            DateFormat('MMM d').format(checkIn.dateTime),
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
                      reservedSize: 40,
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
                maxX: (limitedCheckIns.length - 1).toDouble(),
                minY: 0,
                maxY: 10,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primary,
                        AppTheme.primary.withValues(alpha: 0.5),
                      ],
                    ),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: AppTheme.primary,
                          strokeWidth: 2,
                          strokeColor: CupertinoColors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primary.withValues(alpha: 0.3),
                          AppTheme.primary.withValues(alpha: 0.1),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
