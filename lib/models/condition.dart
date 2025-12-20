import 'package:flutter/cupertino.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'condition.freezed.dart';
part 'condition.g.dart';

enum ConditionStatus {
  active,
  resolved;

  String get displayName => switch (this) {
    active => 'Active',
    resolved => 'Resolved',
  };
}

@freezed
abstract class Condition with _$Condition {
  const factory Condition({
    required String id,
    @JsonKey(name: 'user_id') required String userId,
    required String name,
    @JsonKey(name: 'start_date') required DateTime startDate,
    @JsonKey(name: 'end_date') DateTime? endDate,
    @JsonKey(name: 'condition_status') @Default(ConditionStatus.active) ConditionStatus status,
    @JsonKey(name: 'color_value') @Default(0xFFE57373) int colorValue,
    @JsonKey(name: 'icon_code_point') @Default(0xf36e) int iconCodePoint,
    @Default('') String notes,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
  }) = _Condition;

  const Condition._();

  factory Condition.fromJson(Map<String, dynamic> json) =>
      _$ConditionFromJson(json);

  Color get color => Color(colorValue);

  IconData get icon => IconData(
    iconCodePoint,
    fontFamily: 'CupertinoIcons',
    fontPackage: 'cupertino_icons',
  );

  int get durationDays => endDate != null
      ? endDate!.difference(startDate).inDays + 1
      : DateTime.now().difference(startDate).inDays + 1;

  bool get isActive => status == ConditionStatus.active;
  bool get isResolved => status == ConditionStatus.resolved;

  Map<String, dynamic> toJsonForUpdate() => {
    'name': name,
    'start_date': startDate.toIso8601String(),
    'end_date': endDate?.toIso8601String(),
    'condition_status': status.name,
    'color_value': colorValue,
    'icon_code_point': iconCodePoint,
    'notes': notes,
    'updated_at': DateTime.now().toIso8601String(),
  };
}

