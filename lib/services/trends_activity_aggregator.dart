import 'package:ethan_utils/ethan_utils.dart';
import 'package:health_notes/models/health_note.dart';
import 'package:health_notes/models/symptom.dart';

class TrendsActivityAggregator() {
  static Map<DateTime, T> combineByCalendarDay<T>({
    required List<HealthNote> notes,
    required T Function(HealthNote note) valueFromNote,
    required T Function(T existing, T newValue) pickWhenSameDay,
  }) {
    final activityData = <DateTime, T>{};

    for (final note in notes) {
      final dateKey = note.dateTime.startOfDay;
      final value = valueFromNote(note);

      if (activityData.containsKey(dateKey)) {
        activityData[dateKey] = pickWhenSameDay(
          activityData[dateKey]! as T,
          value,
        );
      } else {
        activityData[dateKey] = value;
      }
    }

    return activityData;
  }

  static Map<DateTime, int> maxSeverityPerDay({
    required List<HealthNote> notes,
    required String symptomName,
  }) => combineByCalendarDay<int>(
    notes: notes,
    valueFromNote: (note) =>
        highestSeveritySymptom(note, symptomName)?.severityLevel ?? 0,
    pickWhenSameDay: (existing, newValue) =>
        existing > newValue ? existing : newValue,
  );

  static Symptom? highestSeveritySymptom(HealthNote note, String symptomName) {
    Symptom? highest;
    for (final symptom in note.symptomsList) {
      if (symptom.majorComponent != symptomName) continue;
      if (highest == null || symptom.severityLevel > highest.severityLevel) {
        highest = symptom;
      }
    }
    return highest;
  }

  static Map<DateTime, int> maxSubSymptomSeverityPerDay({
    required List<HealthNote> notes,
    required String majorComponent,
    required String minorComponent,
  }) => combineByCalendarDay<int>(
    notes: notes,
    valueFromNote: (note) =>
        highestSeveritySubSymptom(
          note,
          majorComponent,
          minorComponent,
        )?.severityLevel ??
        0,
    pickWhenSameDay: (existing, newValue) =>
        existing > newValue ? existing : newValue,
  );

  static Symptom? highestSeveritySubSymptom(
    HealthNote note,
    String majorComponent,
    String minorComponent,
  ) {
    Symptom? highest;
    for (final symptom in note.symptomsList) {
      if (symptom.majorComponent != majorComponent) continue;
      if (symptom.minorComponent != minorComponent) continue;
      if (highest == null || symptom.severityLevel > highest.severityLevel) {
        highest = symptom;
      }
    }
    return highest;
  }
}
