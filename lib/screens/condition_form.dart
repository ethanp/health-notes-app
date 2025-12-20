import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_notes/models/condition.dart';
import 'package:health_notes/providers/conditions_provider.dart';
import 'package:health_notes/theme/app_theme.dart';
import 'package:health_notes/widgets/enhanced_ui_components.dart';
import 'package:health_notes/widgets/spacing.dart';
import 'package:intl/intl.dart';

class ConditionForm extends ConsumerStatefulWidget {
  final Condition? condition;
  final String title;
  final String saveButtonText;

  const ConditionForm({
    this.condition,
    this.title = 'New Condition',
    this.saveButtonText = 'Save',
  });

  @override
  ConsumerState<ConditionForm> createState() => _ConditionFormState();
}

class _ConditionFormState extends ConsumerState<ConditionForm> {
  late TextEditingController nameController;
  late TextEditingController notesController;
  late DateTime startDate;
  late int selectedColorValue;
  late int selectedIconCodePoint;

  bool get isEditing => widget.condition != null;
  bool isSaving = false;

  static const List<int> availableColors = [
    0xFFE57373, // Red
    0xFFFFB74D, // Orange
    0xFFFFF176, // Yellow
    0xFF81C784, // Green
    0xFF64B5F6, // Blue
    0xFF9575CD, // Purple
    0xFFBA68C8, // Pink
    0xFF4DB6AC, // Teal
  ];

  static final List<IconData> availableIcons = [
    CupertinoIcons.bandage,
    CupertinoIcons.heart_fill,
    CupertinoIcons.bolt_fill,
    CupertinoIcons.flame_fill,
    CupertinoIcons.drop_fill,
    CupertinoIcons.moon_fill,
    CupertinoIcons.sun_max_fill,
    CupertinoIcons.thermometer,
    CupertinoIcons.bed_double_fill,
    CupertinoIcons.eye,
    CupertinoIcons.ear,
    CupertinoIcons.hand_raised_fill,
  ];

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.condition?.name ?? '');
    notesController = TextEditingController(text: widget.condition?.notes ?? '');
    startDate = widget.condition?.startDate ?? DateTime.now();
    selectedColorValue = widget.condition?.colorValue ?? availableColors.first;
    selectedIconCodePoint = widget.condition?.iconCodePoint ?? availableIcons.first.codePoint;
  }

  @override
  void dispose() {
    nameController.dispose();
    notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: EnhancedUIComponents.navigationBar(
        title: widget.title,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: isSaving ? null : saveCondition,
          child: isSaving
              ? const CupertinoActivityIndicator()
              : Text(widget.saveButtonText),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
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
      ),
    );
  }

  Widget nameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Condition Name', style: AppTypography.labelMedium),
        VSpace.s,
        CupertinoTextField(
          controller: nameController,
          placeholder: 'e.g., Cold, Migraine, Flare-up',
          padding: const EdgeInsets.all(16),
          decoration: AppComponents.inputField,
          style: AppTypography.input,
          placeholderStyle: AppTypography.inputPlaceholder,
        ),
      ],
    );
  }

  Widget startDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Start Date', style: AppTypography.labelMedium),
        VSpace.s,
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: showDatePicker,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: AppComponents.inputField,
            child: Row(
              children: [
                Icon(CupertinoIcons.calendar, color: AppColors.textSecondary, size: 20),
                HSpace.m,
                Text(
                  DateFormat('EEEE, MMMM d, y').format(startDate),
                  style: AppTypography.bodyMedium,
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
        Text('Color', style: AppTypography.labelMedium),
        VSpace.s,
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: availableColors.map((colorValue) {
            final isSelected = colorValue == selectedColorValue;
            return GestureDetector(
              onTap: () => setState(() => selectedColorValue = colorValue),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Color(colorValue),
                  shape: BoxShape.circle,
                  border: isSelected
                      ? Border.all(color: CupertinoColors.white, width: 3)
                      : null,
                  boxShadow: isSelected ? AppComponents.mediumShadow : null,
                ),
                child: isSelected
                    ? const Icon(CupertinoIcons.checkmark, color: CupertinoColors.white, size: 20)
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget iconPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Icon', style: AppTypography.labelMedium),
        VSpace.s,
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: availableIcons.map((icon) {
            final isSelected = icon.codePoint == selectedIconCodePoint;
            return GestureDetector(
              onTap: () => setState(() => selectedIconCodePoint = icon.codePoint),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isSelected
                      ? Color(selectedColorValue).withValues(alpha: 0.2)
                      : AppColors.backgroundTertiary,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? Color(selectedColorValue)
                        : AppColors.backgroundQuaternary,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Icon(
                  icon,
                  color: isSelected ? Color(selectedColorValue) : AppColors.textSecondary,
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
        Text('Notes', style: AppTypography.labelMedium),
        VSpace.s,
        CupertinoTextField(
          controller: notesController,
          placeholder: 'Optional notes about this condition...',
          padding: const EdgeInsets.all(16),
          decoration: AppComponents.inputField,
          style: AppTypography.input,
          placeholderStyle: AppTypography.inputPlaceholder,
          maxLines: 4,
        ),
      ],
    );
  }

  void showDatePicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 300,
        color: AppColors.backgroundSecondary,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                CupertinoButton(
                  child: const Text('Done'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: startDate,
                maximumDate: DateTime.now(),
                onDateTimeChanged: (date) => setState(() => startDate = date),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> saveCondition() async {
    final name = nameController.text.trim();
    if (name.isEmpty) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Name Required'),
          content: const Text('Please enter a name for the condition.'),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
      return;
    }

    final existingCondition = await ref
        .read(conditionsNotifierProvider.notifier)
        .getActiveConditionByName(name);
    
    if (existingCondition != null && (!isEditing || existingCondition.id != widget.condition!.id)) {
      if (!mounted) return;
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Condition Already Exists'),
          content: Text('An active condition named "$name" already exists.'),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
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
        await ref.read(conditionsNotifierProvider.notifier).updateCondition(updated);
      } else {
        await ref.read(conditionsNotifierProvider.notifier).addCondition(
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
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: Text('Failed to save condition: $e'),
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

