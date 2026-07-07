import 'package:ethan_utils/ethan_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:health_notes/models/applied_tool.dart';
import 'package:health_notes/models/health_tool.dart';
import 'package:health_notes/theme/app_theme.dart';
import 'package:health_notes/widgets/applied_tool_picker_sheet.dart';
import 'package:health_notes/widgets/app_card.dart';
import 'package:health_notes/widgets/enhanced_ui_components.dart';
import 'package:health_notes/widgets/note_summary_rows.dart';
import 'package:health_notes/theme/spacing.dart';

class AppliedToolsSection extends StatelessWidget {
  final bool isEditable;
  final List<AppliedTool> appliedTools;
  final Map<int, TextEditingController> noteControllers;
  final Function(HealthTool) onAdd;
  final Function(int) onRemove;
  final Function(int, String) onUpdateNote;

  const AppliedToolsSection({
    super.key,
    required this.isEditable,
    required this.appliedTools,
    required this.noteControllers,
    required this.onAdd,
    required this.onRemove,
    required this.onUpdateNote,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: isEditable
          ? AppComponents.inputField
          : AppComponents.primaryCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [_header(context), VSpace.s, _content(context)],
      ),
    );
  }

  Widget _header(BuildContext context) {
    return EnhancedUIComponents.sectionHeader(
      title: 'Applied Tools',
      trailing: isEditable
          ? CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => _showToolPicker(context),
              child: const Icon(CupertinoIcons.add),
            )
          : null,
    );
  }

  Widget _content(BuildContext context) {
    if (appliedTools.isEmpty) {
      return Text('No tools applied', style: AppTypography.bodyMedium);
    }

    if (!isEditable) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: appliedTools
            .mapL((tool) => AppliedToolSummaryRow(appliedTool: tool)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: appliedTools.asMap().entries.map((entry) {
        final index = entry.key;
        final tool = entry.value;
        final controller = noteControllers[index]!;
        return _editableItem(index, tool, controller);
      }).toList(),
    );
  }

  Widget _editableItem(
    int index,
    AppliedTool tool,
    TextEditingController noteController,
  ) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(tool.toolName, style: AppTypography.labelLarge),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => onRemove(index),
                child: const Icon(
                  CupertinoIcons.delete,
                  color: AppColors.destructive,
                ),
              ),
            ],
          ),
          VSpace.s,
          CupertinoTextField(
            controller: noteController,
            placeholder: 'Note for this tool (optional)',
            placeholderStyle: AppTypography.inputPlaceholder,
            style: AppTypography.input,
            maxLines: 2,
            onChanged: (value) => onUpdateNote(index, value),
          ),
        ],
      ),
    );
  }

  void _showToolPicker(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => AppliedToolPickerSheet(
        appliedTools: appliedTools,
        onSelect: (t) {
          onAdd(t);
          Navigator.of(context).pop();
        },
      ),
    );
  }
}
