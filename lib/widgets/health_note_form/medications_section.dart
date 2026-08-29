import 'package:ethan_ui/ethan_ui.dart';
import 'package:ethan_utils/ethan_utils.dart';
import 'package:flutter/material.dart';
import 'package:health_notes/models/drug_dose.dart';
import 'package:health_notes/models/drug_name.dart';
import 'package:health_notes/models/medication_schedule.dart';
import 'package:health_notes/theme/app_theme.dart';
import 'package:health_notes/theme/spacing.dart';
import 'package:health_notes/utils/number_formatter.dart';
import 'package:health_notes/widgets/form_section_container.dart';
import 'package:health_notes/widgets/health_note_form/form_controllers.dart';
import 'package:health_notes/widgets/medication_schedule/due_dose_chip.dart';
import 'package:health_notes/widgets/medication_suggestion_chips.dart';
import 'package:health_notes/widgets/note_summary_rows.dart';

class MedicationsSection extends StatelessWidget {
  final bool isEditable;
  final List<DrugDose> drugDoses;
  final Map<int, DrugDoseControllers> controllers;
  final VoidCallback onAdd;
  final Function(int) onRemove;
  final Function(int, {DrugName? name, double? dosage, String? unit}) onUpdate;
  final List<ScheduledDoseOccurrence> dueOccurrences;
  final ScheduledDoseOccurrence? nearestDue;
  final ValueChanged<ScheduledDoseOccurrence>? onDueActivated;
  final VoidCallback? onManageSchedules;
  final bool hasSchedules;

  const MedicationsSection({
    required this.isEditable,
    required this.drugDoses,
    required this.controllers,
    required this.onAdd,
    required this.onRemove,
    required this.onUpdate,
    this.dueOccurrences = const [],
    this.nearestDue,
    this.onDueActivated,
    this.onManageSchedules,
    this.hasSchedules = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: FormSectionContainer(
        isEditable: isEditable,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [_header(), VSpace.s, _content(context)],
        ),
      ),
    );
  }

  Widget _header() {
    return ESectionHeader(
      title: 'Medications',
      trailing: isEditable
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Medication schedules',
                  onPressed: onManageSchedules,
                  icon: const Icon(Icons.calendar_month_outlined),
                ),
                IconButton(
                  tooltip: 'Add medication',
                  onPressed: onAdd,
                  icon: const Icon(Icons.add),
                ),
              ],
            )
          : null,
    );
  }

  Widget _content(BuildContext context) {
    if (!isEditable) {
      if (drugDoses.isEmpty) {
        return Text('No medications recorded', style: EText.body.medium);
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: drugDoses.mapL((dose) => MedicationSummaryRow(dose: dose)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (dueOccurrences.isNotEmpty) ...[_dueToday(), VSpace.m],
        if (drugDoses.isEmpty && dueOccurrences.isEmpty) _emptyEditable(),
        ...drugDoses.asMap().entries.map((entry) {
          final index = entry.key;
          return _editableItem(index, entry.value, controllers[index]!);
        }),
      ],
    );
  }

  Widget _emptyEditable() {
    if (!hasSchedules) {
      return TextButton(
        onPressed: onManageSchedules,
        child: const Text('Set up a schedule'),
      );
    }
    return Text('No medications recorded', style: EText.body.medium);
  }

  Widget _dueToday() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Due today', style: EText.label.large.size(12)),
        VSpace.s,
        Wrap(
          spacing: 8,
          runSpacing: 16,
          children: dueOccurrences.mapL(
            (occurrence) => DueDoseChip(
              occurrence: occurrence,
              isNearest: nearestDue?.scheduledDoseId == occurrence.scheduledDoseId &&
                  nearestDue?.scheduleId == occurrence.scheduleId,
              onActivated: () => onDueActivated?.call(occurrence),
            ),
          ),
        ),
      ],
    );
  }

  Widget _editableItem(
    int index,
    DrugDose dose,
    DrugDoseControllers doseControllers,
  ) {
    return ECard(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: doseControllers.name,
                  style: EText.body.medium,
                  decoration: _inputDecoration(hint: 'Medication name'),
                  onChanged: (value) => onUpdate(index, name: DrugName(value)),
                ),
              ),
              HSpace.s,
              IconButton(
                tooltip: 'Remove medication',
                onPressed: () => onRemove(index),
                icon: const Icon(Icons.delete_outline, color: EColors.danger),
              ),
            ],
          ),
          VSpace.s,
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: doseControllers.dosage,
                  style: EText.body.medium,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration(hint: 'Dosage'),
                  onChanged: (value) {
                    final dosage = double.tryParse(value) ?? 0.0;
                    onUpdate(index, dosage: dosage);
                  },
                ),
              ),
              HSpace.s,
              SizedBox(
                width: 80,
                child: TextField(
                  controller: doseControllers.unit,
                  style: EText.body.medium,
                  decoration: _inputDecoration(hint: 'Unit'),
                  onChanged: (value) => onUpdate(index, unit: value),
                ),
              ),
            ],
          ),
          MedicationDoseSuggestionChips(
            typedName: dose.name.display,
            onDoseSelected: (recommendation) =>
                _applySuggestedDose(index, recommendation),
          ),
        ],
      ),
    );
  }

  void _applySuggestedDose(int index, DrugDose recommendation) {
    onUpdate(
      index,
      name: recommendation.name,
      dosage: recommendation.dosage,
      unit: recommendation.unit,
    );
    controllers[index]?.name.text = recommendation.name.display;
    controllers[index]?.dosage.text = formatDecimalValue(
      recommendation.dosage,
    );
    controllers[index]?.unit.text = recommendation.unit;
  }

  InputDecoration _inputDecoration({required String hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: EText.body.medium.muted,
      filled: true,
      fillColor: EColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.small),
        borderSide: const BorderSide(color: EColors.surfaceRaised),
      ),
    );
  }
}
