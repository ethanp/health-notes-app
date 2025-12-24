import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:health_notes/models/pinned_symptom_components.dart';
import 'package:health_notes/services/pinned_symptom_components_service.dart';

part 'pinned_symptom_components_provider.g.dart';

@riverpod
class PinnedSymptomComponentsNotifier extends _$PinnedSymptomComponentsNotifier {
  @override
  Future<PinnedSymptomComponents> build() async {
    return PinnedSymptomComponentsService.load();
  }

  Future<void> toggleMajorPin(String normalizedName) async {
    final current = await future;
    final updated = current.toggleMajorPin(normalizedName);
    state = AsyncData(updated);
    await PinnedSymptomComponentsService.save(updated);
  }

  Future<void> toggleMinorPin(
    String normalizedMajor,
    String normalizedMinor,
  ) async {
    final current = await future;
    final updated = current.toggleMinorPin(normalizedMajor, normalizedMinor);
    state = AsyncData(updated);
    await PinnedSymptomComponentsService.save(updated);
  }
}


