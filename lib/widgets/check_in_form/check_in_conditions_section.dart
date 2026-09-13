import 'package:ethan_ui/ethan_ui.dart';
import 'package:flutter/material.dart';
import 'package:health_notes/models/condition_entry.dart';
import 'package:health_notes/screens/condition_form.dart';
import 'package:health_notes/theme/app_theme.dart';
import 'package:health_notes/ui/condition_appearance.dart';
import 'package:health_notes/utils/symptom_severity.dart';
import 'package:health_notes/theme/spacing.dart';

class const CheckInConditionsSection({
  required final bool conditionsLoaded,
  required final List<ConditionEntryDraft> conditionDrafts,
  required final VoidCallback onAddCondition,
  required final void Function(int index) onConditionRemoved,
  required final VoidCallback onDraftChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ECard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(),
          VSpace.s,
          Text(
            'Log entries for active conditions',
            style: EText.body.small.tertiary,
          ),
          VSpace.m,
          if (!conditionsLoaded)
            const Center(child: CircularProgressIndicator())
          else if (conditionDrafts.isEmpty)
            const CheckInNoConditionsMessage()
          else
            ...conditionDrafts.asMap().entries.map(
              (entry) => CheckInConditionEntryCard(
                draft: entry.value,
                onRemoved: () => onConditionRemoved(entry.key),
                onDraftChanged: onDraftChanged,
              ),
            ),
        ],
      ),
    );
  }

  Widget _header() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Active Conditions', style: EText.headline.small),
        TextButton.icon(
          onPressed: onAddCondition,
          icon: const Icon(Icons.add, size: 18),
          label: Text('Add', style: EText.body.medium.semibold.accent),
        ),
      ],
    );
  }

  static Future<void> showAddConditionOptions({
    required BuildContext context,
    required Future<void> Function() onAfterConditionCreated,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Create New Condition'),
              onTap: () async {
                Navigator.of(sheetContext).pop();
                await Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const ConditionForm(),
                  ),
                );
                await onAfterConditionCreated();
              },
            ),
            ListTile(
              title: const Text('Cancel'),
              onTap: () => Navigator.of(sheetContext).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

class const CheckInNoConditionsMessage() extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: EColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.small),
      ),
      child: Center(
        child: Text(
          'No active conditions to log',
          style: EText.body.medium.muted,
        ),
      ),
    );
  }
}

class const CheckInConditionEntryCard({
  required final ConditionEntryDraft draft,
  required final VoidCallback onRemoved,
  required final VoidCallback onDraftChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: EColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.small),
        border: Border.all(
          color: draft.color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(),
          VSpace.m,
          _severitySlider(),
          VSpace.m,
          _phasePicker(),
          VSpace.m,
          _notesField(),
          VSpace.m,
          _resolveToggle(),
        ],
      ),
    );
  }

  Widget _header() {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: AppComponents.tintedSolidDecoration(
            draft.color,
            radius: 14,
            borderWidth: 0,
          ),
          child: Icon(
            Icons.healing,
            size: 14,
            color: draft.color,
          ),
        ),
        HSpace.s,
        Expanded(
          child: Text(draft.conditionName, style: EText.label.large.primary),
        ),
        IconButton(
          tooltip: 'Remove condition',
          onPressed: onRemoved,
          icon: Icon(
            Icons.cancel,
            color: EColors.danger.withValues(alpha: 0.7),
            size: 20,
          ),
        ),
      ],
    );
  }

  Widget _severitySlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Severity', style: EText.label.medium),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: SymptomSeverity.fourBucketGreenYellowOrangeRed(
                  draft.severity,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${draft.severity}/10',
                style: EText.label.small.copyWith(color: Colors.white),
              ),
            ),
          ],
        ),
        VSpace.xs,
        Slider(
          value: draft.severity.toDouble(),
          min: 1,
          max: 10,
          divisions: 9,
          activeColor: SymptomSeverity.fourBucketGreenYellowOrangeRed(
            draft.severity,
          ),
          onChanged: (value) {
            draft.severity = value.round();
            onDraftChanged();
          },
        ),
      ],
    );
  }

  Widget _phasePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Phase', style: EText.label.medium),
        VSpace.xs,
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: ConditionPhase.values.map((phase) {
            final isSelected = draft.phase == phase;
            return GestureDetector(
              onTap: () {
                draft.phase = phase;
                onDraftChanged();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.s,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? phase.color.withValues(alpha: 0.2)
                      : EColors.surfaceRaised,
                  borderRadius: BorderRadius.circular(AppRadius.large),
                  border: Border.all(
                    color: isSelected ? phase.color : EColors.borderStrong,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Text(
                  phase.displayName,
                  style: EText.caption.copyWith(
                    color: isSelected ? phase.color : EColors.textSecondary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _notesField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Notes', style: EText.label.medium),
        VSpace.xs,
        TextField(
          maxLines: 2,
          style: EText.body.small,
          onChanged: (value) => draft.notes = value,
          decoration: InputDecoration(
            hintText: 'Optional notes for this condition...',
            hintStyle: EText.body.medium.muted.size(13),
            filled: true,
            fillColor: EColors.surfaceRaised,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.small),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _resolveToggle() {
    return Row(
      children: [
        Switch(
          value: draft.markResolved,
          onChanged: (value) {
            draft.markResolved = value;
            onDraftChanged();
          },
          activeThumbColor: EColors.success,
        ),
        HSpace.s,
        Expanded(
          child: Text(
            'Mark as resolved after this entry',
            style: EText.body.small.secondary,
          ),
        ),
      ],
    );
  }
}
