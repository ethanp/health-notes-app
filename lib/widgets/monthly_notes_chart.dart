import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:health_notes/theme/app_theme.dart';
import 'package:intl/intl.dart';

class MonthlyNotesChart extends StatelessWidget {
  final Map<String, int> monthlyStats;

  const MonthlyNotesChart({super.key, required this.monthlyStats});

  @override
  Widget build(BuildContext context) {
    final sortedMonths = monthlyStats.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    final maxValue = sortedMonths
        .map((e) => e.value)
        .reduce((a, b) => a > b ? a : b);
    final spots = sortedMonths.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.value.toDouble());
    }).toList();

    return Container(
      decoration: AppComponents.primaryCard,
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        height: 180,
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: (maxValue / 4).ceilToDouble().clamp(
                1,
                double.infinity,
              ),
              getDrawingHorizontalLine: (value) => FlLine(
                color: CupertinoColors.systemGrey.withValues(alpha: 0.2),
                strokeWidth: 1,
              ),
            ),
            titlesData: FlTitlesData(
              rightTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  interval: 1,
                  getTitlesWidget: (value, meta) {
                    final idx = value.toInt();
                    if (idx < 0 || idx >= sortedMonths.length) {
                      return const SizedBox.shrink();
                    }
                    final monthKey = sortedMonths[idx].key;
                    return SideTitleWidget(
                      meta: meta,
                      space: 4,
                      child: Text(
                        _formatMonthShort(monthKey),
                        style: AppTypography.bodySmallSystemGrey.copyWith(
                          fontSize: 10,
                        ),
                      ),
                    );
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 32,
                  interval: (maxValue / 4).ceilToDouble().clamp(
                    1,
                    double.infinity,
                  ),
                  getTitlesWidget: (value, meta) {
                    return Text(
                      value.toInt().toString(),
                      style: AppTypography.bodySmallSystemGrey.copyWith(
                        fontSize: 10,
                      ),
                    );
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            minX: 0,
            maxX: (sortedMonths.length - 1).toDouble(),
            minY: 0,
            maxY: maxValue.toDouble() * 1.1,
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: AppColors.primary,
                barWidth: 2,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) =>
                      FlDotCirclePainter(
                        radius: 4,
                        color: AppColors.primary,
                        strokeWidth: 1.5,
                        strokeColor: CupertinoColors.white,
                      ),
                ),
                belowBarData: BarAreaData(
                  show: true,
                  color: AppColors.primary.withValues(alpha: 0.1),
                ),
              ),
            ],
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (spot) => AppColors.backgroundSecondary,
                getTooltipItems: (spots) => spots.map((spot) {
                  final idx = spot.x.toInt();
                  final monthKey = sortedMonths[idx].key;
                  final count = spot.y.toInt();
                  return LineTooltipItem(
                    '$count notes\n',
                    AppTypography.bodySmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                    children: [
                      TextSpan(
                        text: _formatMonthFull(monthKey),
                        style: AppTypography.bodySmall.copyWith(
                          color: CupertinoColors.white,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
          duration: Duration.zero,
        ),
      ),
    );
  }

  String _formatMonthShort(String monthKey) {
    try {
      final parts = monthKey.split('-');
      if (parts.length == 2) {
        final month = int.parse(parts[1]);
        return DateFormat('MMM').format(DateTime(2000, month));
      }
    } catch (_) {}
    return monthKey;
  }

  String _formatMonthFull(String monthKey) {
    try {
      final parts = monthKey.split('-');
      if (parts.length == 2) {
        final year = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        return DateFormat("MMM ''yy").format(DateTime(year, month));
      }
    } catch (_) {}
    return monthKey;
  }
}

