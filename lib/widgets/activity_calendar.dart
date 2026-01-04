import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:health_notes/models/check_in.dart';
import 'package:health_notes/theme/app_theme.dart';
import 'package:health_notes/theme/spacing.dart';
import 'package:health_notes/utils/date_utils.dart';
import 'package:health_notes/utils/number_formatter.dart';
import 'package:health_notes/utils/severity_utils.dart';

typedef ColorCalculator<T> = Color Function(T value);
typedef LegendBuilder<T> = Widget Function();
typedef DateInfoCallback<T> =
    void Function(BuildContext context, DateTime date, T value);
typedef ActivityDescriptor<T> = String Function(T value);
typedef DayCellBuilder<T> =
    Widget Function(
      BuildContext context,
      DateTime date,
      T value,
      bool hasActivity,
      Color color,
    );

typedef WeekStats = ({
  List<Widget> cells,
  int activeDays,
  num sum,
  bool ownsWeek,
});

class CalendarConstants {
  static const double cellSize = 39;
  static const double cellMargin = 2;
  static const double summaryWidth = 55;
  static const double daysBadgeWidth = 18;
  static const double legendItemSize = 12;
  static const double summaryFontSize = 10;
  static const int daysPerWeek = 7;
  static const int monthsToShow = 12;
  static const double alphaMin = 0.15;
  static const double alphaMax = 0.9;
  static const double boldThreshold = 0.5;
}

Color intensityColor(
  double intensity, {
  double alphaMin = 0.15,
  double alphaMax = 0.9,
}) {
  return Color.lerp(
    AppColors.primary.withValues(alpha: alphaMin),
    AppColors.primary.withValues(alpha: alphaMax),
    intensity,
  )!;
}

class ActivityCalendar<T> extends StatefulWidget {
  final String title;
  final String subtitle;
  final Map<DateTime, T> activityData;
  final ColorCalculator<T> colorCalculator;
  final LegendBuilder<T> legendBuilder;
  final DateInfoCallback<T> onDateTap;
  final ActivityDescriptor<T> activityDescriptor;
  final T emptyValue;
  final DayCellBuilder<T>? dayCellBuilder;
  final double? gridHeight;
  final bool scrollToEnd;

  const ActivityCalendar({
    super.key,
    required this.title,
    required this.subtitle,
    required this.activityData,
    required this.colorCalculator,
    required this.legendBuilder,
    required this.onDateTap,
    required this.activityDescriptor,
    required this.emptyValue,
    this.dayCellBuilder,
    this.gridHeight,
    this.scrollToEnd = false,
  });

  @override
  State<ActivityCalendar<T>> createState() => _ActivityCalendarState<T>();
}

class _ActivityCalendarState<T> extends State<ActivityCalendar<T>> {
  ScrollController? _scrollController;

