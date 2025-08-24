import 'package:freezed_annotation/freezed_annotation.dart';

part 'symptom.freezed.dart';
part 'symptom.g.dart';

@freezed
abstract class Symptom with _$Symptom {
  const factory Symptom({
    required String name,
    @JsonKey(name: 'severity_level') required int severityLevel,
  }) = _Symptom;

  factory Symptom.fromJson(Map<String, dynamic> json) =>
      _$SymptomFromJson(json);
}

extension SymptomExtensions on Symptom {
  bool get isValid =>
      name.isNotEmpty && severityLevel >= 1 && severityLevel <= 10;
  bool get isEmpty => name.isEmpty;

  String get displayName => name.isEmpty ? 'Unnamed symptom' : name;
  String get displaySeverity => 'Severity: $severityLevel/10';
  String get fullDisplay => '$displayName - $displaySeverity';

  Symptom copyWith({String? name, int? severityLevel}) {
    return Symptom(
      name: name ?? this.name,
      severityLevel: severityLevel ?? this.severityLevel,
    );
  }

  static Symptom get empty => const Symptom(name: '', severityLevel: 1);
}
