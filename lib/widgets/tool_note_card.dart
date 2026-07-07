import 'package:ethan_utils/ethan_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:health_notes/models/health_note.dart';
import 'package:health_notes/screens/health_note_view_screen.dart';
import 'package:health_notes/theme/app_theme.dart';
import 'package:health_notes/widgets/app_card.dart';
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
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () => context.push(HealthNoteViewScreen(note: note)),
        child: AppCard(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppDateUtils.formatLongDate(note.dateTime),
                      style: AppText.label.medium,
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
                          style: AppText.body.medium.primary,
                        ),
                      ],
                    ),
                    if (appliedTool.note.isNotEmpty) ...[
                      VSpace.xs,
                      Text(
                        appliedTool.note,
                        style: AppText.body.small.secondary,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (note.notes.isNotEmpty && appliedTool.note.isEmpty) ...[
                      VSpace.xs,
                      Text(
                        note.notes,
                        style: AppText.body.small.tertiary,
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
