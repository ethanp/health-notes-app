import 'package:freezed_annotation/freezed_annotation.dart';

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
