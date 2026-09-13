import 'package:ethan_ui/ethan_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_notes/models/drug_dose.dart';
import 'package:health_notes/models/drug_name.dart';
import 'package:health_notes/models/health_note.dart';
import 'package:health_notes/models/symptom.dart';
import 'package:health_notes/providers/health_notes_provider.dart';
import 'package:health_notes/providers/sync_provider.dart';
import 'package:health_notes/screens/health_notes_home_page.dart';

const _phoneSize = Size(390, 844);

void main() {
  setUpAll(() async {
    await ETheme.loadFontsForWidgetTests();
  });

  testWidgets('writes notes list for README', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(_phoneSize);
    try {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            healthNotesProvider.overrideWith(_OverviewNotes.new),
            connectivityStatusProvider.overrideWithValue(true),
            syncProvider.overrideWithValue(false),
          ],
          child: MaterialApp(
            theme: ETheme.material3Dark,
            debugShowCheckedModeBanner: false,
            home: const HealthNotesHomePage(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('../screenshots/notes.png'),
      );
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}

class _OverviewNotes() extends HealthNotesNotifier {
  @override
  Future<List<HealthNote>> build() async => [
    HealthNote(
      id: 'note-today',
      dateTime: DateTime(2026, 9, 12, 8, 15),
      symptomsList: const [
        Symptom(
          majorComponent: 'Headache',
          minorComponent: 'temples',
          severityLevel: 3,
        ),
        Symptom(majorComponent: 'Fatigue', severityLevel: 2),
      ],
      drugDoses: const [
        DrugDose(name: DrugName('Magnesium'), dosage: 200, unit: 'mg'),
      ],
      notes: 'Slept 6 hours. Better after water.',
      createdAt: DateTime(2026, 9, 12, 8, 16),
    ),
    HealthNote(
      id: 'note-yesterday',
      dateTime: DateTime(2026, 9, 11, 21, 40),
      symptomsList: const [
        Symptom(majorComponent: 'Sore throat', severityLevel: 2),
      ],
      drugDoses: const [
        DrugDose(name: DrugName('Vitamin D'), dosage: 2000, unit: 'IU'),
      ],
      notes: '',
      createdAt: DateTime(2026, 9, 11, 21, 41),
    ),
    HealthNote(
      id: 'note-earlier',
      dateTime: DateTime(2026, 9, 8, 7, 5),
      symptomsList: const [
        Symptom(majorComponent: 'Fatigue', severityLevel: 4),
      ],
      drugDoses: const [],
      notes: 'Long walk in the afternoon helped.',
      createdAt: DateTime(2026, 9, 8, 7, 6),
    ),
  ];
}
