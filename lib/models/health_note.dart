import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:health_notes/models/applied_tool.dart';
import 'package:health_notes/models/drug_dose.dart';
import 'package:health_notes/models/drug_name.dart';
import 'package:health_notes/models/symptom.dart';
import 'package:health_notes/services/text_normalizer.dart';
import 'package:stemmer/stemmer.dart';

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
      symptomsList.where((symptom) => symptom.hasMajorComponent).toList();

  bool hasSymptomNamed(String name) =>
      symptomsList.any((symptom) => symptom.majorComponent == name);

  bool hasSubSymptom(String majorComponent, String minorComponent) =>
      symptomsList.any(
        (symptom) =>
            symptom.majorComponent == majorComponent &&
            symptom.minorComponent == minorComponent,
      );

  bool hasDrug(DrugName drugName) =>
      drugDoses.any((dose) => dose.name == drugName);

  bool hasToolId(String toolId) =>
      appliedTools.any((appliedTool) => appliedTool.toolId == toolId);

  bool hasToolNamed(String toolName) {
    final normalizer = CaseInsensitiveNormalizer();
    return appliedTools.any(
      (appliedTool) => normalizer.areEqual(appliedTool.toolName, toolName),
    );
  }

  bool matchesSearch(String searchQuery) {
    if (searchQuery.trim().isEmpty) return true;

    final queryWords = _processSearchText(searchQuery);
    if (queryWords.isEmpty) return true;

    final noteText = _processSearchText(_searchableText).join(' ');
    return queryWords.every((queryWord) => noteText.contains(queryWord));
  }

  String get _searchableText => [
    ...validSymptoms.map((symptom) => symptom.majorComponent),
    notes,
    ...drugDoses.map((dose) => dose.name.display),
  ].where((text) => text.isNotEmpty).join(' ');

  static final PorterStemmer _stemmer = PorterStemmer();

  static List<String> _processSearchText(String text) => text
      .toLowerCase()
      .split(RegExp(r'\s+'))
      .map((word) => word.trim())
      .where((word) => word.isNotEmpty && word.length > 1)
      .map((word) => _stemmer.stem(word))
      .toList();

  HealthNote withPreferredDrugNames(Map<String, DrugName> preferredByIdentity) {
    var changed = false;
    final rewritten = drugDoses.map((dose) {
      final preferred = preferredByIdentity[dose.name.identity];
      if (preferred == null || preferred.display == dose.name.display) {
        return dose;
      }
      changed = true;
      return dose.copyWith(name: preferred);
    }).toList();
    if (!changed) return this;
    return copyWith(drugDoses: rewritten);
  }

  Map<String, dynamic> toJsonForUpdate() {
    return {
      'date_time': dateTime.toIso8601String(),
      'symptoms_list': validSymptoms.map((s) => s.toJson()).toList(),
      'drug_doses': validDrugDoses.map((d) => d.toJson()).toList(),
      'applied_tools': appliedTools.map((t) => t.toJson()).toList(),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
