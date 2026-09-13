import 'package:ethan_ui/ethan_ui.dart';
import 'package:flutter/material.dart';
import 'package:health_notes/models/date_range_filter.dart';
import 'package:health_notes/theme/app_theme.dart';
import 'package:health_notes/theme/spacing.dart';

class const CheckInTrendsChrome({
  required final Widget header,
  required final Widget dateRangeSelector,
  required final Widget indicator,
  required final Widget charts,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: AppComponents.primaryCard.copyWith(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header,
          VSpace.m,
          dateRangeSelector,
          VSpace.sm,
          indicator,
          VSpace.sm,
          charts,
        ],
      ),
    );
  }
}

class const CheckInTrendsEmptyState() extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ECard(
      child: SizedBox(
        height: 450,
        child: Center(
          child: Text(
            'No check-in data available',
            style: EText.body.medium.tertiary,
          ),
        ),
      ),
    );
  }
}

class const CheckInTrendsImprovementZones() extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: EColors.success.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppRadius.small),
        border: Border.all(
          color: EColors.success.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 14, color: EColors.success),
          HSpace.of(6),
          Expanded(
            child: Text(
              'Green zones: 1-3 (Lower is Better), 4-7 (Middle is Best), 8-10 (Higher is Better)',
              style: EText.body.tiny.withColor(EColors.success),
            ),
          ),
        ],
      ),
    );
  }
}

class const CheckInTrendsDateRangeSelector({
  required final DateRangeFilter selectedDateRange,
  required final ValueChanged<DateRangeFilter> onDateRangeSelected,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: EColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.small),
      ),
      child: SegmentedButton<DateRangeFilter>(
        segments: [
          for (final filter in DateRangeFilter.values)
            ButtonSegment<DateRangeFilter>(
              value: filter,
              label: Text(filter.label),
            ),
        ],
        selected: {selectedDateRange},
        onSelectionChanged: (selection) {
          onDateRangeSelected(selection.first);
        },
        showSelectedIcon: false,
      ),
    );
  }
}
