import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_notes/models/health_tool_category.dart';
import 'package:health_notes/providers/health_tools_provider.dart';
import 'package:health_notes/theme/app_theme.dart';

class HealthToolCategoryForm extends ConsumerStatefulWidget {
  final HealthToolCategory? category;
  final String title;
  final String saveButtonText;
  final Function()? onCancel;
  final Function()? onSuccess;

  const HealthToolCategoryForm({
    this.category,
    required this.title,
    required this.saveButtonText,
    this.onCancel,
    this.onSuccess,
  });

  @override
  ConsumerState<HealthToolCategoryForm> createState() =>
      _HealthToolCategoryFormState();
}

class _HealthToolCategoryFormState
    extends ConsumerState<HealthToolCategoryForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  late String _selectedIcon;
  late String _selectedColor;
  bool _isLoading = false;

  // Predefined icons and colors
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

  static const List<Map<String, String>> availableColors = [
    {'name': 'Blue', 'value': '#007AFF'},
    {'name': 'Green', 'value': '#34C759'},
    {'name': 'Orange', 'value': '#FF9500'},
    {'name': 'Red', 'value': '#FF3B30'},
    {'name': 'Purple', 'value': '#AF52DE'},
    {'name': 'Pink', 'value': '#FF2D92'},
    {'name': 'Yellow', 'value': '#FFCC00'},
    {'name': 'Teal', 'value': '#5AC8FA'},
  ];

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.category?.name ?? '';
    _descriptionController.text = widget.category?.description ?? '';
    _selectedIcon = widget.category?.iconName ?? 'general';
    _selectedColor = widget.category?.colorHex ?? '#007AFF';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(widget.title, style: AppTheme.headlineSmall),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: widget.onCancel ?? () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _isLoading ? null : saveCategory,
          child: _isLoading
              ? const CupertinoActivityIndicator()
              : Text(widget.saveButtonText),
        ),
      ),
      child: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              buildNameSection(),
              const SizedBox(height: 16),
              buildDescriptionSection(),
              const SizedBox(height: 16),
              buildIconSection(),
              const SizedBox(height: 16),
              buildColorSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildNameSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.primaryCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Category Name', style: AppTheme.headlineSmall),
          const SizedBox(height: 16),
          CupertinoTextField(
            controller: _nameController,
            placeholder: 'Enter category name',
            style: AppTheme.input,
            decoration: AppTheme.inputField,
            padding: const EdgeInsets.all(12),
          ),
        ],
      ),
    );
  }

  Widget buildDescriptionSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.primaryCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Description', style: AppTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            'Describe what this category is for',
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.textTertiary),
          ),
          const SizedBox(height: 16),
          CupertinoTextField(
            controller: _descriptionController,
            placeholder: 'Enter description...',
            style: AppTheme.input,
            decoration: AppTheme.inputField,
            padding: const EdgeInsets.all(12),
            maxLines: 3,
            minLines: 2,
          ),
        ],
      ),
    );
  }

  Widget buildIconSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.primaryCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Icon', style: AppTheme.headlineSmall),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: availableIcons.map((icon) {
              final isSelected = _selectedIcon == icon['value'];
              return GestureDetector(
                onTap: () => setState(() => _selectedIcon = icon['value']!),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primary
                        : AppTheme.backgroundTertiary,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primary
                          : AppTheme.backgroundTertiary,
                    ),
                  ),
                  child: Text(
                    icon['name']!,
                    style: AppTheme.bodySmall.copyWith(
                      color: isSelected
                          ? CupertinoColors.white
                          : AppTheme.textPrimary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget buildColorSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.primaryCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Color', style: AppTheme.headlineSmall),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: availableColors.map((color) {
              final isSelected = _selectedColor == color['value'];
              return GestureDetector(
                onTap: () => setState(() => _selectedColor = color['value']!),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _parseColor(color['value']!),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? CupertinoColors.white
                          : Colors.transparent,
                      width: 3,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: _parseColor(
                                color['value']!,
                              ).withValues(alpha: 0.3),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Color _parseColor(String colorHex) {
    try {
      return Color(int.parse(colorHex.replaceAll('#', '0xFF')));
    } catch (e) {
      return AppTheme.primary;
    }
  }

  Future<void> saveCategory() async {
    if (!_formKey.currentState!.validate()) return;
    if (_nameController.text.trim().isEmpty) return;
    if (_descriptionController.text.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final category =
          widget.category?.copyWith(
            name: _nameController.text.trim(),
            description: _descriptionController.text.trim(),
            iconName: _selectedIcon,
            colorHex: _selectedColor,
          ) ??
          HealthToolCategory(
            id: '', // Will be set by the provider
            name: _nameController.text.trim(),
            description: _descriptionController.text.trim(),
            iconName: _selectedIcon,
            colorHex: _selectedColor,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

      if (widget.category != null) {
        await ref
            .read(healthToolCategoriesNotifierProvider.notifier)
            .updateCategory(category);
      } else {
        await ref
            .read(healthToolCategoriesNotifierProvider.notifier)
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
}
