import 'package:ethan_ui/ethan_ui.dart';
import 'package:ethan_utils/ethan_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_notes/models/drug_dose.dart';
import 'package:health_notes/models/drug_name.dart';
import 'package:health_notes/models/medication_schedule.dart';
import 'package:health_notes/providers/medication_recommendations_provider.dart';
import 'package:health_notes/providers/medication_schedules_provider.dart';
import 'package:health_notes/theme/app_theme.dart';
import 'package:health_notes/theme/spacing.dart';

class const MedicationSuggestion({
  required final String label,
  required final VoidCallback onActivated,
});

class const MedicationSuggestionChips({
  required final List<MedicationSuggestion> suggestions,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Suggested', style: EText.label.large.size(12)),
          VSpace.xs,
          Wrap(spacing: 8, runSpacing: 8, children: suggestions.mapL(_chip)),
        ],
      ),
    );
  }

  Widget _chip(MedicationSuggestion suggestion) {
    return GestureDetector(
      onTap: suggestion.onActivated,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: EColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.small),
          border: Border.all(color: EColors.surfaceRaised),
        ),
        child: Text(suggestion.label, style: EText.body.medium),
      ),
    );
  }
}

class const MedicationDoseSuggestionChips({
  required final String typedName,
  required final ValueChanged<DrugDose> onDoseSelected,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final MedicationRecommendationsState? recommendations = ref
        .watch(medicationRecommendationsProvider)
        .asData
        ?.value;
    if (recommendations == null) return const SizedBox.shrink();
    return MedicationSuggestionChips(
      suggestions: recommendations
          .matchingDoses(typedName)
          .mapL(
            (dose) => MedicationSuggestion(
              label: dose.suggestionLabel,
              onActivated: () => onDoseSelected(dose),
            ),
          ),
    );
  }
}

class const MedicationNameSuggestionChips({
  required final String typedName,
  required final ValueChanged<DrugName> onNameSelected,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final MedicationRecommendationsState? recommendations = ref
        .watch(medicationRecommendationsProvider)
        .asData
        ?.value;
    if (recommendations == null) return const SizedBox.shrink();
    final List<MedicationSchedule> schedules =
        ref.watch(medicationSchedulesProvider).asData?.value ?? const [];
    return MedicationSuggestionChips(
      suggestions: recommendations
          .matchingNames(
            typedName,
            additionalNames: schedules.mapL(
              (schedule) => schedule.medicationName,
            ),
          )
          .mapL(
            (name) => MedicationSuggestion(
              label: name.display,
              onActivated: () => onNameSelected(name),
            ),
          ),
    );
  }
}
