import 'package:flutter_test/flutter_test.dart';
import 'package:health_notes/models/drug_dose.dart';
import 'package:health_notes/models/health_note.dart';
import 'package:health_notes/models/symptom.dart';
import 'package:health_notes/services/search_service.dart';

void main() {
  group('SearchService', () {
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
          DrugDose(name: 'aspirin', dosage: 500, unit: 'mg'),
          DrugDose(name: 'ibuprofen', dosage: 400, unit: 'mg'),
        ],
        notes: 'feeling better after taking medication',
        createdAt: DateTime.now(),
      );
    });

    test('should match when all query words are found', () {
      // Test that "headache pain" matches the note with symptoms "headache pain"
      expect(SearchService.matchesSearch(testNote, 'headache pain'), isTrue);

      // Test that "aspirin medication" matches (aspirin in drugs, medication in notes)
      expect(
        SearchService.matchesSearch(testNote, 'aspirin medication'),
        isTrue,
      );
    });

    test('should match with stemming', () {
      // Test that "headaches" (plural) matches "headache" (singular) through stemming
      expect(SearchService.matchesSearch(testNote, 'headaches'), isTrue);

      // Test that "medications" (plural) matches "medication" (singular) through stemming
      expect(SearchService.matchesSearch(testNote, 'medications'), isTrue);
    });

    test('should require ALL query words to be present', () {
      // Test that "headache fever" should NOT match since "fever" is not in the note
      expect(SearchService.matchesSearch(testNote, 'headache fever'), isFalse);

      // Test that "aspirin paracetamol" should NOT match since "paracetamol" is not in the note
      expect(
        SearchService.matchesSearch(testNote, 'aspirin paracetamol'),
        isFalse,
      );
    });

    test('should handle empty search query', () {
      expect(SearchService.matchesSearch(testNote, ''), isTrue);
      expect(SearchService.matchesSearch(testNote, '   '), isTrue);
    });

    test('should ignore very short words', () {
      // Test that single letter words are ignored
      expect(SearchService.matchesSearch(testNote, 'a b c'), isTrue);
    });

    test('should be case insensitive', () {
      expect(SearchService.matchesSearch(testNote, 'HEADACHE PAIN'), isTrue);
      expect(
        SearchService.matchesSearch(testNote, 'Aspirin Medication'),
        isTrue,
      );
    });

    test('should handle multiple spaces between words', () {
      expect(SearchService.matchesSearch(testNote, 'headache    pain'), isTrue);
      expect(
        SearchService.matchesSearch(testNote, '  aspirin  medication  '),
        isTrue,
      );
    });
  });
}
