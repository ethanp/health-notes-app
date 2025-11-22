import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:health_notes/utils/number_formatter.dart';

part 'drug_dose.freezed.dart';
part 'drug_dose.g.dart';

@freezed
abstract class DrugDose with _$DrugDose {
  const factory DrugDose({
    required String name,
    required double dosage,
    @Default('mg') String unit,
  }) = _DrugDose;

  factory DrugDose.fromJson(Map<String, dynamic> json) =>
      _$DrugDoseFromJson(json);
}

/// Extension for DrugDose to add utility methods without interfering with freezed code generation
extension DrugDoseExtensions on DrugDose {
  bool get isValid => name.isNotEmpty && dosage > 0;
  bool get isEmpty => name.isEmpty;

  String get displayName => name.isEmpty ? 'Unnamed medication' : name;
  String get displayDosage => '${formatDecimalValue(dosage)}$unit';
  String get fullDisplay => '$displayName - $displayDosage';

  DrugDose copyWith({String? name, double? dosage, String? unit}) {
    return DrugDose(
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      unit: unit ?? this.unit,
    );
  }

  static DrugDose get empty =>
      const DrugDose(name: '', dosage: 0.0, unit: 'mg');
}
