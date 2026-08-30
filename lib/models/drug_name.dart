import 'package:freezed_annotation/freezed_annotation.dart';

class const DrugName(final String display) implements Comparable<DrugName> {
  static const empty = DrugName('');

  String get identity => display.trim().toLowerCase();

  bool get isEmpty => identity.isEmpty;

  bool get isNotEmpty => identity.isNotEmpty;

  bool get _hasUppercase => display != display.toLowerCase();

  bool matchesPrefix(String typed) {
    final prefix = typed.trim().toLowerCase();
    if (prefix.isEmpty) return true;
    return identity.startsWith(prefix);
  }

  factory fromJson(String json) => DrugName(json);

  String toJson() => display;

  static DrugName preferredAmong(Iterable<DrugName> names) {
    final seen = names.where((name) => name.isNotEmpty);
    if (seen.isEmpty) return empty;

    final counts = <String, int>{};
    final firstSpelling = <String, DrugName>{};
    for (final name in seen) {
      final spelling = name.display.trim();
      counts[spelling] = (counts[spelling] ?? 0) + 1;
      firstSpelling.putIfAbsent(spelling, () => DrugName(spelling));
    }

    DrugName? preferred;
    var preferredCount = -1;
    for (final spelling in firstSpelling.entries) {
      final count = counts[spelling.key]!;
      if (preferred == null ||
          count > preferredCount ||
          (count == preferredCount &&
              spelling.value._hasUppercase &&
              !preferred._hasUppercase)) {
        preferred = spelling.value;
        preferredCount = count;
      }
    }
    return preferred!;
  }

  static Map<String, DrugName> preferredByIdentity(Iterable<DrugName> names) {
    final groups = <String, List<DrugName>>{};
    for (final name in names.where((name) => name.isNotEmpty)) {
      groups.putIfAbsent(name.identity, () => []).add(name);
    }
    return {
      for (final group in groups.entries)
        group.key: preferredAmong(group.value),
    };
  }

  @override
  int compareTo(DrugName other) => identity.compareTo(other.identity);

  @override
  bool operator ==(Object other) =>
      other is DrugName && other.identity == identity;

  @override
  int get hashCode => identity.hashCode;

  @override
  String toString() => display;
}

class const DrugNameConverter() implements JsonConverter<DrugName, String> {
  @override
  DrugName fromJson(String json) => DrugName(json);

  @override
  String toJson(DrugName name) => name.display;
}
