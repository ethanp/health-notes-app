import 'package:health_notes/models/health_note.dart';
import 'package:health_notes/models/symptom.dart';

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
          majorComponent == other.majorComponent &&
          minorComponent == other.minorComponent;

  @override
  int get hashCode => majorComponent.hashCode ^ minorComponent.hashCode;

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

    // Sort notes by date (most recent first) to ensure we get the most recent symptoms
    final sortedNotes = List<HealthNote>.from(notes)
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));

    // Iterate through notes in chronological order (most recent first)
    for (final note in sortedNotes) {
      for (final symptom in note.validSymptoms) {
        // Create a unique key for the major-minor combination
        final key = '${symptom.majorComponent}|${symptom.minorComponent}';

        // Only add if we don't already have this combination and we have at least one component
        if (!suggestionsMap.containsKey(key) &&
            (symptom.majorComponent.isNotEmpty ||
                symptom.minorComponent.isNotEmpty)) {
          suggestionsMap[key] = SymptomSuggestion(
            majorComponent: symptom.majorComponent,
            minorComponent: symptom.minorComponent,
            lastSeverityLevel: symptom.severityLevel,
          );

          // Stop when we have 3 suggestions
          if (suggestionsMap.length >= 3) {
            break;
          }
        }
      }

      // Stop when we have 3 suggestions
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
