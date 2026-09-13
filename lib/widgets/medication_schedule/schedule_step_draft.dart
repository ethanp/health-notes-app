import 'package:flutter/material.dart';
import 'package:health_notes/models/medication_schedule.dart';
import 'package:health_notes/utils/data_utils.dart';

class ScheduleStepDraft({
  required final String id,
  required final TextEditingController duration,
  required final List<ScheduleDoseDraft> doses,
}) {
  factory taper({required DoseWhen when}) {
    return ScheduleStepDraft(
      id: DataUtils.uuid.v4(),
      duration: TextEditingController(),
      doses: [ScheduleDoseDraft(when: when)],
    );
  }

  factory dailyTimes({required DoseWhen when}) {
    return ScheduleStepDraft(
      id: DataUtils.uuid.v4(),
      duration: TextEditingController(),
      doses: [ScheduleDoseDraft(when: when)],
    );
  }

  factory fromStep(ScheduleStep step) {
    return ScheduleStepDraft(
      id: step.id,
      duration: TextEditingController(
        text: step.durationDays?.toString() ?? '',
      ),
      doses: step.doses.map(ScheduleDoseDraft.fromDose).toList(),
    );
  }

  void dispose() {
    duration.dispose();
    for (final dose in doses) {
      dose.dispose();
    }
  }

  ScheduleStep toStep() {
    final durationDays = int.tryParse(duration.text.trim());
    return ScheduleStep(
      id: id,
      durationDays: durationDays != null && durationDays > 0
          ? durationDays
          : null,
      doses: doses
          .where((dose) => dose.parsedAmount != null)
          .map((dose) => dose.toDose())
          .toList(),
    );
  }
}

class ScheduleDoseDraft({required var DoseWhen when, String amountText = ''}) {
  factory fromDose(ScheduledDose dose) {
    return ScheduleDoseDraft(when: dose.when, amountText: _amountText(dose.amount))
      ..id = dose.id;
  }

  static String _amountText(double amount) {
    if (amount == amount.truncateToDouble()) return amount.toInt().toString();
    return amount.toString();
  }

  String id = DataUtils.uuid.v4();
  final TextEditingController amount = TextEditingController(text: amountText);
  double? get parsedAmount {
    final parsed = double.tryParse(amount.text.trim());
    if (parsed == null || parsed <= 0) return null;
    return parsed;
  }

  void dispose() => amount.dispose();

  ScheduledDose toDose() {
    return ScheduledDose(id: id, amount: parsedAmount ?? 0, when: when);
  }
}
