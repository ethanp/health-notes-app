import 'package:ethan_ui/ethan_ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_notes/models/health_tool_category.dart';
import 'package:health_notes/providers/health_tools_provider.dart';
import 'package:health_notes/theme/app_theme.dart';
import 'package:health_notes/widgets/color_picker_grid.dart';
import 'package:health_notes/widgets/health_notes_page.dart';
import 'package:health_notes/theme/spacing.dart';

class const HealthToolCategoryForm({
  final HealthToolCategory? category,
  required final String title,
  required final String saveButtonText,
  final Function()? onCancel,
  final Function()? onSuccess,
}) extends ConsumerStatefulWidget {
  @override
  ConsumerState<HealthToolCategoryForm> createState() =>
      _HealthToolCategoryFormState();
}

class _HealthToolCategoryFormState()
    extends ConsumerState<HealthToolCategoryForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  late String _selectedIcon;
  late String _selectedColor;
  late Color _selectedColorValue;
  bool _isLoading = false;

  static const List<Map<String, String>> availableIcons = [
    {'name': 'Allergies', 'value': 'allergies'},
    {'name': 'Anxiety', 'value': 'anxiety'},
    {'name': 'Nausea', 'value': 'nausea'},
    {'name': 'Cold', 'value': 'cold'},
    {'name': 'Flu', 'value': 'flu'},
    {'name': 'Travel', 'value': 'travel'},
    {'name': 'Car Travel', 'value': 'car_travel'},
    {'name': 'Plane Travel', 'value': 'plane_travel'},
    {'name': 'General', 'value': 'general'},
  ];

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.category?.name ?? '';
    _descriptionController.text = widget.category?.description ?? '';
    _selectedIcon = widget.category?.iconName ?? 'general';
    _selectedColor = widget.category?.colorHex ?? '#007AFF';
    _selectedColorValue = _parseColor(_selectedColor);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return HealthNotesPage(
      title: widget.title,
      leading: TextButton(
        onPressed: widget.onCancel ?? () => Navigator.of(context).pop(),
        child: const Text('Cancel'),
      ),
      actions: [
        if (_isLoading)
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        else
          TextButton(
            onPressed: saveCategory,
            child: Text(widget.saveButtonText),
          ),
      ],
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.m),
          children: [
            nameSection(),
            VSpace.m,
            descriptionSection(),
            VSpace.m,
            iconSection(),
            VSpace.m,
            colorSection(),
          ],
        ),
      ),
    );
  }

  Widget nameSection() {
    return ECard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Category Name', style: EText.headline.small),
          VSpace.m,
          CupertinoTextField(
            controller: _nameController,
            placeholder: 'Enter category name',
            style: EText.body.medium,
            decoration: AppComponents.inputField,
            padding: const EdgeInsets.all(AppSpacing.sm),
          ),
        ],
      ),
    );
  }

  Widget descriptionSection() {
    return ECard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Description', style: EText.headline.small),
          VSpace.s,
          Text(
            'Describe what this category is for',
            style: EText.body.medium.tertiary,
          ),
          VSpace.m,
          CupertinoTextField(
            controller: _descriptionController,
            placeholder: 'Enter description...',
            style: EText.body.medium,
            decoration: AppComponents.inputField,
            padding: const EdgeInsets.all(AppSpacing.sm),
            maxLines: 3,
            minLines: 2,
          ),
        ],
      ),
    );
  }

  Widget iconSection() {
    return ECard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Icon', style: EText.headline.small),
          VSpace.m,
          iconChoices(),
        ],
      ),
    );
  }

  Widget iconChoices() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: availableIcons.map((icon) {
        final isSelected = _selectedIcon == icon['value'];
        return GestureDetector(
          onTap: () => setState(() => _selectedIcon = icon['value']!),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.s,
            ),
            decoration: BoxDecoration(
              color: isSelected ? EColors.accent : EColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? EColors.accent : EColors.surface,
              ),
            ),
            child: Text(
              icon['name']!,
              style: EText.body.small.copyWith(
                color: isSelected ? CupertinoColors.white : EColors.textPrimary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget colorSection() {
    return ECard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Color', style: EText.headline.small),
          VSpace.m,
          colorChoices(),
        ],
      ),
    );
  }

  Widget colorChoices() {
    return ColorPickerGrid(
      colors: ColorPickerGrid.systemColors,
      selectedColor: _selectedColorValue,
      onColorSelected: (color) => setState(() {
        _selectedColorValue = color;
        _selectedColor = _colorToHex(color);
      }),
    );
  }

  Color _parseColor(String colorHex) {
    final parsed = int.tryParse(colorHex.replaceAll('#', '0xFF'));
    return parsed != null ? Color(parsed) : EColors.accent;
  }

  String _colorToHex(Color color) {
    return '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
  }

  Future<void> saveCategory() async {
    if (!_formKey.currentState!.validate()) return;
    if (_nameController.text.trim().isEmpty) return;
    if (_descriptionController.text.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final category = _composeCategory();

      if (widget.category != null) {
        await ref
            .read(healthToolCategoriesProvider.notifier)
            .updateCategory(category);
      } else {
        await ref
            .read(healthToolCategoriesProvider.notifier)
            .addCategory(category);
      }

      if (mounted) {
        widget.onSuccess?.call();
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: Text('Failed to save category: $e'),
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
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  HealthToolCategory _composeCategory() {
    final base = widget.category;
    if (base != null) {
      return base.copyWith(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        iconName: _selectedIcon,
        colorHex: _selectedColor,
      );
    }
    return HealthToolCategory(
      id: '',
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      iconName: _selectedIcon,
      colorHex: _selectedColor,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}
