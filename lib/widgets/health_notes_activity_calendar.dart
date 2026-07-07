import 'package:ethan_utils/ethan_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:health_notes/models/health_note.dart';
import 'package:health_notes/theme/app_theme.dart';
import 'package:health_notes/widgets/activity_calendar.dart';
import 'package:health_notes/theme/spacing.dart';

class HealthNotesActivityCalendar extends StatelessWidget {
  final List<HealthNote> notes;
  final void Function(DateTime date) onDateTap;
  final double? gridHeight;
  final bool scrollToEnd;

  const HealthNotesActivityCalendar({
    super.key,
    required this.notes,
    required this.onDateTap,
    this.gridHeight,
    this.scrollToEnd = false,
  });

  @override
  Widget build(BuildContext context) {
    final activityData = activityDataForNotes(notes);
    final maxCount = activityData.values.isEmpty
        ? 0
        : activityData.values.reduce((a, b) => a > b ? a : b);

    return ActivityCalendar<int>(
      title: 'Note Activity',
      subtitle: 'Number shows notes recorded each day',
      activityData: activityData,
      colorCalculator: (count) =>
          CheckInsActivityCalendar.checkInsColor(count, maxCount),
      legendBuilder: () => noteActivityLegend(maxCount),
      onDateTap: (context, date, count) => onDateTap(date),
      activityDescriptor: (count) =>
          count == 0 ? 'No notes' : '$count note${count == 1 ? '' : 's'}',
      emptyValue: 0,
      gridHeight: gridHeight,
      scrollToEnd: scrollToEnd,
    );
  }

  static Map<DateTime, int> activityDataForNotes(List<HealthNote> notes) {
    final data = <DateTime, int>{};

    for (final note in notes) {
      final dateKey = note.dateTime.startOfDay;
      data.update(dateKey, (count) => count + 1, ifAbsent: () => 1);
    }

    return data;
  }

  Widget noteActivityLegend(int maxCount) {
    return Row(
      children: [
        Text('Less', style: AppText.body.small.systemGrey),
        HSpace.s,
        ...intensityGradientSquares(),
        HSpace.s,
        Text('More', style: AppText.body.small.systemGrey),
        const Spacer(),
        if (maxCount > 0)
          Text('Max: $maxCount/day', style: AppText.body.small.systemGrey),
      ],
    );
  }
}
