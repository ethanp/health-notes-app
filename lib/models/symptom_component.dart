import 'package:freezed_annotation/freezed_annotation.dart';

part 'symptom_component.freezed.dart';
part 'symptom_component.g.dart';

enum ComponentSection { pinned, recent, historical }

@freezed
abstract class SymptomComponent with _$SymptomComponent {
  const factory SymptomComponent({
    required String name,
    required String normalizedName,
    @Default(false) bool isPinned,
    @Default(0) int usageCount,
    @Default(0) int recentUsageCount,
    @Default(ComponentSection.historical) ComponentSection section,
  }) = _SymptomComponent;

  const SymptomComponent._();

  factory SymptomComponent.fromJson(Map<String, dynamic> json) =>
      _$SymptomComponentFromJson(json);

  int get displayCount =>
      section == ComponentSection.recent ? recentUsageCount : usageCount;
}

