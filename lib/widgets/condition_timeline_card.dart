import 'package:ethan_ui/ethan_ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_notes/models/condition.dart';
import 'package:health_notes/models/condition_entry.dart';
import 'package:health_notes/providers/conditions_provider.dart';
import 'package:health_notes/services/condition_activity_aggregator.dart';
import 'package:health_notes/utils/health_date_format.dart';
import 'package:health_notes/theme/app_theme.dart';
import 'package:health_notes/theme/spacing.dart';

class const ConditionTimelineCard({required final Condition condition})
    extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(conditionEntriesProvider(condition.id));
    final linkedSymptomsAsync = ref.watch(
      symptomsForConditionProvider(condition.id),
    );

    return ECard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header(),
          VSpace.m,
          activityPreview(entriesAsync, linkedSymptomsAsync),
          VSpace.s,
          footer(),
        ],
      ),
    );
  }

  Widget activityPreview(
    AsyncValue<List<ConditionEntry>> entriesAsync,
    AsyncValue<List<LinkedSymptom>> linkedSymptomsAsync,
  ) {
    if (entriesAsync.isLoading || linkedSymptomsAsync.isLoading) {
      return chartLoadingPlaceholder();
    }
    if (entriesAsync.hasError || linkedSymptomsAsync.hasError) {
      return chartLoadingPlaceholder();
    }

    final entries = entriesAsync.value ?? [];
    final linkedSymptoms = linkedSymptomsAsync.value ?? [];
    final activityByDate = ConditionActivityAggregator.byDate(
      entries: entries,
      linkedSymptoms: linkedSymptoms,
    );
    final sparklinePoints = ConditionActivityAggregator.sparklinePoints(
      activityByDate,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        severityChart(sparklinePoints),
        if (sparklinePoints.isNotEmpty) ...[
          VSpace.xs,
          Text(
            activityCaption(entries, linkedSymptoms),
            style: EText.caption.tertiary,
          ),
        ],
      ],
    );
  }

  Widget header() {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: AppComponents.tintedSolidDecoration(
            condition.color,
            radius: 18,
          ),
          child: Icon(condition.icon, size: 18, color: condition.color),
        ),
        HSpace.m,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(condition.name, style: EText.label.large.primary),
              VSpace.xs,
              Text(
                condition.dateRangeCaption,
                style: EText.body.small.tertiary,
              ),
            ],
          ),
        ),
        statusBadge(),
      ],
    );
  }

  Widget statusBadge() {
    final color = condition.isActive
        ? CupertinoColors.systemOrange
        : CupertinoColors.systemGreen;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: AppComponents.tintedSolidDecoration(
        color,
        radius: AppRadius.medium,
      ),
      child: Text(
        condition.status.displayName,
        style: EText.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget severityChart(List<ConditionSeverityPoint> points) {
    if (points.isEmpty) return chartEmptyPlaceholder();

    const chartHeight = 40.0;
    return SizedBox(
      height: chartHeight,
      child: CustomPaint(
        size: const Size(double.infinity, chartHeight),
        painter: SeverityChartPainter(points: points, color: condition.color),
      ),
    );
  }

  Widget chartLoadingPlaceholder() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: EColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.small),
      ),
    );
  }

  Widget chartEmptyPlaceholder() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: EColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.small),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(CupertinoIcons.chart_bar, size: 14, color: EColors.textMuted),
          HSpace.xs,
          Text('No activity yet', style: EText.caption.quaternary),
        ],
      ),
    );
  }

  String activityCaption(
    List<ConditionEntry> entries,
    List<LinkedSymptom> linkedSymptoms,
  ) {
    if (entries.isNotEmpty) {
      if (linkedSymptoms.isNotEmpty) {
        return '${entries.length} ${entries.length == 1 ? 'entry' : 'entries'} · '
            '${linkedSymptoms.length} ${linkedSymptoms.length == 1 ? 'symptom' : 'symptoms'}';
      }
      return '${entries.length} check-in ${entries.length == 1 ? 'entry' : 'entries'}';
    }
    return '${linkedSymptoms.length} linked '
        '${linkedSymptoms.length == 1 ? 'symptom' : 'symptoms'} · '
        'last ${linkedSymptoms.first.date.monthDayYear}';
  }

  Widget footer() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '${condition.durationDays} day${condition.durationDays == 1 ? '' : 's'}',
          style: EText.caption.quaternary,
        ),
        Icon(CupertinoIcons.chevron_right, size: 14, color: EColors.textMuted),
      ],
    );
  }
}

class SeverityChartPainter({
  required final List<ConditionSeverityPoint> points,
  required final Color color,
}) extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final stepX = points.length > 1
        ? size.width / (points.length - 1)
        : size.width / 2;

    _fillUnderSeverityPolyline(canvas, size, stepX);
    _strokePolylineThroughSeverity(canvas, size, stepX);
    _dotEachSeverityReading(canvas, size, stepX);
  }

  double _severityAsHeight(int severity, Size size) {
    final normalizedSeverity = severity.clamp(1, 10) / 10.0;
    return size.height -
        (normalizedSeverity * size.height * 0.8) -
        (size.height * 0.1);
  }

  double _evenlySpacedReadingX(int index, double stepX, Size size) {
    return points.length > 1 ? index * stepX : size.width / 2;
  }

  void _fillUnderSeverityPolyline(Canvas canvas, Size size, double stepX) {
    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    final fillPath = Path();
    for (var index = 0; index < points.length; index++) {
      final x = _evenlySpacedReadingX(index, stepX, size);
      final y = _severityAsHeight(points[index].severity, size);
      if (index == 0) {
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        fillPath.lineTo(x, y);
      }
    }
    fillPath.lineTo(size.width, size.height);
    fillPath.close();
    canvas.drawPath(fillPath, fillPaint);
  }

  void _strokePolylineThroughSeverity(Canvas canvas, Size size, double stepX) {
    final stroke = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    for (var index = 0; index < points.length; index++) {
      final x = _evenlySpacedReadingX(index, stepX, size);
      final y = _severityAsHeight(points[index].severity, size);
      if (index == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, stroke);
  }

  void _dotEachSeverityReading(Canvas canvas, Size size, double stepX) {
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (var index = 0; index < points.length; index++) {
      final x = _evenlySpacedReadingX(index, stepX, size);
      final y = _severityAsHeight(points[index].severity, size);
      canvas.drawCircle(Offset(x, y), 3, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
