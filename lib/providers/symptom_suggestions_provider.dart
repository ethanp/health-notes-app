import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:riverpod/riverpod.dart';
import 'package:health_notes/services/symptom_suggestions_service.dart';
import 'package:health_notes/providers/health_notes_provider.dart';

part 'symptom_suggestions_provider.g.dart';

@riverpod
Future<List<SymptomSuggestion>> symptomSuggestions(Ref ref) async {
  final notes = await ref.watch(healthNotesNotifierProvider.future);

  return SymptomSuggestionsService.getRecentSymptomSuggestions(notes);
}
