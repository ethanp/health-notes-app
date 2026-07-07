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

class SubSymptomTrendsScreen extends BaseTrendsScreen {
  final String majorComponent;
  final String minorComponent;

  const SubSymptomTrendsScreen({
    required this.majorComponent,
    required this.minorComponent,
  }) : super(itemName: minorComponent);

  @override
  BaseTrendsState<SubSymptomTrendsScreen, int> createState() =>
      _SubSymptomTrendsScreenState();
}

class _SubSymptomTrendsScreenState
    extends BaseTrendsState<SubSymptomTrendsScreen, int> {
  @override
  String get itemNoun => 'sub-symptom';

  String get _fullLabel => '${widget.majorComponent} — ${widget.minorComponent}';

  @override
  String get title => '$_fullLabel Trends';

  @override
  Future<void> onRefresh() async {
    await ref.read(healthNotesNotifierProvider.notifier).refreshNotes();
  }

  @override
  List<HealthNote> filterSourceNotes(List<HealthNote> notes) {
    return NoteFilterUtils.bySubSymptom(
      notes,
      widget.majorComponent,
      widget.minorComponent,
    );
  }

  @override
  Map<DateTime, int> buildActivityData(List<HealthNote> notes) {
    return TrendsActivityAggregator.maxSubSymptomSeverityPerDay(
      notes: notes,
      majorComponent: widget.majorComponent,
      minorComponent: widget.minorComponent,
    );
  }

  @override
  Widget buildActivityContent(
    Map<DateTime, int> activityData,
    List<HealthNote> notes,
  ) {
    return SeverityActivityCalendar(
      itemName: _fullLabel,
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
  String noActivityMessage(DateTime date) =>
      'No "${widget.minorComponent}" was recorded on this date.';

  @override
  String valueOnlyMessage(DateTime date, int severity) {
    final description = SeverityUtils.descriptionForSeverity(severity);
    return 'You reported $description (level $severity) on this date.';
  }

  @override
  Widget? dateSummary(DateTime date, int severity, List<HealthNote> notes) {
    final description = SeverityUtils.descriptionForSeverity(severity);
    final color = SeverityUtils.colorForSeverity(severity);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
        ),
        child: Text(
          'Peak: Level $severity — $description',
          style: AppText.label.medium.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  @override
  Widget noteDetailLabel(HealthNote note) {
    final symptom = TrendsActivityAggregator.highestSeveritySubSymptom(
      note,
      widget.majorComponent,
      widget.minorComponent,
    );
    final noteSeverity = symptom?.severityLevel ?? 0;
    return Text.rich(
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
      ]),
    );
  }
}
