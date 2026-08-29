import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';
import 'package:health_notes/providers/medication_recommendations_provider.dart';
import 'package:health_notes/providers/health_notes_provider.dart';
import 'package:health_notes/models/health_note.dart';
import 'package:health_notes/models/drug_dose.dart';
import 'package:health_notes/models/drug_name.dart';

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

      final catalog = await container.read(
        medicationRecommendationsProvider.future,
      );

      expect(catalog.recent.length, 5);
      expect(catalog.recent[0].name, const DrugName('Meds A'));
      expect(catalog.recent[1].name, const DrugName('Meds B'));
      expect(catalog.recent[2].name, const DrugName('Meds C'));
      expect(catalog.recent[3].name, const DrugName('Meds D'));
      expect(catalog.recent[4].name, const DrugName('Meds E'));

      expect(catalog.common.length, 5);
      expect(catalog.common.first.name, const DrugName('Meds A'));

      expect(catalog.allKnown.length, 6);
      expect(catalog.allKnown.map((dose) => dose.name).toSet(), {
        const DrugName('Meds A'),
        const DrugName('Meds B'),
        const DrugName('Meds C'),
        const DrugName('Meds D'),
        const DrugName('Meds E'),
        const DrugName('Meds F'),
      });
    },
  );

  test('matchingDoses narrows to prefix matches', () {
    final allKnown = [doseA, doseB, doseC, doseD, doseE, doseF];
    final catalog = MedicationRecommendationsState(
      recent: [doseA, doseB],
      common: [doseA, doseC],
      allKnown: allKnown,
    );

    expect(catalog.matchingDoses('').map((dose) => dose.name).toList(), [
      const DrugName('Meds A'),
      const DrugName('Meds B'),
      const DrugName('Meds C'),
    ]);

    expect(catalog.matchingDoses('meds').map((dose) => dose.name).toList(), [
      const DrugName('Meds A'),
      const DrugName('Meds B'),
      const DrugName('Meds C'),
      const DrugName('Meds D'),
      const DrugName('Meds E'),
      const DrugName('Meds F'),
    ]);
  });

  test('matchingNames dedupes and includes additional schedule names', () {
    final catalog = MedicationRecommendationsState(
      recent: const [],
      common: const [],
      allKnown: [doseA, doseB],
    );

    expect(
      catalog.matchingNames(
        'meds',
        additionalNames: [
          const DrugName('Meds A'),
          const DrugName('Meds G'),
        ],
      ),
      [
        const DrugName('Meds A'),
        const DrugName('Meds B'),
        const DrugName('Meds G'),
      ],
    );
  });

  test('matchingNames when empty uses recent, common, then additional', () {
    final catalog = MedicationRecommendationsState(
      recent: [doseA, doseB],
      common: [doseA, doseC],
      allKnown: [doseA, doseB, doseC, doseD],
    );

    expect(
      catalog.matchingNames(
        '',
        additionalNames: [const DrugName('Meds G')],
      ),
      [
        const DrugName('Meds A'),
        const DrugName('Meds B'),
        const DrugName('Meds C'),
        const DrugName('Meds G'),
      ],
    );
  });

  test('matchingNames skips the exact typed name', () {
    final catalog = MedicationRecommendationsState(
      recent: const [],
      common: const [],
      allKnown: [
        doseA,
        DrugDose(name: const DrugName('Meds AB'), dosage: 5, unit: 'mg'),
      ],
    );

    expect(catalog.matchingNames('Meds A'), [const DrugName('Meds AB')]);
    expect(catalog.matchingNames('Meds AB'), isEmpty);
  });

  test('unitForName returns the known unit for a name', () {
    final catalog = MedicationRecommendationsState(
      recent: const [],
      common: const [],
      allKnown: [
        DrugDose(name: const DrugName('Vitamin D'), dosage: 2000, unit: 'IU'),
      ],
    );

    expect(catalog.unitForName(const DrugName('Vitamin D')), 'IU');
    expect(catalog.unitForName(const DrugName('Unknown')), isNull);
  });

  test('strengthIdentity merges mixed-case spellings of the same dose', () {
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
    expect(titled.strengthIdentity, lower.strengthIdentity);
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
