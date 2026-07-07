import 'package:ethan_utils/ethan_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_notes/models/applied_tool.dart';
import 'package:health_notes/models/drug_dose.dart';
import 'package:health_notes/models/symptom.dart';
import 'package:health_notes/screens/drug_trends_screen.dart';
import 'package:health_notes/screens/symptom_trends_screen.dart';
import 'package:health_notes/screens/tool_detail_screen.dart';
import 'package:health_notes/theme/app_theme.dart';
import 'package:health_notes/theme/spacing.dart';
import 'package:health_notes/utils/severity_utils.dart';
import 'package:health_notes/widgets/accent_border_card.dart';
import 'package:health_notes/widgets/condition_badge.dart';
import 'package:health_notes/widgets/enhanced_ui_components.dart';

/// Shared left-accent row for a single symptom, used in note lists and the
/// health note detail view.
class SymptomSummaryRow extends ConsumerWidget {
  final Symptom symptom;

  const SymptomSummaryRow({super.key, required this.symptom});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final severityColor = SeverityUtils.colorForSeverity(symptom.severityLevel);

    return AccentBorderCard(
      accentColor: severityColor,
      onTap: symptom.majorComponent.isEmpty
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
                EnhancedUIComponents.statusIndicator(
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
                    style: AppTypography.bodySmallSecondary,
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
      TextSpan(children: [
        TextSpan(
          text: symptom.majorComponent.isNotEmpty
              ? symptom.majorComponent
              : 'Unnamed symptom',
          style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
        if (symptom.minorComponent.isNotEmpty)
          TextSpan(
            text: ' — ${symptom.minorComponent}',
            style: AppTypography.bodySmallSecondary,
          ),
      ]),
    );
  }
}

/// Shared left-accent row for a single medication dose.
class MedicationSummaryRow extends StatelessWidget {
  final DrugDose dose;

  const MedicationSummaryRow({super.key, required this.dose});

  @override
  Widget build(BuildContext context) {
    return AccentBorderCard(
      accentColor: AppColors.secondary,
      onTap: dose.name.isEmpty
          ? null
          : () => context.push(DrugTrendsScreen(drugName: dose.name)),
      child: Row(
        children: [
          Expanded(
            child: Text(
              dose.displayName,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (dose.dosage > 0) ...[
            HSpace.s,
            EnhancedUIComponents.statusIndicator(
              text: dose.displayDosage,
              color: AppColors.secondary,
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

  const AppliedToolSummaryRow({super.key, required this.appliedTool});

  @override
  Widget build(BuildContext context) {
    return AccentBorderCard(
      accentColor: AppColors.accentWarm,
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
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          if (appliedTool.note.isNotEmpty) ...[
            VSpace.xs,
            Text(appliedTool.note, style: AppTypography.bodySmallSecondary),
          ],
        ],
      ),
    );
  }
}
