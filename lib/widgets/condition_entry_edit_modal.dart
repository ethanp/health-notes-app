import 'package:flutter/cupertino.dart';
import 'package:health_notes/models/condition_entry.dart';
import 'package:health_notes/theme/app_theme.dart';
import 'package:health_notes/theme/spacing.dart';
import 'package:intl/intl.dart';

class ConditionEntryEditModal extends StatefulWidget {
  final ConditionEntry entry;
  final Future<void> Function(ConditionEntry updatedEntry) onSave;

  const ConditionEntryEditModal({
    super.key,
    required this.entry,
    required this.onSave,
  });

  @override
  State<ConditionEntryEditModal> createState() => _ConditionEntryEditModalState();
}

class _ConditionEntryEditModalState extends State<ConditionEntryEditModal> {
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
        color: AppColors.backgroundSecondary,
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
            Text('Edit Entry', style: AppTypography.headlineSmall),
            VSpace.xs,
            Text(
              DateFormat('EEEE, MMMM d, y').format(widget.entry.entryDate),
              style: AppTypography.bodySmallTertiary,
            ),
          ],
        ),
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).pop(),
          child: Icon(
            CupertinoIcons.xmark_circle_fill,
            color: AppColors.textQuaternary,
            size: 28,
          ),
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
            Text('Severity', style: AppTypography.labelMedium),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: severityColor(severity),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$severity/10',
                style: AppTypography.labelMediumWhite,
              ),
            ),
          ],
        ),
        VSpace.m,
        CupertinoSlider(
          value: severity.toDouble(),
          min: 1,
          max: 10,
          divisions: 9,
          activeColor: severityColor(severity),
          onChanged: (value) => setState(() => severity = value.round()),
        ),
        VSpace.xs,
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Mild', style: AppTypography.captionSecondary),
            Text('Severe', style: AppTypography.captionSecondary),
          ],
        ),
      ],
    );
  }

  Widget phasePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Phase', style: AppTypography.labelMedium),
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
          color: isSelected ? p.color.withValues(alpha: 0.2) : AppColors.backgroundTertiary,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? p.color : AppColors.backgroundQuaternary,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          p.displayName,
          style: AppTypography.labelMedium.copyWith(
            color: isSelected ? p.color : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget notesField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Notes', style: AppTypography.labelMedium),
        VSpace.s,
        CupertinoTextField(
          controller: notesController,
          placeholder: 'Optional notes for this entry...',
          padding: const EdgeInsets.all(12),
          decoration: AppComponents.inputField,
          style: AppTypography.input,
          placeholderStyle: AppTypography.inputPlaceholder,
          maxLines: 3,
        ),
      ],
    );
  }

  Widget saveButton() {
    return SizedBox(
      width: double.infinity,
      child: CupertinoButton(
        color: AppColors.primary,
        onPressed: isSaving ? null : saveEntry,
        child: isSaving
            ? const CupertinoActivityIndicator(color: CupertinoColors.white)
            : const Text('Save Changes'),
      ),
    );
  }

  Color severityColor(int severity) {
    if (severity <= 3) return CupertinoColors.systemGreen;
    if (severity <= 5) return CupertinoColors.systemYellow;
    if (severity <= 7) return CupertinoColors.systemOrange;
    return CupertinoColors.systemRed;
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
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: Text('Failed to save entry: $e'),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
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

