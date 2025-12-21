import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_notes/models/health_tool.dart';
import 'package:health_notes/models/health_tool_category.dart';
import 'package:health_notes/providers/health_tools_provider.dart';
import 'package:health_notes/screens/health_tool_form.dart';
import 'package:health_notes/theme/app_theme.dart';
import 'package:health_notes/widgets/enhanced_ui_components.dart';
import 'package:health_notes/widgets/refreshable_list_view.dart';
import 'package:health_notes/theme/spacing.dart';

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
      navigationBar: EnhancedUIComponents.navigationBar(
        title: widget.category.name,
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => _showAddToolForm(),
          child: const Icon(CupertinoIcons.add),
        ),
      ),
      child: SafeArea(child: categoryBody(toolsAsync)),
    );
  }

  Widget categoryBody(AsyncValue<List<HealthTool>> toolsAsync) {
    return Column(
      children: [
        categoryHeader(),
        Expanded(child: toolsListSection(toolsAsync)),
      ],
    );
  }

  Widget categoryHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppComponents.primaryCard,
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.category.description, style: AppTypography.bodyMedium),
        ],
      ),
    );
  }

  Widget toolsListSection(AsyncValue<List<HealthTool>> toolsAsync) {
    return toolsAsync.when(
      data: (tools) => tools.isEmpty ? emptyState() : toolsList(tools),
      loading: () =>
          EnhancedUIComponents.loadingIndicator(message: 'Loading tools...'),
      error: (error, stack) =>
          Center(child: Text('Error: $error', style: AppTypography.error)),
    );
  }

  Widget emptyState() {
    return EnhancedUIComponents.emptyState(
      title: 'No tools for ${widget.category.name}',
      message: 'Add your first tool to get started',
      icon: CupertinoIcons.wrench,
      action: EnhancedUIComponents.button(
        text: 'Add Tool',
        onPressed: () => _showAddToolForm(),
        icon: CupertinoIcons.add,
      ),
    );
  }

  Widget toolsList(List<HealthTool> tools) {
    return RefreshableListView<HealthTool>(
      onRefresh: () async {
        await ref.read(healthToolsNotifierProvider.notifier).refresh();
      },
      items: tools,
      itemBuilder: (tool) => toolCard(tool),
      padding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }

  Widget toolCard(HealthTool tool) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppComponents.primaryCard,
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () => _showToolDetails(tool),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [toolHeader(tool), VSpace.s, toolDescription(tool)],
          ),
        ),
      ),
    );
  }

  Widget toolHeader(HealthTool tool) {
    return Row(
      children: [
        Expanded(child: Text(tool.name, style: AppTypography.labelLarge)),
        const Icon(
          CupertinoIcons.chevron_right,
          color: CupertinoColors.systemGrey,
          size: 16,
        ),
      ],
    );
  }

  Widget toolDescription(HealthTool tool) {
    return Text(
      tool.description,
      style: AppTypography.bodyMediumTertiary,
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
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
      builder: (context) => AppAlertDialogs.confirmDestructive(
        title: 'Delete Tool',
        content: 'Are you sure you want to delete "${tool.name}"?',
        confirmText: 'Delete',
      ),
    ).then((confirmed) {
      if (confirmed == true) {
        _deleteTool(tool);
      }
    });
  }

  Future<void> _deleteTool(HealthTool tool) async {
    try {
      await ref.read(healthToolsNotifierProvider.notifier).deleteTool(tool.id);
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => AppAlertDialogs.success(
            title: 'Success',
            content: 'Tool deleted successfully',
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => AppAlertDialogs.error(
            title: 'Error',
            content: 'Failed to delete tool: $e',
          ),
        );
      }
    }
  }
}
