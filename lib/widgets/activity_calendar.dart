import 'package:flutter/cupertino.dart';
import 'package:health_notes/models/check_in.dart';
import 'package:health_notes/theme/app_theme.dart';

import 'package:intl/intl.dart';

typedef ActivityDataExtractor<T> = Map<DateTime, T> Function();
typedef ColorCalculator<T> = Color Function(T value);
typedef LegendBuilder<T> = Widget Function();
typedef DateInfoCallback<T> =
    void Function(BuildContext context, DateTime date, T value);
typedef ActivityDescriptor<T> = String Function(T value);

class ActivityCalendar<T> extends StatelessWidget {
  final String title;
  final String subtitle;
  final Map<DateTime, T> activityData;
  final ColorCalculator<T> colorCalculator;
  final LegendBuilder<T> legendBuilder;
  final DateInfoCallback<T> onDateTap;
  final ActivityDescriptor<T> activityDescriptor;
  final T emptyValue;

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
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppComponents.primaryCard,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.headlineSmall),
          const SizedBox(height: 8),
          Text(subtitle, style: AppTypography.bodySmallSystemGrey),
          const SizedBox(height: 16),
          legendBuilder(),
          const SizedBox(height: 16),
          activityGrid(context),
        ],
      ),
    );
  }

  Widget activityGrid(BuildContext context) {
    final now = DateTime.now();
    final monthsToShow = 12;
    final months = <Widget>[];

    for (int monthOffset = monthsToShow - 1; monthOffset >= 0; monthOffset--) {
      final monthDate = DateTime(now.year, now.month - monthOffset, 1);
      final daysInMonth = DateTime(monthDate.year, monthDate.month + 1, 0).day;

      if (!monthHasActivity(monthDate, daysInMonth)) continue;

      final monthName = DateFormat('MMM yyyy').format(monthDate);
      months.add(monthWidget(context, monthDate, monthName, daysInMonth));
    }

    return months.isEmpty ? emptyState() : monthsScrollView(context, months);
  }

  bool monthHasActivity(DateTime monthDate, int daysInMonth) {
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(monthDate.year, monthDate.month, day);
      if (activityData.containsKey(date) && activityData[date] != emptyValue) {
        return true;
      }
    }
    return false;
  }

  Widget monthWidget(
    BuildContext context,
    DateTime monthDate,
    String monthName,
    int daysInMonth,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        monthHeader(monthName),
        ...weekRows(context, monthDate, daysInMonth),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget monthHeader(String monthName) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(monthName, style: AppTypography.bodySmallSystemGreySemibold),
    );
  }

  List<Widget> weekRows(
    BuildContext context,
    DateTime monthDate,
    int daysInMonth,
  ) {
    final weekRows = <Widget>[];
    final firstDayOfMonth = DateTime(monthDate.year, monthDate.month, 1);
    final firstWeekday = firstDayOfMonth.weekday;
    final totalDays = firstWeekday - 1 + daysInMonth;
    final weeksInMonth = (totalDays / 7).ceil();

    for (int week = 0; week < weeksInMonth; week++) {
      final weekDays = <Widget>[];

      for (int day = 0; day < 7; day++) {
        final dayOffset = week * 7 + day - (firstWeekday - 1);
        final isInMonth = dayOffset >= 0 && dayOffset < daysInMonth;

        if (isInMonth) {
          final date = DateTime(monthDate.year, monthDate.month, dayOffset + 1);
          weekDays.add(dayCell(context, date));
        } else {
          weekDays.add(emptyCell());
        }
      }

      weekRows.add(
        Row(mainAxisAlignment: MainAxisAlignment.center, children: weekDays),
      );
    }

    return weekRows;
  }

  Widget dayCell(BuildContext context, DateTime date) {
    final value = activityData[date] ?? emptyValue;
    final color = colorCalculator(value);
    final hasActivity = value != emptyValue;
    final displayText = hasActivity
        ? _formatActivityValue(value)
        : '${date.day}';

    return GestureDetector(
      onTap: () => onDateTap(context, date, value),
      child: Container(
        width: 40,
        height: 40,
        margin: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: hasActivity
              ? color
              : AppColors.backgroundPrimary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: cellBorderColor(value),
            width: hasActivity ? 1.5 : 0.5,
          ),
          boxShadow: hasActivity
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            displayText,
            style: cellTextStyle(value).copyWith(
              fontSize: hasActivity ? 12 : 14,
              fontWeight: hasActivity ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  String _formatActivityValue(T value) {
    if (value is int) {
      return value.toString();
    } else if (value is double) {
      return value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1);
    } else {
      return value.toString();
    }
  }

  Widget emptyCell() {
    return Container(width: 40, height: 40, margin: const EdgeInsets.all(3));
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
            const SizedBox(height: 16),
            Text(
              'No activity data available',
              style: AppTypography.bodyMediumSystemGreySemibold,
            ),
            const SizedBox(height: 8),
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

  Widget monthsScrollView(BuildContext context, List<Widget> months) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: months,
      ),
    );
  }

  Color cellBorderColor(T value) {
    if (value == emptyValue) {
      return CupertinoColors.systemGrey4.withValues(alpha: 0.3);
    }
    return colorCalculator(value).withValues(alpha: 0.6);
  }

  TextStyle cellTextStyle(T value) {
    if (value == emptyValue) {
      return AppTypography.bodySmall.copyWith(
        color: CupertinoColors.systemGrey.withValues(alpha: 0.6),
        fontSize: 12,
      );
    }

    final color = colorCalculator(value);
    final luminance = color.computeLuminance();
    final textColor = luminance > 0.5
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
      colorCalculator: _severityColor,
      legendBuilder: severityLegend,
      onDateTap: onDateTap,
      activityDescriptor: (severity) =>
          severity == 0 ? 'No activity' : 'Severity level $severity',
      emptyValue: 0,
    );
  }

  Color _severityColor(int severity) {
    if (severity == 0)
      return AppColors.backgroundPrimary.withValues(alpha: 0.3);

    final normalizedSeverity = (severity / 10.0).clamp(
      0.0,
      1.0,
    ); // Normalize and clamp to 0.0-1.0
    final hue = (120 - (normalizedSeverity * 120)).clamp(
      0.0,
      360.0,
    ); // Ensure hue is in valid range
    final saturation = (30 + (normalizedSeverity * 60)).clamp(
      0.0,
      100.0,
    ); // Ensure saturation is valid
    final lightness = (85 - (normalizedSeverity * 50)).clamp(
      0.0,
      100.0,
    ); // Ensure lightness is valid

    return HSLColor.fromAHSL(
      1.0,
      hue,
      saturation / 100,
      lightness / 100,
    ).toColor();
  }

  Widget severityLegend() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Severity Levels:', style: AppTypography.bodyMediumWhiteSemibold),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            _legendItem(0, 'No Activity'),
            for (int i = 1; i <= 10; i++) _legendItem(i, '$i'),
          ],
        ),
      ],
    );
  }

  Widget _legendItem(int severity, String label) {
    final isInactive = severity == 0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: _severityColor(severity),
            borderRadius: BorderRadius.circular(2),
            border: Border.all(
              color: isInactive
                  ? CupertinoColors.systemGrey4.withValues(alpha: 0.3)
                  : _severityColor(severity).withValues(alpha: 0.6),
            ),
          ),
        ),
        const SizedBox(width: 4),
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

  const DosageActivityCalendar({
    super.key,
    required this.drugName,
    required this.activityData,
    required this.onDateTap,
  });

  @override
  Widget build(BuildContext context) {
    final maxDosage = activityData.values.isNotEmpty
        ? activityData.values.reduce((a, b) => a > b ? a : b)
        : 0.0;

    return ActivityCalendar<double>(
      title: '$drugName Activity',
      subtitle:
          'Color intensity indicates dosage amount. Translucent days show no recorded doses.',
      activityData: activityData,
      colorCalculator: (dosage) => _dosageColor(dosage, maxDosage),
      legendBuilder: () => dosageLegend(maxDosage),
      onDateTap: onDateTap,
      activityDescriptor: (dosage) => dosage == 0.0
          ? 'No doses'
          : '${dosage.toStringAsFixed(dosage.truncateToDouble() == dosage ? 0 : 1)}mg',
      emptyValue: 0.0,
    );
  }

  Color _dosageColor(double dosage, double maxDosage) {
    if (dosage == 0.0)
      return AppColors.backgroundPrimary.withValues(alpha: 0.3);
    if (maxDosage == 0.0) return AppColors.primary.withValues(alpha: 0.1);

    final intensity = dosage / maxDosage;
    final baseColor = AppColors.primary;
    return Color.lerp(
      baseColor.withValues(alpha: 0.1),
      baseColor.withValues(alpha: 0.8),
      intensity,
    )!;
  }

  Widget dosageLegend(double maxDosage) {
    return Row(
      children: [
        Text('Less', style: AppTypography.bodySmallSystemGrey),
        const SizedBox(width: 8),
        ...List.generate(5, (index) {
          final intensity = (index + 1) / 5.0;
          final baseColor = AppColors.primary;
          return Container(
            width: 12,
            height: 12,
            margin: const EdgeInsets.only(right: 2),
            decoration: BoxDecoration(
              color: Color.lerp(
                baseColor.withValues(alpha: 0.1),
                baseColor.withValues(alpha: 0.8),
                intensity,
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }),
        const SizedBox(width: 8),
        Text('More', style: AppTypography.bodySmallSystemGrey),
        const Spacer(),
        if (maxDosage > 0)
          Text(
            'Max: ${maxDosage.toStringAsFixed(maxDosage.truncateToDouble() == maxDosage ? 0 : 1)}mg',
            style: AppTypography.bodySmallSystemGrey,
          ),
      ],
    );
  }
}

class CheckInsActivityCalendar extends StatelessWidget {
  final List<CheckIn> checkIns;
  final void Function(DateTime date) onDateTap;

  const CheckInsActivityCalendar({
    super.key,
    required this.checkIns,
    required this.onDateTap,
  });

  @override
  Widget build(BuildContext context) {
    final activityData = _generateActivityData();

    return ActivityCalendar<int>(
      title: 'Check-ins',
      subtitle: 'Tap on a date to view check-ins for that day',
      activityData: activityData,
      colorCalculator: _checkInsColor,
      legendBuilder: checkInsLegend,
      onDateTap: (context, date, count) => onDateTap(date),
      activityDescriptor: (count) => count == 0
          ? 'No check-ins'
          : '$count check-in${count == 1 ? '' : 's'}',
      emptyValue: 0,
    );
  }

  Map<DateTime, int> _generateActivityData() {
    final activityData = <DateTime, int>{};

    for (final checkIn in checkIns) {
      final dateKey = DateTime(
        checkIn.dateTime.year,
        checkIn.dateTime.month,
        checkIn.dateTime.day,
      );

      activityData.update(
        dateKey,
        (existing) => existing + 1,
        ifAbsent: () => 1,
      );
    }

    return activityData;
  }

  Color _checkInsColor(int count) {
    if (count == 0) return AppColors.backgroundPrimary.withValues(alpha: 0.1);

    switch (count) {
      case 1:
        return const Color(0xFFE8F5E8); // Very light green
      case 2:
        return const Color(0xFFC8E6C9); // Light green
      case 3:
        return const Color(0xFFA5D6A7); // Medium light green
      case 4:
        return AppColors.success;
      case 5:
        return const Color(0xFF66BB6A); // Strong green
      default: // 6+
        return const Color(0xFF4CAF50); // Deep green (best)
    }
  }

  Widget checkInsLegend() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Daily Check-in Count:',
          style: AppTypography.bodyMediumWhiteSemibold,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _checkInsLegendItem(0, 'None'),
            const SizedBox(width: 16),
            _checkInsLegendItem(1, '1'),
            const SizedBox(width: 12),
            _checkInsLegendItem(2, '2'),
            const SizedBox(width: 12),
            _checkInsLegendItem(3, '3'),
            const SizedBox(width: 12),
            _checkInsLegendItem(4, '4'),
            const SizedBox(width: 12),
            _checkInsLegendItem(5, '5'),
            const SizedBox(width: 12),
            _checkInsLegendItem(6, '6+'),
          ],
        ),
      ],
    );
  }

  Widget _checkInsLegendItem(int count, String label) {
    final color = _checkInsColor(count);
    return Column(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: count == 0
                  ? CupertinoColors.systemGrey4.withValues(alpha: 0.5)
                  : color.withValues(alpha: 0.8),
              width: count == 0 ? 0.5 : 1,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: CupertinoColors.white.withValues(alpha: 0.9),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
