import 'package:ethan_utils/ethan_utils.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_notes/models/health_note.dart';
import 'package:health_notes/widgets/health_notes_activity_calendar.dart';

void main() {
  group('HealthNotesActivityCalendar.activityDataForNotes', () {
    final day = DateTime(2025, 6, 15);

    HealthNote noteAt({
      required String id,
      required DateTime dateTime,
    }) {
      return HealthNote(
        id: id,
        dateTime: dateTime,
        createdAt: dateTime,
      );
    }

    test('aggregates multiple notes on the same day', () {
      final notes = [
        noteAt(id: '1', dateTime: day),
        noteAt(id: '2', dateTime: day.add(const Duration(hours: 3))),
        noteAt(id: '3', dateTime: day.add(const Duration(hours: 8))),
      ];

      final activityData = HealthNotesActivityCalendar.activityDataForNotes(
        notes,
      );

      expect(activityData.length, 1);
      expect(activityData[day.startOfDay], 3);
    });

    test('separates notes on different days', () {
      final notes = [
        noteAt(id: '1', dateTime: day),
        noteAt(id: '2', dateTime: day.add(const Duration(days: 1))),
      ];

      final activityData = HealthNotesActivityCalendar.activityDataForNotes(
        notes,
      );

      expect(activityData.length, 2);
      expect(activityData[day.startOfDay], 1);
      expect(activityData[day.add(const Duration(days: 1)).startOfDay], 1);
    });

    test('buckets notes at different times into the same day', () {
      final morningNote = noteAt(
        id: '1',
        dateTime: DateTime(2025, 6, 15, 8, 30),
      );
      final eveningNote = noteAt(
        id: '2',
        dateTime: DateTime(2025, 6, 15, 21, 45),
      );

      final activityData = HealthNotesActivityCalendar.activityDataForNotes(
        [morningNote, eveningNote],
      );

      expect(activityData.length, 1);
      expect(activityData[day.startOfDay], 2);
    });
  });
}
