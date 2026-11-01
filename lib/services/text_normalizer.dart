abstract class TextNormalizer() {
  String normalize(String text);
  bool areEqual(String text1, String text2);
  bool contains(String text, String searchTerm);
}

class CaseInsensitiveNormalizer() implements TextNormalizer {
  @override
  String normalize(String text) => text.trim().toLowerCase();

  @override
  bool areEqual(String text1, String text2) =>
      normalize(text1) == normalize(text2);

  @override
  bool contains(String text, String searchTerm) =>
      normalize(text).contains(normalize(searchTerm));
}

class SymptomNormalizer() {
  static final TextNormalizer _normalizer = CaseInsensitiveNormalizer();

  static String pipeJoinedNormalizedPair(
    String majorComponent,
    String minorComponent,
  ) =>
      '${_normalizer.normalize(majorComponent)}|${_normalizer.normalize(minorComponent)}';

  static bool areEqual(
    String major1,
    String minor1,
    String major2,
    String minor2,
  ) =>
      _normalizer.areEqual(major1, major2) &&
      _normalizer.areEqual(minor1, minor2);
}

class CaseInsensitiveAggregator<T>() {
  static final TextNormalizer _normalizer = CaseInsensitiveNormalizer();

  static Map<String, int> countByCaseInsensitiveDisplay(Iterable<String> items) {
    final Map<String, String> displayNames = {};
    final Map<String, int> counts = {};

    for (final item in items) {
      final normalized = _normalizer.normalize(item);
      displayNames.putIfAbsent(normalized, () => item);
      counts.update(normalized, (count) => count + 1, ifAbsent: () => 1);
    }

    return Map.fromEntries(
      counts.entries.map(
        (entry) => MapEntry(displayNames[entry.key]!, entry.value),
      ),
    );
  }

  static Map<String, List<T>> groupByCaseInsensitiveKey<T>(
    Iterable<T> items,
    String Function(T) keyExtractor,
  ) {
    final Map<String, String> displayNames = {};
    final Map<String, List<T>> groups = {};

    for (final item in items) {
      final key = keyExtractor(item);
      final normalized = _normalizer.normalize(key);

      displayNames.putIfAbsent(normalized, () => key);
      groups.putIfAbsent(normalized, () => []).add(item);
    }

    return Map.fromEntries(
      groups.entries.map(
        (entry) => MapEntry(displayNames[entry.key]!, entry.value),
      ),
    );
  }
}
