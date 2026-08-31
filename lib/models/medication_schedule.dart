import 'package:ethan_utils/ethan_utils.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:health_notes/models/drug_dose.dart';
import 'package:health_notes/models/drug_name.dart';
import 'package:health_notes/models/health_note.dart';
import 'package:health_notes/utils/whole_number_or_trimmed_decimal.dart';
import 'package:intl/intl.dart';

part 'medication_schedule.freezed.dart';
part 'medication_schedule.g.dart';

enum ScheduleKind({required final String label}) {
  taper(label: 'Taper'),
  daily(label: 'Daily'),
}

enum PartOfDay({required final String label, required final int sortHour}) {
  morning(label: 'morning', sortHour: 8),
  afternoon(label: 'afternoon', sortHour: 14),
  evening(label: 'evening', sortHour: 18),
  night(label: 'night', sortHour: 22);

  String get pluralLabel => '${label}s';
}

@freezed
sealed class DoseWhen with _$DoseWhen {
  const DoseWhen._();

  const factory DoseWhen.clock({required int hour, required int minute}) =
      ClockDoseWhen;

  const factory DoseWhen.partOfDay(PartOfDay part) = PartOfDayDoseWhen;

  factory DoseWhen.fromJson(Map<String, dynamic> json) =>
      _$DoseWhenFromJson(json);

  String get caption => switch (this) {
    ClockDoseWhen(:final hour, :final minute) => DateFormat(
      'h:mm a',
    ).format(DateTime(2000, 1, 1, hour, minute)),
    PartOfDayDoseWhen(:final part) => part.label,
  };

  int get sortMinutes => switch (this) {
    ClockDoseWhen(:final hour, :final minute) => hour * 60 + minute,
    PartOfDayDoseWhen(:final part) => part.sortHour * 60,
  };
}

@freezed
abstract class ScheduledDose with _$ScheduledDose {
  @JsonSerializable(explicitToJson: true)
  const factory ScheduledDose({
    required String id,
    required double amount,
    required DoseWhen when,
  }) = _ScheduledDose;

  const ScheduledDose._();

  factory ScheduledDose.fromJson(Map<String, dynamic> json) =>
      _$ScheduledDoseFromJson(json);

  String amountCaption(String unit) =>
      '${amount.wholeNumberOrTrimmedDecimal}$unit';

  String timedAmountCaption(String unit) => switch (when) {
    ClockDoseWhen() => '${amountCaption(unit)} at ${when.caption}',
    PartOfDayDoseWhen(:final part) =>
      '${amountCaption(unit)} each ${part.label}',
  };
}

@freezed
abstract class ScheduleStep with _$ScheduleStep {
  @JsonSerializable(explicitToJson: true)
  const factory ScheduleStep({
    required String id,
    required List<ScheduledDose> doses,
    int? durationDays,
  }) = _ScheduleStep;

  const ScheduleStep._();

  factory ScheduleStep.fromJson(Map<String, dynamic> json) =>
      _$ScheduleStepFromJson(json);

  bool get isOpenEnded => durationDays == null;

  String sentenceFragment({required String unit, required bool omitWhen}) {
    if (doses.isEmpty) return '';
    final amountPhrase = omitWhen && doses.length == 1
        ? doses.first.amountCaption(unit)
        : doses
              .map((dose) => dose.timedAmountCaption(unit))
              .join(doses.length == 2 ? ' and ' : ', ');
    if (durationDays == null) return amountPhrase;
    final dayWord = durationDays == 1 ? 'day' : 'days';
    return '$amountPhrase for $durationDays $dayWord';
  }
}

