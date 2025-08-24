import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_notes/models/health_tool.dart';
import 'package:health_notes/models/health_tool_category.dart';
import 'package:health_notes/providers/health_tools_provider.dart';
import 'package:health_notes/theme/app_theme.dart';

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
      navigationBar: CupertinoNavigationBar(
        middle: Text(widget.title, style: AppTheme.titleMedium),
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
              buildNameSection(),
              const SizedBox(height: 16),
              buildDescriptionSection(),
              const SizedBox(height: 16),
              buildCategorySection(categoriesAsync),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildNameSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tool Name', style: AppTheme.titleMedium),
          const SizedBox(height: 16),
          CupertinoTextField(
            controller: _nameController,
            placeholder: 'Enter tool name',
            style: AppTheme.input,
            decoration: AppTheme.inputContainer,
            padding: const EdgeInsets.all(12),
          ),
        ],
      ),
    );
  }

  Widget buildDescriptionSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Description', style: AppTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Describe what this tool is and how to use it',
            style: AppTheme.bodyMediumSecondary,
          ),
          const SizedBox(height: 16),
          CupertinoTextField(
            controller: _descriptionController,
            placeholder: 'Enter detailed description...',
            style: AppTheme.input,
            decoration: AppTheme.inputContainer,
            padding: const EdgeInsets.all(12),
            maxLines: 5,
            minLines: 3,
          ),
        ],
      ),
    );
  }

  Widget buildCategorySection(
    AsyncValue<List<HealthToolCategory>> categoriesAsync,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Category', style: AppTheme.titleMedium),
          const SizedBox(height: 16),
          categoriesAsync.when(
            data: (categories) {
              if (categories.isEmpty) {
                return Text(
                  'No categories available. Please create a category first.',
                  style: AppTheme.bodyMediumSecondary,
                );
              }

              // If only one category, show it as selected without a segmented control
              if (categories.length == 1) {
                final category = categories.first;
                _selectedCategoryId = category.id;
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: AppTheme.inputContainer,
                  child: Row(
                    children: [
                      Icon(
                        CupertinoIcons.check_mark_circled_solid,
                        color: AppTheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(category.name, style: AppTheme.bodyMedium),
                    ],
                  ),
                );
              }

              return CupertinoSlidingSegmentedControl<String>(
                groupValue: _selectedCategoryId,
                children: {
                  for (final category in categories)
                    category.id: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(category.name, style: AppTheme.bodyMedium),
                    ),
                },
                onValueChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedCategoryId = value);
                  }
                },
              );
            },
            loading: () => const CupertinoActivityIndicator(),
            error: (error, stack) =>
                Text('Error loading categories: $error', style: AppTheme.error),
          ),
        ],
      ),
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
      final tool =
          widget.tool?.copyWith(
            name: _nameController.text.trim(),
            description: _descriptionController.text.trim(),
            categoryId: _selectedCategoryId,
          ) ??
          HealthTool(
            id: '', // Will be set by the provider
            name: _nameController.text.trim(),
            description: _descriptionController.text.trim(),
            categoryId: _selectedCategoryId,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

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
}
