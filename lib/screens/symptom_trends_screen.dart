import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_notes/models/health_note.dart';
import 'package:health_notes/providers/health_notes_provider.dart';
import 'package:health_notes/theme/app_theme.dart';
import 'package:health_notes/widgets/enhanced_ui_components.dart';
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
              Center(child: Text('Error: $error', style: AppTheme.error)),
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
    return Container(
      decoration: AppTheme.primaryCard,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${widget.symptomName} Activity', style: AppTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            'Color intensity indicates symptom severity. Translucent days show no recorded activity.',
            style: AppTheme.bodySmall.copyWith(
              color: CupertinoColors.systemGrey,
            ),
          ),
          const SizedBox(height: 16),
          severityLegend(),
          const SizedBox(height: 16),
          activityGrid(activityData),
        ],
      ),
    );
  }

  Widget activityGrid(Map<DateTime, int> activityData) {
    final now = DateTime.now();
    final monthsToShow = 12; // Show last 12 months

    final months = <Widget>[];

    for (int monthOffset = 0; monthOffset < monthsToShow; monthOffset++) {
      final monthDate = DateTime(now.year, now.month - monthOffset, 1);
      final monthName = DateFormat('MMM yyyy').format(monthDate);
      final daysInMonth = DateTime(monthDate.year, monthDate.month + 1, 0).day;

      bool monthHasActivity = false;
      for (int day = 1; day <= daysInMonth; day++) {
        final date = DateTime(monthDate.year, monthDate.month, day);
        if (activityData.containsKey(date) && activityData[date]! > 0) {
          monthHasActivity = true;
          break;
        }
      }

      if (!monthHasActivity) continue;

      final monthWeeks = <Widget>[];
      final firstDayOfMonth = DateTime(monthDate.year, monthDate.month, 1);
      final firstWeekday = firstDayOfMonth.weekday; // 1 = Monday, 7 = Sunday

      final totalDays = firstWeekday - 1 + daysInMonth; // Include padding days
      final weeksInMonth = (totalDays / 7).ceil();

      for (int week = 0; week < weeksInMonth; week++) {
        final weekDays = <Widget>[];

        for (int day = 0; day < 7; day++) {
          final dayOffset = week * 7 + day - (firstWeekday - 1);
          final isInMonth = dayOffset >= 0 && dayOffset < daysInMonth;

          if (isInMonth) {
            final date = DateTime(
              monthDate.year,
              monthDate.month,
              dayOffset + 1,
            );
            final severity = activityData[date] ?? 0;
            final color = _severityColor(severity);

            weekDays.add(
              GestureDetector(
                onTap: () => _showDateInfo(context, date, severity),
                child: Container(
                  width: 30,
                  height: 30,
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: severity > 0
                        ? color
                        : AppTheme.backgroundPrimary.withValues(
                            alpha: 0.3,
                          ), // More translucent for inactive days
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: _gridCellBorderColor(severity)),
                  ),
                  child: Center(
                    child: Text(
                      '${date.day}',
                      style: _gridCellTextStyle(severity),
                    ),
                  ),
                ),
              ),
            );
          } else {
            weekDays.add(
              Container(width: 30, height: 30, margin: const EdgeInsets.all(2)),
            );
          }
        }

        monthWeeks.add(Row(mainAxisSize: MainAxisSize.min, children: weekDays));
      }

      months.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8, left: 4),
              child: Text(
                monthName,
                style: AppTheme.bodySmall.copyWith(
                  color: CupertinoColors.systemGrey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ...monthWeeks,
            const SizedBox(height: 16),
          ],
        ),
      );
    }

    if (months.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            children: [
              Icon(
                CupertinoIcons.calendar,
                size: 48,
                color: CupertinoColors.systemGrey.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'No activity data available',
                style: AppTheme.bodyMedium.copyWith(
                  color: CupertinoColors.systemGrey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Start recording symptoms to see trends',
                style: AppTheme.bodySmall.copyWith(
                  color: CupertinoColors.systemGrey.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: months,
      ),
    );
  }

  Color _severityColor(int severity) {
    if (severity == 0) return AppTheme.backgroundPrimary.withValues(alpha: 0.3);

    final normalizedSeverity = severity / 10.0; // 0.0 to 1.0

    final hue = 120 - (normalizedSeverity * 120);

    final saturation = 30 + (normalizedSeverity * 60);

    final lightness = 85 - (normalizedSeverity * 50);

    return HSLColor.fromAHSL(
      1.0,
      hue,
      saturation / 100,
      lightness / 100,
    ).toColor();
  }

  Widget severityLegend() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Severity Levels:',
          style: AppTheme.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: CupertinoColors.white,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            legendItem(0, 'No Activity'),
            for (int i = 1; i <= 10; i++) legendItem(i, '$i'),
          ],
        ),
      ],
    );
  }

  Widget legendItem(int severity, String label) {
    final isInactive = severity == 0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: _severityColor(severity),
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: _legendBorderColor(isInactive), width: 1),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTheme.bodySmall.copyWith(
            color: isInactive
                ? AppTheme.textQuaternary.withValues(alpha: 0.6)
                : CupertinoColors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
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
        Text('Health Notes (${notes.length})', style: AppTheme.headlineSmall),
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
      decoration: AppTheme.primaryCard,
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
                  style: AppTheme.labelLarge,
                ),
              ),
              severityIndicator(symptom.severityLevel),
            ],
          ),
          if (symptom.minorComponent.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              symptom.minorComponent,
              style: AppTheme.bodyMedium.copyWith(
                color: CupertinoColors.systemGrey,
              ),
            ),
          ],
          if (symptom.additionalNotes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(symptom.additionalNotes, style: AppTheme.bodyMedium),
          ],
          if (note.notes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey6,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(note.notes, style: AppTheme.bodySmall),
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
        style: AppTheme.labelSmall.copyWith(color: severityColor),
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

      return symptom.minorComponent.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          symptom.additionalNotes.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          note.notes.toLowerCase().contains(_searchQuery.toLowerCase());
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
              style: AppTheme.headlineSmall.copyWith(
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
                style: AppTheme.labelMedium.copyWith(
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
              _buildInfoRow('Type', symptom.minorComponent),
              const SizedBox(height: 12),
            ],
            if (symptom.additionalNotes.isNotEmpty) ...[
              _buildInfoRow('Notes', symptom.additionalNotes),
              const SizedBox(height: 12),
            ],
            if (noteForDate.notes.isNotEmpty) ...[
              _buildInfoRow('General Notes', noteForDate.notes),
              const SizedBox(height: 12),
            ],
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: AppTheme.cardGradient,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                border: Border.all(
                  color: CupertinoColors.systemGrey4.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    CupertinoIcons.doc_text,
                    color: AppTheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'View full health note',
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(
                    CupertinoIcons.chevron_right,
                    color: AppTheme.primary,
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

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            '$label:',
            style: AppTheme.labelMedium.copyWith(
              color: CupertinoColors.systemGrey,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTheme.bodyMedium.copyWith(color: CupertinoColors.white),
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
          style: AppTheme.headlineSmall.copyWith(
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
                  gradient: AppTheme.cardGradient,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
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
                          style: AppTheme.labelLarge.copyWith(
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
                            style: AppTheme.labelSmall.copyWith(
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
                        style: AppTheme.bodyMedium.copyWith(
                          color: CupertinoColors.systemGrey,
                        ),
                      ),
                    ],
                    if (symptom.additionalNotes.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        symptom.additionalNotes,
                        style: AppTheme.bodyMedium.copyWith(
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
                  gradient: AppTheme.cardGradient,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
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
                      style: AppTheme.labelMedium.copyWith(
                        color: CupertinoColors.systemGrey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      note.notes,
                      style: AppTheme.bodyMedium.copyWith(
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

  Color _gridCellBorderColor(int severity) {
    return severity > 0
        ? CupertinoColors.systemGrey4.withValues(alpha: 0.5)
        : AppTheme.backgroundPrimary.withValues(alpha: 0.2);
  }

  TextStyle _gridCellTextStyle(int severity) {
    return AppTheme.bodySmall.copyWith(
      color: severity > 0
          ? CupertinoColors.white
          : AppTheme.textQuaternary.withValues(alpha: 0.6),
      fontWeight: FontWeight.w600,
      fontSize: 12,
    );
  }

  Color _legendBorderColor(bool isInactive) {
    return isInactive
        ? AppTheme.backgroundPrimary.withValues(alpha: 0.2)
        : CupertinoColors.systemGrey4.withValues(alpha: 0.5);
  }
}
