import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_notes/models/health_note.dart';
import 'package:health_notes/models/drug_dose.dart';
import 'package:health_notes/models/symptom.dart';
import 'package:health_notes/providers/health_notes_provider.dart';
import 'package:health_notes/theme/app_theme.dart';

import 'package:health_notes/services/text_normalizer.dart';
import 'package:health_notes/widgets/enhanced_ui_components.dart';
import 'package:health_notes/widgets/activity_calendar.dart';
import 'package:intl/intl.dart';

class DrugTrendsScreen extends ConsumerStatefulWidget {
  final String drugName;

  const DrugTrendsScreen({super.key, required this.drugName});

  @override
  ConsumerState<DrugTrendsScreen> createState() => _DrugTrendsScreenState();
}

class _DrugTrendsScreenState extends ConsumerState<DrugTrendsScreen> {
  late TextEditingController _searchController;
  String _searchQuery = '';
  final _normalizer = CaseInsensitiveNormalizer();

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
        middle: Text('${widget.drugName} Trends'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).pop(),
          child: const Icon(CupertinoIcons.back),
        ),
      ),
      child: SafeArea(
        child: healthNotesAsync.when(
          data: (notes) => drugTrendsContent(notes),
          loading: () => EnhancedUIComponents.loadingIndicator(
            message: 'Loading drug trends...',
          ),
          error: (error, stack) =>
              Center(child: Text('Error: $error', style: AppTypography.error)),
        ),
      ),
    );
  }

  Widget drugTrendsContent(List<HealthNote> notes) {
    final drugNotes = notes
        .where(
          (note) => note.drugDoses.any(
            (drug) => _normalizer.areEqual(drug.name, widget.drugName),
          ),
        )
        .toList();

    if (drugNotes.isEmpty) {
      return EnhancedUIComponents.emptyState(
        title: 'No data for ${widget.drugName}',
        message: 'No health notes with this drug have been recorded yet',
        icon: CupertinoIcons.exclamationmark_triangle,
      );
    }

    final activityData = _generateActivityData(drugNotes);
    final filteredNotes = _filterNotes(drugNotes);

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
              drugNotesList(filteredNotes),
            ]),
          ),
        ),
      ],
    );
  }

  Widget activityChart(Map<DateTime, double> activityData) {
    return DosageActivityCalendar(
      drugName: widget.drugName,
      activityData: activityData,
      onDateTap: _showDateInfo,
    );
  }

  Widget searchSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Search Notes', style: AppTypography.labelLarge),
        const SizedBox(height: 12),
        EnhancedUIComponents.searchField(
          controller: _searchController,
          placeholder: 'Search notes containing ${widget.drugName}...',
          onChanged: (query) {
            setState(() {
              _searchQuery = query;
            });
          },
        ),
      ],
    );
  }

  Widget drugNotesList(List<HealthNote> notes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Health Notes (${notes.length})',
              style: AppTypography.labelLarge,
            ),
            if (notes.isNotEmpty)
              Text(
                'Total doses: ${_calculateTotalDoses(notes)}',
                style: AppTypography.bodySmallSystemGrey,
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (notes.isEmpty)
          Container(
            decoration: AppComponents.primaryCard,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.search,
                  color: CupertinoColors.systemGrey,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No notes match your search criteria',
                    style: AppTypography.bodyMediumSystemGrey,
                  ),
                ),
              ],
            ),
          )
        else
          ...notes.map((note) => drugNoteCard(note)),
      ],
    );
  }

  Widget drugNoteCard(HealthNote note) {
    final relevantDoses = note.drugDoses
        .where((drug) => _normalizer.areEqual(drug.name, widget.drugName))
        .toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppComponents.primaryCard,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            noteHeader(note.dateTime),
            const SizedBox(height: 12),
            ...relevantDoses.map(dosageContainer),
            if (note.symptomsList.isNotEmpty) symptomsInfo(note.symptomsList),
            if (note.notes.isNotEmpty) notesInfo(note.notes),
          ],
        ),
      ),
    );
  }

  Widget noteHeader(DateTime dateTime) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          DateFormat('EEEE, MMMM dd, yyyy').format(dateTime),
          style: AppTypography.labelMedium,
        ),
        Text(
          DateFormat('h:mm a').format(dateTime),
          style: AppTypography.bodySmallSystemGrey,
        ),
      ],
    );
  }

  Widget dosageContainer(DrugDose dose) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(CupertinoIcons.capsule, color: AppColors.primary, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              dose.fullDisplay,
              style: AppTypography.bodyMediumSemibold,
            ),
          ),
        ],
      ),
    );
  }

  Widget symptomsInfo(List<Symptom> symptoms) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          'Symptoms: ${symptoms.map((s) => s.fullDescription).join(', ')}',
          style: AppTypography.bodySmallSystemGrey,
        ),
      ],
    );
  }

  Widget notesInfo(String notes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text('Notes: $notes', style: AppTypography.bodySmallSystemGrey),
      ],
    );
  }

  Map<DateTime, double> _generateActivityData(List<HealthNote> notes) {
    final activityMap = <DateTime, double>{};

    for (final note in notes) {
      final dateKey = DateTime(
        note.dateTime.year,
        note.dateTime.month,
        note.dateTime.day,
      );

      final relevantDoses = note.drugDoses
          .where((drug) => _normalizer.areEqual(drug.name, widget.drugName))
          .toList();

      if (relevantDoses.isNotEmpty) {
        final totalDosage = relevantDoses
            .map((dose) => dose.dosage)
            .reduce((a, b) => a + b);

        activityMap.update(
          dateKey,
          (existing) => existing + totalDosage,
          ifAbsent: () => totalDosage,
        );
      }
    }

    return activityMap;
  }

  List<HealthNote> _filterNotes(List<HealthNote> notes) {
    if (_searchQuery.isEmpty) {
      return notes.reversed.toList();
    }

    final query = _searchQuery.toLowerCase();
    return notes
        .where(
          (note) =>
              _normalizer.contains(note.notes, query) ||
              note.symptomsList.any(
                (symptom) =>
                    _normalizer.contains(symptom.majorComponent, query) ||
                    _normalizer.contains(symptom.minorComponent, query) ||
                    _normalizer.contains(symptom.additionalNotes, query),
              ) ||
              note.drugDoses.any(
                (drug) => _normalizer.contains(drug.name, query),
              ),
        )
        .toList()
        .reversed
        .toList();
  }

  int _calculateTotalDoses(List<HealthNote> notes) {
    return notes
        .expand((note) => note.drugDoses)
        .where((drug) => _normalizer.areEqual(drug.name, widget.drugName))
        .length;
  }

  void _showDateInfo(BuildContext context, DateTime date, double dosage) {
    if (dosage == 0) {
      final formattedDate = DateFormat('EEEE, MMMM dd, yyyy').format(date);
      showCupertinoDialog(
        context: context,
        builder: (BuildContext context) => CupertinoAlertDialog(
          title: Text(formattedDate),
          content: Text('No ${widget.drugName} was recorded on this date.'),
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

    final notesForDate = notes.where((note) {
      final noteDate = DateTime(
        note.dateTime.year,
        note.dateTime.month,
        note.dateTime.day,
      );
      final targetDate = DateTime(date.year, date.month, date.day);
      return noteDate.isAtSameMomentAs(targetDate) &&
          note.drugDoses.any(
            (drug) => _normalizer.areEqual(drug.name, widget.drugName),
          );
    }).toList();

    if (notesForDate.isEmpty) {
      final formattedDate = DateFormat('EEEE, MMMM dd, yyyy').format(date);
      showCupertinoDialog(
        context: context,
        builder: (BuildContext context) => CupertinoAlertDialog(
          title: Text(formattedDate),
          content: Text(
            'You took ${dosage.toStringAsFixed(dosage.truncateToDouble() == dosage ? 0 : 1)}mg of ${widget.drugName} on this date.',
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
    final relevantDoses = notesForDate
        .expand((note) => note.drugDoses)
        .where((drug) => _normalizer.areEqual(drug.name, widget.drugName))
        .toList();

    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: Text(formattedDate),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Total dosage: ${dosage.toStringAsFixed(dosage.truncateToDouble() == dosage ? 0 : 1)}mg',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            ...relevantDoses.map(
              (dose) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      CupertinoIcons.capsule,
                      color: AppColors.primary,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        dose.fullDisplay,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
