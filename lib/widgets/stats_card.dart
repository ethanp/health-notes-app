import 'package:flutter/cupertino.dart';
import 'package:health_notes/theme/app_theme.dart';
import 'package:health_notes/theme/spacing.dart';

class StatsCard extends StatelessWidget {
  final List<Widget> statRows;

  const StatsCard({super.key, required this.statRows});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppComponents.primaryCard,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: statRows,
      ),
    );
  }
}

class StatRow extends StatelessWidget {
  final String label;
  final int value;
  final String unit;
  final VoidCallback? onTap;

  const StatRow({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final row = Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: AppTypography.bodyMediumWhite)),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$value $unit',
                style: AppTypography.bodyMediumPrimarySemibold,
              ),
              if (onTap != null) HSpace.s,
              if (onTap != null)
                const Icon(
                  CupertinoIcons.chevron_right,
                  size: 16,
                  color: CupertinoColors.systemGrey,
                ),
            ],
          ),
        ],
      ),
    );

    if (onTap == null) return row;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: row,
    );
  }
}
