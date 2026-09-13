import 'package:ethan_ui/ethan_ui.dart';
import 'package:flutter/material.dart';
import 'package:health_notes/models/condition.dart';
import 'package:health_notes/models/condition_entry.dart';
import 'package:health_notes/providers/conditions_provider.dart';
import 'package:health_notes/theme/app_theme.dart';
import 'package:health_notes/theme/spacing.dart';

class const ConditionStatisticsSection({
  required final Condition condition,
  required final List<ConditionEntry> entries,
  required final List<LinkedSymptom> linkedSymptoms,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final avgSeverity = entries.isEmpty
        ? 0.0
        : entries.map((entry) => entry.severity).reduce((a, b) => a + b) /
              entries.length;

    return ECard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Statistics', style: EText.label.large.primary),
          VSpace.m,
          Row(
            children: [
              Expanded(
                child: ConditionStatCard(
                  label: 'Duration',
                  value: '${condition.durationDays}',
                  unit: 'days',
                ),
              ),
              HSpace.m,
              Expanded(
                child: ConditionStatCard(
                  label: 'Entries',
                  value: '${entries.length}',
                  unit: 'logged',
                ),
              ),
            ],
          ),
          VSpace.m,
          Row(
            children: [
              Expanded(
                child: ConditionStatCard(
                  label: 'Avg Severity',
                  value: avgSeverity.toStringAsFixed(1),
                  unit: '/10',
                ),
              ),
              HSpace.m,
              Expanded(
                child: ConditionStatCard(
                  label: 'Symptoms',
                  value: '${linkedSymptoms.length}',
                  unit: 'linked',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class const ConditionStatCard({
  required final String label,
  required final String value,
  required final String unit,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: EColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.small),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: EText.caption),
          VSpace.xs,
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: EText.headline.medium),
              HSpace.xs,
              Text(unit, style: EText.caption),
            ],
          ),
        ],
      ),
    );
  }
}
