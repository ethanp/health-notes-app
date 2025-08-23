import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:health_notes/models/drug_dose.dart';

part 'health_note.freezed.dart';

@freezed
abstract class HealthNote with _$HealthNote {
  const factory HealthNote({
    required String id,
    required DateTime dateTime,
    @Default('') String symptoms,
    @Default([]) List<DrugDose> drugDoses,
    @Default('') String notes,
    required DateTime createdAt,
  }) = _HealthNote;

  factory HealthNote.fromJson(Map<String, dynamic> json) {
    return HealthNote(
      id: json['id'] as String,
      dateTime: DateTime.parse(json['date_time'] as String),
      symptoms: json['symptoms'] as String? ?? '',
      drugDoses:
          (json['drug_doses'] as List<dynamic>?)
              ?.map((e) => DrugDose.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      notes: json['notes'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
