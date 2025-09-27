import 'package:flutter/cupertino.dart';
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
      decoration: AppTheme.primaryCard,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: AppTheme.bodySmall.copyWith(
              color: CupertinoColors.systemGrey,
            ),
          ),
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

    for (int monthOffset = 0; monthOffset < monthsToShow; monthOffset++) {
      final monthDate = DateTime(now.year, now.month - monthOffset, 1);
      final daysInMonth = DateTime(monthDate.year, monthDate.month + 1, 0).day;

      if (!monthHasActivity(monthDate, daysInMonth)) continue;

      final monthName = DateFormat('MMM yyyy').format(monthDate);
      months.add(monthWidget(context, monthDate, monthName, daysInMonth));
    }

    return months.isEmpty ? emptyState() : monthsScrollView(months);
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
      child: Text(
        monthName,
        style: AppTheme.bodySmall.copyWith(
          color: CupertinoColors.systemGrey,
          fontWeight: FontWeight.w500,
        ),
      ),
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

      weekRows.add(Row(mainAxisSize: MainAxisSize.min, children: weekDays));
    }

    return weekRows;
  }

  Widget dayCell(BuildContext context, DateTime date) {
    final value = activityData[date] ?? emptyValue;
    final color = colorCalculator(value);

    return GestureDetector(
      onTap: () => onDateTap(context, date, value),
      child: Container(
        width: 30,
        height: 30,
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: value != emptyValue
              ? color
              : AppTheme.backgroundPrimary.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: cellBorderColor(value)),
        ),
        child: Center(child: Text('${date.day}', style: cellTextStyle(value))),
      ),
    );
  }

  Widget emptyCell() {
    return Container(width: 30, height: 30, margin: const EdgeInsets.all(2));
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
              style: AppTheme.bodyMedium.copyWith(
                color: CupertinoColors.systemGrey,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start recording data to see trends',
              style: AppTheme.bodySmall.copyWith(
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
        crossAxisAlignment: CrossAxisAlignment.start,
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
      return AppTheme.bodySmall.copyWith(
        color: CupertinoColors.systemGrey.withValues(alpha: 0.6),
        fontSize: 12,
      );
    }

    final color = colorCalculator(value);
    final luminance = color.computeLuminance();
    final textColor = luminance > 0.5
        ? CupertinoColors.black
        : CupertinoColors.white;

    return AppTheme.bodySmall.copyWith(
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
    if (severity == 0) return AppTheme.backgroundPrimary.withValues(alpha: 0.3);

    final normalizedSeverity = severity / 10.0;
    final hue = 120 - (normalizedSeverity * 120);
    final saturation = 30 + (normalizedSeverity * 60);
    final lightness = 85 - (normalizedSeverity * 50);

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
        Text(
          'Severity Levels:',
          style: AppTheme.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: CupertinoColors.white,
          ),
        ),
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
          style: AppTheme.bodySmall.copyWith(
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
    if (dosage == 0.0) return AppTheme.backgroundPrimary.withValues(alpha: 0.3);
    if (maxDosage == 0.0) return AppTheme.primary.withValues(alpha: 0.1);

    final intensity = dosage / maxDosage;
    final baseColor = AppTheme.primary;
    return Color.lerp(
      baseColor.withValues(alpha: 0.1),
      baseColor.withValues(alpha: 0.8),
      intensity,
    )!;
  }

  Widget dosageLegend(double maxDosage) {
    return Row(
      children: [
        Text(
          'Less',
          style: AppTheme.bodySmall.copyWith(color: CupertinoColors.systemGrey),
        ),
        const SizedBox(width: 8),
        ...List.generate(5, (index) {
          final intensity = (index + 1) / 5.0;
          final baseColor = AppTheme.primary;
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
        Text(
          'More',
          style: AppTheme.bodySmall.copyWith(color: CupertinoColors.systemGrey),
        ),
        const Spacer(),
        if (maxDosage > 0)
          Text(
            'Max: ${maxDosage.toStringAsFixed(maxDosage.truncateToDouble() == maxDosage ? 0 : 1)}mg',
            style: AppTheme.bodySmall.copyWith(
              color: CupertinoColors.systemGrey,
            ),
          ),
      ],
    );
  }
}
