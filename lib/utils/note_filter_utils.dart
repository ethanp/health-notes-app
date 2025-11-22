import 'package:health_notes/models/health_note.dart';
import 'package:health_notes/services/search_service.dart';
import 'package:health_notes/services/text_normalizer.dart';

/// Centralized note filtering utilities
class NoteFilterUtils {
  static final _normalizer = CaseInsensitiveNormalizer();

  /// Filter notes by symptom name
  static List<HealthNote> bySymptom(
    List<HealthNote> notes,
    String symptomName,
  ) =>
      notes
          .where((note) => note.symptomsList.any(
                (s) => s.majorComponent == symptomName,
              ))
          .toList();

  /// Filter notes by drug name (case-insensitive)
  static List<HealthNote> byDrug(
    List<HealthNote> notes,
    String drugName,
  ) =>
      notes
          .where((note) => note.drugDoses.any(
                (d) => _normalizer.areEqual(d.name, drugName),
              ))
          .toList();

  /// Filter notes by search query using SearchService
  static List<HealthNote> bySearchQuery(
    List<HealthNote> notes,
    String query,
  ) {
    if (query.trim().isEmpty) return notes;
    return notes.where((note) => SearchService.matchesSearch(note, query)).toList();
  }

  /// Filter notes by date range
  static List<HealthNote> byDateRange(
    List<HealthNote> notes,
    DateTime? startDate,
    DateTime? endDate,
  ) {
    return notes.where((note) {
      if (startDate != null && note.dateTime.isBefore(startDate)) {
        return false;
      }
      if (endDate != null && note.dateTime.isAfter(endDate)) {
        return false;
      }
      return true;
    }).toList();
  }

  /// Sort notes by date (newest first)
  static List<HealthNote> sortByDateDescending(List<HealthNote> notes) {
    final sorted = List<HealthNote>.from(notes);
    sorted.sort((a, b) => b.dateTime.compareTo(a.dateTime));
    return sorted;
  }

  /// Sort notes by date (oldest first)
  static List<HealthNote> sortByDateAscending(List<HealthNote> notes) {
    final sorted = List<HealthNote>.from(notes);
    sorted.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    return sorted;
  }
}
