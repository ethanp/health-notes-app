import 'package:ethan_utils/ethan_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:health_notes/models/health_note.dart';
import 'package:health_notes/screens/health_note_view_screen.dart';
import 'package:health_notes/utils/date_utils.dart';

/// Shows a date-tap dialog listing notes for that day, each navigating
/// to HealthNoteViewScreen. Callers provide an optional summary widget
/// and a per-note label builder — all chrome, layout, and navigation
/// are handled here.
///
/// For dates with no notes, use [showDateInfoDialog] instead.
void showNoteDateDialog({
  required BuildContext context,
  required DateTime date,
  required List<HealthNote> notes,
  Widget? summary,
  required Widget Function(HealthNote note) noteLabelBuilder,
}) {
  showCupertinoDialog(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) => CupertinoAlertDialog(
      title: Text(AppDateUtils.formatLongDate(date)),
      content: summary,
      actions: [
        ...notes.map(
          (note) => CupertinoDialogAction(
            isDefaultAction: true,
            child: noteLabelBuilder(note),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              if (context.mounted) {
                context.push(HealthNoteViewScreen(note: note));
              }
            },
          ),
        ),
        CupertinoDialogAction(
          isDestructiveAction: true,
          child: const Text('Close'),
          onPressed: () => Navigator.of(dialogContext).pop(),
        ),
      ],
    ),
  );
}

/// Shows a simple informational dialog for a date with no linkable notes.
void showDateInfoDialog({
  required BuildContext context,
  required DateTime date,
  required String message,
}) {
  showCupertinoDialog(
    context: context,
    builder: (dialogContext) => CupertinoAlertDialog(
      title: Text(AppDateUtils.formatLongDate(date)),
      content: Text(message),
      actions: [
        CupertinoDialogAction(
          child: const Text('OK'),
          onPressed: () => Navigator.of(dialogContext).pop(),
        ),
      ],
    ),
  );
}
