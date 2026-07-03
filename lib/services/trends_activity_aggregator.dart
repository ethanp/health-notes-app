import 'package:ethan_utils/ethan_utils.dart';
import 'package:health_notes/models/health_note.dart';
import 'package:health_notes/models/symptom.dart';

class TrendsActivityAggregator {
  static Map<DateTime, T> aggregate<T>({
    required List<HealthNote> notes,
    required T Function(HealthNote note) valueExtractor,
    required T Function(T existing, T newValue) combiner,
  }) {
    final activityData = <DateTime, T>{};

    for (final note in notes) {
      final dateKey = note.dateTime.startOfDay;
      final value = valueExtractor(note);

      if (activityData.containsKey(dateKey)) {
        activityData[dateKey] = combiner(activityData[dateKey]! as T, value);
      } else {
        activityData[dateKey] = value;
      }
    }

    return activityData;
  }

  static Map<DateTime, int> maxSeverityPerDay({
    required List<HealthNote> notes,
    required String symptomName,
  }) =>
      aggregate<int>(
        notes: notes,
        valueExtractor: (note) =>
            highestSeveritySymptom(note, symptomName)?.severityLevel ?? 0,
        combiner: (existing, newValue) =>
            existing > newValue ? existing : newValue,
      );

  static Symptom? highestSeveritySymptom(
    HealthNote note,
    String symptomName,
  ) {
    Symptom? highest;
    for (final symptom in note.symptomsList) {
      if (symptom.majorComponent != symptomName) continue;
      if (highest == null ||
          symptom.severityLevel > highest.severityLevel) {
        highest = symptom;
      }
    }
    return highest;
  }
}
