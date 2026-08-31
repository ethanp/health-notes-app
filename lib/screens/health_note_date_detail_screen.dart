import 'package:ethan_ui/ethan_ui.dart';
import 'package:ethan_utils/ethan_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:health_notes/models/health_note.dart';
import 'package:health_notes/screens/health_note_view_screen.dart';
import 'package:health_notes/theme/app_theme.dart';
import 'package:health_notes/theme/spacing.dart';
import 'package:health_notes/utils/health_date_format.dart';
import 'package:health_notes/utils/note_filter_utils.dart';
import 'package:health_notes/widgets/health_note_card.dart';
import 'package:health_notes/widgets/health_notes_page.dart';

class const HealthNoteDateDetailScreen({
  required final DateTime date,
  required final List<HealthNote> allNotes,
}) extends StatelessWidget {
  List<HealthNote> get notesForDate {
    final targetDate = date.startOfDay;
    return NoteFilterUtils.sortByDateDescending(
      allNotes.where((note) => note.dateTime.sameDayAs(targetDate)).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredNotes = notesForDate;

    return HealthNotesPage(
      title: 'Health Notes',
      body: Column(
        children: [
          dateHeader(context),
          Expanded(
            child: filteredNotes.isEmpty
                ? emptyState()
                : notesList(context, filteredNotes),
          ),
        ],
      ),
    );
  }

  Widget dateHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: EColors.backgroundLift,
        border: Border(
          bottom: BorderSide(
            color: EColors.textSecondary.withValues(alpha: 0.2),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            date.weekdayMonthDayYear,
            style: EText.headline.small.primary,
          ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => Navigator.of(context).pop(),
            child: Icon(CupertinoIcons.xmark, color: EColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget notesList(BuildContext context, List<HealthNote> filteredNotes) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.m),
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
      padding: const EdgeInsets.all(AppSpacing.l),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.calendar,
              size: 48,
              color: EColors.textSecondary,
            ),
            VSpace.m,
            Text('No notes for this date', style: EText.body.medium.primary),
            VSpace.s,
            Text(
              'Notes will appear here when you add them',
              style: EText.body.small.secondary,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
