import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_notes/models/condition.dart';
import 'package:health_notes/models/symptom.dart';
import 'package:health_notes/models/symptom_component_index.dart';
import 'package:health_notes/providers/conditions_provider.dart';
import 'package:health_notes/providers/pinned_symptom_components_provider.dart';
import 'package:health_notes/providers/symptom_component_provider.dart';
import 'package:health_notes/screens/condition_detail_screen.dart';
import 'package:health_notes/screens/condition_form.dart';
import 'package:health_notes/screens/symptom_trends_screen.dart';
import 'package:health_notes/theme/app_theme.dart';
import 'package:health_notes/widgets/component_picker_sheet.dart';
import 'package:health_notes/widgets/enhanced_ui_components.dart';
import 'package:health_notes/widgets/health_note_form/form_controllers.dart';
import 'package:health_notes/theme/spacing.dart';

class SymptomsSection extends ConsumerWidget {
  final bool isEditable;
  final List<Symptom> symptoms;
  final Map<int, SymptomControllers> controllers;
  final VoidCallback onAdd;
  final Function(int) onRemove;
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
    required this.onAdd,
    required this.onRemove,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Pre-load providers so they're ready when user taps a selector
    if (isEditable) {
      ref.watch(symptomComponentIndexProvider);
      ref.watch(conditionsNotifierProvider);
    }

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
          _componentSelectors(context, ref, index, symptom),
          VSpace.s,
          _severityRow(index, symptom, controllers),
          VSpace.s,
          _editableNotes(index, controllers),
          VSpace.s,
          _conditionLinkRow(context, ref, index, symptom),
        ],
      ),
    );
  }

  Widget _componentSelectors(
    BuildContext context,
    WidgetRef ref,
    int index,
    Symptom symptom,
  ) {
    return Row(
      children: [
        Expanded(
          child: _componentSelector(
            context: context,
            ref: ref,
            label: symptom.majorComponent.isEmpty
                ? 'Select major...'
                : symptom.majorComponent,
            isEmpty: symptom.majorComponent.isEmpty,
            onTap: () => _showMajorPicker(context, ref, index, symptom),
          ),
        ),
        HSpace.s,
        Expanded(
          child: _componentSelector(
            context: context,
            ref: ref,
            label: symptom.minorComponent.isEmpty
                ? 'Select minor...'
                : symptom.minorComponent,
            isEmpty: symptom.minorComponent.isEmpty,
            onTap: symptom.majorComponent.isEmpty
                ? null
                : () => _showMinorPicker(context, ref, index, symptom),
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

  Widget _componentSelector({
    required BuildContext context,
    required WidgetRef ref,
    required String label,
    required bool isEmpty,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.backgroundTertiary,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: onTap == null
                ? AppColors.textQuaternary.withValues(alpha: 0.3)
                : AppColors.textQuaternary,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: isEmpty
                    ? AppTypography.inputPlaceholder
                    : AppTypography.bodyMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              CupertinoIcons.chevron_down,
              size: 14,
              color: onTap == null
                  ? AppColors.textQuaternary.withValues(alpha: 0.3)
                  : AppColors.textQuaternary,
            ),
          ],
        ),
      ),
    );
  }

  void _showMajorPicker(
    BuildContext context,
    WidgetRef ref,
    int index,
    Symptom symptom,
  ) {
    final indexAsync = ref.read(symptomComponentIndexProvider);
    final componentIndex = indexAsync.valueOrNull;

    if (componentIndex == null) {
      // Still loading - show empty picker that allows creating new
      showCupertinoModalPopup(
        context: context,
        builder: (context) => SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: ComponentPickerSheet(
            title: 'Select Major Component',
            components: const [],
            onSelect: (_) {},
            onTogglePin: (_) {},
            onCreate: (name) {
              onUpdate(index, majorComponent: name, minorComponent: '');
            },
          ),
        ),
      );
      return;
    }

    final components = componentIndex.getMajorComponents();
    final conditionsAsync = ref.read(conditionsNotifierProvider);
    final activeConditionIds = conditionsAsync.maybeWhen(
      data: (conditions) =>
          conditions.where((c) => c.isActive).map((c) => c.id).toSet(),
      orElse: () => <String>{},
    );

    showCupertinoModalPopup(
      context: context,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: ComponentPickerSheet(
          title: 'Select Major Component',
          components: components,
          onSelect: (name) {
            onUpdate(index, majorComponent: name);
            _autoPopulateMinorAndCondition(
              ref,
              index,
              name,
              componentIndex,
              activeConditionIds,
            );
          },
          onTogglePin: (component) {
            ref
                .read(pinnedSymptomComponentsNotifierProvider.notifier)
                .toggleMajorPin(component.normalizedName);
          },
          onCreate: (name) {
            onUpdate(index, majorComponent: name, minorComponent: '');
          },
        ),
      ),
    );
  }

  void _showMinorPicker(
    BuildContext context,
    WidgetRef ref,
    int index,
    Symptom symptom,
  ) {
    final indexAsync = ref.read(symptomComponentIndexProvider);
    final componentIndex = indexAsync.valueOrNull;

    if (componentIndex == null) {
      showCupertinoModalPopup(
        context: context,
        builder: (context) => SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: ComponentPickerSheet(
            title: 'Select Minor Component',
            subtitle: symptom.majorComponent,
            components: const [],
            onSelect: (_) {},
            onTogglePin: (_) {},
            onCreate: (name) {
              onUpdate(index, minorComponent: name);
            },
          ),
        ),
      );
      return;
    }

    final components = componentIndex.getMinorComponents(
      symptom.majorComponent,
    );
    final conditionsAsync = ref.read(conditionsNotifierProvider);
    final activeConditionIds = conditionsAsync.maybeWhen(
      data: (conditions) =>
          conditions.where((c) => c.isActive).map((c) => c.id).toSet(),
      orElse: () => <String>{},
    );

    showCupertinoModalPopup(
      context: context,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: ComponentPickerSheet(
          title: 'Select Minor Component',
          subtitle: symptom.majorComponent,
          components: components,
          onSelect: (name) {
            onUpdate(index, minorComponent: name);
            _autoLinkCondition(
              ref,
              index,
              symptom.majorComponent,
              name,
              componentIndex,
              activeConditionIds,
            );
          },
          onTogglePin: (component) {
            ref
                .read(pinnedSymptomComponentsNotifierProvider.notifier)
                .toggleMinorPin(
                  symptom.majorComponent.trim().toLowerCase(),
                  component.normalizedName,
                );
          },
          onCreate: (name) {
            onUpdate(index, minorComponent: name);
          },
        ),
      ),
    );
  }

  void _autoPopulateMinorAndCondition(
    WidgetRef ref,
    int index,
    String majorName,
    SymptomComponentIndex componentIndex,
    Set<String> activeConditionIds,
  ) {
    final defaultMinor = componentIndex.getDefaultMinor(majorName) ?? '';
    onUpdate(index, minorComponent: defaultMinor);
    _autoLinkCondition(
      ref,
      index,
      majorName,
      defaultMinor,
      componentIndex,
      activeConditionIds,
    );
  }

  void _autoLinkCondition(
    WidgetRef ref,
    int index,
    String majorName,
    String minorName,
    SymptomComponentIndex componentIndex,
    Set<String> activeConditionIds,
  ) {
    final conditionId = componentIndex.getAutoLinkedCondition(
      majorName,
      minorName,
      activeConditionIds,
    );
    if (conditionId != null) {
      onUpdate(index, conditionId: conditionId);
    }

    final defaultSeverity = componentIndex.getDefaultSeverity(
      majorName,
      minorName,
    );
    onUpdate(index, severityLevel: defaultSeverity);
  }

  Widget _severityRow(
    int index,
    Symptom symptom,
    SymptomControllers controllers,
  ) {
    return Row(
      children: [
        Text('Severity:', style: AppTypography.labelMedium),
        HSpace.m,
        Expanded(
          child: CupertinoSlider(
            value: symptom.severityLevel.toDouble(),
            min: 1,
            max: 10,
            divisions: 9,
            onChanged: (value) {
              onUpdate(index, severityLevel: value.round());
              controllers.severity.text = value.round().toString();
            },
          ),
        ),
        HSpace.s,
        SizedBox(
          width: 40,
          child: Text(
            '${symptom.severityLevel}/10',
            style: AppTypography.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ),
      ],
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
