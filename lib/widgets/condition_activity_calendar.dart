import 'package:flutter/cupertino.dart';
import 'package:health_notes/models/condition.dart';
import 'package:health_notes/models/condition_entry.dart';
import 'package:health_notes/providers/conditions_provider.dart';
import 'package:health_notes/theme/app_theme.dart';
import 'package:health_notes/utils/severity_utils.dart';
import 'package:health_notes/widgets/activity_calendar.dart';
import 'package:health_notes/widgets/spacing.dart';

/// Represents combined activity data for a single day on the condition calendar.
class ConditionDayData {
  final int severity; // 0 = no entry
  final int symptomCount;
  final int maxSymptomSeverity;

  const ConditionDayData({
    this.severity = 0,
    this.symptomCount = 0,
    this.maxSymptomSeverity = 0,
  });

  bool get hasEntry => severity > 0;
  bool get hasSymptoms => symptomCount > 0;
  bool get hasActivity => hasEntry || hasSymptoms;

  /// Returns the primary value for color calculation (prefers entry severity, falls back to symptom)
  int get primaryValue => hasEntry ? severity : maxSymptomSeverity;
}

class ConditionActivityCalendar extends StatelessWidget {
  final Condition condition;
  final List<ConditionEntry> entries;
  final List<LinkedSymptom> linkedSymptoms;
  final void Function(ConditionEntry entry) onEntryTap;
  final void Function(DateTime date, List<LinkedSymptom> symptoms)? onSymptomTap;

  const ConditionActivityCalendar({
    super.key,
    required this.condition,
    required this.entries,
    this.linkedSymptoms = const [],
    required this.onEntryTap,
    this.onSymptomTap,
  });

  @override
  Widget build(BuildContext context) {
    final activityData = generateActivityData();
    final entryMap = Map.fromEntries(
      entries.map((e) => MapEntry(
        DateTime(e.entryDate.year, e.entryDate.month, e.entryDate.day),
        e,
      )),
    );

    final symptomsByDate = <DateTime, List<LinkedSymptom>>{};
    for (final ls in linkedSymptoms) {
      final dateKey = DateTime(ls.date.year, ls.date.month, ls.date.day);
      symptomsByDate.putIfAbsent(dateKey, () => []).add(ls);
    }

    return ActivityCalendar<ConditionDayData>(
      title: '${condition.name} Activity',
      subtitle: 'Entries show severity • Badges show linked symptoms',
      activityData: activityData,
      colorCalculator: colorForDayData,
      legendBuilder: combinedLegend,
      onDateTap: (context, date, data) {
        if (data.hasEntry) {
          final entry = entryMap[date];
          if (entry != null) {
            onEntryTap(entry);
          }
        } else if (data.hasSymptoms && onSymptomTap != null) {
          onSymptomTap!(date, symptomsByDate[date] ?? []);
        }
      },
      activityDescriptor: (data) => _describeDay(data),
      emptyValue: const ConditionDayData(),
      dayCellBuilder: (context, date, data, hasActivity, color) {
        return _buildDayCell(context, date, data, hasActivity, color, entryMap, symptomsByDate);
      },
    );
  }

