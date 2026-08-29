import 'package:ethan_ui/ethan_ui.dart';
import 'package:ethan_utils/ethan_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_notes/models/health_tool.dart';
import 'package:health_notes/models/health_tool_category.dart';
import 'package:health_notes/providers/health_tools_provider.dart';
import 'package:health_notes/screens/health_tool_form.dart';
import 'package:health_notes/theme/app_theme.dart';
import 'package:health_notes/widgets/app_dialogs.dart';
import 'package:health_notes/widgets/health_notes_page.dart';
import 'package:health_notes/widgets/refreshable_list_view.dart';
import 'package:health_notes/theme/spacing.dart';

class HealthToolCategoryScreen extends ConsumerStatefulWidget {
  final HealthToolCategory category;

  const HealthToolCategoryScreen({required this.category});

  @override
  ConsumerState<HealthToolCategoryScreen> createState() =>
      _HealthToolCategoryScreenState();
}

class _HealthToolCategoryScreenState
    extends ConsumerState<HealthToolCategoryScreen> {
  @override
  Widget build(BuildContext context) {
    final toolsAsync = ref.watch(toolsByCategoryProvider(widget.category.id));

    return HealthNotesPage(
      title: widget.category.name,
      actions: [
        IconButton(
          tooltip: 'Add tool',
          onPressed: () => _showAddToolForm(),
          icon: const Icon(Icons.add),
        ),
      ],
      body: categoryBody(toolsAsync),
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
    return ECard(
      margin: const EdgeInsets.all(AppSpacing.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.category.description, style: EText.body.medium),
        ],
      ),
    );
  }

  Widget toolsListSection(AsyncValue<List<HealthTool>> toolsAsync) {
    return toolsAsync.when(
      data: (tools) => tools.isEmpty ? emptyState() : toolsList(tools),
      loading: () =>
          ELoadingState(message: 'Loading tools...'),
      error: (error, stack) =>
          Center(child: Text('Error: $error', style: EText.error)),
    );
  }

  Widget emptyState() {
    return EEmptyState(
      title: 'No tools for ${widget.category.name}',
      message: 'Add your first tool to get started',
      icon: CupertinoIcons.wrench,
      action: FilledButton.icon(
        onPressed: () => _showAddToolForm(),
        icon: const Icon(Icons.add),
        label: const Text('Add Tool'),
      ),
    );
  }

  Widget toolsList(List<HealthTool> tools) {
    return RefreshableListView<HealthTool>(
      onReloadRequested: () async {
        await ref.read(healthToolsNotifierProvider.notifier).refresh();
      },
      items: tools,
      itemBuilder: (tool) => toolCard(tool),
      padding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }

  Widget toolCard(HealthTool tool) {
    return ECard(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: EdgeInsets.zero,
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () => _showToolDetails(tool),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.m),
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
        Expanded(child: Text(tool.name, style: EText.label.large)),
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
      style: EText.body.medium.tertiary,
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
    context.push(
      HealthToolForm(
        category: widget.category,
        title: 'Add Tool',
        saveButtonText: 'Save',
      ),
    );
  }

  void _showEditToolForm(HealthTool tool) {
    context.push(
      HealthToolForm(tool: tool, title: 'Edit Tool', saveButtonText: 'Update'),
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
