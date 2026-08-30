import 'package:ethan_utils/ethan_utils.dart';
import 'package:health_notes/models/condition_entry.dart';
import 'package:health_notes/providers/conditions_provider.dart';

class const ConditionDayData({
  final int severity = 0,
  final int symptomCount = 0,
  final int maxSymptomSeverity = 0,
}) {
  bool get hasEntry => severity > 0;
  bool get hasSymptoms => symptomCount > 0;
  bool get hasActivity => hasEntry || hasSymptoms;
  int get primaryValue => hasEntry ? severity : maxSymptomSeverity;

  @override
  String toString() => '$primaryValue';
}

class const ConditionSeverityPoint({
  required final DateTime date,
  required final int severity,
});

class ConditionActivityAggregator() {
  static Map<DateTime, ConditionDayData> byDate({
    required List<ConditionEntry> entries,
    required List<LinkedSymptom> linkedSymptoms,
  }) {
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
        maxSymptomSeverity: symptomSeverity > currentMax
            ? symptomSeverity
            : currentMax,
      );
    }

    return activityByDate;
  }

  static List<ConditionSeverityPoint> sparklinePoints(
    Map<DateTime, ConditionDayData> activityByDate,
  ) {
    final activeDays =
        activityByDate.entries
            .where((entry) => entry.value.hasActivity)
            .toList()
          ..sort((first, second) => first.key.compareTo(second.key));

    return activeDays
        .map(
          (entry) => ConditionSeverityPoint(
            date: entry.key,
            severity: entry.value.primaryValue,
          ),
        )
        .toList();
  }
}
