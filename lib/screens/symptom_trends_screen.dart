import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_notes/models/health_note.dart';
import 'package:health_notes/models/symptom.dart';
import 'package:health_notes/providers/health_notes_provider.dart';
import 'package:health_notes/theme/app_theme.dart';
import 'package:health_notes/utils/date_utils.dart';
import 'package:health_notes/utils/note_filter_utils.dart';
import 'package:health_notes/utils/severity_utils.dart';
import 'package:health_notes/widgets/activity_calendar.dart';
import 'package:health_notes/widgets/enhanced_ui_components.dart';
import 'package:health_notes/widgets/spacing.dart';
import 'package:health_notes/widgets/symptom_note_card.dart';
import 'package:health_notes/widgets/trends_components.dart';

class SymptomTrendsScreen extends ConsumerStatefulWidget {
  final String symptomName;

  const SymptomTrendsScreen({super.key, required this.symptomName});

  @override
  ConsumerState<SymptomTrendsScreen> createState() =>
      _SymptomTrendsScreenState();
}

class _SymptomTrendsScreenState extends ConsumerState<SymptomTrendsScreen> {
  late TextEditingController _searchController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final healthNotesAsync = ref.watch(healthNotesNotifierProvider);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('${widget.symptomName} Trends'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).pop(),
          child: const Icon(CupertinoIcons.back),
        ),
      ),
      child: SafeArea(
        child: healthNotesAsync.when(
          data: (notes) => symptomTrendsContent(notes),
          loading: () => EnhancedUIComponents.loadingIndicator(
            message: 'Loading symptom trends...',
          ),
          error: (error, stack) =>
              Center(child: Text('Error: $error', style: AppTypography.error)),
        ),
      ),
    );
  }

  Widget symptomTrendsContent(List<HealthNote> notes) {
    final symptomNotes = NoteFilterUtils.bySymptom(notes, widget.symptomName);

    if (symptomNotes.isEmpty) {
      return EnhancedUIComponents.emptyState(
        title: 'No data for ${widget.symptomName}',
        message: 'No health notes with this symptom have been recorded yet',
        icon: CupertinoIcons.exclamationmark_triangle,
      );
    }

    final sortedSymptomNotes = NoteFilterUtils.sortByDateDescending(
      symptomNotes,
    );
    final activityData = TrendsActivityDataGenerator.generateSeverityData(
      notes: symptomNotes,
      symptomName: widget.symptomName,
    );
    final filteredNotes = _searchQuery.isEmpty
        ? sortedSymptomNotes
        : NoteFilterUtils.sortByDateDescending(
            NoteFilterUtils.bySearchQuery(sortedSymptomNotes, _searchQuery),
          );

    return CustomScrollView(
      slivers: [
        CupertinoSliverRefreshControl(
          onRefresh: () async {
            await ref.read(healthNotesNotifierProvider.notifier).refreshNotes();
          },
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              activityChart(activityData),
              VSpace.of(20),
              searchSection(),
              VSpace.of(20),
              symptomNotesList(filteredNotes),
            ]),
          ),
        ),
      ],
    );
  }

  Widget activityChart(Map<DateTime, int> activityData) {
    return SeverityActivityCalendar(
      itemName: widget.symptomName,
      activityData: activityData,
      onDateTap: _showDateInfo,
    );
  }

  Color _severityColor(int severity) {
    return SeverityUtils.colorForSeverity(severity);
  }

  Widget searchSection() {
    return EnhancedUIComponents.searchField(
      controller: _searchController,
      placeholder: 'Search notes for ${widget.symptomName}...',
      onChanged: (query) => setState(() => _searchQuery = query),
    );
  }

  Widget symptomNotesList(List<HealthNote> filteredNotes) {
    return filteredNotes.isEmpty
        ? const NoMatchingNotesState()
        : notesSection(filteredNotes);
  }

  Widget notesSection(List<HealthNote> notes) {
    return NotesSection(
      noteCount: notes.length,
      noteCards: notes
          .map(
            (note) =>
                SymptomNoteCard(note: note, symptomName: widget.symptomName),
          )
          .toList(),
    );
  }

  void _showDateInfo(BuildContext context, DateTime date, int severity) {
    if (severity == 0) {
      final formattedDate = AppDateUtils.formatLongDate(date);
      showCupertinoDialog(
        context: context,
        builder: (dialogContext) =>
            noSymptomsAlert(dialogContext, formattedDate),
      );
      return;
    }

    final healthNotesAsync = ref.read(healthNotesNotifierProvider);
    final notes = healthNotesAsync.value ?? [];
    final formattedDate = AppDateUtils.formatLongDate(date);
    final noteForDate = findNoteForDate(notes, date);

    if (noteForDate == null) {
      showCupertinoDialog(
        context: context,
        builder: (dialogContext) => dateInfoNoNoteAlert(
          dialogContext,
          formattedDate,
          severity,
          SeverityUtils.descriptionForSeverity(severity),
        ),
      );
      return;
    }

    showCupertinoDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) =>
          dateInfoAlert(dialogContext, formattedDate, severity, noteForDate),
    );
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

  HealthNote? findNoteForDate(List<HealthNote> notes, DateTime date) {
    final targetDate = AppDateUtils.dateOnly(date);
    return notes.where((note) {
      final noteDate = AppDateUtils.dateOnly(note.dateTime);
      return noteDate.isAtSameMomentAs(targetDate);
    }).firstOrNull;
  }

  Widget dateInfoAlert(
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
