import 'package:flutter/cupertino.dart';
import 'package:health_notes/theme/app_theme.dart';
import 'package:health_notes/widgets/activity_calendar.dart';
import 'package:health_notes/theme/spacing.dart';

class ToolActivityCalendar extends StatelessWidget {
  final String toolName;
  final Map<DateTime, int> activityData;
  final void Function(BuildContext context, DateTime date, int count) onDateTap;

  const ToolActivityCalendar({
    super.key,
    required this.toolName,
    required this.activityData,
    required this.onDateTap,
  });

  int get maxCount => activityData.values.isEmpty
      ? 0
      : activityData.values.reduce((a, b) => a > b ? a : b);

  @override
  Widget build(BuildContext context) {
    return ActivityCalendar<int>(
      title: '$toolName Usage',
      subtitle: 'Color intensity indicates usage frequency per day',
      activityData: activityData,
      colorCalculator: usageColor,
      legendBuilder: usageLegend,
      onDateTap: onDateTap,
      activityDescriptor: (count) =>
          count == 0 ? 'No uses' : '$count use${count == 1 ? '' : 's'}',
      emptyValue: 0,
    );
  }

  Color usageColor(int count) {
    if (count == 0) return AppColors.backgroundPrimary.withValues(alpha: 0.1);
    if (maxCount == 0) return AppColors.primary.withValues(alpha: 0.1);
    return intensityColor(count / maxCount);
  }

  Widget usageLegend() {
    return Row(
      children: [
        Text('Less', style: AppTypography.bodySmallSystemGrey),
        HSpace.s,
        ...intensityGradientSquares(),
        HSpace.s,
        Text('More', style: AppTypography.bodySmallSystemGrey),
        const Spacer(),
        if (maxCount > 0)
          Text('Max: $maxCount/day', style: AppTypography.bodySmallSystemGrey),
      ],
    );
  }
}
