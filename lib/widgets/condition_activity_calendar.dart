import 'package:flutter/cupertino.dart';
import 'package:health_notes/models/condition.dart';
import 'package:health_notes/models/condition_entry.dart';
import 'package:health_notes/theme/app_theme.dart';
import 'package:health_notes/utils/severity_utils.dart';
import 'package:health_notes/widgets/activity_calendar.dart';
import 'package:health_notes/widgets/spacing.dart';

class ConditionActivityCalendar extends StatelessWidget {
  final Condition condition;
  final List<ConditionEntry> entries;
  final void Function(ConditionEntry entry) onEntryTap;

  const ConditionActivityCalendar({
    super.key,
    required this.condition,
    required this.entries,
    required this.onEntryTap,
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

    return ActivityCalendar<int>(
      title: '${condition.name} Activity',
      subtitle: 'Tap a date with an entry to edit severity, phase, or notes',
      activityData: activityData,
      colorCalculator: colorForSeverity,
      legendBuilder: severityLegend,
      onDateTap: (context, date, severity) {
        if (severity > 0) {
          final entry = entryMap[date];
          if (entry != null) {
            onEntryTap(entry);
          }
        }
      },
      activityDescriptor: (severity) =>
          severity == 0 ? 'No entry' : 'Severity $severity/10',
      emptyValue: 0,
    );
  }

  Map<DateTime, int> generateActivityData() {
    final data = <DateTime, int>{};

    for (final entry in entries) {
      final dateKey = DateTime(
        entry.entryDate.year,
        entry.entryDate.month,
        entry.entryDate.day,
      );
      data[dateKey] = entry.severity;
    }

    return data;
  }

  Color colorForSeverity(int severity) {
    if (severity == 0) {
      return AppColors.backgroundPrimary.withValues(alpha: 0.1);
    }
    return SeverityUtils.colorForSeverity(severity);
  }

  Widget severityLegend() {
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
              color: colorForSeverity(severity),
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

