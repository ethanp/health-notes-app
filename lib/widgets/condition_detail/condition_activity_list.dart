import 'package:ethan_ui/ethan_ui.dart';
import 'package:flutter/material.dart';
import 'package:health_notes/models/condition_entry.dart';
import 'package:health_notes/providers/conditions_provider.dart';
import 'package:health_notes/screens/sub_symptom_trends_screen.dart';
import 'package:health_notes/screens/symptom_trends_screen.dart';
import 'package:health_notes/theme/app_theme.dart';
import 'package:health_notes/ui/condition_appearance.dart';
import 'package:health_notes/utils/symptom_severity.dart';
import 'package:health_notes/widgets/status_tint_chip.dart';
import 'package:health_notes/theme/spacing.dart';
import 'package:intl/intl.dart';

class const ConditionActivityList({
  required final List<ConditionEntry> entries,
  required final List<LinkedSymptom> linkedSymptoms,
  required final void Function(ConditionEntry entry) onEntrySelected,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ESectionHeader(title: 'Daily Entries'),
        VSpace.s,
        ConditionEntriesList(
          entries: entries,
          linkedSymptoms: linkedSymptoms,
          onEntrySelected: onEntrySelected,
        ),
        if (linkedSymptoms.isNotEmpty) ...[
          VSpace.l,
          ESectionHeader(title: 'Linked Symptoms'),
          VSpace.s,
          ConditionLinkedSymptoms(linkedSymptoms: linkedSymptoms),
        ],
      ],
    );
  }
}

class const ConditionEntriesList({
  required final List<ConditionEntry> entries,
  required final List<LinkedSymptom> linkedSymptoms,
  required final void Function(ConditionEntry entry) onEntrySelected,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return ECard(
        child: Center(
          child: Text(
            linkedSymptoms.isNotEmpty
                ? 'No check-in entries yet'
                : 'No entries yet. Add entries via check-ins.',
            style: EText.body.medium.muted,
          ),
        ),
      );
    }

    final sortedEntries = [...entries]
      ..sort((a, b) => b.entryDate.compareTo(a.entryDate));

    return Column(
      children: sortedEntries
          .map(
            (entry) => ConditionEntryCard(
              entry: entry,
              onSelected: () => onEntrySelected(entry),
            ),
          )
          .toList(),
    );
  }
}

class const ConditionEntryCard({
  required final ConditionEntry entry,
  required final VoidCallback onSelected,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onSelected,
        child: ECard(
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('EEE, MMM d').format(entry.entryDate),
                    style: EText.label.medium,
                  ),
                  VSpace.xs,
                  Row(
                    children: [
                      ConditionPhaseBadge(phase: entry.phase),
                      if (entry.notes.isNotEmpty) ...[
                        HSpace.s,
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 14,
                          color: EColors.textMuted,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              const Spacer(),
              ConditionSeverityIndicator(severity: entry.severity),
              HSpace.s,
              Icon(
                Icons.chevron_right,
                size: 14,
                color: EColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class const ConditionPhaseBadge({required final ConditionPhase phase})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: AppComponents.tintedSolidDecoration(
        phase.color,
        radius: AppRadius.small,
      ),
      child: Text(
        phase.displayName,
        style: EText.caption.copyWith(color: phase.color),
      ),
    );
  }
}

class const ConditionSeverityIndicator({required final int severity})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: SymptomSeverity.fourBucketGreenYellowOrangeRed(severity),
        borderRadius: BorderRadius.circular(AppRadius.medium),
      ),
      child: Text('$severity', style: EText.label.medium.white),
    );
  }
}

class const ConditionLinkedSymptoms({
  required final List<LinkedSymptom> linkedSymptoms,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final byDescription = <String, List<LinkedSymptom>>{};
    for (final linkedSymptom in linkedSymptoms) {
      final key = linkedSymptom.symptom.fullDescription;
      byDescription.putIfAbsent(key, () => []).add(linkedSymptom);
    }

    final sortedKeys = byDescription.keys.toList()
      ..sort(
        (a, b) => byDescription[b]!.length.compareTo(byDescription[a]!.length),
      );

    return Column(
      children: sortedKeys.map((description) {
        final occurrences = byDescription[description]!;
        final avgSeverity =
            occurrences
                .map((linkedSymptom) => linkedSymptom.symptom.severityLevel)
                .reduce((a, b) => a + b) /
            occurrences.length;
        final avgColor = SymptomSeverity.hslGreenToRed(avgSeverity.round());

        return GestureDetector(
          onTap: () => _showSymptomTrends(context, occurrences.first),
          child: Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.s,
            ),
            decoration: BoxDecoration(
              color: EColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.small),
              border: Border(left: BorderSide(color: avgColor, width: 3)),
            ),
            child: Row(
              children: [
                Expanded(child: Text(description, style: EText.body.medium)),
                HSpace.s,
                Text(
                  '${occurrences.length}×',
                  style: EText.body.small.secondary,
                ),
                HSpace.s,
                StatusTintChip(
                  text: 'avg ${avgSeverity.toStringAsFixed(1)}',
                  color: avgColor,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  void _showSymptomTrends(BuildContext context, LinkedSymptom linkedSymptom) {
    final symptom = linkedSymptom.symptom;
    if (!symptom.hasMajorComponent) return;
    if (symptom.minorComponent.isNotEmpty) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => SubSymptomTrendsScreen(
            majorComponent: symptom.majorComponent,
            minorComponent: symptom.minorComponent,
          ),
        ),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            SymptomTrendsScreen(symptomName: symptom.majorComponent),
      ),
    );
  }
}
