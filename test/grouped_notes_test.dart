import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_notes/models/health_note.dart';
import 'package:health_notes/widgets/grouped_notes_section.dart';

HealthNote noteAt(String id, DateTime dateTime) => HealthNote(
      id: id,
      dateTime: dateTime,
      createdAt: dateTime,
    );

void main() {
  group('GroupedNotesSection', () {
    testWidgets('renders date-grouped headers and cards', (tester) async {
      final july3 = DateTime(2026, 7, 3, 9, 0);
      final july2 = DateTime(2026, 7, 2, 14, 0);
      final july1 = DateTime(2026, 7, 1, 10, 0);

      final notes = [
        noteAt('1', july3),
        noteAt('2', july3.add(const Duration(hours: 3))),
        noteAt('3', july2),
        noteAt('4', july1),
      ];

      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            child: SingleChildScrollView(
              child: GroupedNotesSection(
                notes: notes,
                cardBuilder: (dayNotes) =>
                    dayNotes.map((note) => Text('card-${note.id}')).toList(),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Health Notes (4)'), findsOneWidget);

      expect(find.text('Jul 03, 2026'), findsOneWidget);
      expect(find.text('2 notes'), findsOneWidget);
      expect(find.text('card-1'), findsOneWidget);
      expect(find.text('card-2'), findsOneWidget);

      expect(find.text('Jul 02, 2026'), findsOneWidget);
      expect(find.text('card-3'), findsOneWidget);

      expect(find.text('Jul 01, 2026'), findsOneWidget);
      expect(find.text('card-4'), findsOneWidget);

      expect(find.text('1 note'), findsNWidgets(2));
    });

    testWidgets('shows empty state when notes is empty', (tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            child: GroupedNotesSection(
              notes: const [],
              cardBuilder: (_) => [],
            ),
          ),
        ),
      );

      expect(find.text('No matching notes'), findsOneWidget);
    });

    testWidgets('renders optional header above grouped notes', (
      tester,
    ) async {
      final july3 = DateTime(2026, 7, 3, 9, 0);

      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            child: SingleChildScrollView(
              child: GroupedNotesSection(
                notes: [noteAt('1', july3)],
                cardBuilder: (dayNotes) =>
                    dayNotes.map((note) => Text('card-${note.id}')).toList(),
                header: const Text('Total doses: 5'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Total doses: 5'), findsOneWidget);
      expect(find.text('card-1'), findsOneWidget);
    });
  });
}