  @override
  void initState() {
    super.initState();
    if (widget.gridHeight != null) {
      _scrollController = ScrollController();
      if (widget.scrollToEnd) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController!.hasClients) {
            _scrollController!.jumpTo(
              _scrollController!.position.maxScrollExtent,
            );
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _scrollController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppComponents.primaryCard,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.title, style: AppTypography.headlineSmall),
          VSpace.s,
          Text(widget.subtitle, style: AppTypography.bodySmallSystemGrey),
          VSpace.m,
          widget.legendBuilder(),
          VSpace.m,
          widget.gridHeight != null
              ? SizedBox(
                  height: widget.gridHeight,
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    child: activityGrid(context),
                  ),
                )
              : activityGrid(context),
        ],
      ),
    );
  }

  Widget activityGrid(BuildContext context) {
    final globalMaxSum = computeGlobalMaxSum();
    final months = buildActiveMonths(context, globalMaxSum);
    return months.isEmpty ? emptyState() : monthsScrollView(months);
  }

  num computeGlobalMaxSum() {
    final weekSums = <int, num>{};

    for (final entry in widget.activityData.entries) {
      if (entry.value == widget.emptyValue || entry.value is! num) continue;
      final v = (entry.value as num);
      final weekKey = isoWeekKey(entry.key);
      weekSums.update(weekKey, (sum) => sum + v, ifAbsent: () => v);
    }

    return weekSums.values.fold(0, math.max);
  }

  int isoWeekKey(DateTime date) {
    final monday = date.subtract(Duration(days: date.weekday - 1));
    return monday.year * 10000 + monday.month * 100 + monday.day;
  }

  List<Widget> buildActiveMonths(BuildContext context, num globalMaxSum) {
    final now = DateTime.now();
    final months = <Widget>[];

    for (
      int offset = CalendarConstants.monthsToShow - 1;
      offset >= 0;
      offset--
    ) {
      final monthDate = DateTime(now.year, now.month - offset, 1);
      final daysInMonth = DateTime(monthDate.year, monthDate.month + 1, 0).day;

      if (monthHasActivity(monthDate, daysInMonth)) {
        months.add(monthWidget(context, monthDate, daysInMonth, globalMaxSum));
      }
    }

    return months;
  }

  bool monthHasActivity(DateTime monthDate, int daysInMonth) {
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(monthDate.year, monthDate.month, day);
      if (widget.activityData.containsKey(date) &&
          widget.activityData[date] != widget.emptyValue) {
        return true;
      }
    }
    return false;
  }

  Widget monthWidget(
    BuildContext context,
    DateTime monthDate,
    int daysInMonth,
    num globalMaxSum,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        monthHeader(AppDateUtils.formatMonthYear(monthDate)),
        dayOfWeekLabel(),
        ...buildWeekRows(context, monthDate, daysInMonth, globalMaxSum),
        VSpace.m,
      ],
    );
  }

  Widget monthHeader(String monthName) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2, left: 4),
      child: Text(monthName, style: AppTypography.bodySmallSystemGreySemibold),
    );
  }

  static const _dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  Widget dayOfWeekLabel() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final label in _dayLabels)
          SizedBox(
            width:
                CalendarConstants.cellSize + CalendarConstants.cellMargin * 2,
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(
                color: CupertinoColors.systemGrey,
                fontSize: 9,
              ),
            ),
          ),
        SizedBox(width: CalendarConstants.summaryWidth + 8),
      ],
    );
  }

  List<Widget> buildWeekRows(
    BuildContext context,
    DateTime monthDate,
    int daysInMonth,
    num globalMaxSum,
  ) {
    return computeWeekStats(
      context,
      monthDate,
      daysInMonth,
    ).map((stat) => buildWeekRow(stat, globalMaxSum)).toList();
  }

  List<WeekStats> computeWeekStats(
    BuildContext context,
    DateTime monthDate,
    int daysInMonth,
  ) {
    final firstWeekday = DateTime(monthDate.year, monthDate.month, 1).weekday;
    final totalDays = firstWeekday - 1 + daysInMonth;
    final weeksInMonth = (totalDays / CalendarConstants.daysPerWeek).ceil();

    return List.generate(
      weeksInMonth,
      (week) =>
          buildWeekStat(context, monthDate, daysInMonth, week, firstWeekday),
    );
  }

  WeekStats buildWeekStat(
    BuildContext context,
    DateTime monthDate,
    int daysInMonth,
    int week,
    int firstWeekday,
  ) {
    final cells = <Widget>[];
    var activeDays = 0;
    num sum = 0;
    var ownsWeek = false;

    for (int day = 0; day < CalendarConstants.daysPerWeek; day++) {
      final dayOffset =
          week * CalendarConstants.daysPerWeek + day - (firstWeekday - 1);
      final isInMonth = dayOffset >= 0 && dayOffset < daysInMonth;

      if (isInMonth) {
        final date = DateTime(monthDate.year, monthDate.month, dayOffset + 1);
        if (day == 6) ownsWeek = true;
        cells.add(dayCell(context, date));
      } else {
        cells.add(emptyCell());
      }
    }

    if (ownsWeek) {
      final sundayOffset =
          week * CalendarConstants.daysPerWeek + 6 - (firstWeekday - 1);
      final sunday = DateTime(
        monthDate.year,
        monthDate.month,
        sundayOffset + 1,
      );
      final monday = sunday.subtract(const Duration(days: 6));
      for (int i = 0; i < CalendarConstants.daysPerWeek; i++) {
        final date = monday.add(Duration(days: i));
        final value = widget.activityData[date] ?? widget.emptyValue;
        if (value != widget.emptyValue) {
          activeDays++;
          if (value is num) sum += value;
        }
      }
    }

    return (cells: cells, activeDays: activeDays, sum: sum, ownsWeek: ownsWeek);
  }

  num findMaxSum(List<WeekStats> stats) =>
      stats.fold<num>(0, (max, stat) => stat.sum > max ? stat.sum : max);

  Widget buildWeekRow(WeekStats stat, num maxSum) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [...stat.cells, weekSummary(stat, maxSum)],
      ),
    );
  }

  Widget weekSummary(WeekStats stat, num maxSum) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0),
      child: SizedBox(
        width: CalendarConstants.summaryWidth,
        child: stat.ownsWeek && stat.activeDays > 0
            ? weekSummaryContent(stat.activeDays, stat.sum, maxSum)
            : null,
      ),
    );
  }

  Widget weekSummaryContent(int activeDays, num sum, num maxSum) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [daysBadge(activeDays), sumLabel(sum, maxSum)],
    );
  }

  Widget daysBadge(int activeDays) {
    final intensity = activeDays / CalendarConstants.daysPerWeek;

    return SizedBox(
      width: CalendarConstants.daysBadgeWidth,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: intensityColor(intensity, alphaMin: 0.15, alphaMax: 0.7),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          '$activeDays',
          textAlign: TextAlign.center,
          style: AppTypography.bodySmall.copyWith(
            color: CupertinoColors.white,
            fontSize: CalendarConstants.summaryFontSize,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget sumLabel(num sum, num maxSum) {
    final intensity = maxSum > 0 ? sum / maxSum : 0.0;
    final display = sum is double
        ? formatDecimalValue(sum)
        : sum.toInt().toString();

    return Text(
      display,
      textAlign: TextAlign.right,
      style: AppTypography.bodySmall.copyWith(
        color: Color.lerp(
          CupertinoColors.systemGrey.withValues(alpha: 0.5),
          CupertinoColors.white,
          intensity,
        ),
        fontSize: CalendarConstants.summaryFontSize,
        fontWeight: intensity > CalendarConstants.boldThreshold
            ? FontWeight.w600
            : FontWeight.normal,
      ),
    );
  }

  Widget dayCell(BuildContext context, DateTime date) {
    final value = widget.activityData[date] ?? widget.emptyValue;
    final hasActivity = value != widget.emptyValue;
    final color = widget.colorCalculator(value);

    if (widget.dayCellBuilder != null) {
      return widget.dayCellBuilder!(context, date, value, hasActivity, color);
    }

    return GestureDetector(
      onTap: () => widget.onDateTap(context, date, value),
      child: Container(
        width: CalendarConstants.cellSize,
        height: CalendarConstants.cellSize,
        margin: const EdgeInsets.all(CalendarConstants.cellMargin),
        decoration: dayCellDecoration(hasActivity, color, value, date),
        child: Stack(
          children: [
            if (hasActivity) miniDateLabel(date),
            Center(child: dayCellText(value, hasActivity, date)),
          ],
        ),
      ),
    );
  }

  Widget miniDateLabel(DateTime date) {
    return Positioned(
      left: 3,
      top: 2,
      child: Text(
        '${date.day}',
        style: TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w500,
          color: AppColors.backgroundPrimary,
        ),
      ),
    );
  }

  BoxDecoration dayCellDecoration(
    bool hasActivity,
    Color color,
    T value,
    DateTime date,
  ) {
    final isToday = _isToday(date);
    return BoxDecoration(
      color: hasActivity
          ? color
          : AppColors.backgroundPrimary.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(
        color: isToday ? AppColors.todayBorder : cellBorderColor(value),
        width: isToday ? 1.5 : (hasActivity ? 1 : 0.5),
      ),
      boxShadow: hasActivity ? [dayCellShadow(color)] : null,
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  BoxShadow dayCellShadow(Color color) {
    return BoxShadow(
      color: color.withValues(alpha: 0.3),
      blurRadius: 3,
      offset: const Offset(0, 1),
    );
  }

  Widget dayCellText(T value, bool hasActivity, DateTime date) {
    final displayText = hasActivity ? formatValue(value) : '${date.day}';

    return Text(
      displayText,
      style: cellTextStyle(value).copyWith(
        fontSize: hasActivity ? 10 : 11,
        fontWeight: hasActivity ? FontWeight.bold : FontWeight.w500,
      ),
    );
  }

  String formatValue(T value) {
    if (value is double) return formatDecimalValue(value);
    return value.toString();
  }

  Widget emptyCell() {
    return Container(
      width: CalendarConstants.cellSize,
      height: CalendarConstants.cellSize,
      margin: const EdgeInsets.all(CalendarConstants.cellMargin),
    );
  }

  Widget emptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          children: [
            Icon(
              CupertinoIcons.calendar,
              size: 48,
              color: CupertinoColors.systemGrey.withValues(alpha: 0.5),
            ),
            VSpace.m,
            Text(
              'No activity data available',
              style: AppTypography.bodyMediumSystemGreySemibold,
            ),
            VSpace.s,
            Text(
              'Start recording data to see trends',
              style: AppTypography.bodySmall.copyWith(
                color: CupertinoColors.systemGrey.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget monthsScrollView(List<Widget> months) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: months,
      ),
    );
  }

  Color cellBorderColor(T value) {
    if (value == widget.emptyValue) {
      return CupertinoColors.systemGrey4.withValues(alpha: 0.3);
    }
    return widget.colorCalculator(value).withValues(alpha: 0.6);
  }

  TextStyle cellTextStyle(T value) {
    if (value == widget.emptyValue) {
      return AppTypography.bodySmall.copyWith(
        color: CupertinoColors.systemGrey.withValues(alpha: 0.6),
        fontSize: 12,
      );
    }

    final color = widget.colorCalculator(value);
    final textColor = color.computeLuminance() > 0.5
        ? CupertinoColors.black
        : CupertinoColors.white;

    return AppTypography.bodySmall.copyWith(
      color: textColor,
      fontSize: 12,
      fontWeight: FontWeight.w500,
    );
  }
}

class SeverityActivityCalendar extends StatelessWidget {
  final String itemName;
  final Map<DateTime, int> activityData;
  final void Function(BuildContext context, DateTime date, int severity)
  onDateTap;

  const SeverityActivityCalendar({
    super.key,
    required this.itemName,
    required this.activityData,
    required this.onDateTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActivityCalendar<int>(
      title: '$itemName Activity',
      subtitle:
          'Color intensity indicates symptom severity. Translucent days show no recorded activity.',
      activityData: activityData,
      colorCalculator: SeverityUtils.colorForSeverity,
      legendBuilder: severityLegend,
      onDateTap: onDateTap,
      activityDescriptor: (severity) =>
          severity == 0 ? 'No activity' : 'Severity level $severity',
      emptyValue: 0,
    );
  }

  Widget severityLegend() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Severity Levels:', style: AppTypography.bodyMediumWhiteSemibold),
        VSpace.s,
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            severityLegendItem(0, 'No Activity'),
            for (int i = 1; i <= 10; i++) severityLegendItem(i, '$i'),
          ],
        ),
      ],
    );
  }

  Widget severityLegendItem(int severity, String label) {
    final color = SeverityUtils.colorForSeverity(severity);
    final isInactive = severity == 0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
            border: Border.all(
              color: isInactive
                  ? CupertinoColors.systemGrey4.withValues(alpha: 0.3)
                  : color.withValues(alpha: 0.6),
            ),
          ),
        ),
        HSpace.xs,
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: CupertinoColors.white.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }
}

