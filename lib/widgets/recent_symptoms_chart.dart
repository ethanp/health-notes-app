import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:health_notes/theme/app_theme.dart';

class RecentSymptomsChart extends StatelessWidget {
  final Map<String, int> symptomStats;
  final void Function(String) onSymptomTap;

  const RecentSymptomsChart({
    super.key,
    required this.symptomStats,
    required this.onSymptomTap,
  });

  @override
  Widget build(BuildContext context) {
    final sortedSymptoms = symptomStats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topSymptoms = sortedSymptoms.take(7).toList();

    if (topSymptoms.isEmpty) return const SizedBox.shrink();

    final maxValue = topSymptoms
        .map((e) => e.value)
        .reduce((a, b) => a > b ? a : b);

    return Container(
      decoration: AppComponents.primaryCard,
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        height: 200,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxValue.toDouble() * 1.2,
            minY: 0,
            barTouchData: BarTouchData(
              enabled: true,
              touchCallback: (event, response) {
                if (event.isInterestedForInteractions &&
                    response != null &&
                    response.spot != null) {
                  final idx = response.spot!.touchedBarGroupIndex;
                  if (idx >= 0 && idx < topSymptoms.length) {
                    onSymptomTap(topSymptoms[idx].key);
                  }
                }
              },
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (group) => AppColors.backgroundSecondary,
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final symptom = topSymptoms[groupIndex];
                  return BarTooltipItem(
                    '${symptom.key}\n',
                    AppTypography.bodySmall.copyWith(
                      color: CupertinoColors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                    children: [
                      TextSpan(
                        text: '${symptom.value} times',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.primary,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              show: true,
              rightTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 60,
                  getTitlesWidget: (value, meta) {
                    final idx = value.toInt();
                    if (idx < 0 || idx >= topSymptoms.length) {
                      return const SizedBox.shrink();
                    }
                    final label = topSymptoms[idx].key;
                    return SideTitleWidget(
                      meta: meta,
                      space: 4,
                      child: Transform.rotate(
                        angle: -0.5,
                        child: Text(
                          label,
                          style: AppTypography.bodySmall.copyWith(
                            color: CupertinoColors.white.withValues(alpha: 0.9),
                            fontSize: 11,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    );
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  interval: (maxValue / 3).ceilToDouble().clamp(
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
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: (maxValue / 3).ceilToDouble().clamp(
                1,
                double.infinity,
              ),
              getDrawingHorizontalLine: (value) => FlLine(
                color: CupertinoColors.systemGrey.withValues(alpha: 0.2),
                strokeWidth: 1,
              ),
            ),
            borderData: FlBorderData(show: false),
            barGroups: topSymptoms.asMap().entries.map((entry) {
              return BarChartGroupData(
                x: entry.key,
                barRods: [
                  BarChartRodData(
                    toY: entry.value.value.toDouble(),
                    color: AppColors.primary,
                    width: 16,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(4),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
          duration: Duration.zero,
        ),
      ),
    );
  }
}

