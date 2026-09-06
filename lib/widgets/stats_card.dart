import 'package:ethan_ui/ethan_ui.dart';
import 'package:flutter/material.dart';
import 'package:health_notes/theme/app_theme.dart';
import 'package:health_notes/theme/spacing.dart';

class const StatsCard({required final List<Widget> statRows})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ECard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: statRows,
      ),
    );
  }
}

class const StatRow({
  required final String label,
  required final int value,
  required final String unit,
  final VoidCallback? onTap,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final row = Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: EText.body.medium.white)),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$value $unit',
                style: EText.body.medium.semibold.withColor(EColors.accent),
              ),
              if (onTap != null) HSpace.s,
              if (onTap != null)
                const Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: EColors.textMuted,
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
