import 'package:freezed_annotation/freezed_annotation.dart';

part 'symptom.freezed.dart';
part 'symptom.g.dart';

@freezed
abstract class Symptom with _$Symptom {
  const factory Symptom({
    @JsonKey(name: 'major_component') required String majorComponent,
    @JsonKey(name: 'minor_component') @Default('') String minorComponent,
    @JsonKey(name: 'severity_level') required int severityLevel,
    @JsonKey(name: 'additional_notes') @Default('') String additionalNotes,
  }) = _Symptom;

  factory Symptom.fromJson(Map<String, dynamic> json) =>
      _$SymptomFromJson(json);
}

extension SymptomExtensions on Symptom {
  bool get isValid =>
      majorComponent.isNotEmpty && severityLevel >= 1 && severityLevel <= 10;
  bool get isEmpty => majorComponent.isEmpty;

  String get displayName =>
      majorComponent.isEmpty ? 'Unnamed symptom' : majorComponent;
  String get displaySeverity => 'Severity: $severityLevel/10';
  String get fullDisplay => '$displayName - $displaySeverity';

  /// Returns the full symptom description combining major and minor components
  String get fullDescription {
    if (majorComponent.isEmpty && minorComponent.isEmpty) {
      return 'Unnamed symptom';
    } else if (majorComponent.isEmpty) {
      return minorComponent;
    } else if (minorComponent.isEmpty) {
      return majorComponent;
    } else {
      return '$majorComponent - $minorComponent';
    }
  }

  /// Returns a simplified name for the symptom (just the major component if available)
  String get simplifiedName => majorComponent;

  Symptom copyWith({
    String? majorComponent,
    String? minorComponent,
    int? severityLevel,
    String? additionalNotes,
  }) {
    return Symptom(
      majorComponent: majorComponent ?? this.majorComponent,
      minorComponent: minorComponent ?? this.minorComponent,
      severityLevel: severityLevel ?? this.severityLevel,
      additionalNotes: additionalNotes ?? this.additionalNotes,
    );
  }

  static Symptom get empty =>
      const Symptom(majorComponent: '', severityLevel: 1);
}
