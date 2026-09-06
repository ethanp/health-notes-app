import 'package:ethan_ui/ethan_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_notes/models/health_tool.dart';
import 'package:health_notes/models/health_tool_category.dart';
import 'package:health_notes/providers/health_tools_provider.dart';
import 'package:health_notes/theme/app_theme.dart';
import 'package:health_notes/widgets/health_notes_page.dart';
import 'package:health_notes/theme/spacing.dart';

class const HealthToolForm({
  final HealthTool? tool,
  final HealthToolCategory? category,
  required final String title,
  required final String saveButtonText,
  final Function()? onCancel,
  final Function()? onSuccess,
}) extends ConsumerStatefulWidget {
  @override
  ConsumerState<HealthToolForm> createState() => _HealthToolFormState();
}

class _HealthToolFormState() extends ConsumerState<HealthToolForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  late String _selectedCategoryId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.tool?.name ?? '';
    _descriptionController.text = widget.tool?.description ?? '';
    _selectedCategoryId = widget.tool?.categoryId ?? widget.category?.id ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(healthToolCategoriesProvider);

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
          TextButton(onPressed: saveTool, child: Text(widget.saveButtonText)),
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
            categorySection(categoriesAsync),
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
          Text('Tool Name', style: EText.headline.small),
          VSpace.m,
          TextField(
            controller: _nameController,
            style: EText.body.medium,
            decoration: InputDecoration(
              hintText: 'Enter tool name',
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
            'Describe what this tool is and how to use it',
            style: EText.body.medium.tertiary,
          ),
          VSpace.m,
          TextField(
            controller: _descriptionController,
            style: EText.body.medium,
            maxLines: 5,
            minLines: 3,
            decoration: InputDecoration(
              hintText: 'Enter detailed description...',
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
      ),
    );
  }

  Widget categorySection(AsyncValue<List<HealthToolCategory>> categoriesAsync) {
    return ECard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Category', style: EText.headline.small),
          VSpace.m,
          categoriesAsync.when(
            data: (categories) => categoryContent(categories),
            loading: () => ELoadingState(message: 'Loading categories...'),
            error: (error, stack) =>
                Text('Error loading categories: $error', style: EText.error),
          ),
        ],
      ),
    );
  }

  Widget categoryContent(List<HealthToolCategory> categories) {
    if (categories.isEmpty) {
      return Text(
        'No categories available. Please create a category first.',
        style: EText.body.medium.tertiary,
      );
    }

    if (categories.length == 1) {
      final category = categories.first;
      _selectedCategoryId = category.id;
      return singleCategoryDisplay(category);
    }

    return categorySelector(categories);
  }

  Widget singleCategoryDisplay(HealthToolCategory category) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: AppComponents.inputField,
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: EColors.accent,
            size: 20,
          ),
          HSpace.s,
          Text(category.name, style: EText.body.medium),
        ],
      ),
    );
  }

  Widget categorySelector(List<HealthToolCategory> categories) {
    return SegmentedButton<String>(
      segments: [
        for (final category in categories)
          ButtonSegment(value: category.id, label: Text(category.name)),
      ],
      selected: {_selectedCategoryId},
      onSelectionChanged: (selection) {
        setState(() => _selectedCategoryId = selection.first);
      },
    );
  }

  Future<void> saveTool() async {
    if (!_formKey.currentState!.validate()) return;
    if (_nameController.text.trim().isEmpty) return;
    if (_descriptionController.text.trim().isEmpty) return;
    if (_selectedCategoryId.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final tool = _composeTool();

      if (widget.tool != null) {
        await ref.read(healthToolsProvider.notifier).updateTool(tool);
      } else {
        await ref.read(healthToolsProvider.notifier).addTool(tool);
      }

      if (mounted) {
        widget.onSuccess?.call();
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: Text('Failed to save tool: $e'),
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
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  HealthTool _composeTool() {
    final base = widget.tool;
    if (base != null) {
      return base.copyWith(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        categoryId: _selectedCategoryId,
      );
    }
    return HealthTool(
      id: '',
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      categoryId: _selectedCategoryId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}