class DosageActivityCalendar extends StatelessWidget {
  final String drugName;
  final Map<DateTime, double> activityData;
  final void Function(BuildContext context, DateTime date, double dosage)
  onDateTap;
  final String unit;

  const DosageActivityCalendar({
    super.key,
    required this.drugName,
    required this.activityData,
    required this.onDateTap,
    required this.unit,
  });

  double get maxDosage => activityData.values.isEmpty
      ? 0.0
      : activityData.values.reduce((a, b) => a > b ? a : b);

  @override
  Widget build(BuildContext context) {
    return ActivityCalendar<double>(
      title: '$drugName Activity',
      subtitle:
          'Color intensity indicates dosage amount. Translucent days show no recorded doses.',
      activityData: activityData,
      colorCalculator: dosageColor,
      legendBuilder: dosageLegend,
      onDateTap: onDateTap,
      activityDescriptor: (dosage) =>
          dosage == 0.0 ? 'No doses' : '${formatDecimalValue(dosage)}$unit',
      emptyValue: 0.0,
    );
  }

  Color dosageColor(double dosage) {
    if (dosage == 0.0) {
      return AppColors.backgroundPrimary.withValues(alpha: 0.3);
    }
    if (maxDosage == 0.0) return AppColors.primary.withValues(alpha: 0.1);
    return intensityColor(dosage / maxDosage, alphaMin: 0.1, alphaMax: 0.8);
  }

