import 'package:health_notes/models/health_note.dart';

/// Centralized note filtering utilities
class NoteFilterUtils {
  /// Filter notes by symptom name
  static List<HealthNote> bySymptom(
    List<HealthNote> notes,
    String symptomName,
  ) => notes.where((note) => note.hasSymptomNamed(symptomName)).toList();

  /// Filter notes by a specific major/minor symptom pair (sub-symptom)
  static List<HealthNote> bySubSymptom(
    List<HealthNote> notes,
    String majorComponent,
    String minorComponent,
  ) => notes
      .where(
        (note) => note.hasSubSymptom(majorComponent, minorComponent),
      )
      .toList();

  /// Filter notes by drug name (case-insensitive)
  static List<HealthNote> byDrug(List<HealthNote> notes, String drugName) =>
      notes.where((note) => note.hasDrugNamed(drugName)).toList();

  /// Filter notes by tool ID
  static List<HealthNote> byToolId(List<HealthNote> notes, String toolId) =>
      notes.where((note) => note.hasToolId(toolId)).toList();

  /// Filter notes by tool name (case-insensitive)
  static List<HealthNote> byToolName(List<HealthNote> notes, String toolName) =>
      notes.where((note) => note.hasToolNamed(toolName)).toList();

  /// Filter notes by search query
  static List<HealthNote> bySearchQuery(List<HealthNote> notes, String query) {
    if (query.trim().isEmpty) return notes;
    return notes.where((note) => note.matchesSearch(query)).toList();
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
