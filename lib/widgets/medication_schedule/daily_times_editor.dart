import 'package:ethan_ui/ethan_ui.dart';
import 'package:flutter/material.dart';
import 'package:health_notes/theme/app_theme.dart';
import 'package:health_notes/theme/spacing.dart';

import 'schedule_form_fields.dart';
import 'schedule_step_draft.dart';

class const DailyTimesEditor({
  required final ScheduleStepDraft step,
  required final String unit,
  required final VoidCallback onChanged,
  required final VoidCallback onAddDose,
  required final ValueChanged<int> onRemoveDose,
  required final ValueChanged<ScheduleDoseDraft> onPickClockTime,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final doseIndex in step.doses.asMap().keys)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.s),
            child: DailyTimeDoseCard(
              dose: step.doses[doseIndex],
              unit: unit,
              canRemove: step.doses.length > 1,
              onChanged: onChanged,
              onPickClockTime: () => onPickClockTime(step.doses[doseIndex]),
              onRemove: () => onRemoveDose(doseIndex),
            ),
          ),
        TextButton(onPressed: onAddDose, child: const Text('Add time')),
      ],
    );
  }
}

class const DailyTimeDoseCard({
  required final ScheduleDoseDraft dose,
  required final String unit,
  required final bool canRemove,
  required final VoidCallback onChanged,
  required final VoidCallback onPickClockTime,
  required final VoidCallback onRemove,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ECard(
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: dose.amount,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: EText.body.medium,
              decoration: ScheduleFormFields.decoration(hint: '200'),
              onChanged: (_) => onChanged(),
            ),
          ),
          HSpace.s,
          Text(unit),
          HSpace.m,
          TextButton(
            onPressed: onPickClockTime,
            child: Text(dose.when.caption),
          ),
          if (canRemove)
            IconButton(
              tooltip: 'Remove time',
              onPressed: onRemove,
              icon: const Icon(Icons.delete_outline, color: EColors.danger),
            ),
        ],
      ),
    );
  }
}
