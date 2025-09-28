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

  factory HealthNote.fromJson(Map<String, dynamic> json) =>
      _$HealthNoteFromJson(json);
}

extension HealthNoteExtensions on HealthNote {
  bool get hasSymptoms => symptomsList.isNotEmpty;

  bool get hasNotes => notes.isNotEmpty;

  bool get hasDrugDoses => drugDoses.isNotEmpty;

  bool get hasAppliedTools => appliedTools.isNotEmpty;

  bool get isEmpty =>
      !hasSymptoms && !hasNotes && !hasDrugDoses && !hasAppliedTools;

  List<DrugDose> get validDrugDoses =>
      drugDoses.where((dose) => dose.name.isNotEmpty).toList();

  List<Symptom> get validSymptoms => symptomsList
      .where((symptom) => symptom.majorComponent.isNotEmpty)
      .toList();

  HealthNote copyWith({
    String? id,
    DateTime? dateTime,
    List<Symptom>? symptomsList,
    List<DrugDose>? drugDoses,
    List<AppliedTool>? appliedTools,
    String? notes,
    DateTime? createdAt,
  }) {
    return HealthNote(
      id: id ?? this.id,
      dateTime: dateTime ?? this.dateTime,
      symptomsList: symptomsList ?? this.symptomsList,
      drugDoses: drugDoses ?? this.drugDoses,
      appliedTools: appliedTools ?? this.appliedTools,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJsonForUpdate() {
    return {
      'date_time': dateTime.toIso8601String(),
      'symptoms_list': validSymptoms
          .map((symptom) => symptom.toJson())
          .toList(),
      'drug_doses': validDrugDoses.map((dose) => dose.toJson()).toList(),
      'applied_tools': appliedTools.map((t) => t.toJson()).toList(),
      'notes': notes,
    };
  }
}
