import 'package:ethan_ui/ethan_ui.dart';
import 'package:flutter/material.dart';
import 'package:health_notes/models/medication_schedule.dart';
import 'package:health_notes/theme/app_theme.dart';
import 'package:health_notes/theme/spacing.dart';

import 'schedule_form_fields.dart';
import 'schedule_step_draft.dart';

class const TaperScheduleEditor({
  required final List<ScheduleStepDraft> steps,
  required final String unit,
  required final VoidCallback onChanged,
  required final VoidCallback onAddStep,
  required final ValueChanged<int> onRemoveStep,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final stepIndex in steps.asMap().keys) ...[
          if (stepIndex > 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
              child: Text('then', style: EText.label.medium.tertiary),
            ),
          TaperStepCard(
            step: steps[stepIndex],
            unit: unit,
            canRemove: steps.length > 1,
            onChanged: onChanged,
            onRemove: () => onRemoveStep(stepIndex),
          ),
        ],
        VSpace.m,
        OutlinedButton(onPressed: onAddStep, child: const Text('Then')),
      ],
    );
  }
}

class const TaperStepCard({
  required final ScheduleStepDraft step,
  required final String unit,
  required final bool canRemove,
  required final VoidCallback onChanged,
  required final VoidCallback onRemove,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final dose = step.doses.first;
    return ECard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: dose.amount,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: EText.body.medium,
                  decoration: ScheduleFormFields.decoration(hint: '40'),
                  onChanged: (_) => onChanged(),
                ),
              ),
              HSpace.s,
              Text(unit),
              HSpace.m,
              const Text('for'),
              HSpace.s,
              SizedBox(
                width: 64,
                child: TextField(
                  controller: step.duration,
                  keyboardType: TextInputType.number,
                  style: EText.body.medium,
                  decoration: ScheduleFormFields.decoration(hint: '7'),
                  onChanged: (_) => onChanged(),
                ),
              ),
            ],
          ),
          VSpace.s,
          PartOfDayChoices(dose: dose, onChanged: onChanged),
          if (canRemove)
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                tooltip: 'Remove step',
                onPressed: onRemove,
                icon: const Icon(Icons.delete_outline, color: EColors.danger),
              ),
            ),
        ],
      ),
    );
  }
}

class const PartOfDayChoices({
  required final ScheduleDoseDraft dose,
  required final VoidCallback onChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: PartOfDay.values.map((part) {
        final isSelected =
            dose.when is PartOfDayDoseWhen &&
            (dose.when as PartOfDayDoseWhen).part == part;
        return FilterChip(
          label: Text(
            part.pluralLabel,
            style: isSelected ? EText.label.medium : EText.label.medium.white,
          ),
          selected: isSelected,
          backgroundColor: EColors.surfaceRaised,
          selectedColor: EColors.accentGlow.withValues(alpha: 0.35),
          onSelected: (_) {
            dose.when = DoseWhen.partOfDay(part);
            onChanged();
          },
        );
      }).toList(),
    );
  }
}
