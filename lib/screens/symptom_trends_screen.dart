import 'package:ethan_utils/ethan_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:health_notes/models/health_note.dart';
import 'package:health_notes/providers/health_notes_provider.dart';
import 'package:health_notes/screens/health_note_view_screen.dart';
import 'package:health_notes/screens/sub_symptom_trends_screen.dart';
import 'package:health_notes/screens/trends/base_trends_screen.dart';
import 'package:health_notes/theme/app_theme.dart';
import 'package:health_notes/theme/spacing.dart';
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
  List<TrendsSegment> extraSegments(List<HealthNote> sortedNotes) {
    final subSymptoms = _subSymptomBreakdown(sortedNotes);
    if (subSymptoms.isEmpty) return [];
    return [
      TrendsSegment(
        title: 'Sub-symptoms',
        content: subSymptoms.map(_subSymptomRow).toList(),
      ),
    ];
  }

  List<_SubSymptomStat> _subSymptomBreakdown(List<HealthNote> notes) {
    final subSymptomCounts = <String, int>{};
    final subSymptomPeaks = <String, int>{};
    final subSymptomLatest = <String, DateTime>{};
    for (final note in notes) {
      for (final symptom in note.symptomsList) {
        if (symptom.majorComponent != widget.symptomName) continue;
        final minorComponent = symptom.minorComponent;
        if (minorComponent.isEmpty) continue;
        subSymptomCounts.update(
          minorComponent,
          (count) => count + 1,
          ifAbsent: () => 1,
        );
        subSymptomPeaks.update(
          minorComponent,
          (peak) =>
              symptom.severityLevel > peak ? symptom.severityLevel : peak,
          ifAbsent: () => symptom.severityLevel,
        );
        subSymptomLatest.update(
          minorComponent,
          (latest) =>
              note.dateTime.isAfter(latest) ? note.dateTime : latest,
          ifAbsent: () => note.dateTime,
        );
      }
    }

    final stats = subSymptomCounts.keys
        .map((minorComponent) => _SubSymptomStat(
              minorComponent: minorComponent,
              count: subSymptomCounts[minorComponent]!,
              peakSeverity: subSymptomPeaks[minorComponent]!,
              mostRecent: subSymptomLatest[minorComponent]!,
            ))
        .toList();
    stats.sort((first, second) => second.count.compareTo(first.count));
    return stats;
  }

  Widget _subSymptomRow(_SubSymptomStat stat) {
    final color = SeverityUtils.colorForSeverity(stat.peakSeverity);
    return GestureDetector(
      onTap: () => context.push(
        SubSymptomTrendsScreen(
          majorComponent: widget.symptomName,
          minorComponent: stat.minorComponent,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.backgroundTertiary,
          borderRadius: BorderRadius.circular(8),
          border: Border(left: BorderSide(color: color, width: 3)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(stat.minorComponent, style: AppTypography.bodyMedium),
                  Text(
                    AppDateUtils.formatShortDate(stat.mostRecent),
                    style: AppTypography.bodySmallSystemGrey,
                  ),
                ],
              ),
            ),
            Text('${stat.count}×', style: AppTypography.bodySmallSecondary),
            HSpace.s,
            const Icon(
              CupertinoIcons.chevron_right,
              size: 16,
              color: CupertinoColors.systemGrey3,
            ),
          ],
        ),
      ),
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
      'No symptoms were recorded on this date.';

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
          style: AppTypography.labelMedium.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  @override
  Widget noteDetailLabel(HealthNote note) {
    final symptom = TrendsActivityAggregator.highestSeveritySymptom(
      note,
      widget.symptomName,
    );
    final noteSeverity = symptom?.severityLevel ?? 0;
    final subsymptom = symptom?.minorComponent ?? '';
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
        if (subsymptom.isNotEmpty)
          TextSpan(
            text: ' $subsymptom',
            style: const TextStyle(fontWeight: FontWeight.w400),
          ),
      ]),
    );
  }
}

class _SubSymptomStat {
  final String minorComponent;
  final int count;
  final int peakSeverity;
  final DateTime mostRecent;

  const _SubSymptomStat({
    required this.minorComponent,
    required this.count,
    required this.peakSeverity,
    required this.mostRecent,
  });
}
