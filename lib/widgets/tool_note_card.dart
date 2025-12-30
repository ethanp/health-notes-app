import 'package:flutter/cupertino.dart';
import 'package:health_notes/models/health_note.dart';
import 'package:health_notes/screens/health_note_view_screen.dart';
import 'package:health_notes/theme/app_theme.dart';
import 'package:health_notes/theme/spacing.dart';
import 'package:health_notes/utils/date_utils.dart';

class ToolNoteCard extends StatelessWidget {
  final HealthNote note;
  final String toolId;

  const ToolNoteCard({super.key, required this.note, required this.toolId});

  @override
  Widget build(BuildContext context) {
    final appliedTool = note.appliedTools.firstWhere(
      (t) => t.toolId == toolId,
      orElse: () => note.appliedTools.first,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () => Navigator.of(context).push(
          CupertinoPageRoute(
            builder: (context) => HealthNoteViewScreen(note: note),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: AppComponents.primaryCard,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppDateUtils.formatLongDate(note.dateTime),
                      style: AppTypography.labelMedium,
                    ),
                    VSpace.xs,
                    Row(
                      children: [
                        Icon(
                          CupertinoIcons.wrench,
                          size: 14,
                          color: AppColors.primary,
                        ),
                        HSpace.xs,
                        Text(
                          appliedTool.toolName,
                          style: AppTypography.bodyMediumPrimary,
                        ),
                      ],
                    ),
                    if (appliedTool.note.isNotEmpty) ...[
                      VSpace.xs,
                      Text(
                        appliedTool.note,
                        style: AppTypography.bodySmallSecondary,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (note.notes.isNotEmpty && appliedTool.note.isEmpty) ...[
                      VSpace.xs,
                      Text(
                        note.notes,
                        style: AppTypography.bodySmallTertiary,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              HSpace.s,
              Icon(
                CupertinoIcons.chevron_right,
                size: 14,
                color: AppColors.textQuaternary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
