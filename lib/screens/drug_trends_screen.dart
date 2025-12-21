import 'package:flutter/cupertino.dart';
import 'package:health_notes/models/drug_dose.dart';
import 'package:health_notes/models/health_note.dart';
import 'package:health_notes/providers/health_notes_provider.dart';
import 'package:health_notes/screens/trends/base_trends_screen.dart';
import 'package:health_notes/services/text_normalizer.dart';
import 'package:health_notes/theme/app_theme.dart';
import 'package:health_notes/utils/date_utils.dart';
import 'package:health_notes/utils/note_filter_utils.dart';
import 'package:health_notes/utils/number_formatter.dart';
import 'package:health_notes/widgets/activity_calendar.dart';
import 'package:health_notes/widgets/health_note_card.dart';
import 'package:health_notes/theme/spacing.dart';
import 'package:health_notes/widgets/trends_components.dart';

class DrugTrendsScreen extends BaseTrendsScreen {
  final String drugName;

  const DrugTrendsScreen({required this.drugName}) : super(itemName: drugName);

  @override
  BaseTrendsState<DrugTrendsScreen, double> createState() =>
      _DrugTrendsScreenState();
}

class _DrugTrendsScreenState extends BaseTrendsState<DrugTrendsScreen, double> {
  final _normalizer = CaseInsensitiveNormalizer();

  @override
  String get itemNoun => 'drug';

  @override
  Future<void> onRefresh() async {
    await ref.read(healthNotesNotifierProvider.notifier).refreshNotes();
  }

  @override
  List<HealthNote> filterSourceNotes(List<HealthNote> notes) {
    return NoteFilterUtils.byDrug(notes, widget.drugName);
  }

  @override
  Map<DateTime, double> buildActivityData(List<HealthNote> notes) {
    return TrendsActivityDataGenerator.generate<double>(
      notes: notes,
      valueExtractor: (note) => _totalDosageForNote(note),
      aggregator: (existing, newValue) => existing + newValue,
    );
  }

  @override
  Widget buildActivityContent(
    Map<DateTime, double> activityData,
    List<HealthNote> notes,
  ) {
    final unit = _unitForDrug(notes) ?? 'mg';
    return DosageActivityCalendar(
      drugName: widget.drugName,
      activityData: activityData,
      onDateTap: (context, date, dosage) =>
          handleDateTap(context, date, dosage, notes),
      unit: unit,
    );
  }

  @override
  List<Widget> buildNotesContent(List<HealthNote> notes) {
    return notes
        .map(
          (note) =>
              HealthNoteCard(note: note, onTap: () => _showNoteDetail(note)),
        )
        .toList();
  }

  @override
  Widget? buildNotesHeader(List<HealthNote> notes) {
    final totalDoses = _calculateTotalDoses(notes);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            'Total doses: $totalDoses',
            style: AppTypography.bodySmallSystemGrey,
          ),
        ),
        VSpace.of(12),
      ],
    );
  }

  @override
  List<HealthNote> notesForDate(List<HealthNote> notes, DateTime date) {
    final targetDate = AppDateUtils.dateOnly(date);
    return notes
        .where(
          (note) =>
              AppDateUtils.isSameDay(note.dateTime, targetDate) &&
              _relevantDoses(note).isNotEmpty,
        )
        .toList();
  }

  @override
  CupertinoAlertDialog buildNoActivityDialog(
    BuildContext dialogContext,
    DateTime date,
  ) {
    return noDosageAlert(
      dialogContext,
      AppDateUtils.formatLongDate(date),
      widget.drugName,
    );
  }

  @override
  CupertinoAlertDialog buildValueOnlyDialog(
    BuildContext dialogContext,
    DateTime date,
    double dosage,
    List<HealthNote> scopedNotes,
  ) {
    return dosageSummaryAlert(
      dialogContext,
      AppDateUtils.formatLongDate(date),
      dosage,
      widget.drugName,
      _unitForDrug(scopedNotes) ?? 'mg',
    );
  }

  @override
  CupertinoAlertDialog buildDetailDialog(
    BuildContext dialogContext,
    DateTime date,
    double dosage,
    List<HealthNote> relevantNotes,
  ) {
    final relevantDoses = relevantNotes
        .expand((note) => _relevantDoses(note))
        .toList();
    return dosageDetailAlert(
      dialogContext,
      AppDateUtils.formatLongDate(date),
      dosage,
      relevantDoses,
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
    showCupertinoDialog(
      context: context,
      builder: (dialogContext) => dosageDetailAlert(
        dialogContext,
        AppDateUtils.formatLongDate(note.dateTime),
        _totalDosageForNote(note),
        _relevantDoses(note),
      ),
    );
  }

  int _calculateTotalDoses(List<HealthNote> notes) {
    return notes
        .expand((note) => note.drugDoses)
        .where((drug) => _normalizer.areEqual(drug.name, widget.drugName))
        .length;
  }

  CupertinoAlertDialog noDosageAlert(
    BuildContext dialogContext,
    String formattedDate,
    String drugName,
  ) {
    return CupertinoAlertDialog(
      title: Text(formattedDate),
      content: Text('No $drugName was recorded on this date.'),
      actions: [
        CupertinoDialogAction(
          child: const Text('OK'),
          onPressed: () => Navigator.of(dialogContext).pop(),
        ),
      ],
    );
  }

  CupertinoAlertDialog dosageSummaryAlert(
    BuildContext dialogContext,
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
          onPressed: () => Navigator.of(dialogContext).pop(),
        ),
      ],
    );
  }

  CupertinoAlertDialog dosageDetailAlert(
    BuildContext dialogContext,
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
          onPressed: () => Navigator.of(dialogContext).pop(),
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
