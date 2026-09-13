import 'package:ethan_ui/ethan_ui.dart';
import 'package:ethan_utils/ethan_utils.dart';
import 'package:flutter/material.dart';
import 'package:health_notes/models/condition.dart';
import 'package:health_notes/models/condition_entry.dart';
import 'package:health_notes/providers/conditions_provider.dart';
import 'package:health_notes/services/condition_activity_aggregator.dart';
import 'package:health_notes/theme/app_theme.dart';
import 'package:health_notes/theme/spacing.dart';
import 'package:health_notes/utils/symptom_severity.dart';
import 'package:health_notes/widgets/health_notes_month_stack.dart';

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

    return HealthNotesMonthStack(
      title: '${condition.name} Activity',
      subtitle: 'Color shows severity from entries and linked symptoms',
      legend: _severityLegend(),
      presentationFor: (date) {
        final dayData = activityData[date.startOfDay] ?? const ConditionDayData();
        if (!dayData.hasActivity) {
          return HealthNotesMonthStack.severityDay(
            date: date,
            severity: 0,
            background: SymptomSeverity.hslGreenToRed(0),
            semanticsLabel: 'No activity',
          );
        }
        final severity = dayData.checkInSeverityOrMaxSymptom;
        return HealthNotesMonthStack.severityDay(
          date: date,
          severity: severity,
          background: SymptomSeverity.hslGreenToRed(severity),
          semanticsLabel: _describeDay(dayData),
          secondaryLabel: '$severity',
        );
      },
      quantityOn: (date) {
        final dayData = activityData[date.startOfDay] ?? const ConditionDayData();
        return dayData.hasActivity ? dayData.checkInSeverityOrMaxSymptom : 0;
      },
      chartFrom: activityData.isEmpty ? null : activityData.keys.min,
      measureTitle: 'severity',
      formatMeasure: (quantity) => quantity.round().toString(),
      onDaySelected: (day) {
        final date = day.date.startOfDay;
        final dayData = activityData[date] ?? const ConditionDayData();
        if (dayData.hasEntry) {
          final entry = entryMap[date];
          if (entry != null) onEntrySelected(entry);
          return;
        }
        if (dayData.hasSymptoms && onSymptomTap != null) {
          onSymptomTap!(date, symptomsByDate[date] ?? []);
        }
      },
    );
  }

  String _describeDay(ConditionDayData dayData) {
    final parts = <String>[];
    if (dayData.hasEntry) parts.add('Severity ${dayData.severity}/10');
    if (dayData.hasSymptoms) {
      parts.add(
        '${dayData.symptomCount} symptom${dayData.symptomCount == 1 ? '' : 's'}',
      );
    }
    return parts.join(' · ');
  }

  Widget _severityLegend() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Severity 0–10', style: EText.body.small.muted),
        VSpace.s,
        Row(
          children: [
            Text('Mild', style: EText.body.small.muted),
            HSpace.s,
            ...List.generate(5, (index) {
              final severity = (index + 1) * 2;
              return Container(
                width: 12,
                height: 12,
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
        ),
      ],
    );
  }
}
