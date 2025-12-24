import 'package:health_notes/models/symptom_component.dart';
import 'package:health_notes/services/text_normalizer.dart';

class SymptomComponentIndex {
  final Map<String, SymptomComponent> _majorComponents;
  final Map<String, Map<String, SymptomComponent>> _minorComponents;
  final Map<String, int> _pairSeverities;
  final Map<String, String> _pairConditions;

  SymptomComponentIndex({
    required Map<String, SymptomComponent> majorComponents,
    required Map<String, Map<String, SymptomComponent>> minorComponents,
    required Map<String, int> pairSeverities,
    required Map<String, String> pairConditions,
  }) : _majorComponents = majorComponents,
       _minorComponents = minorComponents,
       _pairSeverities = pairSeverities,
       _pairConditions = pairConditions;

  List<SymptomComponent> getMajorComponents({String? searchQuery}) {
    var components = _majorComponents.values.toList();

    if (searchQuery != null && searchQuery.isNotEmpty) {
      final normalizedQuery = searchQuery.trim().toLowerCase();
      components = components
          .where((c) => c.normalizedName.contains(normalizedQuery))
          .toList();
    }

    return _sortBySection(components);
  }

  List<SymptomComponent> getMinorComponents(
    String majorName, {
    String? searchQuery,
  }) {
    final normalizedMajor = majorName.trim().toLowerCase();
    final minors = _minorComponents[normalizedMajor]?.values.toList() ?? [];

    var components = minors;

    if (searchQuery != null && searchQuery.isNotEmpty) {
      final normalizedQuery = searchQuery.trim().toLowerCase();
      components = components
          .where((c) => c.normalizedName.contains(normalizedQuery))
          .toList();
    }

    return _sortBySection(components);
  }

  String? getDefaultMajor() {
    final components = getMajorComponents();
    if (components.isEmpty) return null;
    return components.first.name;
  }

  String? getDefaultMinor(String majorName) {
    final components = getMinorComponents(majorName);
    if (components.isEmpty) return null;
    return components.first.name;
  }

  int getDefaultSeverity(String majorName, String minorName) {
    final key = SymptomNormalizer.generateKey(majorName, minorName);
    return _pairSeverities[key] ?? 5;
  }

  String? getAutoLinkedCondition(
    String majorName,
    String minorName,
    Set<String> activeConditionIds,
  ) {
    final key = SymptomNormalizer.generateKey(majorName, minorName);
    final conditionId = _pairConditions[key];
    if (conditionId != null && activeConditionIds.contains(conditionId)) {
      return conditionId;
    }
    return null;
  }

  bool get isEmpty => _majorComponents.isEmpty;

  List<SymptomComponent> _sortBySection(List<SymptomComponent> components) {
    final pinned = <SymptomComponent>[];
    final recent = <SymptomComponent>[];
    final historical = <SymptomComponent>[];

    for (final c in components) {
      switch (c.section) {
        case ComponentSection.pinned:
          pinned.add(c);
        case ComponentSection.recent:
          recent.add(c);
        case ComponentSection.historical:
          historical.add(c);
      }
    }

    pinned.sort((a, b) => b.usageCount.compareTo(a.usageCount));
    recent.sort((a, b) => b.recentUsageCount.compareTo(a.recentUsageCount));
    historical.sort((a, b) => b.usageCount.compareTo(a.usageCount));

    return [...pinned, ...recent, ...historical];
  }
}

