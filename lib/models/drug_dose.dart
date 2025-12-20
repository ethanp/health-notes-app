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

  const DrugDose._();

  factory DrugDose.fromJson(Map<String, dynamic> json) =>
      _$DrugDoseFromJson(json);

  static const empty = DrugDose(name: '', dosage: 0.0, unit: 'mg');

  bool get isValid => name.isNotEmpty && dosage > 0;
  bool get isEmpty => name.isEmpty;

  String get displayName => name.isEmpty ? 'Unnamed medication' : name;
  String get displayDosage => '${formatDecimalValue(dosage)}$unit';
  String get fullDisplay => '$displayName - $displayDosage';
}
