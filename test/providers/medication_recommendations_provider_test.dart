import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';
import 'package:health_notes/providers/medication_recommendations_provider.dart';
import 'package:health_notes/providers/health_notes_provider.dart';
import 'package:health_notes/models/health_note.dart';
import 'package:health_notes/models/drug_dose.dart';
import 'package:health_notes/models/drug_name.dart';

// Mock data
final date1 = DateTime(2023, 1, 1);
final date2 = DateTime(2023, 1, 2);
final date3 = DateTime(2023, 1, 3);

final doseA = DrugDose(name: const DrugName('Meds A'), dosage: 10, unit: 'mg');
final doseB = DrugDose(name: const DrugName('Meds B'), dosage: 20, unit: 'mg');
final doseC = DrugDose(name: const DrugName('Meds C'), dosage: 30, unit: 'mg');
final doseD = DrugDose(name: const DrugName('Meds D'), dosage: 40, unit: 'mg');
final doseE = DrugDose(name: const DrugName('Meds E'), dosage: 50, unit: 'mg');
final doseF = DrugDose(name: const DrugName('Meds F'), dosage: 60, unit: 'mg');

HealthNote createNote(DateTime date, List<DrugDose> doses) {
  return HealthNote(
    id: 'id_${date.millisecondsSinceEpoch}',
    dateTime: date,
    symptomsList: [],
    drugDoses: doses,
    appliedTools: [],
    notes: '',
    createdAt: date,
  );
}

void main() {
  test(
    'MedicationRecommendationsProvider returns correct recent and common recommendations',
    () async {
      final container = ProviderContainer(
        overrides: [
          healthNotesNotifierProvider.overrideWith(
            () => HealthNotesNotifierMock(),
          ),
        ],
      );

      final recommendations = await container.read(
        medicationRecommendationsProvider.future,
      );

      // Recent: Should be from the latest notes.
      // Note 3: A, B
      // Note 2: A, C
      // Note 1: D, E, F
      // Order of notes in mock is [Note 3, Note 2, Note 1] (descending date)
      // Recent logic: Flatten -> (Date3, A), (Date3, B), (Date2, A), (Date2, C), (Date1, D)...
      // Sort by date desc.
      // Unique: A, B, C, D, E. (F is 6th, should be dropped if limit is 5)
      // Wait, A is in Note 3 and Note 2. The most recent one (Note 3) is kept.

      // Expected Recent: A, B, C, D, E (in that order of recency? Or just unique set?)
      // The implementation sorts by date desc, then takes unique.
      // So: A (from Note 3), B (from Note 3), C (from Note 2), D (from Note 1), E (from Note 1).

      expect(recommendations.recent.length, 5);
      expect(recommendations.recent[0].name, const DrugName('Meds A'));
      expect(recommendations.recent[1].name, const DrugName('Meds B'));
      expect(recommendations.recent[2].name, const DrugName('Meds C'));
      expect(recommendations.recent[3].name, const DrugName('Meds D'));
      expect(recommendations.recent[4].name, const DrugName('Meds E'));

      // Common: Most frequent.
      // A: 2 times
      // B: 1 time
      // C: 1 time
      // D: 1 time
      // E: 1 time
      // F: 1 time
      // Top 5: A (2), then others (1).

      expect(recommendations.common.length, 5);
      expect(recommendations.common.first.name, const DrugName('Meds A'));

      expect(recommendations.allKnown.length, 6);
      expect(recommendations.allKnown.map((dose) => dose.name).toSet(), {
        const DrugName('Meds A'),
        const DrugName('Meds B'),
        const DrugName('Meds C'),
        const DrugName('Meds D'),
        const DrugName('Meds E'),
        const DrugName('Meds F'),
      });
    },
  );

  test('MedicationRecommendationsFilter narrows to prefix matches', () {
    final allKnown = [doseA, doseB, doseC, doseD, doseE, doseF];

    final emptyQueryMatches =
        MedicationRecommendationsFilter.matchingRecommendations(
          typedName: '',
          recent: [doseA, doseB],
          common: [doseA, doseC],
          allKnown: allKnown,
        );

    expect(emptyQueryMatches.map((dose) => dose.name).toList(), [
      const DrugName('Meds A'),
      const DrugName('Meds B'),
      const DrugName('Meds C'),
    ]);

    final prefixMatches =
        MedicationRecommendationsFilter.matchingRecommendations(
          typedName: 'meds',
          recent: [],
          common: [],
          allKnown: allKnown,
        );

    expect(prefixMatches.map((dose) => dose.name).toList(), [
      const DrugName('Meds A'),
      const DrugName('Meds B'),
      const DrugName('Meds C'),
      const DrugName('Meds D'),
      const DrugName('Meds E'),
      const DrugName('Meds F'),
    ]);
  });

  test('doseKey merges mixed-case spellings of the same dose', () {
    final titled = DrugDose(
      name: const DrugName('Tylenol'),
      dosage: 500,
      unit: 'mg',
    );
    final lower = DrugDose(
      name: const DrugName('tylenol'),
      dosage: 500,
      unit: 'mg',
    );
    expect(
      MedicationRecommendationsFilter.doseKey(titled),
      MedicationRecommendationsFilter.doseKey(lower),
    );
  });
}

class HealthNotesNotifierMock extends HealthNotesNotifier {
  @override
  Future<List<HealthNote>> build() async {
    return [
      createNote(date3, [doseA, doseB]),
      createNote(date2, [doseA, doseC]),
      createNote(date1, [doseD, doseE, doseF]),
    ];
  }
}
