import 'package:ethan_ui/ethan_ui.dart';
import 'package:flutter/material.dart';
import 'package:ethan_utils/ethan_utils.dart';
import 'package:health_notes/models/condition.dart';
import 'package:health_notes/models/condition_entry.dart';
import 'package:health_notes/providers/conditions_provider.dart';
import 'package:health_notes/services/condition_activity_aggregator.dart';
import 'package:health_notes/theme/app_theme.dart';
import 'package:health_notes/utils/symptom_severity.dart';
import 'package:health_notes/widgets/activity_calendar.dart';
import 'package:health_notes/theme/spacing.dart';

class const ConditionActivityCalendar({
  required final Condition condition,
  required final List<ConditionEntry> entries,
  final List<LinkedSymptom> linkedSymptoms = const [],
  required final void Function(ConditionEntry entry) onEntrySelected,
  final void Function(DateTime date, List<LinkedSymptom> symptoms)?
  onSymptomTap,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final activityData = ConditionActivityAggregator.byDate(
      entries: entries,
      linkedSymptoms: linkedSymptoms,
    );
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
      colorForActivity: checkInSeverityOrMaxSymptomAsColor,
      legendBuilder: _legend,
      onDateTap: (context, date, dayData) {
        if (dayData.hasEntry) {
          final entry = entryMap[date];
          if (entry != null) onEntrySelected(entry);
        } else if (dayData.hasSymptoms && onSymptomTap != null) {
          onSymptomTap!(date, symptomsByDate[date] ?? []);
        }
      },
      activityDescriptor: _describeDay,
      emptyValue: const ConditionDayData(),
    );
  }

  Color checkInSeverityOrMaxSymptomAsColor(ConditionDayData dayData) {
    if (!dayData.hasActivity) {
      return EColors.background.withValues(alpha: 0.1);
    }
    return SymptomSeverity.hslGreenToRed(dayData.checkInSeverityOrMaxSymptom);
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
        Text('Mild', style: EText.body.small.muted),
        HSpace.s,
        ...List.generate(5, (index) {
          final severity = (index + 1) * 2;
          return Container(
            width: CalendarConstants.legendItemSize,
            height: CalendarConstants.legendItemSize,
            margin: const EdgeInsets.only(right: 2),
            decoration: BoxDecoration(
              color: SymptomSeverity.hslGreenToRed(severity),
              borderRadius: BorderRadius.circular(AppRadius.xs),
            ),
          );
        }),
        HSpace.s,
        Text('Severe', style: EText.body.small.muted),
      ],
    );
  }
}