  Widget dosageLegend() {
    return Row(
      children: [
        Text('Less', style: AppTypography.bodySmallSystemGrey),
        HSpace.s,
        ...intensityGradientSquares(alphaMin: 0.1, alphaMax: 0.8),
        HSpace.s,
        Text('More', style: AppTypography.bodySmallSystemGrey),
        const Spacer(),
        if (maxDosage > 0)
          Text(
            'Max: ${formatDecimalValue(maxDosage)}$unit',
            style: AppTypography.bodySmallSystemGrey,
          ),
      ],
    );
  }
}

class CheckInsActivityCalendar extends StatelessWidget {
  final List<CheckIn> checkIns;
  final void Function(DateTime date) onDateTap;
  final double? gridHeight;
  final bool scrollToEnd;

  const CheckInsActivityCalendar({
    super.key,
    required this.checkIns,
    required this.onDateTap,
    this.gridHeight,
    this.scrollToEnd = false,
  });

  @override
  Widget build(BuildContext context) {
    final activityData = generateActivityData();
    final maxCount = activityData.values.isEmpty
        ? 0
        : activityData.values.reduce((a, b) => a > b ? a : b);

    return ActivityCalendar<int>(
      title: 'Check-ins',
      subtitle: 'Tap on a date to view check-ins for that day',
      activityData: activityData,
      colorCalculator: (count) => checkInsColor(count, maxCount),
      legendBuilder: () => checkInsLegend(maxCount),
      onDateTap: (context, date, count) => onDateTap(date),
      activityDescriptor: (count) => count == 0
          ? 'No check-ins'
          : '$count check-in${count == 1 ? '' : 's'}',
      emptyValue: 0,
      gridHeight: gridHeight,
      scrollToEnd: scrollToEnd,
    );
  }

