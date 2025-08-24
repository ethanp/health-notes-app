import 'package:health_notes/models/health_note.dart';
import 'package:stemmer/stemmer.dart';

class SearchService {
  static final PorterStemmer _stemmer = PorterStemmer();

  /// Breaks a search query into individual words, stems them, and searches
  /// across multiple fields.
  ///
  /// Returns true if ALL query words are found somewhere across the note fields.
  static bool matchesSearch(HealthNote note, String searchQuery) {
    if (searchQuery.trim().isEmpty) return true;

    final List<String> queryWords = _processText(searchQuery);
    if (queryWords.isEmpty) return true;

    final String searchableText = _getSearchableText(note);
    final String noteText = _processText(searchableText).join(' ');

    return queryWords.every((queryWord) => noteText.contains(queryWord));
  }

  /// Processes text by tokenizing, cleaning, and stemming words
  static List<String> _processText(String text) => text
      .toLowerCase()
      .split(RegExp(r'\s+'))
      .map((word) => word.trim())
      .where((word) => word.isNotEmpty && word.length > 1)
      .map((word) => _stemmer.stem(word))
      .toList();

  /// Gets all searchable text from a health note
  static String _getSearchableText(HealthNote note) => [
    note.symptoms,
    note.notes,
    ...note.drugDoses.map((d) => d.name),
  ].where((text) => text.isNotEmpty).join(' ');
}
