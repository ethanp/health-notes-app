import 'package:freezed_annotation/freezed_annotation.dart';

part 'pinned_symptom_components.freezed.dart';
part 'pinned_symptom_components.g.dart';

@freezed
abstract class PinnedSymptomComponents with _$PinnedSymptomComponents {
  const factory PinnedSymptomComponents({
    @JsonKey(name: 'pinned_majors') @Default({}) Set<String> pinnedMajors,
    @JsonKey(name: 'pinned_minors')
    @Default({})
    Map<String, Set<String>> pinnedMinors,
  }) = _PinnedSymptomComponents;

  const PinnedSymptomComponents._();

  factory PinnedSymptomComponents.fromJson(Map<String, dynamic> json) =>
      _$PinnedSymptomComponentsFromJson(json);

  static const empty = PinnedSymptomComponents();

  bool isMajorPinned(String normalizedName) =>
      pinnedMajors.contains(normalizedName);

  bool isMinorPinned(String normalizedMajor, String normalizedMinor) =>
      pinnedMinors[normalizedMajor]?.contains(normalizedMinor) ?? false;

  PinnedSymptomComponents toggleMajorPin(String normalizedName) {
    final newPinned = Set<String>.from(pinnedMajors);
    if (newPinned.contains(normalizedName)) {
      newPinned.remove(normalizedName);
    } else {
      newPinned.add(normalizedName);
    }
    return copyWith(pinnedMajors: newPinned);
  }

  PinnedSymptomComponents toggleMinorPin(
    String normalizedMajor,
    String normalizedMinor,
  ) {
    final newMinors = Map<String, Set<String>>.from(
      pinnedMinors.map((k, v) => MapEntry(k, Set<String>.from(v))),
    );
    final majorMinors = newMinors.putIfAbsent(normalizedMajor, () => {});
    if (majorMinors.contains(normalizedMinor)) {
      majorMinors.remove(normalizedMinor);
      if (majorMinors.isEmpty) {
        newMinors.remove(normalizedMajor);
      }
    } else {
      majorMinors.add(normalizedMinor);
    }
    return copyWith(pinnedMinors: newMinors);
  }
}

