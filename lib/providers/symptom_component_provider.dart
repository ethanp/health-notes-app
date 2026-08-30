import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:health_notes/models/symptom_component_index.dart';
import 'package:health_notes/providers/health_notes_provider.dart';
import 'package:health_notes/providers/pinned_symptom_components_provider.dart';
import 'package:health_notes/services/symptom_component_service.dart';

part 'symptom_component_provider.g.dart';

@riverpod
Future<SymptomComponentIndex> symptomComponentIndex(Ref ref) async {
  final notes = await ref.watch(healthNotesProvider.future);
  final pinned = await ref.watch(pinnedSymptomComponentsProvider.future);
  return SymptomComponentService.buildIndex(notes, pinned);
}
