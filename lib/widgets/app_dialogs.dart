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

class AppAlertDialog extends StatelessWidget {
  final String title;
  final String? content;
  final Widget? contentWidget;
  final List<AppAlertDialogAction> actions;
  final bool showCancelButton;
  final String? cancelText;

  const AppAlertDialog({
    super.key,
    required this.title,
    this.content,
    this.contentWidget,
    required this.actions,
    this.showCancelButton = false,
    this.cancelText,
  }) : assert(
         content != null || contentWidget != null,
         'Either content or contentWidget must be provided',
       );

  @override
  Widget build(BuildContext context) {
    final allActions = <CupertinoDialogAction>[];

    allActions.addAll(
      actions.map(
        (action) => CupertinoDialogAction(
          onPressed: () {
            Navigator.of(context).pop(true);
          },
          isDestructiveAction: action.isDestructive,
          child: Text(action.text),
        ),
      ),
    );

    if (showCancelButton) {
      allActions.add(
        CupertinoDialogAction(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelText ?? 'Cancel'),
        ),
      );
    }

    return CupertinoAlertDialog(
      title: Text(title),
      content: contentWidget ?? (content != null ? Text(content!) : null),
      actions: allActions,
    );
  }
}

class AppAlertDialogAction {
  final String text;
  final bool isDestructive;

  const AppAlertDialogAction({required this.text, this.isDestructive = false});
}

class AppAlertDialogs {
  static AppAlertDialog confirmDestructive({
    required String title,
    required String content,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    bool isDestructive = true,
  }) {
    return AppAlertDialog(
      title: title,
      content: content,
      showCancelButton: true,
      cancelText: cancelText,
      actions: [
        AppAlertDialogAction(text: confirmText, isDestructive: isDestructive),
      ],
    );
  }

  static AppAlertDialog error({
    required String title,
    required String content,
    String okText = 'OK',
  }) {
    return AppAlertDialog(
      title: title,
      content: content,
      actions: [AppAlertDialogAction(text: okText)],
    );
  }

  static AppAlertDialog success({
    required String title,
    required String content,
    String okText = 'OK',
  }) {
    return AppAlertDialog(
      title: title,
      content: content,
      actions: [AppAlertDialogAction(text: okText)],
    );
  }

  static AppAlertDialog custom({
    required String title,
    String? content,
    Widget? contentWidget,
    required List<AppAlertDialogAction> actions,
    bool showCancelButton = false,
    String? cancelText,
  }) {
    return AppAlertDialog(
      title: title,
      content: content,
      contentWidget: contentWidget,
      actions: actions,
      showCancelButton: showCancelButton,
      cancelText: cancelText,
    );
  }
}
