import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_notes/models/health_tool.dart';
import 'package:health_notes/models/health_tool_category.dart';
import 'package:health_notes/providers/health_tools_provider.dart';
import 'package:health_notes/screens/health_tool_form.dart';
import 'package:health_notes/theme/app_theme.dart';
import 'package:health_notes/widgets/refreshable_list_view.dart';

class HealthToolCategoryScreen extends ConsumerStatefulWidget {
  final HealthToolCategory category;

  const HealthToolCategoryScreen({super.key, required this.category});

  @override
  ConsumerState<HealthToolCategoryScreen> createState() =>
      _HealthToolCategoryScreenState();
}

class _HealthToolCategoryScreenState
    extends ConsumerState<HealthToolCategoryScreen> {
  @override
  Widget build(BuildContext context) {
    final toolsAsync = ref.watch(toolsByCategoryProvider(widget.category.id));

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(widget.category.name, style: AppTheme.headlineSmall),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => _showAddToolForm(),
          child: const Icon(CupertinoIcons.add),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Category header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.primaryCard,
              margin: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.category.description, style: AppTheme.bodyMedium),
                ],
              ),
            ),
            // Tools list
            Expanded(
              child: toolsAsync.when(
                data: (tools) =>
                    tools.isEmpty ? buildEmptyState() : buildToolsList(tools),
                loading: () =>
                    const Center(child: CupertinoActivityIndicator()),
                error: (error, stack) =>
                    Center(child: Text('Error: $error', style: AppTheme.error)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.wrench,
            size: 48,
            color: CupertinoColors.systemGrey,
          ),
          const SizedBox(height: 16),
          Text(
            'No tools for ${widget.category.name}',
            style: AppTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first tool to get started',
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.textTertiary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          CupertinoButton.filled(
            onPressed: () => _showAddToolForm(),
            child: const Text('Add Tool'),
          ),
        ],
      ),
    );
  }

  Widget buildToolsList(List<HealthTool> tools) {
    return RefreshableListView<HealthTool>(
      onRefresh: () async {
        await ref.read(healthToolsNotifierProvider.notifier).refresh();
      },
      items: tools,
      itemBuilder: (tool) => buildToolCard(tool),
      padding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }

  Widget buildToolCard(HealthTool tool) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppTheme.primaryCard,
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () => _showToolDetails(tool),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(tool.name, style: AppTheme.labelLarge)),
                  const Icon(
                    CupertinoIcons.chevron_right,
                    color: CupertinoColors.systemGrey,
                    size: 16,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                tool.description,
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.textTertiary,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showToolDetails(HealthTool tool) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(tool.name),
        message: Text(tool.description),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(context).pop();
              _showEditToolForm(tool);
            },
            child: const Text('Edit'),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.of(context).pop();
              _showDeleteConfirmation(tool);
            },
            child: const Text('Delete'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  void _showAddToolForm() {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => HealthToolForm(
          category: widget.category,
          title: 'Add Tool',
          saveButtonText: 'Save',
        ),
      ),
    );
  }

  void _showEditToolForm(HealthTool tool) {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => HealthToolForm(
          tool: tool,
          title: 'Edit Tool',
          saveButtonText: 'Update',
        ),
      ),
    );
  }

  void _showDeleteConfirmation(HealthTool tool) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Delete Tool'),
        content: Text('Are you sure you want to delete "${tool.name}"?'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.of(context).pop();
              _deleteTool(tool);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteTool(HealthTool tool) async {
    try {
      await ref.read(healthToolsNotifierProvider.notifier).deleteTool(tool.id);
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Success'),
            content: const Text('Tool deleted successfully'),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: Text('Failed to delete tool: $e'),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      }
    }
  }
}
