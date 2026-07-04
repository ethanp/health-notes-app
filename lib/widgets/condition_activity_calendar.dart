import 'package:ethan_utils/ethan_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:health_notes/models/condition.dart';
import 'package:health_notes/models/condition_entry.dart';
import 'package:health_notes/providers/conditions_provider.dart';
import 'package:health_notes/theme/app_theme.dart';
import 'package:health_notes/utils/severity_utils.dart';
import 'package:health_notes/widgets/activity_calendar.dart';
import 'package:health_notes/theme/spacing.dart';

class ConditionDayData {
  final int severity;
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
  int get primaryValue => hasEntry ? severity : maxSymptomSeverity;

  @override
  String toString() => '$primaryValue';
}

class ConditionActivityCalendar extends StatelessWidget {
  final Condition condition;
  final List<ConditionEntry> entries;
  final List<LinkedSymptom> linkedSymptoms;
  final void Function(ConditionEntry entry) onEntryTap;
  final void Function(DateTime date, List<LinkedSymptom> symptoms)?
      onSymptomTap;

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
    final activityData = _generateActivityData();
    final entryMap = Map.fromEntries(
      entries.map((entry) => MapEntry(entry.entryDate.startOfDay, entry)),
    );
    final symptomsByDate = <DateTime, List<LinkedSymptom>>{};
    for (final linkedSymptom in linkedSymptoms) {
      final dateKey = linkedSymptom.date.startOfDay;
      symptomsByDate.putIfAbsent(dateKey, () => []).add(linkedSymptom);
    }

    return ActivityCalendar<ConditionDayData>(
      title: '${condition.name} Activity',
      subtitle: 'Color shows severity from entries and linked symptoms',
      activityData: activityData,
      colorCalculator: _colorForDay,
      legendBuilder: _legend,
      onDateTap: (context, date, dayData) {
        if (dayData.hasEntry) {
          final entry = entryMap[date];
          if (entry != null) onEntryTap(entry);
        } else if (dayData.hasSymptoms && onSymptomTap != null) {
          onSymptomTap!(date, symptomsByDate[date] ?? []);
        }
      },
      activityDescriptor: _describeDay,
      emptyValue: const ConditionDayData(),
    );
  }

  Map<DateTime, ConditionDayData> _generateActivityData() {
    final activityByDate = <DateTime, ConditionDayData>{};

    for (final entry in entries) {
      final dateKey = entry.entryDate.startOfDay;
      activityByDate[dateKey] = ConditionDayData(
        severity: entry.severity,
        symptomCount: activityByDate[dateKey]?.symptomCount ?? 0,
        maxSymptomSeverity: activityByDate[dateKey]?.maxSymptomSeverity ?? 0,
      );
    }

    for (final linkedSymptom in linkedSymptoms) {
      final dateKey = linkedSymptom.date.startOfDay;
      final existing = activityByDate[dateKey];
      final currentMax = existing?.maxSymptomSeverity ?? 0;
      final symptomSeverity = linkedSymptom.symptom.severityLevel;

      activityByDate[dateKey] = ConditionDayData(
        severity: existing?.severity ?? 0,
        symptomCount: (existing?.symptomCount ?? 0) + 1,
        maxSymptomSeverity:
            symptomSeverity > currentMax ? symptomSeverity : currentMax,
      );
    }

    return activityByDate;
  }

  Color _colorForDay(ConditionDayData dayData) {
    if (!dayData.hasActivity) {
      return AppColors.backgroundPrimary.withValues(alpha: 0.1);
    }
    return SeverityUtils.colorForSeverity(dayData.primaryValue);
  }

  String _describeDay(ConditionDayData dayData) {
    if (!dayData.hasActivity) return 'No activity';
    final parts = <String>[];
    if (dayData.hasEntry) parts.add('Severity ${dayData.severity}/10');
    if (dayData.hasSymptoms) {
      parts.add(
        '${dayData.symptomCount} symptom${dayData.symptomCount == 1 ? '' : 's'}',
      );
    }
    return parts.join(' · ');
  }

  Widget _legend() {
    return Row(
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
    );
  }
}
