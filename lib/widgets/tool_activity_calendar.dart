import 'package:ethan_ui/ethan_ui.dart';
import 'package:flutter/material.dart';
import 'package:health_notes/widgets/activity_calendar.dart';
import 'package:health_notes/theme/spacing.dart';

class const ToolActivityCalendar({
  required final String toolName,
  required final Map<DateTime, int> activityData,
  required final void Function(BuildContext context, DateTime date, int count)
  onDateTap,
}) extends StatelessWidget {
  int get maxCount => activityData.values.isEmpty
      ? 0
      : activityData.values.reduce((a, b) => a > b ? a : b);

  @override
  Widget build(BuildContext context) {
    return ActivityCalendar<int>(
      title: '$toolName Usage',
      subtitle: 'Color intensity indicates usage frequency per day',
      activityData: activityData,
      colorForActivity: (count) =>
          EHeatmapIntensity.colorForQuantity(count, max: maxCount),
      legendBuilder: usageLegend,
      onDateTap: onDateTap,
      activityDescriptor: (count) =>
          count == 0 ? 'No uses' : '$count use${count == 1 ? '' : 's'}',
      emptyValue: 0,
    );
  }

  Widget usageLegend() {
    return Row(
      children: [
        Text('Less', style: EText.body.small.muted),
        HSpace.s,
        ...EHeatmapIntensity.legendSwatches,
        HSpace.s,
        Text('More', style: EText.body.small.muted),
        const Spacer(),
        if (maxCount > 0)
          Text('Max: $maxCount/day', style: EText.body.small.muted),
      ],
    );
  }
}
