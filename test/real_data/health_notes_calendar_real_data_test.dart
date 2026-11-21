import 'package:ethan_sync/ethan_sync.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_notes/app_identity.dart';
import 'package:health_notes/models/health_note.dart';
import 'package:health_notes/services/health_notes_dao.dart';
import 'package:health_notes/sync/powersync_schema.dart';
import 'package:health_notes/widgets/health_notes_activity_calendar.dart';
import 'package:intl/intl.dart';

void main() {
  final RealDataSnapshot snapshot = RealDataSnapshot.ofPackageUnderTest();
  late List<HealthNote> realNotes;

  setUpAll(() async {
    if (snapshot.skipReasonUntilExported != null) return;
    final realDatabase = await snapshot.openWith(healthNotesSchema);
    realNotes = await HealthNotesDao(
      realDatabase,
    ).getAllNotes(AppIdentity.localUserId);
    await realDatabase.close();
  });

  testWidgets('note calendar shows every month that has notes', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: HealthNotesActivityCalendar(
              notes: realNotes,
              onDateTap: (_) {},
            ),
          ),
        ),
      ),
    );

    final Set<String> monthsWithNotes = realNotes
        .map((note) => DateFormat('MMM y').format(note.dateTime))
        .toSet();
    expect(monthsWithNotes, isNotEmpty);
    for (final monthCaption in monthsWithNotes) {
      expect(find.text(monthCaption), findsOneWidget, reason: monthCaption);
    }
  }, skip: snapshot.skipReasonUntilExported != null);
}
