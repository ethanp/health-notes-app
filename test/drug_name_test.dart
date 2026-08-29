import 'package:flutter_test/flutter_test.dart';
import 'package:health_notes/models/drug_dose.dart';
import 'package:health_notes/models/drug_name.dart';
import 'package:health_notes/models/health_note.dart';
import 'package:health_notes/models/medication_schedule.dart';
import 'package:health_notes/services/canonical_drug_names.dart';

HealthNote _note({
  required String id,
  required List<DrugDose> drugDoses,
}) {
  final at = DateTime(2026, 1, 1);
  return HealthNote(
    id: id,
    dateTime: at,
    drugDoses: drugDoses,
    notes: '',
    createdAt: at,
  );
}

MedicationSchedule _schedule({
  required String id,
  required DrugName medicationName,
}) {
  final at = DateTime(2026, 1, 1);
  return MedicationSchedule(
    id: id,
    userId: 'user-1',
    medicationName: medicationName,
    startDate: at,
    createdAt: at,
    updatedAt: at,
  );
}

void main() {
  group('DrugName', () {
    test('equals and hashes by identity', () {
      const titled = DrugName('Tylenol');
      const lower = DrugName('tylenol');
      const padded = DrugName('  TYLENOL  ');
      expect(titled, lower);
      expect(titled, padded);
      expect(titled.hashCode, lower.hashCode);
      expect({titled, lower, padded}, {const DrugName('Tylenol')});
    });

    test('matchesPrefix is case-insensitive and trims', () {
      const ibuprofen = DrugName('Ibuprofen');
      expect(ibuprofen.matchesPrefix('ibu'), isTrue);
      expect(ibuprofen.matchesPrefix('IBU'), isTrue);
      expect(ibuprofen.matchesPrefix('Ibuprofen'), isTrue);
      expect(ibuprofen.matchesPrefix('  asp  '), isFalse);
      expect(const DrugName('Aspirin').matchesPrefix('  asp  '), isTrue);
      expect(ibuprofen.matchesPrefix(''), isTrue);
      expect(ibuprofen.matchesPrefix('   '), isTrue);
      expect(ibuprofen.matchesPrefix('profen'), isFalse);
    });

    test('toJson and fromJson use display', () {
      const name = DrugName('Tylenol');
      expect(name.toJson(), 'Tylenol');
      expect(DrugName.fromJson('Tylenol').display, 'Tylenol');
      expect(const DrugNameConverter().fromJson('tylenol'), name);
      expect(const DrugNameConverter().toJson(name), 'Tylenol');
    });

    test('preferredAmong uses frequency then any-uppercase', () {
      expect(
        DrugName.preferredAmong([
          const DrugName('tylenol'),
          const DrugName('Tylenol'),
          const DrugName('Tylenol'),
        ]).display,
        'Tylenol',
      );
      expect(
        DrugName.preferredAmong([
          const DrugName('tylenol'),
          const DrugName('Tylenol'),
        ]).display,
        'Tylenol',
      );
      expect(
        DrugName.preferredAmong([
          const DrugName('Tylenol'),
          const DrugName('TYLENOL'),
        ]).display,
        'Tylenol',
      );
    });
  });

  group('HealthNote.hasDrug', () {
    test('matches a mixed-case stored dose', () {
      final note = _note(
        id: 'n1',
        drugDoses: const [
          DrugDose(name: DrugName('Tylenol'), dosage: 500, unit: 'mg'),
        ],
      );
      expect(note.hasDrug(const DrugName('TYLENOL')), isTrue);
      expect(note.hasDrug(const DrugName('ibuprofen')), isFalse);
    });
  });

  group('CanonicalDrugNames', () {
    test('rewrites stored spellings to the preferred form', () {
      final lowercaseNote = _note(
        id: 'n-lower',
        drugDoses: const [
          DrugDose(name: DrugName('tylenol'), dosage: 500, unit: 'mg'),
        ],
      );
      final titledNote = _note(
        id: 'n-titled',
        drugDoses: const [
          DrugDose(name: DrugName('Tylenol'), dosage: 500, unit: 'mg'),
          DrugDose(name: DrugName('Tylenol'), dosage: 325, unit: 'mg'),
        ],
      );
      final lowercaseSchedule = _schedule(
        id: 's-lower',
        medicationName: const DrugName('tylenol'),
      );

      final first = CanonicalDrugNames.pendingRewrites(
        notes: [lowercaseNote, titledNote],
        schedules: [lowercaseSchedule],
      );

      expect(first.notes, hasLength(1));
      expect(first.notes.single.id, 'n-lower');
      expect(first.notes.single.drugDoses.single.name.display, 'Tylenol');
      expect(first.schedules, hasLength(1));
      expect(first.schedules.single.medicationName.display, 'Tylenol');

      final second = CanonicalDrugNames.pendingRewrites(
        notes: [first.notes.single, titledNote],
        schedules: [first.schedules.single],
      );
      expect(second.isEmpty, isTrue);
    });
  });
}
