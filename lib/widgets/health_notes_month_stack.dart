import 'package:ethan_ui/ethan_ui.dart';
import 'package:ethan_utils/ethan_utils.dart';
import 'package:flutter/material.dart';
import 'package:health_notes/theme/app_theme.dart';
import 'package:health_notes/theme/spacing.dart';
import 'package:health_notes/utils/whole_number_or_trimmed_decimal.dart';

class const HealthNotesMonthStack({
  required final String title,
  required final String subtitle,
  required final Widget legend,
  required final ECalendarDayPresentation<DateTime> Function(DateTime date)
  presentationFor,
  required final void Function(ECalendarDayPresentation<DateTime> day)
  onDaySelected,
  final num Function(DateTime date)? quantityOn,
  final DateTime? chartFrom,
  final String? measureTitle,
  final String Function(num quantity)? formatMeasure,
  final double? gridHeight,
  final bool scrollToEnd = false,
  final void Function(List<DateTime> dates)? onMultiSelectConfirmed,
  final String? multiSelectActionLabel,
}) extends StatefulWidget {
  @override
  State<HealthNotesMonthStack> createState() => _HealthNotesMonthStackState();

  static EPeriodQuartileHeatmapScale periodQuartileScale({
    required Iterable<num> observedQuantities,
    required String unitTitle,
    required String Function(num quantity) captionForQuantity,
  }) => EPeriodQuartileHeatmapScale(
    observedQuantities: observedQuantities,
    legendTitle: '$unitTitle · period quartiles',
    captionForQuantity: captionForQuantity,
  );

  static ECalendarDayPresentation<DateTime> countedDay({
    required DateTime date,
    required num quantity,
    required EHeatmapScale scale,
    required String Function(num quantity) caption,
  }) {
    final day = date.startOfDay;
    if (quantity <= 0) {
      return ECalendarDayPresentation(
        date: day,
        id: day,
        semanticsLabel: caption(0),
        visual: const ECalendarDayEmpty(),
      );
    }
    return ECalendarDayPresentation(
      date: day,
      id: day,
      semanticsLabel: caption(quantity),
      visual: ECalendarDayMeasuredHeat(intensity: scale.intensityFor(quantity)),
      secondaryLabel: quantity.wholeNumberOrTrimmedDecimal,
    );
  }

  static ECalendarPeriodPresentation countedWeek({
    required DateTime weekMonday,
    required num Function(DateTime date) quantityOn,
  }) {
    var activeDays = 0;
    num sum = 0;
    for (var offset = 0; offset < DateTime.daysPerWeek; offset++) {
      final quantity = quantityOn(weekMonday.shiftedByDays(offset));
      if (quantity <= 0) continue;
      activeDays++;
      sum += quantity;
    }
    return ECalendarPeriodPresentation(
      activeDays: activeDays,
      measureCaption: activeDays > 0 ? sum.wholeNumberOrTrimmedDecimal : null,
    );
  }

  static ECalendarPeriodPresentation countedMonth({
    required DateTime monthStart,
    required num Function(DateTime date) quantityOn,
  }) {
    final daysInMonth = DateTime(monthStart.year, monthStart.month + 1, 0).day;
    var activeDays = 0;
    num sum = 0;
    for (var day = 1; day <= daysInMonth; day++) {
      final quantity = quantityOn(
        DateTime(monthStart.year, monthStart.month, day),
      );
      if (quantity <= 0) continue;
      activeDays++;
      sum += quantity;
    }
    return ECalendarPeriodPresentation(
      activeDays: activeDays,
      measureCaption: activeDays > 0 ? sum.wholeNumberOrTrimmedDecimal : null,
    );
  }

  static Color inkOn(Color background) =>
      background.computeLuminance() > 0.5 ? Colors.black : Colors.white;

  static ECalendarDayPresentation<DateTime> severityDay({
    required DateTime date,
    required int severity,
    required Color background,
    required String semanticsLabel,
    String? secondaryLabel,
  }) {
    final day = date.startOfDay;
    if (severity <= 0) {
      return ECalendarDayPresentation(
        date: day,
        id: day,
        semanticsLabel: semanticsLabel,
        visual: const ECalendarDayEmpty(),
      );
    }
    return ECalendarDayPresentation(
      date: day,
      id: day,
      semanticsLabel: semanticsLabel,
      visual: ECalendarDaySeverity(
        background: background,
        ink: inkOn(background),
      ),
      secondaryLabel: secondaryLabel ?? '$severity',
    );
  }
}

class _HealthNotesMonthStackState() extends State<HealthNotesMonthStack> {
  bool _showCharts = false;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return ECard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _titleRow(),
          VSpace.s,
          Text(widget.subtitle, style: EText.body.small.muted),
          VSpace.m,
          widget.legend,
          VSpace.m,
          if (_showCharts && widget.quantityOn != null)
            ECalendarCharts(
              dailyMeasures: _dailyMeasures(now),
              measureTitle: widget.measureTitle ?? 'measure',
              formatMeasure:
                  widget.formatMeasure ??
                  (quantity) => quantity.wholeNumberOrTrimmedDecimal,
            )
          else
            EMonthStackCalendar<DateTime>(
              firstVisibleMonth: DateTime(now.year, now.month - 11, 1),
              lastVisibleMonth: DateTime(now.year, now.month, 1),
              keepLastMonthIfAnyVisible: true,
              maxHeight: widget.gridHeight,
              scrollToEnd: widget.scrollToEnd,
              presentationFor: widget.presentationFor,
              weekPresentation: widget.quantityOn == null
                  ? null
                  : (weekMonday) => HealthNotesMonthStack.countedWeek(
                      weekMonday: weekMonday,
                      quantityOn: widget.quantityOn!,
                    ),
              monthPresentation: widget.quantityOn == null
                  ? null
                  : (monthStart) => HealthNotesMonthStack.countedMonth(
                      monthStart: monthStart,
                      quantityOn: widget.quantityOn!,
                    ),
              onDaySelected: widget.onDaySelected,
              onMultiSelectConfirmed: widget.onMultiSelectConfirmed == null
                  ? null
                  : (days) => widget.onMultiSelectConfirmed!(
                      days.map((day) => day.date.startOfDay).toList(),
                    ),
              multiSelectActionLabel: widget.multiSelectActionLabel,
              empty: const _HealthNotesCalendarEmpty(),
            ),
        ],
      ),
    );
  }

  Widget _titleRow() {
    return Row(
      children: [
        Expanded(child: Text(widget.title, style: EText.headline.small)),
        if (widget.quantityOn != null)
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('Grid')),
              ButtonSegment(value: true, label: Text('Charts')),
            ],
            selected: {_showCharts},
            onSelectionChanged: (selected) {
              setState(() => _showCharts = selected.single);
            },
          ),
      ],
    );
  }

  List<ECalendarDailyMeasure> _dailyMeasures(DateTime now) {
    final quantityOn = widget.quantityOn!;
    final today = now.startOfDay;
    final start = (widget.chartFrom ?? DateTime(now.year, now.month - 11, 1))
        .startOfDay;
    final days = <ECalendarDailyMeasure>[];
    for (
      var day = start;
      !day.isAfter(today);
      day = day.shiftedByDays(1)
    ) {
      final quantity = quantityOn(day);
      days.add(
        ECalendarDailyMeasure(
          date: day,
          quantity: quantity,
          isActive: quantity > 0,
        ),
      );
    }
    return days;
  }
}

class const _HealthNotesCalendarEmpty() extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
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
}
