import 'package:ethan_ui/ethan_ui.dart';
import 'package:flutter/material.dart';
import 'package:ethan_utils/ethan_utils.dart';
import 'package:health_notes/models/health_note.dart';
import 'package:health_notes/screens/health_note_view_screen.dart';
import 'package:health_notes/theme/app_theme.dart';
import 'package:health_notes/theme/spacing.dart';
import 'package:health_notes/utils/health_date_format.dart';

class const ToolNoteCard({
  required final HealthNote note,
  required final String toolId,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final appliedTool = note.appliedTools.firstWhere(
      (t) => t.toolId == toolId,
      orElse: () => note.appliedTools.first,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        onTap: () => context.push(HealthNoteViewScreen(note: note)),
        child: ECard(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      note.dateTime.weekdayMonthDayYear,
                      style: EText.label.medium,
                    ),
                    VSpace.xs,
                    Row(
                      children: [
                        Icon(
                          Icons.build,
                          size: 14,
                          color: EColors.accent,
                        ),
                        HSpace.xs,
                        Text(
                          appliedTool.toolName,
                          style: EText.body.medium.primary,
                        ),
                      ],
                    ),
                    if (appliedTool.note.isNotEmpty) ...[
                      VSpace.xs,
                      Text(
                        appliedTool.note,
                        style: EText.body.small.secondary,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (note.notes.isNotEmpty && appliedTool.note.isEmpty) ...[
                      VSpace.xs,
                      Text(
                        note.notes,
                        style: EText.body.small.tertiary,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              HSpace.s,
              Icon(
                Icons.chevron_right,
                size: 14,
                color: EColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
