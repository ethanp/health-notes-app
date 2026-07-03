import 'package:ethan_utils/ethan_utils.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_notes/models/health_note.dart';
import 'package:health_notes/models/symptom.dart';
import 'package:health_notes/services/trends_activity_aggregator.dart';

void main() {
  group('TrendsActivityAggregator.maxSeverityPerDay', () {
    final day = DateTime(2025, 6, 15, 14, 30);

    test('uses max severity when one note has multiple matching symptoms', () {
      final note = HealthNote(
        id: '1',
        dateTime: day,
        symptomsList: [
          const Symptom(
            majorComponent: 'pain',
            minorComponent: 'back',
            severityLevel: 3,
          ),
          const Symptom(
            majorComponent: 'pain',
            minorComponent: 'knee',
            severityLevel: 8,
          ),
        ],
        createdAt: day,
      );

      final activityData = TrendsActivityAggregator.maxSeverityPerDay(
        notes: [note],
        symptomName: 'pain',
      );

      expect(activityData[day.startOfDay], 8);
    });

    test('uses max severity across multiple notes on the same day', () {
      final morningNote = HealthNote(
        id: '1',
        dateTime: day,
        symptomsList: [
          const Symptom(majorComponent: 'pain', severityLevel: 4),
        ],
        createdAt: day,
      );
      final eveningNote = HealthNote(
        id: '2',
        dateTime: day.add(const Duration(hours: 6)),
        symptomsList: [
          const Symptom(majorComponent: 'pain', severityLevel: 7),
        ],
        createdAt: day,
      );

      final activityData = TrendsActivityAggregator.maxSeverityPerDay(
        notes: [morningNote, eveningNote],
        symptomName: 'pain',
      );

      expect(activityData[day.startOfDay], 7);
    });

    test('ignores non-matching symptoms when computing max', () {
      final note = HealthNote(
        id: '1',
        dateTime: day,
        symptomsList: [
          const Symptom(majorComponent: 'headache', severityLevel: 9),
          const Symptom(majorComponent: 'pain', severityLevel: 5),
        ],
        createdAt: day,
      );

      final activityData = TrendsActivityAggregator.maxSeverityPerDay(
        notes: [note],
        symptomName: 'pain',
      );

      expect(activityData[day.startOfDay], 5);
    });
  });
}
