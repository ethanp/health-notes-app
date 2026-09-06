import 'package:ethan_ui/ethan_ui.dart';
import 'package:flutter/material.dart';
import 'package:health_notes/models/condition_entry.dart';
import 'package:health_notes/theme/app_theme.dart';
import 'package:health_notes/theme/spacing.dart';
import 'package:health_notes/utils/symptom_severity.dart';
import 'package:intl/intl.dart';

class const ConditionEntryEditModal({
  required final ConditionEntry entry,
  required final Future<void> Function(ConditionEntry updatedEntry) onSave,
}) extends StatefulWidget {
  @override
  State<ConditionEntryEditModal> createState() =>
      _ConditionEntryEditModalState();
}

class _ConditionEntryEditModalState() extends State<ConditionEntryEditModal> {
  late int severity;
  late ConditionPhase phase;
  late TextEditingController notesController;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    severity = widget.entry.severity;
    phase = widget.entry.phase;
    notesController = TextEditingController(text: widget.entry.notes);
  }

  @override
  void dispose() {
    notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: EColors.backgroundLift,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            modalHeader(),
            VSpace.l,
            severitySlider(),
            VSpace.l,
            phasePicker(),
            VSpace.l,
            notesField(),
            VSpace.l,
            saveButton(),
          ],
        ),
      ),
    );
  }

  Widget modalHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Edit Entry', style: EText.headline.small),
            VSpace.xs,
            Text(
              DateFormat('EEEE, MMMM d, y').format(widget.entry.entryDate),
              style: EText.body.small.tertiary,
            ),
          ],
        ),
        IconButton(
          tooltip: 'Close',
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(Icons.cancel, color: EColors.textMuted, size: 28),
        ),
      ],
    );
  }

  Widget severitySlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Severity', style: EText.label.medium),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: SymptomSeverity.fourBucketGreenYellowOrangeRed(severity),
                borderRadius: BorderRadius.circular(AppRadius.medium),
              ),
              child: Text('$severity/10', style: EText.label.medium.white),
            ),
          ],
        ),
        VSpace.m,
        Slider(
          value: severity.toDouble(),
          min: 1,
          max: 10,
          divisions: 9,
          activeColor: SymptomSeverity.fourBucketGreenYellowOrangeRed(severity),
          onChanged: (value) => setState(() => severity = value.round()),
        ),
        VSpace.xs,
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Mild', style: EText.caption.quaternary),
            Text('Severe', style: EText.caption.quaternary),
          ],
        ),
      ],
    );
  }

  Widget phasePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Phase', style: EText.label.medium),
        VSpace.s,
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ConditionPhase.values.map((p) => phaseChip(p)).toList(),
        ),
      ],
    );
  }

  Widget phaseChip(ConditionPhase p) {
    final isSelected = phase == p;
    return GestureDetector(
      onTap: () => setState(() => phase = p),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? p.color.withValues(alpha: 0.2) : EColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? p.color : EColors.surfaceRaised,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          p.displayName,
          style: EText.label.medium.copyWith(
            color: isSelected ? p.color : EColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget notesField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Notes', style: EText.label.medium),
        VSpace.s,
        TextField(
          controller: notesController,
          maxLines: 3,
          style: EText.body.medium,
          decoration: InputDecoration(
            hintText: 'Optional notes for this entry...',
            hintStyle: EText.body.medium.muted,
            filled: true,
            fillColor: EColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.small),
              borderSide: const BorderSide(color: EColors.surfaceRaised),
            ),
          ),
        ),
      ],
    );
  }

  Widget saveButton() {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: isSaving ? null : saveEntry,
        child: isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text('Save Changes'),
      ),
    );
  }

  Future<void> saveEntry() async {
    setState(() => isSaving = true);

    try {
      final updatedEntry = widget.entry.copyWith(
        severity: severity,
        phase: phase,
        notes: notesController.text.trim(),
        updatedAt: DateTime.now(),
      );
      await widget.onSave(updatedEntry);
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: Text('Failed to save entry: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }
}
