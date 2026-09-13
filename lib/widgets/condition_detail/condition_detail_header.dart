import 'package:ethan_ui/ethan_ui.dart';
import 'package:flutter/material.dart';
import 'package:health_notes/models/condition.dart';
import 'package:health_notes/theme/app_theme.dart';
import 'package:health_notes/ui/condition_appearance.dart';
import 'package:health_notes/theme/spacing.dart';

class const ConditionDetailHeader({required final Condition condition})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ECard(
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: AppComponents.tintedSolidDecoration(
              condition.color,
              radius: 28,
              borderWidth: 2,
            ),
            child: Icon(condition.icon, size: 28, color: condition.color),
          ),
          HSpace.m,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(condition.name, style: EText.headline.small),
                VSpace.xs,
                Text(
                  condition.dateRangeCaption,
                  style: EText.body.small.tertiary,
                ),
              ],
            ),
          ),
          ConditionStatusBadge(condition: condition),
        ],
      ),
    );
  }
}

class const ConditionStatusBadge({required final Condition condition})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final color = condition.isActive ? EColors.warning : EColors.success;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.s,
      ),
      decoration: AppComponents.tintedSolidDecoration(
        color,
        radius: AppRadius.large,
      ),
      child: Text(
        condition.status.displayName,
        style: EText.label.medium.copyWith(color: color),
      ),
    );
  }
}
