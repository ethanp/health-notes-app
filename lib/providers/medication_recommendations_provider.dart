import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:health_notes/models/drug_dose.dart';
import 'package:health_notes/models/drug_name.dart';
import 'package:health_notes/providers/health_notes_provider.dart';

part 'medication_recommendations_provider.g.dart';

class const _NotedDose({
  required final DateTime notedAt,
  required final DrugDose dose,
});

@riverpod
class MedicationRecommendations() extends _$MedicationRecommendations {
  @override
  Future<MedicationRecommendationsState> build() async {
    final notes = await ref.watch(healthNotesProvider.future);

    final allDoses = notes
        .expand((note) => note.drugDoses)
        .where((dose) => dose.isValid)
        .toList();

    final notedDoses = notes.expand((note) {
      return note.drugDoses
          .where((dose) => dose.isValid)
          .map((dose) => _NotedDose(notedAt: note.dateTime, dose: dose));
    }).toList();

    notedDoses.sort((left, right) => right.notedAt.compareTo(left.notedAt));

    final recentDoses = <String, DrugDose>{};
    for (final notedDose in notedDoses) {
      final key = notedDose.dose.strengthIdentity;
      if (!recentDoses.containsKey(key)) {
        recentDoses[key] = notedDose.dose;
        if (recentDoses.length >= 5) break;
      }
    }

    final frequency = <String, int>{};
    final uniqueDoses = <String, DrugDose>{};

    for (final dose in allDoses) {
      final key = dose.strengthIdentity;
      frequency[key] = (frequency[key] ?? 0) + 1;
      uniqueDoses[key] = dose;
    }

    final sortedKeys = frequency.keys.toList()
      ..sort((left, right) => frequency[right]!.compareTo(frequency[left]!));

    final commonDoses = sortedKeys
        .take(5)
        .map((key) => uniqueDoses[key]!)
        .toList();

    return MedicationRecommendationsState(
      recent: recentDoses.values.toList(),
      common: commonDoses,
      allKnown: uniqueDoses.values.toList(),
    );
  }
}

class const MedicationRecommendationsState({
  required final List<DrugDose> recent,
  required final List<DrugDose> common,
  required final List<DrugDose> allKnown,
}) {
  static const maxSuggestions = 10;

  List<DrugDose> matchingDoses(String typedName) {
    final typed = DrugName(typedName);
    final candidateDoses = typed.isEmpty
        ? [...recent, ...common]
        : allKnown.where((dose) => dose.name.matchesPrefix(typedName));

    final deduped = <String, DrugDose>{};
    for (final dose in candidateDoses) {
      if (dose.name == typed) continue;
      deduped.putIfAbsent(dose.strengthIdentity, () => dose);
    }

    return deduped.values.take(maxSuggestions).toList();
  }

  List<DrugName> matchingNames(
    String typedName, {
    List<DrugName> additionalNames = const [],
  }) {
    final typed = DrugName(typedName);
    final extraNames = typed.isEmpty
        ? additionalNames
        : additionalNames.where((name) => name.matchesPrefix(typedName));
    return _uniqueNames([
      ...matchingDoses(typedName).map((dose) => dose.name),
      ...extraNames,
    ], skipping: typed);
  }

  String? unitForName(DrugName name) {
    for (final dose in allKnown) {
      if (dose.name == name && dose.unit.isNotEmpty) return dose.unit;
    }
    return null;
  }

  List<DrugName> _uniqueNames(
    Iterable<DrugName> candidateNames, {
    required DrugName skipping,
  }) {
    final Map<String, DrugName> preferredSpellings =
        DrugName.preferredByIdentity(candidateNames);
    final seenIdentities = <String>{};
    final suggestedNames = <DrugName>[];
    for (final name in candidateNames) {
      if (name.isEmpty || name == skipping) continue;
      if (!seenIdentities.add(name.identity)) continue;
      suggestedNames.add(preferredSpellings[name.identity]!);
      if (suggestedNames.length >= maxSuggestions) break;
    }
    return suggestedNames;
  }
}
