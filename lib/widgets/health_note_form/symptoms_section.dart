import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_notes/models/condition.dart';
import 'package:health_notes/models/symptom.dart';
import 'package:health_notes/providers/conditions_provider.dart';
import 'package:health_notes/providers/symptom_suggestions_provider.dart';
import 'package:health_notes/screens/condition_detail_screen.dart';
import 'package:health_notes/screens/condition_form.dart';
import 'package:health_notes/screens/symptom_trends_screen.dart';
import 'package:health_notes/services/symptom_suggestions_service.dart';
import 'package:health_notes/services/text_normalizer.dart';
import 'package:health_notes/theme/app_theme.dart';
import 'package:health_notes/widgets/enhanced_ui_components.dart';
import 'package:health_notes/widgets/health_note_form/form_controllers.dart';
import 'package:health_notes/widgets/spacing.dart';

class SymptomsSection extends ConsumerWidget {
  final bool isEditable;
  final List<Symptom> symptoms;
  final Map<int, SymptomControllers> controllers;
  final Set<String> usedSuggestions;
  final VoidCallback onAdd;
  final Function(int) onRemove;
  final Function(int, Symptom, String) onUpdateFromSuggestion;
  final Function(
    int, {
    int? severityLevel,
    String? majorComponent,
    String? minorComponent,
    String? additionalNotes,
    String? conditionId,
  })
  onUpdate;

