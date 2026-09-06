import 'package:ethan_ui/ethan_ui.dart';
import 'package:flutter/material.dart';
import 'package:ethan_utils/ethan_utils.dart';
import 'package:health_notes/models/applied_tool.dart';
import 'package:health_notes/models/health_tool.dart';
import 'package:health_notes/theme/app_theme.dart';
import 'package:health_notes/widgets/applied_tool_picker_sheet.dart';
import 'package:health_notes/widgets/form_section_container.dart';
import 'package:health_notes/widgets/note_summary_rows.dart';
import 'package:health_notes/theme/spacing.dart';

class const AppliedToolsSection({
  required final bool isEditable,
  required final List<AppliedTool> appliedTools,
  required final Map<int, TextEditingController> noteControllers,
  required final Function(HealthTool) onAdd,
  required final Function(int) onRemove,
  required final Function(int, String) onUpdateNote,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FormSectionContainer(
      isEditable: isEditable,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [_header(context), VSpace.s, _content(context)],
      ),
    );
  }

  Widget _header(BuildContext context) {
    return ESectionHeader(
      title: 'Applied Tools',
      trailing: isEditable
          ? IconButton(
              tooltip: 'Add tool',
              onPressed: () => _showToolPicker(context),
              icon: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _content(BuildContext context) {
    if (appliedTools.isEmpty) {
      return Text('No tools applied', style: EText.body.medium);
    }

    if (!isEditable) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: appliedTools.mapL(
          (tool) => AppliedToolSummaryRow(appliedTool: tool),
        ),
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
    return ECard(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(tool.toolName, style: EText.label.large)),
              IconButton(
                tooltip: 'Remove tool',
                onPressed: () => onRemove(index),
                icon: const Icon(Icons.delete, color: EColors.danger),
              ),
            ],
          ),
          VSpace.s,
          TextField(
            controller: noteController,
            style: EText.body.medium,
            maxLines: 2,
            onChanged: (value) => onUpdateNote(index, value),
            decoration: InputDecoration(
              hintText: 'Note for this tool (optional)',
              hintStyle: EText.body.medium.muted,
            ),
          ),
        ],
      ),
    );
  }

  void _showToolPicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
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