@freezed
abstract class MedicationSchedule with _$MedicationSchedule {
  @JsonSerializable(explicitToJson: true)
  const factory MedicationSchedule({
    required String id,
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'medication_name')
    @DrugNameConverter()
    required DrugName medicationName,
    @Default('mg') String unit,
    @JsonKey(name: 'start_date') required DateTime startDate,
    @JsonKey(name: 'end_date') DateTime? endDate,
    @Default([]) List<ScheduleStep> steps,
    @Default('') String notes,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
  }) = _MedicationSchedule;

  const MedicationSchedule._();

  factory MedicationSchedule.fromJson(Map<String, dynamic> json) =>
      _$MedicationScheduleFromJson(json);

  DateTime get startDay => startDate.startOfDay;

  ScheduleKind get kind {
    if (steps.length > 1 || steps.any((step) => step.durationDays != null)) {
      return ScheduleKind.taper;
    }
    return ScheduleKind.daily;
  }

  DateTime? get endedDay => endDate?.startOfDay;

  DateTime? get lastCoveredDayFromSteps {
    var cursor = startDay;
    for (final step in steps) {
      if (step.durationDays == null) return null;
      cursor = _addCalendarDays(cursor, step.durationDays!);
    }
    return _addCalendarDays(cursor, -1);
  }

  DateTime? get lastCoveredDay {
    final fromSteps = lastCoveredDayFromSteps;
    if (endedDay == null) return fromSteps;
    if (fromSteps == null) return endedDay;
    return endedDay!.isBefore(fromSteps) ? endedDay : fromSteps;
  }

  bool get isOpenEnded => lastCoveredDayFromSteps == null && endDate == null;

  bool covers(DateTime day) {
    final calendarDay = day.startOfDay;
    if (calendarDay.isBefore(startDay)) return false;
    if (endedDay != null && calendarDay.isAfter(endedDay!)) return false;
    final lastFromSteps = lastCoveredDayFromSteps;
    if (lastFromSteps != null && calendarDay.isAfter(lastFromSteps)) {
      return false;
    }
    return steps.isNotEmpty;
  }

  bool get isActiveOnToday => covers(DateTime.now());

  bool get isUpcoming => startDay.isAfter(DateTime.now().startOfDay);

  bool get isListedAsActive => isActiveOnToday || isUpcoming;

  bool get hasEnded => !isListedAsActive;

  String get listCaption {
    if (isUpcoming) return 'Starts ${startDay.monthDayCaption}';
    final progress = progressOn(DateTime.now());
    if (progress != null) return progress.caption;
    return _endedCaption;
  }

  ScheduleStep? stepOn(DateTime day) {
    if (!covers(day)) return null;
    var remaining = _calendarDaysFromStart(day);
    for (final step in steps) {
      if (step.durationDays == null) return step;
      if (remaining < step.durationDays!) return step;
      remaining -= step.durationDays!;
    }
    return null;
  }

  int dayInStepOn(DateTime day) {
    if (!covers(day)) return 0;
    var remaining = _calendarDaysFromStart(day);
    for (final step in steps) {
      if (step.durationDays == null) return remaining + 1;
      if (remaining < step.durationDays!) return remaining + 1;
      remaining -= step.durationDays!;
    }
    return 0;
  }

  List<ScheduledDoseOccurrence> occurrencesOn(DateTime day) {
    final step = stepOn(day);
    if (step == null) return const [];
    final dayInStep = dayInStepOn(day);
    final occurrences = step.doses.mapL(
      (dose) => ScheduledDoseOccurrence(
        schedule: this,
        step: step,
        scheduledDose: dose,
        day: day.startOfDay,
        dayInStep: dayInStep,
      ),
    );
    occurrences.sort(
      (left, right) => left.scheduledDose.when.sortMinutes.compareTo(
        right.scheduledDose.when.sortMinutes,
      ),
    );
    return occurrences;
  }

  String get sentence {
    final fragments = <String>[];
    DoseWhen? previousWhen;
    for (final step in steps) {
      if (step.doses.isEmpty) continue;
      final omitWhen =
          previousWhen != null &&
          step.doses.length == 1 &&
          step.doses.first.when == previousWhen;
      fragments.add(step.sentenceFragment(unit: unit, omitWhen: omitWhen));
      previousWhen = step.doses.length == 1 ? step.doses.first.when : null;
    }
    if (fragments.isEmpty) return '';
    if (fragments.length == 1) return fragments.first;
    return '${fragments.first}, then ${fragments.skip(1).join(', then ')}';
  }

  ScheduleProgress? progressOn(DateTime day) {
    final step = stepOn(day);
    if (step == null) return null;
    final dayNumber = _calendarDaysFromStart(day) + 1;
    final last = lastCoveredDay;
    final totalDays = last == null
        ? null
        : _calendarDaysBetween(startDay, last) + 1;
    return ScheduleProgress(
      dayNumber: dayNumber,
      totalDays: totalDays,
      currentStep: step,
      dayInStep: dayInStepOn(day),
      caption: _progressCaption(
        dayNumber: dayNumber,
        totalDays: totalDays,
        step: step,
      ),
    );
  }

  String _progressCaption({
    required int dayNumber,
    required int? totalDays,
    required ScheduleStep step,
  }) {
    final dayPhrase = totalDays == null
        ? 'Day $dayNumber'
        : 'Day $dayNumber of $totalDays';
    if (totalDays == null) return '$dayPhrase · $_courseDateRangeCaption';
    final todayDose = _todayDosePhrase(step);
    if (todayDose.isEmpty) return '$dayPhrase · $_courseDateRangeCaption';
    return '$dayPhrase · $todayDose · $_courseDateRangeCaption';
  }

  String _todayDosePhrase(ScheduleStep step) {
    if (step.doses.isEmpty) return '';
    if (step.doses.length == 1) {
      final dose = step.doses.first;
      return '${dose.amountCaption(unit)} ${dose.when.caption}';
    }
    return step.doses.map((dose) => dose.timedAmountCaption(unit)).join(', ');
  }

  String get _courseDateRangeCaption {
    final last = lastCoveredDay;
    if (last == null) return startDay.monthDayCaption;
    return '${startDay.monthDayCaption} - ${last.monthDayCaption}';
  }

  String get _endedCaption {
    final last = lastCoveredDay;
    if (last == null) return startDay.monthDayCaption;
    final totalDays = _calendarDaysBetween(startDay, last) + 1;
    return 'Day $totalDays of $totalDays · $_courseDateRangeCaption';
  }

  int _calendarDaysFromStart(DateTime day) =>
      _calendarDaysBetween(startDay, day.startOfDay);

  int _calendarDaysBetween(DateTime from, DateTime to) {
    return DateTime.utc(
      to.year,
      to.month,
      to.day,
    ).difference(DateTime.utc(from.year, from.month, from.day)).inDays;
  }

  DateTime _addCalendarDays(DateTime day, int days) =>
      DateTime(day.year, day.month, day.day + days);

  MedicationSchedule withPreferredName(DrugName preferred) {
    if (medicationName.display == preferred.display) return this;
    return copyWith(medicationName: preferred);
  }

  Map<String, dynamic> toJsonForUpdate() => {
    'medication_name': medicationName.display,
    'unit': unit,
    'start_date': startDate.toIso8601String(),
    'end_date': endDate?.toIso8601String(),
    'steps': steps.map((step) => step.toJson()).toList(),
    'notes': notes,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };
}

