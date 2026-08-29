import 'package:flutter_test/flutter_test.dart';
import 'package:health_notes/models/drug_dose.dart';
import 'package:health_notes/models/drug_name.dart';
import 'package:health_notes/models/health_note.dart';
import 'package:health_notes/models/symptom.dart';

void main() {
  group('HealthNote.matchesSearch', () {
    late HealthNote testNote;

    setUp(() {
      testNote = HealthNote(
        id: '1',
        dateTime: DateTime.now(),
        symptomsList: [
          Symptom(majorComponent: 'headache', severityLevel: 5),
          Symptom(majorComponent: 'pain', severityLevel: 7),
        ],
        drugDoses: [
          DrugDose(name: const DrugName('aspirin'), dosage: 500, unit: 'mg'),
          DrugDose(name: const DrugName('ibuprofen'), dosage: 400, unit: 'mg'),
        ],
        notes: 'feeling better after taking medication',
        createdAt: DateTime.now(),
      );
    });

    test('should match when all query words are found', () {
      expect(testNote.matchesSearch('headache pain'), isTrue);
      expect(testNote.matchesSearch('aspirin medication'), isTrue);
    });

    test('should match with stemming', () {
      expect(testNote.matchesSearch('headaches'), isTrue);
      expect(testNote.matchesSearch('medications'), isTrue);
    });

    test('should require ALL query words to be present', () {
      expect(testNote.matchesSearch('headache fever'), isFalse);
      expect(testNote.matchesSearch('aspirin paracetamol'), isFalse);
    });

    test('should handle empty search query', () {
      expect(testNote.matchesSearch(''), isTrue);
      expect(testNote.matchesSearch('   '), isTrue);
    });

    test('should ignore very short words', () {
      expect(testNote.matchesSearch('a b c'), isTrue);
    });

    test('should be case insensitive', () {
      expect(testNote.matchesSearch('HEADACHE PAIN'), isTrue);
      expect(testNote.matchesSearch('Aspirin Medication'), isTrue);
    });

    test('should handle multiple spaces between words', () {
      expect(testNote.matchesSearch('headache    pain'), isTrue);
      expect(testNote.matchesSearch('  aspirin  medication  '), isTrue);
    });
  });
}
