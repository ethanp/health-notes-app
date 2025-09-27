import 'package:health_notes/models/health_note.dart';
import 'package:health_notes/models/symptom.dart';
import 'package:health_notes/services/text_normalizer.dart';

class SymptomSuggestion {
  final String majorComponent;
  final String minorComponent;
  final int lastSeverityLevel;

  const SymptomSuggestion({
    required this.majorComponent,
    required this.minorComponent,
    required this.lastSeverityLevel,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SymptomSuggestion &&
          runtimeType == other.runtimeType &&
          SymptomNormalizer.areEqual(
            majorComponent,
            minorComponent,
            other.majorComponent,
            other.minorComponent,
          );

  @override
  int get hashCode =>
      SymptomNormalizer.generateKey(majorComponent, minorComponent).hashCode;

  @override
  String toString() {
    if (majorComponent.isEmpty && minorComponent.isEmpty) {
      return 'No components';
    } else if (majorComponent.isEmpty) {
      return minorComponent;
    } else if (minorComponent.isEmpty) {
      return majorComponent;
    } else {
      return '$majorComponent - $minorComponent';
    }
  }
}

class SymptomSuggestionsService {
  /// Returns the 3 most recent unique (major, minor) component pairs from health notes
  static List<SymptomSuggestion> getRecentSymptomSuggestions(
    List<HealthNote> notes,
  ) {
    final Map<String, SymptomSuggestion> suggestionsMap = {};

    final sortedNotes = List<HealthNote>.from(notes)
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));

    for (final note in sortedNotes) {
      for (final symptom in note.validSymptoms) {
        final key = SymptomNormalizer.generateKey(
          symptom.majorComponent,
          symptom.minorComponent,
        );

        if (!suggestionsMap.containsKey(key) &&
            (symptom.majorComponent.isNotEmpty ||
                symptom.minorComponent.isNotEmpty)) {
          suggestionsMap[key] = SymptomSuggestion(
            majorComponent: symptom.majorComponent,
            minorComponent: symptom.minorComponent,
            lastSeverityLevel: symptom.severityLevel,
          );

          if (suggestionsMap.length >= 3) {
            break;
          }
        }
      }

      if (suggestionsMap.length >= 3) {
        break;
      }
    }

    return suggestionsMap.values.toList();
  }

  /// Creates a symptom from a suggestion with the default severity level
  static Symptom createSymptomFromSuggestion(SymptomSuggestion suggestion) {
    return Symptom(
      majorComponent: suggestion.majorComponent,
      minorComponent: suggestion.minorComponent,
      severityLevel: suggestion.lastSeverityLevel,
      additionalNotes: '',
    );
  }
}
