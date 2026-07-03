import 'package:ethan_utils/ethan_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:health_notes/models/health_note.dart';
import 'package:health_notes/screens/health_note_view_screen.dart';
import 'package:health_notes/theme/app_theme.dart';
import 'package:health_notes/theme/spacing.dart';
import 'package:health_notes/utils/date_utils.dart';
import 'package:health_notes/utils/note_filter_utils.dart';
import 'package:health_notes/widgets/health_note_card.dart';

class HealthNoteDateDetailScreen extends StatelessWidget {
  final DateTime date;
  final List<HealthNote> allNotes;

  const HealthNoteDateDetailScreen({
    super.key,
    required this.date,
    required this.allNotes,
  });

  List<HealthNote> get notesForDate {
    final targetDate = date.startOfDay;
    return NoteFilterUtils.sortByDateDescending(
      allNotes
          .where((note) => note.dateTime.sameDayAs(targetDate))
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredNotes = notesForDate;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('Health Notes', style: AppTypography.bodyLargePrimary),
        backgroundColor: AppColors.backgroundSecondary,
        border: Border.all(
          color: AppColors.textSecondary.withValues(alpha: 0.2),
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).pop(),
          child: Icon(CupertinoIcons.back, color: AppColors.textSecondary),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            dateHeader(context),
            Expanded(
              child: filteredNotes.isEmpty
                  ? emptyState()
                  : notesList(context, filteredNotes),
            ),
          ],
        ),
      ),
    );
  }

  Widget dateHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        border: Border(
          bottom: BorderSide(
            color: AppColors.textSecondary.withValues(alpha: 0.2),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            AppDateUtils.formatLongDate(date),
            style: AppTypography.headlineSmallPrimary,
          ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => Navigator.of(context).pop(),
            child: Icon(CupertinoIcons.xmark, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget notesList(BuildContext context, List<HealthNote> filteredNotes) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredNotes.length,
      itemBuilder: (context, index) {
        final note = filteredNotes[index];
        return HealthNoteCard(
          note: note,
          onTap: () => context.push(HealthNoteViewScreen(note: note)),
        );
      },
    );
  }

  Widget emptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.calendar,
              size: 48,
              color: AppColors.textSecondary,
            ),
            VSpace.m,
            Text(
              'No notes for this date',
              style: AppTypography.bodyMediumPrimary,
            ),
            VSpace.s,
            Text(
              'Notes will appear here when you add them',
              style: AppTypography.bodySmallSecondary,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