class ScheduleProgress {
  const ScheduleProgress({
    required this.dayNumber,
    required this.totalDays,
    required this.currentStep,
    required this.dayInStep,
    required this.caption,
  });

  final int dayNumber;
  final int? totalDays;
  final ScheduleStep currentStep;
  final int dayInStep;
  final String caption;
}

class ScheduledDoseOccurrence {
  const ScheduledDoseOccurrence({
    required this.schedule,
    required this.step,
    required this.scheduledDose,
    required this.day,
    required this.dayInStep,
  });

  final MedicationSchedule schedule;
  final ScheduleStep step;
  final ScheduledDose scheduledDose;
  final DateTime day;
  final int dayInStep;

  String get scheduleId => schedule.id;
  String get scheduledDoseId => scheduledDose.id;
  DrugName get medicationName => schedule.medicationName;
  String get amountCaption => scheduledDose.amountCaption(schedule.unit);
  String get whenCaption => scheduledDose.when.caption;

  String? get stepProgressCaption {
    final durationDays = step.durationDays;
    if (durationDays == null) return null;
    final whenWord = switch (scheduledDose.when) {
      PartOfDayDoseWhen(:final part) => part.pluralLabel,
      ClockDoseWhen() => durationDays == 1 ? 'day' : 'days',
    };
    return '$dayInStep of $durationDays $whenWord';
  }

  DrugDose get asDrugDose => DrugDose(
    name: schedule.medicationName,
    dosage: scheduledDose.amount,
    unit: schedule.unit,
    fromSchedule: LoggedFromSchedule(
      scheduleId: schedule.id,
      scheduledDoseId: scheduledDose.id,
      whenCaption: scheduledDose.when.caption,
    ),
  );

  bool isLoggedAmong(Iterable<DrugDose> doses) => doses.any(
    (dose) => dose.logsScheduledDose(
      scheduleId: schedule.id,
      scheduledDoseId: scheduledDose.id,
    ),
  );
}

class DosesWaitingForNote {
  const DosesWaitingForNote({
    required this.schedules,
    required this.day,
    required this.alreadyLogged,
  });

  factory DosesWaitingForNote.forDraft({
    required List<MedicationSchedule> schedules,
    required DateTime day,
    required List<HealthNote> notes,
    required List<DrugDose> draftDoses,
    String? excludingNoteId,
  }) {
    final alreadyLogged = [
      for (final note in notes)
        if (note.dateTime.sameDayAs(day) && note.id != excludingNoteId)
          ...note.drugDoses,
      ...draftDoses,
    ];
    return DosesWaitingForNote(
      schedules: schedules,
      day: day,
      alreadyLogged: alreadyLogged,
    );
  }

  final List<MedicationSchedule> schedules;
  final DateTime day;
  final List<DrugDose> alreadyLogged;

  List<ScheduledDoseOccurrence> get waiting {
    final due = <ScheduledDoseOccurrence>[];
    for (final schedule in schedules) {
      for (final occurrence in schedule.occurrencesOn(day)) {
        if (!occurrence.isLoggedAmong(alreadyLogged)) {
          due.add(occurrence);
        }
      }
    }
    due.sort((left, right) {
      final nameOrder = left.medicationName.compareTo(right.medicationName);
      if (nameOrder != 0) return nameOrder;
      return left.scheduledDose.when.sortMinutes.compareTo(
        right.scheduledDose.when.sortMinutes,
      );
    });
    return due;
  }

  ScheduledDoseOccurrence? nearestTo(DateTime noteDateTime) {
    final due = waiting;
    if (due.isEmpty) return null;
    final noteMinutes = noteDateTime.hour * 60 + noteDateTime.minute;
    return due.reduce((best, candidate) {
      final bestDelta = (best.scheduledDose.when.sortMinutes - noteMinutes)
          .abs();
      final candidateDelta =
          (candidate.scheduledDose.when.sortMinutes - noteMinutes).abs();
      return candidateDelta < bestDelta ? candidate : best;
    });
  }
}
