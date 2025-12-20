import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:health_notes/models/drug_dose.dart';
import 'package:health_notes/models/symptom.dart';
import 'package:health_notes/models/applied_tool.dart';

part 'health_note.freezed.dart';
part 'health_note.g.dart';

@freezed
abstract class HealthNote with _$HealthNote {
  const factory HealthNote({
    required String id,
    @JsonKey(name: 'date_time') required DateTime dateTime,
    @JsonKey(name: 'symptoms_list') @Default([]) List<Symptom> symptomsList,
    @JsonKey(name: 'drug_doses') @Default([]) List<DrugDose> drugDoses,
    @JsonKey(name: 'applied_tools') @Default([]) List<AppliedTool> appliedTools,
    @Default('') String notes,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _HealthNote;

  const HealthNote._(); // Private constructor to allow methods/getters

  factory HealthNote.fromJson(Map<String, dynamic> json) =>
      _$HealthNoteFromJson(json);

  bool get hasSymptoms => symptomsList.isNotEmpty;
  bool get hasNotes => notes.isNotEmpty;
  bool get hasDrugDoses => drugDoses.isNotEmpty;
  bool get hasAppliedTools => appliedTools.isNotEmpty;

  bool get isEmpty =>
      !hasSymptoms && !hasNotes && !hasDrugDoses && !hasAppliedTools;

  List<DrugDose> get validDrugDoses =>
      drugDoses.where((dose) => dose.name.isNotEmpty).toList();

  List<Symptom> get validSymptoms =>
      symptomsList.where((s) => s.majorComponent.isNotEmpty).toList();

  Map<String, dynamic> toJsonForUpdate() {
    return {
      'date_time': dateTime.toIso8601String(),
      'symptoms_list': validSymptoms.map((s) => s.toJson()).toList(),
      'drug_doses': validDrugDoses.map((d) => d.toJson()).toList(),
      'applied_tools': appliedTools.map((t) => t.toJson()).toList(),
      'notes': notes,
    };
  }
}
