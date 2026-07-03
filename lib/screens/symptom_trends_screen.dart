import 'package:ethan_utils/ethan_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:health_notes/models/health_note.dart';
import 'package:health_notes/providers/health_notes_provider.dart';
import 'package:health_notes/screens/health_note_view_screen.dart';
import 'package:health_notes/screens/trends/base_trends_screen.dart';
import 'package:health_notes/theme/app_theme.dart';
import 'package:health_notes/utils/date_utils.dart';
import 'package:health_notes/utils/note_filter_utils.dart';
import 'package:health_notes/utils/severity_utils.dart';
import 'package:health_notes/widgets/activity_calendar.dart';
import 'package:health_notes/widgets/health_note_card.dart';
import 'package:health_notes/services/trends_activity_aggregator.dart';

class SymptomTrendsScreen extends BaseTrendsScreen {
  final String symptomName;

  const SymptomTrendsScreen({required this.symptomName})
    : super(itemName: symptomName);

  @override
  BaseTrendsState<SymptomTrendsScreen, int> createState() =>
      _SymptomTrendsScreenState();
}

class _SymptomTrendsScreenState
    extends BaseTrendsState<SymptomTrendsScreen, int> {
  @override
  String get itemNoun => 'symptom';

  @override
  Future<void> onRefresh() async {
    await ref.read(healthNotesNotifierProvider.notifier).refreshNotes();
  }

  @override
  List<HealthNote> filterSourceNotes(List<HealthNote> notes) {
    return NoteFilterUtils.bySymptom(notes, widget.symptomName);
  }

  @override
  Map<DateTime, int> buildActivityData(List<HealthNote> notes) {
    return TrendsActivityAggregator.maxSeverityPerDay(
      notes: notes,
      symptomName: widget.symptomName,
    );
  }

  @override
  Widget buildActivityContent(
    Map<DateTime, int> activityData,
    List<HealthNote> notes,
  ) {
    return SeverityActivityCalendar(
      itemName: widget.symptomName,
      activityData: activityData,
      onDateTap: (context, date, severity) =>
          handleDateTap(context, date, severity, notes),
    );
  }

  @override
  List<Widget> buildNotesContent(List<HealthNote> notes) {
    return notes
        .map(
          (note) => HealthNoteCard(
            note: note,
            onTap: () => context.push(HealthNoteViewScreen(note: note)),
          ),
        )
        .toList();
  }

  @override
  List<HealthNote> notesForDate(List<HealthNote> notes, DateTime date) {
    final targetDate = date.startOfDay;
    return notes
        .where((note) => note.dateTime.sameDayAs(targetDate))
        .toList();
  }

  @override
  CupertinoAlertDialog buildNoActivityDialog(
    BuildContext dialogContext,
    DateTime date,
  ) {
    return _noSymptomsAlert(dialogContext, AppDateUtils.formatLongDate(date));
  }

  @override
  CupertinoAlertDialog buildValueOnlyDialog(
    BuildContext dialogContext,
    DateTime date,
    int severity,
    List<HealthNote> scopedNotes,
  ) {
    return _dateInfoNoNoteAlert(
      dialogContext,
      AppDateUtils.formatLongDate(date),
      severity,
      SeverityUtils.descriptionForSeverity(severity),
    );
  }

  @override
  CupertinoAlertDialog buildDetailDialog(
    BuildContext dialogContext,
    DateTime date,
    int severity,
    List<HealthNote> relevantNotes,
  ) {
    final severityText = SeverityUtils.descriptionForSeverity(severity);
    return CupertinoAlertDialog(
      title: Text(AppDateUtils.formatLongDate(date)),
      content: _severityPill(severity, severityText),
      actions: [
        ...relevantNotes.map((note) {
          final symptom = TrendsActivityAggregator.highestSeveritySymptom(
            note,
            widget.symptomName,
          );
          final noteSeverity = symptom?.severityLevel ?? 0;
          final subsymptom = symptom?.minorComponent ?? '';
          return CupertinoDialogAction(
            isDefaultAction: true,
            child: Text.rich(
              TextSpan(children: [
                TextSpan(
                  text: AppDateUtils.formatTime(note.dateTime),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const TextSpan(text: '  ·  '),
                TextSpan(
                  text: 'L$noteSeverity',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                if (subsymptom.isNotEmpty)
                  TextSpan(
                    text: ' $subsymptom',
                    style: const TextStyle(fontWeight: FontWeight.w400),
                  ),
              ]),
            ),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              if (!mounted) return;
              context.push(HealthNoteViewScreen(note: note));
            },
          );
        }),
        CupertinoDialogAction(
          isDestructiveAction: true,
          child: const Text('Close'),
          onPressed: () => Navigator.of(dialogContext).pop(),
        ),
      ],
    );
  }

  Widget _severityPill(int severity, String severityText) {
    final color = SeverityUtils.colorForSeverity(severity);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
        child: Text(
          'Peak: Level $severity - $severityText',
          style: AppTypography.labelMedium.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  CupertinoAlertDialog _noSymptomsAlert(
    BuildContext dialogContext,
    String formattedDate,
  ) {
    return CupertinoAlertDialog(
      title: Text(formattedDate),
      content: const Text('No symptoms were recorded on this date.'),
      actions: [
        CupertinoDialogAction(
          child: const Text('OK'),
          onPressed: () => Navigator.of(dialogContext).pop(),
        ),
      ],
    );
  }

  CupertinoAlertDialog _dateInfoNoNoteAlert(
    BuildContext dialogContext,
    String formattedDate,
    int severity,
    String severityText,
  ) {
    return CupertinoAlertDialog(
      title: Text(formattedDate),
      content: Text(
        'You reported $severityText (level $severity) on this date.',
      ),
      actions: [
        CupertinoDialogAction(
          child: const Text('OK'),
          onPressed: () => Navigator.of(dialogContext).pop(),
        ),
      ],
    );
  }
}
