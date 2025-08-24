import 'package:flutter_test/flutter_test.dart';
import 'package:health_notes/models/health_note.dart';
import 'package:health_notes/models/symptom.dart';
import 'package:health_notes/services/symptom_suggestions_service.dart';

void main() {
  group('SymptomSuggestionsService', () {
    test('should return empty list when no notes provided', () {
      final suggestions = SymptomSuggestionsService.getRecentSymptomSuggestions(
        [],
      );
      expect(suggestions, isEmpty);
    });

    test('should return empty list when notes have no symptoms', () {
      final notes = [
        HealthNote(
          id: '1',
          dateTime: DateTime.now(),
          symptomsList: [],
          drugDoses: [],
          notes: '',
          createdAt: DateTime.now(),
        ),
      ];

      final suggestions = SymptomSuggestionsService.getRecentSymptomSuggestions(
        notes,
      );
      expect(suggestions, isEmpty);
    });

    test(
      'should return suggestions from symptoms with major/minor components',
      () {
        final notes = [
          HealthNote(
            id: '1',
            dateTime: DateTime.now(),
            symptomsList: [
              Symptom(
                majorComponent: 'headache',
                minorComponent: 'right temple',
                severityLevel: 7,
              ),
              Symptom(
                majorComponent: 'nausea',
                minorComponent: '',
                severityLevel: 5,
              ),
            ],
            drugDoses: [],
            notes: '',
            createdAt: DateTime.now(),
          ),
        ];

        final suggestions =
            SymptomSuggestionsService.getRecentSymptomSuggestions(notes);
        expect(suggestions.length, 2);

        expect(suggestions[0].majorComponent, 'headache');
        expect(suggestions[0].minorComponent, 'right temple');
        expect(suggestions[0].lastSeverityLevel, 7);

        expect(suggestions[1].majorComponent, 'nausea');
        expect(suggestions[1].minorComponent, '');
        expect(suggestions[1].lastSeverityLevel, 5);
      },
    );

    test('should return only 3 most recent unique suggestions', () {
      final notes = [
        HealthNote(
          id: '1',
          dateTime: DateTime.now().subtract(const Duration(days: 1)),
          symptomsList: [
            Symptom(
              majorComponent: 'headache',
              minorComponent: 'left temple',
              severityLevel: 3,
            ),
          ],
          drugDoses: [],
          notes: '',
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
        HealthNote(
          id: '2',
          dateTime: DateTime.now(),
          symptomsList: [
            Symptom(
              majorComponent: 'headache',
              minorComponent: 'right temple',
              severityLevel: 7,
            ),
            Symptom(
              majorComponent: 'nausea',
              minorComponent: '',
              severityLevel: 5,
            ),
            Symptom(
              majorComponent: 'dizziness',
              minorComponent: 'vertigo',
              severityLevel: 4,
            ),
            Symptom(
              majorComponent: 'fatigue',
              minorComponent: 'mental',
              severityLevel: 6,
            ),
          ],
          drugDoses: [],
          notes: '',
          createdAt: DateTime.now(),
        ),
      ];

      final suggestions = SymptomSuggestionsService.getRecentSymptomSuggestions(
        notes,
      );
      expect(suggestions.length, 3);

      // Should get the 3 most recent unique combinations
      // The service now sorts by date, so the most recent note's symptoms come first
      expect(suggestions[0].majorComponent, 'headache');
      expect(suggestions[0].minorComponent, 'right temple');
      expect(suggestions[1].majorComponent, 'nausea');
      expect(suggestions[1].minorComponent, '');
      expect(suggestions[2].majorComponent, 'dizziness');
      expect(suggestions[2].minorComponent, 'vertigo');
    });

    test('should create symptom from suggestion', () {
      final suggestion = SymptomSuggestion(
        majorComponent: 'headache',
        minorComponent: 'right temple',
        lastSeverityLevel: 7,
      );

      final symptom = SymptomSuggestionsService.createSymptomFromSuggestion(
        suggestion,
      );

      expect(symptom.majorComponent, 'headache');
      expect(symptom.minorComponent, 'right temple');
      expect(symptom.severityLevel, 7);
      expect(symptom.additionalNotes, '');
    });

    test('should handle empty components in suggestion toString', () {
      final suggestion1 = SymptomSuggestion(
        majorComponent: '',
        minorComponent: '',
        lastSeverityLevel: 1,
      );
      expect(suggestion1.toString(), 'No components');

      final suggestion2 = SymptomSuggestion(
        majorComponent: 'headache',
        minorComponent: '',
        lastSeverityLevel: 1,
      );
      expect(suggestion2.toString(), 'headache');

      final suggestion3 = SymptomSuggestion(
        majorComponent: '',
        minorComponent: 'right temple',
        lastSeverityLevel: 1,
      );
      expect(suggestion3.toString(), 'right temple');

      final suggestion4 = SymptomSuggestion(
        majorComponent: 'headache',
        minorComponent: 'right temple',
        lastSeverityLevel: 1,
      );
      expect(suggestion4.toString(), 'headache - right temple');
    });
  });
}
