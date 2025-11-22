import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:health_notes/models/drug_dose.dart';
import 'package:health_notes/providers/health_notes_provider.dart';

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
      return note.drugDoses.where((d) => d.isValid).map((dose) => (note.dateTime, dose));
    }).toList();
    
    noteDosePairs.sort((a, b) => b.$1.compareTo(a.$1));
    
    final recentDoses = <String, DrugDose>{}; // Key by unique properties
    for (final pair in noteDosePairs) {
      final dose = pair.$2;
      final key = '${dose.name}|${dose.dosage}|${dose.unit}';
      if (!recentDoses.containsKey(key)) {
        recentDoses[key] = dose;
        if (recentDoses.length >= 5) break;
      }
    }

    // Common: Top 5 most frequent
    final frequency = <String, int>{};
    final uniqueDoses = <String, DrugDose>{};
    
    for (final dose in allDoses) {
      final key = '${dose.name}|${dose.dosage}|${dose.unit}';
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
    );
  }
}

class MedicationRecommendationsState {
  final List<DrugDose> recent;
  final List<DrugDose> common;

  const MedicationRecommendationsState({
    required this.recent,
    required this.common,
  });
}
