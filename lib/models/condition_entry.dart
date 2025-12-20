import 'package:flutter/cupertino.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'condition_entry.freezed.dart';
part 'condition_entry.g.dart';

enum ConditionPhase {
  onset,
  worsening,
  peak,
  improving;

  String get displayName => switch (this) {
    onset => 'Onset',
    worsening => 'Worsening',
    peak => 'Peak',
    improving => 'Improving',
  };

  Color get color => switch (this) {
    onset => CupertinoColors.systemOrange,
    worsening => CupertinoColors.systemRed,
    peak => const Color(0xFFD32F2F),
    improving => CupertinoColors.systemGreen,
  };
}

@freezed
abstract class ConditionEntry with _$ConditionEntry {
  const factory ConditionEntry({
    required String id,
    @JsonKey(name: 'condition_id') required String conditionId,
    @JsonKey(name: 'entry_date') required DateTime entryDate,
    required int severity,
    @JsonKey(name: 'phase') @Default(ConditionPhase.onset) ConditionPhase phase,
    @Default('') String notes,
    @JsonKey(name: 'linked_check_in_id') required String linkedCheckInId,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
  }) = _ConditionEntry;

  const ConditionEntry._();

  factory ConditionEntry.fromJson(Map<String, dynamic> json) =>
      _$ConditionEntryFromJson(json);

  Map<String, dynamic> toJsonForUpdate() => {
    'condition_id': conditionId,
    'entry_date': entryDate.toIso8601String(),
    'severity': severity,
    'phase': phase.name,
    'notes': notes,
    'linked_check_in_id': linkedCheckInId,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };
}

class ConditionEntryDraft {
  final String conditionId;
  final String conditionName;
  final Color conditionColor;
  int severity;
  ConditionPhase phase;
  String notes;
  bool markResolved;

  ConditionEntryDraft({
    required this.conditionId,
    required this.conditionName,
    required this.conditionColor,
    this.severity = 5,
    this.phase = ConditionPhase.onset,
    this.notes = '',
    this.markResolved = false,
  });
}

