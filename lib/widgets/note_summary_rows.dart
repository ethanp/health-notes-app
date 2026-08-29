import 'package:ethan_ui/ethan_ui.dart';
import 'package:ethan_utils/ethan_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_notes/models/applied_tool.dart';
import 'package:health_notes/models/drug_dose.dart';
import 'package:health_notes/models/symptom.dart';
import 'package:health_notes/screens/drug_trends_screen.dart';
import 'package:health_notes/screens/symptom_trends_screen.dart';
import 'package:health_notes/screens/tool_detail_screen.dart';
import 'package:health_notes/theme/spacing.dart';
import 'package:health_notes/utils/severity_utils.dart';
import 'package:health_notes/widgets/accent_border_card.dart';
import 'package:health_notes/widgets/condition_badge.dart';
import 'package:health_notes/widgets/status_tint_chip.dart';

/// Shared left-accent row for a single symptom, used in note lists and the
/// health note detail view.
class SymptomSummaryRow extends ConsumerWidget {
  final Symptom symptom;

  const SymptomSummaryRow({required this.symptom});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final severityColor = SeverityUtils.colorForSeverity(symptom.severityLevel);

    return AccentBorderCard(
      accentColor: severityColor,
      onTap: !symptom.hasMajorComponent
          ? null
          : () => context.push(
              SymptomTrendsScreen(symptomName: symptom.majorComponent),
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _nameText()),
              if (symptom.severityLevel > 0) ...[
                HSpace.s,
                StatusTintChip(
                  text: '${symptom.severityLevel}',
                  color: severityColor,
                ),
              ],
            ],
          ),
          if (symptom.hasLinkedCondition ||
              symptom.additionalNotes.isNotEmpty) ...[
            VSpace.xs,
            Wrap(
              spacing: 6,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (symptom.hasLinkedCondition)
                  ConditionBadge(conditionId: symptom.conditionId!),
                if (symptom.additionalNotes.isNotEmpty)
                  Text(
                    symptom.additionalNotes,
                    style: EText.body.small.secondary,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _nameText() {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: symptom.hasMajorComponent
                ? symptom.majorComponent
                : 'Unnamed symptom',
            style: EText.body.medium.copyWith(fontWeight: FontWeight.w600),
          ),
          if (symptom.minorComponent.isNotEmpty)
            TextSpan(
              text: ' — ${symptom.minorComponent}',
              style: EText.body.small.secondary,
            ),
        ],
      ),
    );
  }
}

/// Shared left-accent row for a single medication dose.
class MedicationSummaryRow extends StatelessWidget {
  final DrugDose dose;

  const MedicationSummaryRow({required this.dose});

  @override
  Widget build(BuildContext context) {
    return AccentBorderCard(
      accentColor: EColors.accentGlow,
      onTap: dose.name.isEmpty
          ? null
          : () => context.push(DrugTrendsScreen(drugName: dose.name)),
      child: Row(
        children: [
          Expanded(
            child: Text(
              dose.whenCaption.isEmpty
                  ? dose.displayName
                  : '${dose.displayName} · ${dose.whenCaption}',
              style: EText.body.medium.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          if (dose.dosage > 0) ...[
            HSpace.s,
            StatusTintChip(
              text: dose.displayDosage,
              color: EColors.accentGlow,
            ),
          ],
        ],
      ),
    );
  }
}

/// Shared left-accent row for a single applied tool.
class AppliedToolSummaryRow extends StatelessWidget {
  final AppliedTool appliedTool;

  const AppliedToolSummaryRow({required this.appliedTool});

  @override
  Widget build(BuildContext context) {
    return AccentBorderCard(
      accentColor: EColors.warning,
      onTap: () => context.push(
        ToolDetailScreen(
          toolId: appliedTool.toolId,
          toolName: appliedTool.toolName,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            appliedTool.toolName,
            style: EText.body.medium.copyWith(fontWeight: FontWeight.w600),
          ),
          if (appliedTool.note.isNotEmpty) ...[
            VSpace.xs,
            Text(appliedTool.note, style: EText.body.small.secondary),
          ],
        ],
      ),
    );
  }
}
