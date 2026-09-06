import 'package:health_notes/theme/activity_calendar_colors.dart';
import 'package:flutter/material.dart';
import 'package:ethan_ui/ethan_ui.dart';

import 'dart:math' as math;

import 'package:ethan_utils/ethan_utils.dart';
import 'package:health_notes/models/check_in.dart';
import 'package:health_notes/theme/app_theme.dart';
import 'package:health_notes/theme/spacing.dart';
import 'package:health_notes/utils/health_date_format.dart';
import 'package:health_notes/utils/whole_number_or_trimmed_decimal.dart';
import 'package:health_notes/utils/symptom_severity.dart';

typedef LegendBuilder<T> = Widget Function();
typedef DateInfoCallback<T> = void Function(
  BuildContext context,
  DateTime date,
  T value,
);
typedef ActivityDescriptor<T> = String Function(T value);
typedef DayCellBuilder<T> = Widget Function(
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

class CalendarConstants() {
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

Color accentAlphaAsActivityIntensity(
  double intensity, {
  double alphaMin = 0.15,
  double alphaMax = 0.9,
}) {
  return Color.lerp(
    EColors.accent.withValues(alpha: alphaMin),
    EColors.accent.withValues(alpha: alphaMax),
    intensity,
  )!;
}

class const ActivityCalendar<T>({
  required final String title,
  required final String subtitle,
  required final Map<DateTime, T> activityData,
  required final Color Function(T value) colorForActivity,
  required final LegendBuilder<T> legendBuilder,
  required final DateInfoCallback<T> onDateTap,
  required final ActivityDescriptor<T> activityDescriptor,
  required final T emptyValue,
  final DayCellBuilder<T>? dayCellBuilder,
  final double? gridHeight,
  final bool scrollToEnd = false,
  final void Function(List<DateTime> dates)? onMultiSelectConfirmed,
  final String? multiSelectActionLabel,
}) extends StatefulWidget {
  @override
  State<ActivityCalendar<T>> createState() => _ActivityCalendarState<T>();
}

class _ActivityCalendarState<T>() extends State<ActivityCalendar<T>> {
  ScrollController? _scrollController;
  bool _isSelectingDays = false;
  Set<DateTime> _selectedDays = {};

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
    return ECard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.title, style: EText.headline.small),
          VSpace.s,
          Text(widget.subtitle, style: EText.body.small.muted),
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
          if (_isSelectingDays) ...[VSpace.m, _selectionActionBar()],
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
    final monday = date.shiftedByDays(-(date.weekday - 1));
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
        monthHeader(monthDate.monthYear),
        dayOfWeekLabel(),
        ...buildWeekRows(context, monthDate, daysInMonth, globalMaxSum),
        VSpace.m,
      ],
    );
  }

  Widget monthHeader(String monthName) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2, left: 4),
      child: Text(monthName, style: EText.body.small.muted.semibold),
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
              style: EText.body.small.copyWith(
                color: EColors.textMuted,
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
      final monday = sunday.shiftedByDays(-6);
      for (
        int dayOffset = 0;
        dayOffset < CalendarConstants.daysPerWeek;
        dayOffset++
      ) {
        final date = monday.shiftedByDays(dayOffset);
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
          color: accentAlphaAsActivityIntensity(
            intensity,
            alphaMin: 0.15,
            alphaMax: 0.7,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          '$activeDays',
          textAlign: TextAlign.center,
          style: EText.body.small.copyWith(
            color: Colors.white,
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
        ? sum.wholeNumberOrTrimmedDecimal
        : sum.toInt().toString();

    return Text(
      display,
      textAlign: TextAlign.right,
      style: EText.body.small.copyWith(
        color: Color.lerp(
          EColors.textMuted.withValues(alpha: 0.5),
          Colors.white,
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
    final color = widget.colorForActivity(value);

    if (widget.dayCellBuilder != null) {
      return widget.dayCellBuilder!(context, date, value, hasActivity, color);
    }

    final isSelected = _selectedDays.contains(date);

    return GestureDetector(
      onTap: () => _isSelectingDays
          ? _toggleDaySelection(date)
          : widget.onDateTap(context, date, value),
      onLongPress: widget.onMultiSelectConfirmed != null && !_isSelectingDays
          ? () => _enterSelectionMode(date)
          : null,
      child: Container(
        width: CalendarConstants.cellSize,
        height: CalendarConstants.cellSize,
        margin: const EdgeInsets.all(CalendarConstants.cellMargin),
        decoration: isSelected
            ? _selectedCellDecoration(date)
            : dayCellDecoration(hasActivity, color, value, date),
        child: Stack(
          children: [
            if (hasActivity && !isSelected) miniDateLabel(date),
            Center(
              child: isSelected
                  ? _selectionCheckmark()
                  : dayCellText(value, hasActivity, date),
            ),
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
          color: EColors.background,
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
      color: hasActivity ? color : EColors.background.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(
        color: isToday
            ? ActivityCalendarColors.todayBorder
            : cellBorderColor(value),
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
    return Text(
      hasActivity ? formatValue(value) : '${date.day}',
      style: cellTextStyle(value).copyWith(
        fontSize: hasActivity ? 10 : 11,
        fontWeight: hasActivity ? FontWeight.bold : FontWeight.w500,
      ),
    );
  }

  String formatValue(T value) {
    if (value is double) return value.wholeNumberOrTrimmedDecimal;
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
      padding: const EdgeInsets.all(AppSpacing.l),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.calendar_today,
              size: 48,
              color: EColors.textMuted.withValues(alpha: 0.5),
            ),
            VSpace.m,
            Text(
              'No activity data available',
              style: EText.body.medium.muted.semibold,
            ),
            VSpace.s,
            Text(
              'Start recording data to see trends',
              style: EText.body.small.copyWith(
                color: EColors.textMuted.withValues(alpha: 0.7),
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
      return EColors.borderStrong.withValues(alpha: 0.3);
    }
    return widget.colorForActivity(value).withValues(alpha: 0.6);
  }

  TextStyle cellTextStyle(T value) {
    if (value == widget.emptyValue) {
      return EText.label.small.copyWith(
        color: EColors.textMuted.withValues(alpha: 0.6),
      );
    }

    final color = widget.colorForActivity(value);
    final textColor = color.computeLuminance() > 0.5
        ? Colors.black
        : Colors.white;

    return EText.label.small.copyWith(color: textColor);
  }

  void _enterSelectionMode(DateTime date) {
    setState(() {
      _isSelectingDays = true;
      _selectedDays = {date};
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectingDays = false;
      _selectedDays = {};
    });
  }

  void _toggleDaySelection(DateTime date) {
    setState(() {
      if (_selectedDays.contains(date)) {
        _selectedDays.remove(date);
      } else {
        _selectedDays.add(date);
      }
    });
  }

  BoxDecoration _selectedCellDecoration(DateTime date) {
    return BoxDecoration(
      color: EColors.accent.withValues(alpha: 0.25),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: EColors.accent, width: 2.0),
    );
  }

  Widget _selectionCheckmark() {
    return Icon(Icons.check, size: 16, color: EColors.accent);
  }

  Widget _selectionActionBar() {
    final selectedCount = _selectedDays.length;
    final label = widget.multiSelectActionLabel ?? 'Confirm';
    final dayWord = selectedCount == 1 ? 'day' : 'days';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TextButton(
          onPressed: _exitSelectionMode,
          child: Text('Cancel', style: EText.body.medium.muted),
        ),
        TextButton(
          onPressed: selectedCount > 0
              ? () {
                  widget.onMultiSelectConfirmed!(_selectedDays.toList());
                  _exitSelectionMode();
                }
              : null,
          child: Text(
            '$selectedCount $dayWord · $label',
            style: selectedCount > 0
                ? EText.body.medium.semibold.withColor(EColors.accent)
                : EText.body.medium.muted,
          ),
        ),
      ],
    );
  }
}

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
    return ActivityCalendar<int>(
      title: '$itemName Activity',
      subtitle: 'Color intensity indicates symptom severity. Translucent days show no recorded activity.',
      activityData: activityData,
      colorForActivity: SymptomSeverity.hslGreenToRed,
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
        Text('Severity Levels:', style: EText.body.medium.white.semibold),
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
    final color = SymptomSeverity.hslGreenToRed(severity);
    final isInactive = severity == 0;

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
              color: isInactive
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
  double get maxDosage => activityData.values.isEmpty
      ? 0.0
      : activityData.values.reduce((a, b) => a > b ? a : b);

  @override
  Widget build(BuildContext context) {
    return ActivityCalendar<double>(
      title: '$drugName Activity',
      subtitle: 'Color intensity indicates dosage amount. Translucent days show no recorded doses.',
      activityData: activityData,
      colorForActivity: dosageRelativeToMaxAsAccentAlpha,
      legendBuilder: dosageLegend,
      onDateTap: onDateTap,
      activityDescriptor: (dosage) =>
          dosage == 0.0
              ? 'No doses'
              : '${dosage.wholeNumberOrTrimmedDecimal}$unit',
      emptyValue: 0.0,
      onMultiSelectConfirmed: onMultiSelectConfirmed,
      multiSelectActionLabel: 'Add Dose',
    );
  }

  Color dosageRelativeToMaxAsAccentAlpha(double dosage) {
    if (dosage == 0.0) {
      return EColors.background.withValues(alpha: 0.3);
    }
    if (maxDosage == 0.0) return EColors.accent.withValues(alpha: 0.1);
    return accentAlphaAsActivityIntensity(
      dosage / maxDosage,
      alphaMin: 0.1,
      alphaMax: 0.8,
    );
  }

  Widget dosageLegend() {
    return Row(
      children: [
        Text('Less', style: EText.body.small.muted),
        HSpace.s,
        ...fiveStepAccentAlphaSquares(alphaMin: 0.1, alphaMax: 0.8),
        HSpace.s,
        Text('More', style: EText.body.small.muted),
        const Spacer(),
        if (maxDosage > 0)
          Text(
            'Max: ${maxDosage.wholeNumberOrTrimmedDecimal}$unit',
            style: EText.body.small.muted,
          ),
      ],
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
    final maxCount = activityData.values.isEmpty
        ? 0
        : activityData.values.reduce((a, b) => a > b ? a : b);

    return ActivityCalendar<int>(
      title: 'Check-ins',
      subtitle: 'Tap on a date to view check-ins for that day',
      activityData: activityData,
      colorForActivity: (count) =>
          countRelativeToMaxAsAccentAlpha(count, maxCount),
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

  Map<DateTime, int> checkInCountByDay() {
    final data = <DateTime, int>{};

    for (final checkIn in checkIns) {
      final dateKey = checkIn.dateTime.startOfDay;
      data.update(dateKey, (count) => count + 1, ifAbsent: () => 1);
    }

    return data;
  }

  static Color countRelativeToMaxAsAccentAlpha(int count, int maxCount) {
    if (count == 0) return EColors.background.withValues(alpha: 0.1);
    if (maxCount == 0) return EColors.accent.withValues(alpha: 0.1);
    return accentAlphaAsActivityIntensity(count / maxCount);
  }

  Widget checkInsLegend(int maxCount) {
    return Row(
      children: [
        Text('Less', style: EText.body.small.muted),
        HSpace.s,
        ...fiveStepAccentAlphaSquares(),
        HSpace.s,
        Text('More', style: EText.body.small.muted),
        const Spacer(),
        if (maxCount > 0)
          Text('Max: $maxCount/day', style: EText.body.small.muted),
      ],
    );
  }
}

List<Widget> fiveStepAccentAlphaSquares({
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
        color: accentAlphaAsActivityIntensity(
          intensity,
          alphaMin: alphaMin,
          alphaMax: alphaMax,
        ),
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
    );
  });
}