  Map<DateTime, int> generateActivityData() {
    final data = <DateTime, int>{};

    for (final checkIn in checkIns) {
      final dateKey = DateTime(
        checkIn.dateTime.year,
        checkIn.dateTime.month,
        checkIn.dateTime.day,
      );
      data.update(dateKey, (count) => count + 1, ifAbsent: () => 1);
    }

    return data;
  }

  static Color checkInsColor(int count, int maxCount) {
    if (count == 0) return AppColors.backgroundPrimary.withValues(alpha: 0.1);
    if (maxCount == 0) return AppColors.primary.withValues(alpha: 0.1);
    return intensityColor(count / maxCount);
  }

  Widget checkInsLegend(int maxCount) {
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

List<Widget> intensityGradientSquares({
  double alphaMin = CalendarConstants.alphaMin,
  double alphaMax = CalendarConstants.alphaMax,
  int steps = 5,
}) {
  return List.generate(steps, (index) {
    final intensity = (index + 1) / steps;
    return Container(
      width: CalendarConstants.legendItemSize,
      height: CalendarConstants.legendItemSize,
      margin: const EdgeInsets.only(right: 2),
      decoration: BoxDecoration(
        color: intensityColor(
          intensity,
          alphaMin: alphaMin,
          alphaMax: alphaMax,
        ),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  });
}
