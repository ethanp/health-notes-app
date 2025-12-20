import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_notes/models/condition.dart';
import 'package:health_notes/models/condition_entry.dart';
import 'package:health_notes/providers/conditions_provider.dart';
import 'package:health_notes/theme/app_theme.dart';
import 'package:health_notes/widgets/spacing.dart';
import 'package:intl/intl.dart';

class ConditionTimelineCard extends ConsumerWidget {
  final Condition condition;

  const ConditionTimelineCard({required this.condition});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(conditionEntriesNotifierProvider(condition.id));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppComponents.primaryCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header(),
          VSpace.m,
          entriesAsync.when(
            data: (entries) => severityChart(entries),
            loading: () => chartPlaceholder(),
            error: (e, st) => chartPlaceholder(),
          ),
          VSpace.s,
          footer(),
        ],
      ),
    );
  }

  Widget header() {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: condition.color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: condition.color.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Icon(condition.icon, size: 18, color: condition.color),
        ),
        HSpace.m,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(condition.name, style: AppTypography.labelLargePrimary),
              VSpace.xs,
              Text(
                formatDateRange(),
                style: AppTypography.bodySmallTertiary,
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
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Text(
        condition.status.displayName,
        style: AppTypography.caption.copyWith(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget severityChart(List<ConditionEntry> entries) {
    if (entries.isEmpty) return chartPlaceholder();

    final sortedEntries = [...entries]..sort((a, b) => a.entryDate.compareTo(b.entryDate));
    const chartHeight = 40.0;

    return SizedBox(
      height: chartHeight,
      child: CustomPaint(
        size: const Size(double.infinity, chartHeight),
        painter: SeverityChartPainter(
          entries: sortedEntries,
          color: condition.color,
        ),
      ),
    );
  }

  Widget chartPlaceholder() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.backgroundTertiary,
        borderRadius: BorderRadius.circular(AppRadius.small),
      ),
      child: Center(
        child: Text('No entries yet', style: AppTypography.caption),
      ),
    );
  }

  Widget footer() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '${condition.durationDays} day${condition.durationDays == 1 ? '' : 's'}',
          style: AppTypography.captionSecondary,
        ),
        Icon(
          CupertinoIcons.chevron_right,
          size: 14,
          color: AppColors.textQuaternary,
        ),
      ],
    );
  }

  String formatDateRange() {
    final startStr = DateFormat('MMM d').format(condition.startDate);
    if (condition.endDate != null) {
      final endStr = DateFormat('MMM d').format(condition.endDate!);
      return '$startStr - $endStr';
    }
    return 'Started $startStr';
  }
}

class SeverityChartPainter extends CustomPainter {
  final List<ConditionEntry> entries;
  final Color color;

  SeverityChartPainter({required this.entries, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (entries.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();

    final stepX = entries.length > 1 ? size.width / (entries.length - 1) : size.width / 2;

    for (int i = 0; i < entries.length; i++) {
      final x = entries.length > 1 ? i * stepX : size.width / 2;
      final normalizedSeverity = entries[i].severity.clamp(1, 10) / 10.0;
      final y = size.height - (normalizedSeverity * size.height * 0.8) - (size.height * 0.1);

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);

    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (int i = 0; i < entries.length; i++) {
      final x = entries.length > 1 ? i * stepX : size.width / 2;
      final normalizedSeverity = entries[i].severity.clamp(1, 10) / 10.0;
      final y = size.height - (normalizedSeverity * size.height * 0.8) - (size.height * 0.1);
      canvas.drawCircle(Offset(x, y), 3, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

