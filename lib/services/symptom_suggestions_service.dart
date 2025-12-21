import 'package:health_notes/models/health_note.dart';
import 'package:health_notes/models/symptom.dart';
import 'package:health_notes/services/text_normalizer.dart';

class SymptomSuggestion {
  final String majorComponent;
  final String minorComponent;
  final int lastSeverityLevel;
  final String? conditionId;

  const SymptomSuggestion({
    required this.majorComponent,
    required this.minorComponent,
    required this.lastSeverityLevel,
    this.conditionId,
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
  static const int maxSuggestions = 10;

  /// Returns recent unique (major, minor) component pairs from health notes
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
            conditionId: symptom.conditionId,
          );

          if (suggestionsMap.length >= maxSuggestions) break;
        }
      }

      if (suggestionsMap.length >= maxSuggestions) break;
    }

    return suggestionsMap.values.toList();
  }

  static Symptom createSymptomFromSuggestion(SymptomSuggestion suggestion) {
    return Symptom(
      majorComponent: suggestion.majorComponent,
      minorComponent: suggestion.minorComponent,
      severityLevel: suggestion.lastSeverityLevel,
      additionalNotes: '',
      conditionId: suggestion.conditionId,
    );
  }
}
