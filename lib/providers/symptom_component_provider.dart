import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:riverpod/riverpod.dart';
import 'package:health_notes/models/pinned_symptom_components.dart';
import 'package:health_notes/models/symptom_component_index.dart';
import 'package:health_notes/providers/health_notes_provider.dart';
import 'package:health_notes/providers/pinned_symptom_components_provider.dart';
import 'package:health_notes/services/symptom_component_service.dart';

part 'symptom_component_provider.g.dart';

@riverpod
Future<SymptomComponentIndex> symptomComponentIndex(Ref ref) async {
  final notes = await ref.watch(healthNotesNotifierProvider.future);
  final pinned = await ref.watch(
    pinnedSymptomComponentsNotifierProvider.future,
  );
  return SymptomComponentService.buildIndex(notes, pinned);
}

@riverpod
Future<PinnedSymptomComponents> pinnedSymptomComponents(Ref ref) async {
  return ref.watch(pinnedSymptomComponentsNotifierProvider.future);
}


