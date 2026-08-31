import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:health_notes/models/drug_name.dart';
import 'package:health_notes/utils/whole_number_or_trimmed_decimal.dart';

part 'drug_dose.freezed.dart';
part 'drug_dose.g.dart';

@freezed
abstract class LoggedFromSchedule with _$LoggedFromSchedule {
  const factory LoggedFromSchedule({
    required String scheduleId,
    required String scheduledDoseId,
    required String whenCaption,
  }) = _LoggedFromSchedule;

  const LoggedFromSchedule._();

  factory LoggedFromSchedule.fromJson(Map<String, dynamic> json) =>
      _$LoggedFromScheduleFromJson(json);

  bool logsSlot({
    required String scheduleId,
    required String scheduledDoseId,
  }) =>
      this.scheduleId == scheduleId && this.scheduledDoseId == scheduledDoseId;
}

@freezed
abstract class DrugDose with _$DrugDose {
  @JsonSerializable(explicitToJson: true)
  const factory DrugDose({
    @DrugNameConverter() required DrugName name,
    required double dosage,
    @Default('mg') String unit,
    LoggedFromSchedule? fromSchedule,
  }) = _DrugDose;

  const DrugDose._();

  factory DrugDose.fromJson(Map<String, dynamic> json) =>
      _$DrugDoseFromJson(json);

  static const empty = DrugDose(name: DrugName.empty, dosage: 0.0, unit: 'mg');

  bool get isValid => name.isNotEmpty && dosage > 0;
  bool get isEmpty => name.isEmpty;

  String get displayName => name.isEmpty ? 'Unnamed medication' : name.display;
  String get displayDosage => '${dosage.wholeNumberOrTrimmedDecimal}$unit';
  String get suggestionLabel => '$displayName $displayDosage';
  String get strengthIdentity => '${name.identity}|$dosage|$unit';
  String get whenCaption => fromSchedule?.whenCaption ?? '';
  String get fullDisplay {
    if (whenCaption.isEmpty) return '$displayName - $displayDosage';
    return '$displayName - $displayDosage · $whenCaption';
  }

  bool logsScheduledDose({
    required String scheduleId,
    required String scheduledDoseId,
  }) =>
      fromSchedule?.logsSlot(
        scheduleId: scheduleId,
        scheduledDoseId: scheduledDoseId,
      ) ??
      false;
}
