import 'package:ethan_ui/ethan_ui.dart';
import 'package:ethan_utils/ethan_utils.dart';
import 'package:flutter/material.dart';
import 'package:health_notes/models/health_note.dart';
import 'package:health_notes/widgets/health_notes_month_stack.dart';

class const HealthNotesActivityCalendar({
  required final List<HealthNote> notes,
  required final void Function(DateTime date) onDateTap,
  final double? gridHeight,
  final bool scrollToEnd = false,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final activityData = noteCountByDay(notes);
    final scale = HealthNotesMonthStack.periodQuartileScale(
      observedQuantities: activityData.values,
      unitTitle: 'notes/day',
      captionForQuantity: (quantity) => '≤${quantity.round()}',
    );
    return HealthNotesMonthStack(
      title: 'Note Activity',
      subtitle: 'Number shows notes recorded each day',
      legend: EHeatmapLegend(scale: scale),
      gridHeight: gridHeight,
      scrollToEnd: scrollToEnd,
      presentationFor: (date) {
        final count = activityData[date.startOfDay] ?? 0;
        return HealthNotesMonthStack.countedDay(
          date: date,
          quantity: count,
          scale: scale,
          caption: (quantity) =>
              quantity == 0 ? 'No notes' : '$quantity note${quantity == 1 ? '' : 's'}',
        );
      },
      quantityOn: (date) => activityData[date.startOfDay] ?? 0,
      chartFrom: activityData.isEmpty ? null : activityData.keys.min,
      measureTitle: 'notes',
      formatMeasure: (quantity) => quantity.round().toString(),
      onDaySelected: (day) => onDateTap(day.date),
    );
  }

  static Map<DateTime, int> noteCountByDay(List<HealthNote> notes) {
    final data = <DateTime, int>{};
    for (final note in notes) {
      final dateKey = note.dateTime.startOfDay;
      data.update(dateKey, (count) => count + 1, ifAbsent: () => 1);
    }
    return data;
  }
}
