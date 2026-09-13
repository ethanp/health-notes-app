import 'package:ethan_ui/ethan_ui.dart';
import 'package:ethan_utils/ethan_utils.dart';
import 'package:flutter/material.dart';
import 'package:health_notes/widgets/health_notes_month_stack.dart';

class const ToolActivityCalendar({
  required final String toolName,
  required final Map<DateTime, int> activityData,
  required final void Function(BuildContext context, DateTime date, int count)
  onDateTap,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scale = HealthNotesMonthStack.periodQuartileScale(
      observedQuantities: activityData.values,
      unitTitle: 'uses/day',
      captionForQuantity: (quantity) => '≤${quantity.round()}',
    );
    return HealthNotesMonthStack(
      title: '$toolName Usage',
      subtitle: 'Color intensity indicates usage frequency per day',
      legend: EHeatmapLegend(scale: scale),
      presentationFor: (date) {
        final count = activityData[date.startOfDay] ?? 0;
        return HealthNotesMonthStack.countedDay(
          date: date,
          quantity: count,
          scale: scale,
          caption: (quantity) =>
              quantity == 0 ? 'No uses' : '$quantity use${quantity == 1 ? '' : 's'}',
        );
      },
      quantityOn: (date) => activityData[date.startOfDay] ?? 0,
      chartFrom: activityData.isEmpty ? null : activityData.keys.min,
      measureTitle: 'uses',
      formatMeasure: (quantity) => quantity.round().toString(),
      onDaySelected: (day) =>
          onDateTap(context, day.date, activityData[day.date.startOfDay] ?? 0),
    );
  }
}
