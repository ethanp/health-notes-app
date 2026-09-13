import 'package:ethan_ui/ethan_ui.dart';
import 'package:ethan_utils/ethan_utils.dart';
import 'package:flutter/material.dart';
import 'package:health_notes/models/check_in.dart';
import 'package:health_notes/theme/app_theme.dart';
import 'package:health_notes/theme/spacing.dart';
import 'package:health_notes/utils/symptom_severity.dart';
import 'package:health_notes/utils/whole_number_or_trimmed_decimal.dart';
import 'package:health_notes/widgets/health_notes_month_stack.dart';

class const SeverityActivityCalendar({
  required final String itemName,
  required final Map<DateTime, int> activityData,
  required final void Function(
    BuildContext context,
    DateTime date,
    int severity,
  )
  onDateTap,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return HealthNotesMonthStack(
      title: '$itemName Activity',
      subtitle:
          'Color intensity indicates symptom severity. Translucent days show no recorded activity.',
      legend: _severityLegend(),
      presentationFor: (date) {
        final severity = activityData[date.startOfDay] ?? 0;
        return HealthNotesMonthStack.severityDay(
          date: date,
          severity: severity,
          background: SymptomSeverity.hslGreenToRed(severity),
          semanticsLabel: severity == 0
              ? 'No activity'
              : 'Severity level $severity',
        );
      },
      quantityOn: (date) => activityData[date.startOfDay] ?? 0,
      chartFrom: activityData.isEmpty ? null : activityData.keys.min,
      measureTitle: 'severity',
      formatMeasure: (quantity) => quantity.round().toString(),
      onDaySelected: (day) =>
          onDateTap(context, day.date, activityData[day.date.startOfDay] ?? 0),
    );
  }

  Widget _severityLegend() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Severity 0–10', style: EText.body.medium.white.semibold),
        VSpace.s,
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            _severityLegendItem(0, 'No Activity'),
            for (var severity = 1; severity <= 10; severity++)
              _severityLegendItem(severity, '$severity'),
          ],
        ),
      ],
    );
  }

  Widget _severityLegendItem(int severity, String label) {
    final color = SymptomSeverity.hslGreenToRed(severity);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(AppRadius.xs),
            border: Border.all(
              color: severity == 0
                  ? EColors.borderStrong.withValues(alpha: 0.3)
                  : color.withValues(alpha: 0.6),
            ),
          ),
        ),
        HSpace.xs,
        Text(
          label,
          style: EText.body.small.copyWith(
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }
}

class const DosageActivityCalendar({
  required final String drugName,
  required final Map<DateTime, double> activityData,
  required final void Function(
    BuildContext context,
    DateTime date,
    double dosage,
  )
  onDateTap,
  required final String unit,
  final void Function(List<DateTime> dates)? onMultiSelectConfirmed,
}) extends StatelessWidget {
  static EPeriodQuartileHeatmapScale scaleFor({
    required Iterable<num> observedDosages,
    required String unit,
  }) => HealthNotesMonthStack.periodQuartileScale(
    observedQuantities: observedDosages,
    unitTitle: 'dosage',
    captionForQuantity: (quantity) =>
        '${quantity.wholeNumberOrTrimmedDecimal}$unit',
  );

  @override
  Widget build(BuildContext context) {
    final scale = scaleFor(observedDosages: activityData.values, unit: unit);
    return HealthNotesMonthStack(
      title: '$drugName Activity',
      subtitle:
          'Color intensity indicates dosage amount. Translucent days show no recorded doses.',
      legend: EHeatmapLegend(scale: scale),
      presentationFor: (date) {
        final dosage = activityData[date.startOfDay] ?? 0.0;
        return HealthNotesMonthStack.countedDay(
          date: date,
          quantity: dosage,
          scale: scale,
          caption: (quantity) => quantity == 0
              ? 'No doses'
              : '${quantity.wholeNumberOrTrimmedDecimal}$unit',
        );
      },
      quantityOn: (date) => activityData[date.startOfDay] ?? 0,
      chartFrom: activityData.isEmpty ? null : activityData.keys.min,
      measureTitle: 'dosage',
      formatMeasure: (quantity) =>
          '${quantity.wholeNumberOrTrimmedDecimal}$unit',
      onDaySelected: (day) =>
          onDateTap(context, day.date, activityData[day.date.startOfDay] ?? 0),
      onMultiSelectConfirmed: onMultiSelectConfirmed,
      multiSelectActionLabel: 'Add Dose',
    );
  }
}

class const CheckInsActivityCalendar({
  required final List<CheckIn> checkIns,
  required final void Function(DateTime date) onDateTap,
  final double? gridHeight,
  final bool scrollToEnd = false,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final activityData = checkInCountByDay();
    final scale = HealthNotesMonthStack.periodQuartileScale(
      observedQuantities: activityData.values,
      unitTitle: 'check-ins/day',
      captionForQuantity: (quantity) => '≤${quantity.round()}',
    );
    return HealthNotesMonthStack(
      title: 'Check-ins',
      subtitle: 'Tap on a date to view check-ins for that day',
      legend: EHeatmapLegend(scale: scale),
      gridHeight: gridHeight,
      scrollToEnd: scrollToEnd,
      presentationFor: (date) {
        final count = activityData[date.startOfDay] ?? 0;
        return HealthNotesMonthStack.countedDay(
          date: date,
          quantity: count,
          scale: scale,
          caption: (quantity) => quantity == 0
              ? 'No check-ins'
              : '$quantity check-in${quantity == 1 ? '' : 's'}',
        );
      },
      quantityOn: (date) => activityData[date.startOfDay] ?? 0,
      chartFrom: activityData.isEmpty ? null : activityData.keys.min,
      measureTitle: 'check-ins',
      formatMeasure: (quantity) => quantity.round().toString(),
      onDaySelected: (day) => onDateTap(day.date),
    );
  }

  Map<DateTime, int> checkInCountByDay() {
    final data = <DateTime, int>{};
    for (final checkIn in checkIns) {
      final dateKey = checkIn.dateTime.startOfDay;
      data.update(dateKey, (count) => count + 1, ifAbsent: () => 1);
    }
    return data;
  }
}
