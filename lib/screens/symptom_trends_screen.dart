import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_notes/models/health_note.dart';
import 'package:health_notes/providers/health_notes_provider.dart';
import 'package:health_notes/theme/app_theme.dart';

import 'package:health_notes/services/text_normalizer.dart';
import 'package:health_notes/widgets/enhanced_ui_components.dart';
import 'package:health_notes/widgets/activity_calendar.dart';
import 'package:intl/intl.dart';

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
    final symptomNotes = notes
        .where(
          (note) => note.symptomsList.any(
            (symptom) => symptom.majorComponent == widget.symptomName,
          ),
        )
        .toList();

    if (symptomNotes.isEmpty) {
      return EnhancedUIComponents.emptyState(
        title: 'No data for ${widget.symptomName}',
        message: 'No health notes with this symptom have been recorded yet',
        icon: CupertinoIcons.exclamationmark_triangle,
      );
    }

    final activityData = _generateActivityData(symptomNotes);
    final filteredNotes = _filterNotes(symptomNotes);

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
              const SizedBox(height: 20),
              searchSection(),
              const SizedBox(height: 20),
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
    if (severity == 0) return AppColors.backgroundPrimary.withValues(alpha: 0.3);

    final normalizedSeverity = (severity / 10.0).clamp(
      0.0,
      1.0,
    ); // Normalize and clamp to 0.0-1.0
    final hue = (120 - (normalizedSeverity * 120)).clamp(
      0.0,
      360.0,
    ); // Ensure hue is in valid range
    final saturation = (30 + (normalizedSeverity * 60)).clamp(
      0.0,
      100.0,
    ); // Ensure saturation is valid
    final lightness = (85 - (normalizedSeverity * 50)).clamp(
      0.0,
      100.0,
    ); // Ensure lightness is valid

    return HSLColor.fromAHSL(
      1.0,
      hue,
      saturation / 100,
      lightness / 100,
    ).toColor();
  }

  Widget searchSection() {
    return EnhancedUIComponents.searchField(
      controller: _searchController,
      placeholder: 'Search notes for ${widget.symptomName}...',
      onChanged: (query) {
        setState(() {
          _searchQuery = query;
        });
      },
    );
  }

  Widget symptomNotesList(List<HealthNote> notes) {
    if (notes.isEmpty) {
      return EnhancedUIComponents.emptyState(
        title: 'No matching notes',
        message: 'Try adjusting your search terms',
        icon: CupertinoIcons.search,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Health Notes (${notes.length})', style: AppTypography.headlineSmall),
        const SizedBox(height: 12),
        ...notes.map((note) => noteCard(note)),
      ],
    );
  }

  Widget noteCard(HealthNote note) {
    final symptom = note.symptomsList.firstWhere(
      (s) => s.majorComponent == widget.symptomName,
    );

    return Container(
      decoration: AppComponents.primaryCard,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  DateFormat('MMM dd, yyyy').format(note.dateTime),
                  style: AppTypography.labelLarge,
                ),
              ),
              severityIndicator(symptom.severityLevel),
            ],
          ),
          if (symptom.minorComponent.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              symptom.minorComponent,
              style: AppTypography.bodyMedium.copyWith(
                color: CupertinoColors.systemGrey,
              ),
            ),
          ],
          if (symptom.additionalNotes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(symptom.additionalNotes, style: AppTypography.bodyMedium),
          ],
          if (note.notes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey6,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(note.notes, style: AppTypography.bodySmall),
            ),
          ],
        ],
      ),
    );
  }

  Widget severityIndicator(int severity) {
    final severityColor = _severityColor(severity);
    final severityText = severity >= 1 && severity <= 10
        ? severity.toString()
        : 'Unknown';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: severityColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: severityColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        severityText,
        style: AppTypography.labelSmall.copyWith(color: severityColor),
      ),
    );
  }

  Map<DateTime, int> _generateActivityData(List<HealthNote> notes) {
    final activityData = <DateTime, int>{};

    for (final note in notes) {
      final symptom = note.symptomsList.firstWhere(
        (s) => s.majorComponent == widget.symptomName,
      );

      final dateKey = DateTime(
        note.dateTime.year,
        note.dateTime.month,
        note.dateTime.day,
      );

      if (activityData.containsKey(dateKey)) {
        final oldSeverity = activityData[dateKey]!;
        final newSeverity = symptom.severityLevel;
        activityData[dateKey] = oldSeverity > newSeverity
            ? oldSeverity
            : newSeverity;
      } else {
        activityData[dateKey] = symptom.severityLevel;
      }
    }

    return activityData;
  }

  List<HealthNote> _filterNotes(List<HealthNote> notes) {
    if (_searchQuery.isEmpty) return notes;

    return notes.where((note) {
      final symptom = note.symptomsList.firstWhere(
        (s) => s.majorComponent == widget.symptomName,
      );

      return SymptomNormalizer.matchesSearch(
            symptom.majorComponent,
            symptom.minorComponent,
            symptom.additionalNotes,
            _searchQuery,
          ) ||
          CaseInsensitiveNormalizer().contains(note.notes, _searchQuery);
    }).toList();
  }

  void _showDateInfo(BuildContext context, DateTime date, int severity) {
    if (severity == 0) {
      final formattedDate = DateFormat('EEEE, MMMM dd, yyyy').format(date);
      showCupertinoDialog(
        context: context,
        builder: (BuildContext context) => CupertinoAlertDialog(
          title: Text(formattedDate),
          content: const Text('No symptoms were recorded on this date.'),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
      return;
    }

    final healthNotesAsync = ref.read(healthNotesNotifierProvider);
    final notes = healthNotesAsync.value ?? [];

    final noteForDate = notes.where((note) {
      final noteDate = DateTime(
        note.dateTime.year,
        note.dateTime.month,
        note.dateTime.day,
      );
      final targetDate = DateTime(date.year, date.month, date.day);
      return noteDate.isAtSameMomentAs(targetDate);
    }).firstOrNull;

    if (noteForDate == null) {
      final formattedDate = DateFormat('EEEE, MMMM dd, yyyy').format(date);
      final severityText = _getSeverityDescription(severity);

      showCupertinoDialog(
        context: context,
        builder: (BuildContext context) => CupertinoAlertDialog(
          title: Text(formattedDate),
          content: Text(
            'You reported $severityText (level $severity) on this date.',
          ),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
      return;
    }

    final formattedDate = DateFormat('EEEE, MMMM dd, yyyy').format(date);
    final symptom = noteForDate.symptomsList.firstWhere(
      (s) => s.majorComponent == widget.symptomName,
    );
    final severityText = _getSeverityDescription(severity);

    showCupertinoDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: Column(
          children: [
            Text(
              formattedDate,
              style: AppTypography.headlineSmall.copyWith(
                color: CupertinoColors.white,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Container(
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
            ),
          ],
        ),
        content: Column(
          children: [
            const SizedBox(height: 16),
            if (symptom.minorComponent.isNotEmpty) ...[
              infoRow('Type', symptom.minorComponent),
              const SizedBox(height: 12),
            ],
            if (symptom.additionalNotes.isNotEmpty) ...[
              infoRow('Notes', symptom.additionalNotes),
              const SizedBox(height: 12),
            ],
            if (noteForDate.notes.isNotEmpty) ...[
              infoRow('General Notes', noteForDate.notes),
              const SizedBox(height: 12),
            ],
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: AppComponents.cardGradient,
                borderRadius: BorderRadius.circular(AppRadius.medium),
                border: Border.all(
                  color: CupertinoColors.systemGrey4.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    CupertinoIcons.doc_text,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'View full health note',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(
                    CupertinoIcons.chevron_right,
                    color: AppColors.primary,
                    size: 16,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Close'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('View Note'),
            onPressed: () {
              Navigator.of(context).pop();
              _navigateToNoteDetail(noteForDate);
            },
          ),
        ],
      ),
    );
  }

  Widget infoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            '$label:',
            style: AppTypography.labelMedium.copyWith(
              color: CupertinoColors.systemGrey,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTypography.bodyMedium.copyWith(color: CupertinoColors.white),
          ),
        ),
      ],
    );
  }

  String _getSeverityDescription(int severity) {
    return switch (severity) {
      1 => 'Very mild symptoms',
      2 => 'Mild symptoms',
      3 => 'Moderate symptoms',
      4 => 'Moderately severe symptoms',
      5 => 'Severe symptoms',
      6 => 'Very severe symptoms',
      7 => 'Extremely severe symptoms',
      8 => 'Very extreme symptoms',
      9 => 'Extremely intense symptoms',
      10 => 'Maximum severity symptoms',
      _ => 'Unknown severity',
    };
  }

  void _navigateToNoteDetail(HealthNote note) {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: Text(
          DateFormat('MMM dd, yyyy').format(note.dateTime),
          style: AppTypography.headlineSmall.copyWith(
            color: CupertinoColors.white,
            fontSize: 18,
          ),
        ),
        content: Column(
          children: [
            const SizedBox(height: 16),
            ...note.symptomsList.map(
              (symptom) => Container(
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
                          style: AppTypography.labelLarge.copyWith(
                            color: CupertinoColors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _severityColor(
                              symptom.severityLevel,
                            ).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _severityColor(
                                symptom.severityLevel,
                              ).withValues(alpha: 0.4),
                            ),
                          ),
                          child: Text(
                            'Level ${symptom.severityLevel}',
                            style: AppTypography.labelSmall.copyWith(
                              color: _severityColor(symptom.severityLevel),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (symptom.minorComponent.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        symptom.minorComponent,
                        style: AppTypography.bodyMedium.copyWith(
                          color: CupertinoColors.systemGrey,
                        ),
                      ),
                    ],
                    if (symptom.additionalNotes.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        symptom.additionalNotes,
                        style: AppTypography.bodyMedium.copyWith(
                          color: CupertinoColors.white,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (note.notes.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
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
                    const SizedBox(height: 8),
                    Text(
                      note.notes,
                      style: AppTypography.bodyMedium.copyWith(
                        color: CupertinoColors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Close'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
