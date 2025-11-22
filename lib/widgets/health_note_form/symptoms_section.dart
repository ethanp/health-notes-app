import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_notes/models/symptom.dart';
import 'package:health_notes/providers/symptom_suggestions_provider.dart';
import 'package:health_notes/screens/symptom_trends_screen.dart';
import 'package:health_notes/services/symptom_suggestions_service.dart';
import 'package:health_notes/services/text_normalizer.dart';
import 'package:health_notes/theme/app_theme.dart';
import 'package:health_notes/widgets/enhanced_ui_components.dart';
import 'package:health_notes/widgets/health_note_form/form_controllers.dart';

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
        children: [
          _header(),
          const SizedBox(height: 8),
          _content(context, ref),
        ],
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
        children: symptoms.map((s) => _readOnlyItem(context, s)).toList(),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: symptoms.asMap().entries.map((entry) {
        final index = entry.key;
        final symptom = entry.value;
        return _editableItem(ref, index, symptom, controllers[index]!);
      }).toList(),
    );
  }

  Widget _readOnlyItem(BuildContext context, Symptom symptom) {
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
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    symptom.fullDescription,
                    style: AppTypography.bodyMedium,
                  ),
                ),
                EnhancedUIComponents.statusIndicator(
                  text: '${symptom.severityLevel}/10',
                  color: AppColors.primary,
                ),
              ],
            ),
            if (symptom.additionalNotes.isNotEmpty) ...[
              const SizedBox(height: 8),
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

  Widget _editableItem(
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
          const SizedBox(height: 8),
          _editableRow(index, controllers),
          const SizedBox(height: 8),
          _editableNotes(index, controllers),
        ],
      ),
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
            const SizedBox(height: 8),
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
        const SizedBox(width: 8),
        Expanded(
          child: CupertinoTextField(
            controller: controllers.minorComponent,
            placeholder: 'Minor component (e.g., right temple)',
            placeholderStyle: AppTypography.inputPlaceholder,
            style: AppTypography.input,
            onChanged: (value) => onUpdate(index, minorComponent: value),
          ),
        ),
        const SizedBox(width: 8),
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
        const SizedBox(width: 8),
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
