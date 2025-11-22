import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_notes/models/health_note.dart';
import 'package:health_notes/models/drug_dose.dart';
import 'package:health_notes/providers/health_notes_provider.dart';
import 'package:health_notes/theme/app_theme.dart';
import 'package:health_notes/utils/number_formatter.dart';
import 'package:health_notes/services/text_normalizer.dart';
import 'package:health_notes/utils/date_utils.dart';
import 'package:health_notes/utils/note_filter_utils.dart';
import 'package:health_notes/widgets/activity_calendar.dart';
import 'package:health_notes/widgets/enhanced_ui_components.dart';
import 'package:health_notes/widgets/health_note_card.dart';
import 'package:health_notes/widgets/trends_components.dart';
import 'package:health_notes/widgets/spacing.dart';

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
    final drugNotes = NoteFilterUtils.byDrug(notes, widget.drugName);

    if (drugNotes.isEmpty) {
      return EnhancedUIComponents.emptyState(
        title: 'No data for ${widget.drugName}',
        message: 'No health notes with this drug have been recorded yet',
        icon: CupertinoIcons.exclamationmark_triangle,
      );
    }

    final sortedDrugNotes = NoteFilterUtils.sortByDateDescending(drugNotes);
    final activityData = TrendsActivityDataGenerator.generate<double>(
      notes: sortedDrugNotes,
      valueExtractor: (note) => _totalDosageForNote(note),
      aggregator: (existing, newValue) => existing + newValue,
    );
    final unit = _unitForDrug(sortedDrugNotes) ?? 'mg';
    final filteredNotes = _searchQuery.isEmpty
        ? sortedDrugNotes
        : NoteFilterUtils.sortByDateDescending(
            NoteFilterUtils.bySearchQuery(sortedDrugNotes, _searchQuery),
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
              activityChart(activityData, unit),
              VSpace.of(20),
              searchSection(),
              VSpace.of(20),
              drugNotesList(filteredNotes),
            ]),
          ),
        ),
      ],
    );
  }

  Widget activityChart(Map<DateTime, double> activityData, String unit) {
    return DosageActivityCalendar(
      drugName: widget.drugName,
      activityData: activityData,
      onDateTap: _showDateInfo,
      unit: unit,
    );
  }

  Widget searchSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Search Notes', style: AppTypography.labelLarge),
        VSpace.of(12),
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
    if (notes.isEmpty) {
      return const NoMatchingNotesState();
    }

    return NotesSection(
      noteCount: notes.length,
      noteCards: [
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            'Total doses: ${_calculateTotalDoses(notes)}',
            style: AppTypography.bodySmallSystemGrey,
          ),
        ),
        VSpace.of(12),
        ...notes.map(
          (note) =>
              HealthNoteCard(note: note, onTap: () => _showNoteDetail(note)),
        ),
      ],
    );
  }

  List<DrugDose> _relevantDoses(HealthNote note) {
    return note.drugDoses
        .where((drug) => _normalizer.areEqual(drug.name, widget.drugName))
        .toList();
  }

  double _totalDosageForNote(HealthNote note) {
    return _relevantDoses(
      note,
    ).map((dose) => dose.dosage).fold<double>(0, (sum, value) => sum + value);
  }

  String? _unitForDrug(List<HealthNote> notes) {
    for (final note in notes) {
      for (final dose in note.drugDoses) {
        if (_normalizer.areEqual(dose.name, widget.drugName)) {
          return dose.unit;
        }
      }
    }
    return null;
  }

  void _showNoteDetail(HealthNote note) {
    final relevantDoses = _relevantDoses(note);
    final totalDosage = _totalDosageForNote(note);

    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) => dosageDetailAlert(
        AppDateUtils.formatLongDate(note.dateTime),
        totalDosage,
        relevantDoses,
      ),
    );
  }

  int _calculateTotalDoses(List<HealthNote> notes) {
    return notes
        .expand((note) => note.drugDoses)
        .where((drug) => _normalizer.areEqual(drug.name, widget.drugName))
        .length;
  }

  void _showDateInfo(BuildContext context, DateTime date, double dosage) {
    if (dosage == 0) {
      final formattedDate = AppDateUtils.formatLongDate(date);
      showCupertinoDialog(
        context: context,
        builder: (BuildContext context) =>
            noDosageAlert(formattedDate, widget.drugName),
      );
      return;
    }

    final healthNotesAsync = ref.read(healthNotesNotifierProvider);
    final notes = healthNotesAsync.value ?? [];

    final notesForDate = _findNotesForDateWithDrug(notes, date);

    if (notesForDate.isEmpty) {
      final formattedDate = AppDateUtils.formatLongDate(date);
      showCupertinoDialog(
        context: context,
        builder: (BuildContext context) => dosageSummaryAlert(
          formattedDate,
          dosage,
          widget.drugName,
          _unitForDrug(notes) ?? 'mg',
        ),
      );
      return;
    }

    final formattedDate = AppDateUtils.formatLongDate(date);
    final relevantDoses = notesForDate
        .expand((note) => note.drugDoses)
        .where((drug) => _normalizer.areEqual(drug.name, widget.drugName))
        .toList();

    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) =>
          dosageDetailAlert(formattedDate, dosage, relevantDoses),
    );
  }

  CupertinoAlertDialog noDosageAlert(String formattedDate, String drugName) {
    return CupertinoAlertDialog(
      title: Text(formattedDate),
      content: Text('No $drugName was recorded on this date.'),
      actions: [
        CupertinoDialogAction(
          child: const Text('OK'),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  List<HealthNote> _findNotesForDateWithDrug(
    List<HealthNote> notes,
    DateTime date,
  ) {
    final targetDate = AppDateUtils.dateOnly(date);
    return notes
        .where(
          (note) =>
              AppDateUtils.isSameDay(note.dateTime, targetDate) &&
              _relevantDoses(note).isNotEmpty,
        )
        .toList();
  }

  CupertinoAlertDialog dosageSummaryAlert(
    String formattedDate,
    double dosage,
    String drugName,
    String unit,
  ) {
    return CupertinoAlertDialog(
      title: Text(formattedDate),
      content: Text(
        'You took ${formatDecimalValue(dosage)}$unit of $drugName on this date.',
      ),
      actions: [
        CupertinoDialogAction(
          child: const Text('OK'),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  CupertinoAlertDialog dosageDetailAlert(
    String formattedDate,
    double dosage,
    List<DrugDose> relevantDoses,
  ) {
    final unit = relevantDoses.isNotEmpty ? relevantDoses.first.unit : 'mg';
    return CupertinoAlertDialog(
      title: Text(formattedDate),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Total dosage: ${formatDecimalValue(dosage)}$unit',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          VSpace.m,
          ...relevantDoses.map((dose) => doseRow(dose)),
        ],
      ),
      actions: [
        CupertinoDialogAction(
          child: const Text('OK'),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Widget doseRow(DrugDose dose) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(CupertinoIcons.capsule, color: AppColors.primary, size: 16),
          HSpace.s,
          Expanded(
            child: Text(dose.fullDisplay, style: const TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }
}
