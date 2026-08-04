import 'package:ethan_utils/ethan_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'condition_entry.freezed.dart';
part 'condition_entry.g.dart';

enum ConditionPhase {
  onset(color: Color(0xFFFF9500)), // CupertinoColors.systemOrange (light)
  worsening(color: Color(0xFFFF3B30)), // CupertinoColors.systemRed (light)
  peak(color: Color(0xFFD32F2F)),
  improving(color: Color(0xFF34C759)); // CupertinoColors.systemGreen (light)

  const ConditionPhase({required this.color});

  final Color color;

  String get displayName => nameAsCapitalizedWords;
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
