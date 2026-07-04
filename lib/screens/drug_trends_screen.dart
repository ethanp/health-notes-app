import 'package:ethan_utils/ethan_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:health_notes/models/drug_dose.dart';
import 'package:health_notes/models/health_note.dart';
import 'package:health_notes/providers/health_notes_provider.dart';
import 'package:health_notes/screens/health_note_view_screen.dart';
import 'package:health_notes/screens/trends/base_trends_screen.dart';
import 'package:health_notes/services/text_normalizer.dart';
import 'package:health_notes/theme/app_theme.dart';
import 'package:health_notes/utils/date_utils.dart';
import 'package:health_notes/utils/note_filter_utils.dart';
import 'package:health_notes/utils/number_formatter.dart';
import 'package:health_notes/widgets/activity_calendar.dart';
import 'package:health_notes/widgets/drug/bulk_dose_sheet.dart';
import 'package:health_notes/widgets/health_note_card.dart';
import 'package:health_notes/theme/spacing.dart';
import 'package:health_notes/services/trends_activity_aggregator.dart';

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
    return TrendsActivityAggregator.aggregate<double>(
      notes: notes,
      valueExtractor: (note) => _totalDosageForNote(note),
      combiner: (existing, newValue) => existing + newValue,
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
      onMultiSelectConfirmed: (dates) => _handleBulkAddRequested(dates, unit),
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
    final targetDate = date.startOfDay;
    return notes
        .where(
          (note) =>
              note.dateTime.sameDayAs(targetDate) &&
              _relevantDoses(note).isNotEmpty,
        )
        .toList();
  }

  @override
  String noActivityMessage(DateTime date) =>
      'No ${widget.drugName} was recorded on this date.';

  @override
  String valueOnlyMessage(DateTime date, double dosage) {
    final unit = _unitForDrug([]) ?? 'mg';
    return 'You took ${formatDecimalValue(dosage)}$unit of ${widget.drugName} on this date.';
  }

  @override
  Widget? dateSummary(
    DateTime date,
    double dosage,
    List<HealthNote> notes,
  ) {
    final unit = _unitForDrug(notes) ?? 'mg';
    return Text(
      'Total dosage: ${formatDecimalValue(dosage)}$unit',
      style: const TextStyle(fontWeight: FontWeight.w600),
    );
  }

  @override
  Widget noteDetailLabel(HealthNote note) {
    final unit = _unitForDrug([note]) ?? 'mg';
    final noteDosage = _totalDosageForNote(note);
    return Text(
      '${AppDateUtils.formatTime(note.dateTime)}  ·  ${formatDecimalValue(noteDosage)}$unit',
    );
  }

  List<DrugDose> _relevantDoses(HealthNote note) {
    return note.drugDoses
        .where((drug) => _normalizer.areEqual(drug.name, widget.drugName))
        .toList();
  }

  double _totalDosageForNote(HealthNote note) {
    return _relevantDoses(note)
        .map((dose) => dose.dosage)
        .fold<double>(0, (sum, dosage) => sum + dosage);
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

  int _calculateTotalDoses(List<HealthNote> notes) {
    return notes
        .expand((note) => note.drugDoses)
        .where((drug) => _normalizer.areEqual(drug.name, widget.drugName))
        .length;
  }

  void _handleBulkAddRequested(List<DateTime> dates, String unit) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (sheetContext) => BulkDoseSheet(
        drugName: widget.drugName,
        initialUnit: unit,
        dates: dates,
        onConfirm: (dosage, confirmedUnit) =>
            _persistBulkDoses(dates, dosage, confirmedUnit),
      ),
    );
  }

  Future<void> _persistBulkDoses(
    List<DateTime> dates,
    double dosage,
    String unit,
  ) async {
    final notifier = ref.read(healthNotesNotifierProvider.notifier);
    for (final date in dates) {
      await notifier.addNote(
        dateTime: DateTime(date.year, date.month, date.day, 12),
        symptomsList: [],
        drugDoses: [DrugDose(name: widget.drugName, dosage: dosage, unit: unit)],
        notes: '',
      );
    }
  }
}
