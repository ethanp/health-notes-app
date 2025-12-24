import 'package:health_notes/models/health_note.dart';
import 'package:health_notes/models/pinned_symptom_components.dart';
import 'package:health_notes/models/symptom_component.dart';
import 'package:health_notes/models/symptom_component_index.dart';
import 'package:health_notes/services/text_normalizer.dart';

class SymptomComponentService {
  static const _recentDays = 14;

  static SymptomComponentIndex buildIndex(
    List<HealthNote> notes,
    PinnedSymptomComponents pinned,
  ) {
    final now = DateTime.now();
    final recentCutoff = now.subtract(const Duration(days: _recentDays));

    final majorCounts = <String, int>{};
    final majorRecentCounts = <String, int>{};
    final majorDisplayNames = <String, String>{};

    final minorCounts = <String, Map<String, int>>{};
    final minorRecentCounts = <String, Map<String, int>>{};
    final minorDisplayNames = <String, Map<String, String>>{};

    final pairSeverities = <String, int>{};
    final pairConditions = <String, String>{};

    final sortedNotes = List<HealthNote>.from(notes)
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));

    for (final note in sortedNotes) {
      final isRecent = note.dateTime.isAfter(recentCutoff);

      for (final symptom in note.validSymptoms) {
        final major = symptom.majorComponent;
        final minor = symptom.minorComponent;
        final normalizedMajor = major.trim().toLowerCase();
        final normalizedMinor = minor.trim().toLowerCase();

        majorDisplayNames.putIfAbsent(normalizedMajor, () => major);
        majorCounts.update(normalizedMajor, (c) => c + 1, ifAbsent: () => 1);
        if (isRecent) {
          majorRecentCounts.update(
            normalizedMajor,
            (c) => c + 1,
            ifAbsent: () => 1,
          );
        }

        minorDisplayNames
            .putIfAbsent(normalizedMajor, () => {})
            .putIfAbsent(normalizedMinor, () => minor);
        minorCounts
            .putIfAbsent(normalizedMajor, () => {})
            .update(normalizedMinor, (c) => c + 1, ifAbsent: () => 1);
        if (isRecent) {
          minorRecentCounts
              .putIfAbsent(normalizedMajor, () => {})
              .update(normalizedMinor, (c) => c + 1, ifAbsent: () => 1);
        }

        final pairKey = SymptomNormalizer.generateKey(major, minor);
        pairSeverities.putIfAbsent(pairKey, () => symptom.severityLevel);
        if (symptom.conditionId != null && symptom.conditionId!.isNotEmpty) {
          pairConditions.putIfAbsent(pairKey, () => symptom.conditionId!);
        }
      }
    }

    final majorComponents = <String, SymptomComponent>{};
    for (final entry in majorCounts.entries) {
      final normalized = entry.key;
      final count = entry.value;
      final recentCount = majorRecentCounts[normalized] ?? 0;
      final isPinned = pinned.isMajorPinned(normalized);

      final section = isPinned
          ? ComponentSection.pinned
          : recentCount > 0
              ? ComponentSection.recent
              : ComponentSection.historical;

      majorComponents[normalized] = SymptomComponent(
        name: majorDisplayNames[normalized]!,
        normalizedName: normalized,
        isPinned: isPinned,
        usageCount: count,
        recentUsageCount: recentCount,
        section: section,
      );
    }

    final minorComponents = <String, Map<String, SymptomComponent>>{};
    for (final majorEntry in minorCounts.entries) {
      final normalizedMajor = majorEntry.key;
      final minorsMap = <String, SymptomComponent>{};

      for (final minorEntry in majorEntry.value.entries) {
        final normalizedMinor = minorEntry.key;
        final count = minorEntry.value;
        final recentCount =
            minorRecentCounts[normalizedMajor]?[normalizedMinor] ?? 0;
        final isPinned = pinned.isMinorPinned(normalizedMajor, normalizedMinor);

        final section = isPinned
            ? ComponentSection.pinned
            : recentCount > 0
                ? ComponentSection.recent
                : ComponentSection.historical;

        minorsMap[normalizedMinor] = SymptomComponent(
          name: minorDisplayNames[normalizedMajor]![normalizedMinor]!,
          normalizedName: normalizedMinor,
          isPinned: isPinned,
          usageCount: count,
          recentUsageCount: recentCount,
          section: section,
        );
      }

      minorComponents[normalizedMajor] = minorsMap;
    }

    return SymptomComponentIndex(
      majorComponents: majorComponents,
      minorComponents: minorComponents,
      pairSeverities: pairSeverities,
      pairConditions: pairConditions,
    );
  }
}


