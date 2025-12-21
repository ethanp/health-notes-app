import 'package:flutter/cupertino.dart';
import 'package:health_notes/models/health_note.dart';
import 'package:health_notes/models/symptom.dart';
import 'package:health_notes/providers/health_notes_provider.dart';
import 'package:health_notes/screens/trends/base_trends_screen.dart';
import 'package:health_notes/theme/app_theme.dart';
import 'package:health_notes/utils/date_utils.dart';
import 'package:health_notes/utils/note_filter_utils.dart';
import 'package:health_notes/utils/severity_utils.dart';
import 'package:health_notes/widgets/activity_calendar.dart';
import 'package:health_notes/theme/spacing.dart';
import 'package:health_notes/widgets/symptom_note_card.dart';
import 'package:health_notes/widgets/trends_components.dart';

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
    return TrendsActivityDataGenerator.generateSeverityData(
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
          (note) =>
              SymptomNoteCard(note: note, symptomName: widget.symptomName),
        )
        .toList();
  }

  @override
  List<HealthNote> notesForDate(List<HealthNote> notes, DateTime date) {
    final targetDate = AppDateUtils.dateOnly(date);
    return notes
        .where(
          (note) =>
              AppDateUtils.dateOnly(note.dateTime).isAtSameMomentAs(targetDate),
        )
        .toList();
  }

  @override
  CupertinoAlertDialog buildNoActivityDialog(
    BuildContext dialogContext,
    DateTime date,
  ) {
    return noSymptomsAlert(dialogContext, AppDateUtils.formatLongDate(date));
  }

  @override
  CupertinoAlertDialog buildValueOnlyDialog(
    BuildContext dialogContext,
    DateTime date,
    int severity,
    List<HealthNote> scopedNotes,
  ) {
    return dateInfoNoNoteAlert(
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
    final note = relevantNotes.first;
    return dateInfoAlert(
      dialogContext,
      AppDateUtils.formatLongDate(date),
      severity,
      note,
    );
  }

  Color _severityColor(int severity) {
    return SeverityUtils.colorForSeverity(severity);
  }

  CupertinoAlertDialog noSymptomsAlert(
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

  CupertinoAlertDialog dateInfoNoNoteAlert(
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

  CupertinoAlertDialog dateInfoAlert(
    BuildContext dialogContext,
    String formattedDate,
    int severity,
    HealthNote note,
  ) {
    final severityText = SeverityUtils.descriptionForSeverity(severity);
    final symptom = note.symptomsList.firstWhere(
      (s) => s.majorComponent == widget.symptomName,
    );

    return CupertinoAlertDialog(
      title: dateInfoTitle(formattedDate, severity, severityText),
      content: dateInfoContent(dialogContext, note, symptom, severity),
      actions: dateInfoActions(dialogContext, note),
    );
  }

  List<Widget> dateInfoActions(BuildContext dialogContext, HealthNote note) {
    return [
      CupertinoDialogAction(
        child: const Text('Close'),
        onPressed: () => Navigator.of(dialogContext).pop(),
      ),
      CupertinoDialogAction(
        isDefaultAction: true,
        child: const Text('View Note'),
        onPressed: () {
          Navigator.of(dialogContext).pop();
          if (!mounted) return;
          _navigateToNoteDetail(note);
        },
      ),
    ];
  }

  Widget dateInfoTitle(
    String formattedDate,
    int severity,
    String severityText,
  ) {
    return Column(
      children: [
        Text(formattedDate, style: AppTypography.headlineSmallWhite),
        VSpace.s,
        severityPill(severity, severityText),
      ],
    );
  }

  Widget severityPill(int severity, String severityText) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _severityColor(severity).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _severityColor(severity).withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Text(
        'Level $severity - $severityText',
        style: AppTypography.labelMedium.copyWith(
          color: _severityColor(severity),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget dateInfoContent(
    BuildContext dialogContext,
    HealthNote note,
    Symptom symptom,
    int severity,
  ) {
    return Column(
      children: [
        VSpace.m,
        if (symptom.minorComponent.isNotEmpty) ...[
          infoRow('Type', symptom.minorComponent),
          VSpace.of(12),
        ],
        if (symptom.additionalNotes.isNotEmpty) ...[
          infoRow('Notes', symptom.additionalNotes),
          VSpace.of(12),
        ],
        if (note.notes.isNotEmpty) infoRow('General Notes', note.notes),
      ],
    );
  }

  Widget infoRow(String label, String value) {
    return infoRowLayout(
      label,
      Text(value, style: AppTypography.bodyMediumWhite),
    );
  }

  Widget infoRowLayout(String label, Widget value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            '$label:',
            style: AppTypography.labelMediumSystemGreySemibold,
          ),
        ),
        Expanded(child: value),
      ],
    );
  }

  void _navigateToNoteDetail(HealthNote note) {
    showCupertinoDialog(
      context: context,
      builder: (dialogContext) => noteDetailAlert(dialogContext, note),
    );
  }

  Widget noteDetailAlert(BuildContext dialogContext, HealthNote note) {
    return CupertinoAlertDialog(
      title: noteDetailTitle(note),
      content: Column(
        children: [
          VSpace.m,
          ...note.symptomsList.map((symptom) => symptomSummaryCard(symptom)),
          if (note.notes.isNotEmpty) ...[VSpace.m, generalNotesCard(note)],
        ],
      ),
      actions: [
        CupertinoDialogAction(
          child: const Text('Close'),
          onPressed: () => Navigator.of(dialogContext).pop(),
        ),
      ],
    );
  }

  Widget noteDetailTitle(HealthNote note) {
    return Text(
      AppDateUtils.formatShortDate(note.dateTime),
      style: AppTypography.headlineSmallWhite,
    );
  }

  Widget symptomSummaryCard(Symptom symptom) {
    final Color severityColor = _severityColor(symptom.severityLevel);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: AppComponents.cardGradient,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(
          color: CupertinoColors.systemGrey4.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                symptom.majorComponent,
                style: AppTypography.labelLargeWhiteSemibold,
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: severityColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: severityColor.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  'Level ${symptom.severityLevel}',
                  style: AppTypography.labelSmall.copyWith(
                    color: severityColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (symptom.minorComponent.isNotEmpty) ...[
            VSpace.s,
            Text(
              symptom.minorComponent,
              style: AppTypography.bodyMediumSystemGrey,
            ),
          ],
          if (symptom.additionalNotes.isNotEmpty) ...[
            VSpace.s,
            Text(symptom.additionalNotes, style: AppTypography.bodyMediumWhite),
          ],
        ],
      ),
    );
  }

  Widget generalNotesCard(HealthNote note) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: AppComponents.cardGradient,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(
          color: CupertinoColors.systemGrey4.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'General Notes',
            style: AppTypography.labelMedium.copyWith(
              color: CupertinoColors.systemGrey,
              fontWeight: FontWeight.w600,
            ),
          ),
          VSpace.s,
          Text(note.notes, style: AppTypography.bodyMediumWhite),
        ],
      ),
    );
  }
}
