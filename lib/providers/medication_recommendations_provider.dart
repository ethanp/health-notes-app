import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:health_notes/models/drug_dose.dart';
import 'package:health_notes/providers/health_notes_provider.dart';
import 'package:health_notes/services/text_normalizer.dart';

part 'medication_recommendations_provider.g.dart';

@riverpod
class MedicationRecommendations extends _$MedicationRecommendations {
  @override
  Future<MedicationRecommendationsState> build() async {
    final notes = await ref.watch(healthNotesNotifierProvider.future);

    final allDoses = notes
        .expand((note) => note.drugDoses)
        .where((dose) => dose.isValid)
        .toList();

    final noteDosePairs = notes.expand((note) {
      return note.drugDoses
          .where((dose) => dose.isValid)
          .map((dose) => (note.dateTime, dose));
    }).toList();

    noteDosePairs.sort((a, b) => b.$1.compareTo(a.$1));

    final recentDoses = <String, DrugDose>{};
    for (final pair in noteDosePairs) {
      final dose = pair.$2;
      final key = MedicationRecommendationsFilter.doseKey(dose);
      if (!recentDoses.containsKey(key)) {
        recentDoses[key] = dose;
        if (recentDoses.length >= 5) break;
      }
    }

    final frequency = <String, int>{};
    final uniqueDoses = <String, DrugDose>{};

    for (final dose in allDoses) {
      final key = MedicationRecommendationsFilter.doseKey(dose);
      frequency[key] = (frequency[key] ?? 0) + 1;
      uniqueDoses[key] = dose;
    }

    final sortedKeys = frequency.keys.toList()
      ..sort((a, b) => frequency[b]!.compareTo(frequency[a]!));

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

class MedicationRecommendationsState {
  final List<DrugDose> recent;
  final List<DrugDose> common;
  final List<DrugDose> allKnown;

  const MedicationRecommendationsState({
    required this.recent,
    required this.common,
    required this.allKnown,
  });
}

class MedicationRecommendationsFilter {
  static const maxSuggestions = 10;

  static String doseKey(DrugDose dose) =>
      '${dose.name}|${dose.dosage}|${dose.unit}';

  static List<DrugDose> matchingRecommendations({
    required String typedName,
    required List<DrugDose> recent,
    required List<DrugDose> common,
    required List<DrugDose> allKnown,
  }) {
    final source = typedName.trim().isEmpty
        ? [...recent, ...common]
        : allKnown.where(
            (dose) => DrugNameNormalizer.matchesPrefix(dose.name, typedName),
          );

    final deduped = <String, DrugDose>{};
    for (final dose in source) {
      if (DrugNameNormalizer.areEqual(dose.name, typedName)) continue;
      deduped.putIfAbsent(doseKey(dose), () => dose);
    }

    return deduped.values.take(maxSuggestions).toList();
  }
}