  Widget _buildDayCell(
    BuildContext context,
    DateTime date,
    ConditionDayData data,
    bool hasActivity,
    Color color,
    Map<DateTime, ConditionEntry> entryMap,
    Map<DateTime, List<LinkedSymptom>> symptomsByDate,
  ) {
    final entryColor = data.hasEntry
        ? SeverityUtils.colorForSeverity(data.severity)
        : AppColors.backgroundPrimary.withValues(alpha: 0.1);

    return GestureDetector(
      onTap: () {
        if (data.hasEntry) {
          final entry = entryMap[date];
          if (entry != null) onEntryTap(entry);
        } else if (data.hasSymptoms && onSymptomTap != null) {
          onSymptomTap!(date, symptomsByDate[date] ?? []);
        }
      },
      child: Container(
        width: CalendarConstants.cellSize,
        height: CalendarConstants.cellSize,
        margin: const EdgeInsets.all(CalendarConstants.cellMargin),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: entryColor,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: data.hasEntry
                      ? entryColor.withValues(alpha: 0.6)
                      : CupertinoColors.systemGrey4.withValues(alpha: 0.3),
                  width: data.hasEntry ? 1 : 0.5,
                ),
                boxShadow: data.hasEntry
                    ? [BoxShadow(color: entryColor.withValues(alpha: 0.3), blurRadius: 3, offset: const Offset(0, 1))]
                    : null,
              ),
              child: Center(
                child: Text(
                  data.hasEntry ? '${data.severity}' : '${date.day}',
                  style: TextStyle(
                    color: data.hasEntry
                        ? (entryColor.computeLuminance() > 0.5 ? CupertinoColors.black : CupertinoColors.white)
                        : CupertinoColors.systemGrey.withValues(alpha: 0.6),
                    fontSize: data.hasEntry ? 10 : 11,
                    fontWeight: data.hasEntry ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ),
            ),
            if (data.hasSymptoms)
              Positioned(
                top: 2,
                right: 2,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: SeverityUtils.colorForSeverity(data.maxSymptomSeverity),
                    shape: BoxShape.circle,
                    border: Border.all(color: CupertinoColors.white, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: CupertinoColors.black.withValues(alpha: 0.3),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '${data.symptomCount}',
                      style: const TextStyle(
                        color: CupertinoColors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _describeDay(ConditionDayData data) {
    if (!data.hasActivity) return 'No activity';
    final parts = <String>[];
    if (data.hasEntry) parts.add('Severity ${data.severity}/10');
    if (data.hasSymptoms) {
      parts.add('${data.symptomCount} symptom${data.symptomCount == 1 ? '' : 's'}');
    }
    return parts.join(' • ');
  }

  Map<DateTime, ConditionDayData> generateActivityData() {
    final data = <DateTime, ConditionDayData>{};

    // Add entries
    for (final entry in entries) {
      final dateKey = DateTime(
        entry.entryDate.year,
        entry.entryDate.month,
        entry.entryDate.day,
      );
      data[dateKey] = ConditionDayData(
        severity: entry.severity,
        symptomCount: data[dateKey]?.symptomCount ?? 0,
        maxSymptomSeverity: data[dateKey]?.maxSymptomSeverity ?? 0,
      );
    }

    // Add symptoms
    for (final ls in linkedSymptoms) {
      final dateKey = DateTime(ls.date.year, ls.date.month, ls.date.day);
      final existing = data[dateKey];
      final currentMax = existing?.maxSymptomSeverity ?? 0;
      final newMax = ls.symptom.severityLevel > currentMax
          ? ls.symptom.severityLevel
          : currentMax;

      data[dateKey] = ConditionDayData(
        severity: existing?.severity ?? 0,
        symptomCount: (existing?.symptomCount ?? 0) + 1,
        maxSymptomSeverity: newMax,
      );
    }

    return data;
  }

  Color colorForDayData(ConditionDayData data) {
    if (!data.hasActivity) {
      return AppColors.backgroundPrimary.withValues(alpha: 0.1);
    }
    // Use entry severity if available, otherwise use max symptom severity
    return SeverityUtils.colorForSeverity(data.primaryValue);
  }

  Widget combinedLegend() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Mild', style: AppTypography.bodySmallSystemGrey),
            HSpace.s,
            ...List.generate(5, (index) {
              final severity = (index + 1) * 2;
              return Container(
                width: CalendarConstants.legendItemSize,
                height: CalendarConstants.legendItemSize,
                margin: const EdgeInsets.only(right: 2),
                decoration: BoxDecoration(
                  color: SeverityUtils.colorForSeverity(severity),
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
            HSpace.s,
            Text('Severe', style: AppTypography.bodySmallSystemGrey),
          ],
        ),
        if (linkedSymptoms.isNotEmpty) ...[
          VSpace.s,
          Row(
            children: [
              Stack(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: AppColors.backgroundTertiary,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: SeverityUtils.colorForSeverity(5),
                        shape: BoxShape.circle,
                        border: Border.all(color: CupertinoColors.white, width: 0.5),
                      ),
                      child: const Center(
                        child: Text('2', style: TextStyle(color: CupertinoColors.white, fontSize: 6, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                ],
              ),
              HSpace.xs,
              Text(
                'Symptom count (${linkedSymptoms.length} total)',
                style: AppTypography.bodySmallSystemGrey,
              ),
            ],
          ),
        ],
      ],
    );
  }
}