  const SymptomsSection({
    super.key,
    required this.isEditable,
    required this.symptoms,
    required this.controllers,
    required this.usedSuggestions,
    required this.onAdd,
    required this.onRemove,
    required this.onUpdateFromSuggestion,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: isEditable
          ? AppComponents.inputField
          : AppComponents.primaryCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [_header(), VSpace.s, _content(context, ref)],
      ),
    );
  }

  Widget _header() {
    return EnhancedUIComponents.sectionHeader(
      title: 'Symptoms',
      trailing: isEditable
          ? CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: onAdd,
              child: const Icon(CupertinoIcons.add),
            )
          : null,
    );
  }

  Widget _content(BuildContext context, WidgetRef ref) {
    if (symptoms.isEmpty) {
      return Text('No symptoms recorded', style: AppTypography.bodyMedium);
    }

    if (!isEditable) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: symptoms.map((s) => _readOnlyItem(context, ref, s)).toList(),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: symptoms.asMap().entries.map((entry) {
        final index = entry.key;
        final symptom = entry.value;
        return _editableItem(context, ref, index, symptom, controllers[index]!);
      }).toList(),
    );
  }

  Widget _readOnlyItem(BuildContext context, WidgetRef ref, Symptom symptom) {
    return GestureDetector(
      onTap: () {
        if (symptom.majorComponent.isNotEmpty) {
          Navigator.of(context).push(
            CupertinoPageRoute(
              builder: (context) =>
                  SymptomTrendsScreen(symptomName: symptom.majorComponent),
            ),
          );
        }
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                HSpace.of(12),
                Expanded(
                  child: Text(
                    symptom.fullDescription,
                    style: AppTypography.bodyMedium,
                  ),
                ),
                if (symptom.hasLinkedCondition)
                  _conditionBadge(context, ref, symptom.conditionId!),
                HSpace.s,
                EnhancedUIComponents.statusIndicator(
                  text: '${symptom.severityLevel}/10',
                  color: AppColors.primary,
                ),
              ],
            ),
            if (symptom.additionalNotes.isNotEmpty) ...[
              VSpace.s,
              Padding(
                padding: const EdgeInsets.only(left: 20),
                child: Text(
                  symptom.additionalNotes,
                  style: AppTypography.bodyMediumSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _conditionBadge(
    BuildContext context,
    WidgetRef ref,
    String conditionId,
  ) {
    final conditionsAsync = ref.watch(conditionsNotifierProvider);

    return conditionsAsync.when(
      data: (conditions) {
        final condition = conditions
            .where((c) => c.id == conditionId)
            .firstOrNull;
        if (condition == null) return const SizedBox.shrink();

        return GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              CupertinoPageRoute(
                builder: (context) =>
                    ConditionDetailScreen(conditionId: conditionId),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: condition.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: condition.color.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(condition.icon, size: 12, color: condition.color),
                HSpace.xs,
                Text(
                  condition.name,
                  style: AppTypography.caption.copyWith(color: condition.color),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (e, st) => const SizedBox.shrink(),
    );
  }

  Widget _editableItem(
    BuildContext context,
    WidgetRef ref,
    int index,
    Symptom symptom,
    SymptomControllers controllers,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: AppComponents.primaryCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isEditable) _suggestions(ref, index),
          VSpace.s,
          _editableRow(index, controllers),
          VSpace.s,
          _editableNotes(index, controllers),
          VSpace.s,
          _conditionLinkRow(context, ref, index, symptom),
        ],
      ),
    );
  }

  Widget _conditionLinkRow(
    BuildContext context,
    WidgetRef ref,
    int index,
    Symptom symptom,
  ) {
    if (symptom.hasLinkedCondition) {
      return Row(
        children: [
          _conditionBadge(context, ref, symptom.conditionId!),
          HSpace.s,
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => onUpdate(index, conditionId: ''),
            child: Text(
              'Remove',
              style: AppTypography.caption.copyWith(
                color: CupertinoColors.destructiveRed,
              ),
            ),
          ),
        ],
      );
    }

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () => _showConditionPicker(context, ref, index),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            CupertinoIcons.bandage,
            size: 14,
            color: CupertinoColors.systemBlue,
          ),
          HSpace.xs,
          Text(
            '+ Link Condition',
            style: AppTypography.bodySmall.copyWith(
              color: CupertinoColors.systemBlue,
            ),
          ),
        ],
      ),
    );
  }

  void _showConditionPicker(BuildContext context, WidgetRef ref, int index) {
    final conditionsAsync = ref.read(conditionsNotifierProvider);

    conditionsAsync.when(
      data: (conditions) {
        final activeConditions = conditions.where((c) => c.isActive).toList();

        showCupertinoModalPopup(
          context: context,
          builder: (context) => CupertinoActionSheet(
            title: const Text('Link to Condition'),
            message: const Text(
              'Select an active condition or create a new one',
            ),
            actions: [
              ...activeConditions.map(
                (condition) => CupertinoActionSheetAction(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onUpdate(index, conditionId: condition.id);
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(condition.icon, color: condition.color, size: 18),
                      HSpace.s,
                      Text(condition.name),
                    ],
                  ),
                ),
              ),
              CupertinoActionSheetAction(
                onPressed: () async {
                  Navigator.of(context).pop();
                  final newCondition = await Navigator.of(context)
                      .push<Condition>(
                        CupertinoPageRoute(
                          builder: (context) => const ConditionForm(),
                        ),
                      );
                  if (newCondition != null) {
                    onUpdate(index, conditionId: newCondition.id);
                  }
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.add,
                      color: CupertinoColors.systemBlue,
                      size: 18,
                    ),
                    HSpace.s,
                    Text('+ New Condition'),
                  ],
                ),
              ),
            ],
            cancelButton: CupertinoActionSheetAction(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ),
        );
      },
      loading: () {},
      error: (e, st) {},
    );
  }

  Widget _suggestions(WidgetRef ref, int index) {
    final symptom = symptoms[index];

    if (symptom.majorComponent.isNotEmpty ||
        symptom.minorComponent.isNotEmpty) {
      return const SizedBox.shrink();
    }

    final suggestionsAsync = ref.watch(symptomSuggestionsProvider);

    return suggestionsAsync.when(
      data: (suggestions) {
        final availableSuggestions = suggestions.where((suggestion) {
          final suggestionKey = SymptomNormalizer.generateKey(
            suggestion.majorComponent,
            suggestion.minorComponent,
          );
          return !usedSuggestions.contains(suggestionKey);
        }).toList();

        if (availableSuggestions.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Recent symptoms:', style: AppTypography.labelMediumSecondary),
            VSpace.s,
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: availableSuggestions.map((suggestion) {
                return CupertinoButton(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  color: AppColors.backgroundSecondary,
                  borderRadius: BorderRadius.circular(16),
                  onPressed: () {
                    final newSymptom =
                        SymptomSuggestionsService.createSymptomFromSuggestion(
                          suggestion,
                        );
                    final suggestionKey = SymptomNormalizer.generateKey(
                      suggestion.majorComponent,
                      suggestion.minorComponent,
                    );
                    onUpdateFromSuggestion(index, newSymptom, suggestionKey);
                  },
                  child: Text(
                    suggestion.toString(),
                    style: AppTypography.bodySmallPrimary,
                  ),
                );
              }).toList(),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }

  Widget _editableRow(int index, SymptomControllers controllers) {
    return Row(
      children: [
        Expanded(
          child: CupertinoTextField(
            controller: controllers.majorComponent,
            placeholder: 'Major component (e.g., headache)',
            placeholderStyle: AppTypography.inputPlaceholder,
            style: AppTypography.input,
            onChanged: (value) => onUpdate(index, majorComponent: value),
          ),
        ),
        HSpace.s,
        Expanded(
          child: CupertinoTextField(
            controller: controllers.minorComponent,
            placeholder: 'Minor component (e.g., right temple)',
            placeholderStyle: AppTypography.inputPlaceholder,
            style: AppTypography.input,
            onChanged: (value) => onUpdate(index, minorComponent: value),
          ),
        ),
        HSpace.s,
        SizedBox(
          width: 80,
          child: CupertinoTextField(
            controller: controllers.severity,
            placeholder: '1-10',
            placeholderStyle: AppTypography.inputPlaceholder,
            style: AppTypography.input,
            keyboardType: TextInputType.number,
            onChanged: (value) {
              final severity = int.tryParse(value);
              if (severity != null && severity >= 1 && severity <= 10) {
                onUpdate(index, severityLevel: severity);
              }
            },
          ),
        ),
        HSpace.s,
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => onRemove(index),
          child: const Icon(
            CupertinoIcons.delete,
            color: CupertinoColors.destructiveRed,
          ),
        ),
      ],
    );
  }

  Widget _editableNotes(int index, SymptomControllers controllers) {
    return CupertinoTextField(
      controller: controllers.additionalNotes,
      placeholder: 'Additional notes (optional)',
      placeholderStyle: AppTypography.inputPlaceholder,
      style: AppTypography.input,
      maxLines: 2,
      onChanged: (value) => onUpdate(index, additionalNotes: value),
    );
  }
}
