import 'package:ethan_ui/ethan_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_notes/models/condition.dart';
import 'package:health_notes/providers/conditions_provider.dart';
import 'package:health_notes/theme/app_theme.dart';
import 'package:health_notes/widgets/color_picker_grid.dart';
import 'package:health_notes/widgets/health_notes_page.dart';
import 'package:health_notes/theme/spacing.dart';
import 'package:intl/intl.dart';

class const ConditionForm({
  final Condition? condition,
  final String title = 'New Condition',
  final String saveButtonText = 'Save',
}) extends ConsumerStatefulWidget {
  @override
  ConsumerState<ConditionForm> createState() => _ConditionFormState();
}

class _ConditionFormState() extends ConsumerState<ConditionForm> {
  late TextEditingController nameController;
  late TextEditingController notesController;
  late DateTime startDate;
  late int selectedColorValue;
  late int selectedIconCodePoint;

  bool get isEditing => widget.condition != null;
  bool isSaving = false;

  static final List<IconData> availableIcons = [
    Icons.healing,
    Icons.favorite,
    Icons.bolt,
    Icons.local_fire_department,
    Icons.water_drop,
    Icons.nightlight_round,
    Icons.wb_sunny,
    Icons.thermostat,
    Icons.bed,
    Icons.visibility,
    Icons.hearing,
    Icons.front_hand,
  ];

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.condition?.name ?? '');
    notesController = TextEditingController(
      text: widget.condition?.notes ?? '',
    );
    startDate = widget.condition?.startDate ?? DateTime.now();
    selectedColorValue =
        widget.condition?.colorValue ??
        ColorPickerGrid.defaultColors.first.toARGB32();
    selectedIconCodePoint =
        widget.condition?.iconCodePoint ?? availableIcons.first.codePoint;
  }

  @override
  void dispose() {
    nameController.dispose();
    notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return HealthNotesPage(
      title: widget.title,
      leading: TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancel'),
      ),
      actions: [
        if (isSaving)
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        else
          TextButton(
            onPressed: saveCondition,
            child: Text(widget.saveButtonText),
          ),
      ],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.m).withOverlaidTabBar(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            nameField(),
            VSpace.l,
            startDateField(),
            VSpace.l,
            colorPicker(),
            VSpace.l,
            iconPicker(),
            VSpace.l,
            notesField(),
          ],
        ),
      ),
    );
  }

  Widget nameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Condition Name', style: EText.label.medium),
        VSpace.s,
        TextField(
          controller: nameController,
          style: EText.body.medium,
          decoration: InputDecoration(
            hintText: 'e.g., Cold, Migraine, Flare-up',
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

  Widget startDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Start Date', style: EText.label.medium),
        VSpace.s,
        InkWell(
          onTap: pickStartDate,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.m),
            decoration: AppComponents.inputField,
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: EColors.textSecondary,
                  size: 20,
                ),
                HSpace.m,
                Text(
                  DateFormat('EEEE, MMMM d, y').format(startDate),
                  style: EText.body.medium,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget colorPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Color', style: EText.label.medium),
        VSpace.s,
        ColorPickerGrid(
          colors: ColorPickerGrid.defaultColors,
          selectedColor: Color(selectedColorValue),
          onColorSelected: (color) =>
              setState(() => selectedColorValue = color.toARGB32()),
        ),
      ],
    );
  }

  Widget iconPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Icon', style: EText.label.medium),
        VSpace.s,
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: availableIcons.map((icon) {
            final isSelected = icon.codePoint == selectedIconCodePoint;
            return GestureDetector(
              onTap: () =>
                  setState(() => selectedIconCodePoint = icon.codePoint),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isSelected
                      ? Color(selectedColorValue).withValues(alpha: 0.2)
                      : EColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.medium),
                  border: Border.all(
                    color: isSelected
                        ? Color(selectedColorValue)
                        : EColors.surfaceRaised,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Icon(
                  icon,
                  color: isSelected
                      ? Color(selectedColorValue)
                      : EColors.textSecondary,
                  size: 24,
                ),
              ),
            );
          }).toList(),
        ),
      ],
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
          maxLines: 4,
          style: EText.body.medium,
          decoration: InputDecoration(
            hintText: 'Optional notes about this condition...',
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

  Future<void> pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked == null) return;
    setState(() => startDate = picked);
  }

  Future<void> saveCondition() async {
    final name = nameController.text.trim();
    if (name.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Name Required'),
          content: const Text('Please enter a name for the condition.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    final existingCondition = await ref
        .read(conditionsProvider.notifier)
        .getActiveConditionByName(name);

    if (existingCondition != null &&
        (!isEditing || existingCondition.id != widget.condition!.id)) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Condition Already Exists'),
          content: Text('An active condition named "$name" already exists.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    setState(() => isSaving = true);

    try {
      if (isEditing) {
        final updated = widget.condition!.copyWith(
          name: name,
          startDate: startDate,
          colorValue: selectedColorValue,
          iconCodePoint: selectedIconCodePoint,
          notes: notesController.text.trim(),
          updatedAt: DateTime.now(),
        );
        await ref.read(conditionsProvider.notifier).updateCondition(updated);
      } else {
        await ref
            .read(conditionsProvider.notifier)
            .addCondition(
              name: name,
              startDate: startDate,
              colorValue: selectedColorValue,
              iconCodePoint: selectedIconCodePoint,
              notes: notesController.text.trim(),
            );
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: Text('Failed to save condition: $e'),
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
