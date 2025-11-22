import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_notes/models/health_tool.dart';
import 'package:health_notes/models/health_tool_category.dart';
import 'package:health_notes/providers/health_tools_provider.dart';
import 'package:health_notes/theme/app_theme.dart';
import 'package:health_notes/widgets/enhanced_ui_components.dart';
import 'package:health_notes/widgets/spacing.dart';

class HealthToolForm extends ConsumerStatefulWidget {
  final HealthTool? tool;
  final HealthToolCategory? category;
  final String title;
  final String saveButtonText;
  final Function()? onCancel;
  final Function()? onSuccess;

  const HealthToolForm({
    this.tool,
    this.category,
    required this.title,
    required this.saveButtonText,
    this.onCancel,
    this.onSuccess,
  });

  @override
  ConsumerState<HealthToolForm> createState() => _HealthToolFormState();
}

class _HealthToolFormState extends ConsumerState<HealthToolForm> {
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
    final categoriesAsync = ref.watch(healthToolCategoriesNotifierProvider);

    return CupertinoPageScaffold(
      navigationBar: EnhancedUIComponents.navigationBar(
        title: widget.title,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: widget.onCancel ?? () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _isLoading ? null : saveTool,
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
              nameSection(),
              VSpace.m,
              descriptionSection(),
              VSpace.m,
              categorySection(categoriesAsync),
            ],
          ),
        ),
      ),
    );
  }

  Widget nameSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppComponents.primaryCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tool Name', style: AppTypography.headlineSmall),
          VSpace.m,
          CupertinoTextField(
            controller: _nameController,
            placeholder: 'Enter tool name',
            style: AppTypography.input,
            decoration: AppComponents.inputField,
            padding: const EdgeInsets.all(12),
          ),
        ],
      ),
    );
  }

  Widget descriptionSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppComponents.primaryCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Description', style: AppTypography.headlineSmall),
          VSpace.s,
          Text(
            'Describe what this tool is and how to use it',
            style: AppTypography.bodyMediumTertiary,
          ),
          VSpace.m,
          CupertinoTextField(
            controller: _descriptionController,
            placeholder: 'Enter detailed description...',
            style: AppTypography.input,
            decoration: AppComponents.inputField,
            padding: const EdgeInsets.all(12),
            maxLines: 5,
            minLines: 3,
          ),
        ],
      ),
    );
  }

  Widget categorySection(AsyncValue<List<HealthToolCategory>> categoriesAsync) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppComponents.primaryCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Category', style: AppTypography.headlineSmall),
          VSpace.m,
          categoriesAsync.when(
            data: (categories) => categoryContent(categories),
            loading: () => EnhancedUIComponents.loadingIndicator(
              message: 'Loading categories...',
            ),
            error: (error, stack) => Text(
              'Error loading categories: $error',
              style: AppTypography.error,
            ),
          ),
        ],
      ),
    );
  }

  Widget categoryContent(List<HealthToolCategory> categories) {
    if (categories.isEmpty) {
      return Text(
        'No categories available. Please create a category first.',
        style: AppTypography.bodyMediumTertiary,
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
      padding: const EdgeInsets.all(12),
      decoration: AppComponents.inputField,
      child: Row(
        children: [
          Icon(
            CupertinoIcons.check_mark_circled_solid,
            color: AppColors.primary,
            size: 20,
          ),
          HSpace.s,
          Text(category.name, style: AppTypography.bodyMedium),
        ],
      ),
    );
  }

  Widget categorySelector(List<HealthToolCategory> categories) {
    return CupertinoSlidingSegmentedControl<String>(
      groupValue: _selectedCategoryId,
      children: {
        for (final category in categories)
          category.id: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(category.name, style: AppTypography.bodyMedium),
          ),
      },
      onValueChanged: (value) {
        if (value != null) {
          setState(() => _selectedCategoryId = value);
        }
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
        await ref.read(healthToolsNotifierProvider.notifier).updateTool(tool);
      } else {
        await ref.read(healthToolsNotifierProvider.notifier).addTool(tool);
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
            content: Text('Failed to save tool: $e'),
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
