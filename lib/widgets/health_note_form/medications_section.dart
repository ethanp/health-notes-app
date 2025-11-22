import 'package:flutter/cupertino.dart';
import 'package:health_notes/models/drug_dose.dart';
import 'package:health_notes/screens/drug_trends_screen.dart';
import 'package:health_notes/theme/app_theme.dart';
import 'package:health_notes/utils/number_formatter.dart';
import 'package:health_notes/widgets/enhanced_ui_components.dart';
import 'package:health_notes/widgets/health_note_form/form_controllers.dart';
import 'package:health_notes/widgets/spacing.dart';

class MedicationsSection extends StatelessWidget {
  final bool isEditable;
  final List<DrugDose> drugDoses;
  final Map<int, DrugDoseControllers> controllers;
  final VoidCallback onAdd;
  final Function(int) onRemove;
  final Function(int, {String? name, double? dosage, String? unit}) onUpdate;
  final List<DrugDose> recentRecommendations;
  final List<DrugDose> commonRecommendations;

  const MedicationsSection({
    super.key,
    required this.isEditable,
    required this.drugDoses,
    required this.controllers,
    required this.onAdd,
    required this.onRemove,
    required this.onUpdate,
    this.recentRecommendations = const [],
    this.commonRecommendations = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: isEditable
          ? AppComponents.inputField
          : AppComponents.primaryCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [_header(), VSpace.s, _content(context)],
      ),
    );
  }

  Widget _header() {
    return EnhancedUIComponents.sectionHeader(
      title: 'Medications',
      trailing: isEditable
          ? CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: onAdd,
              child: const Icon(CupertinoIcons.add),
            )
          : null,
    );
  }

  Widget _content(BuildContext context) {
    if (drugDoses.isEmpty) {
      return Text('No medications recorded', style: AppTypography.bodyMedium);
    }

    if (!isEditable) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: drugDoses.map((d) => _readOnlyItem(context, d)).toList(),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: drugDoses.asMap().entries.map((entry) {
        final index = entry.key;
        final dose = entry.value;
        return _editableItem(index, dose, controllers[index]!);
      }).toList(),
    );
  }

  Widget _readOnlyItem(BuildContext context, DrugDose dose) {
    return GestureDetector(
      onTap: () {
        if (dose.name.isNotEmpty) {
          Navigator.of(context).push(
            CupertinoPageRoute(
              builder: (context) => DrugTrendsScreen(drugName: dose.name),
            ),
          );
        }
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
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
            Expanded(child: Text(dose.name, style: AppTypography.bodyMedium)),
            Text(dose.displayDosage, style: AppTypography.bodyMediumTertiary),
          ],
        ),
      ),
    );
  }

  Widget _editableItem(
    int index,
    DrugDose dose,
    DrugDoseControllers controllers,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: AppComponents.primaryCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: CupertinoTextField(
                  controller: controllers.name,
                  placeholder: 'Medication name',
                  placeholderStyle: AppTypography.inputPlaceholder,
                  style: AppTypography.input,
                  onChanged: (value) => onUpdate(index, name: value),
                ),
              ),
              HSpace.s,
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => onRemove(index),
                child: const Icon(
                  CupertinoIcons.delete,
                  color: AppColors.destructive,
                ),
              ),
            ],
          ),
          VSpace.s,
          Row(
            children: [
              Expanded(
                child: CupertinoTextField(
                  controller: controllers.dosage,
                  placeholder: 'Dosage',
                  placeholderStyle: AppTypography.inputPlaceholder,
                  style: AppTypography.input,
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    final dosage = double.tryParse(value) ?? 0.0;
                    onUpdate(index, dosage: dosage);
                  },
                ),
              ),
              HSpace.s,
              SizedBox(
                width: 80,
                child: CupertinoTextField(
                  controller: controllers.unit,
                  placeholder: 'Unit',
                  placeholderStyle: AppTypography.inputPlaceholder,
                  style: AppTypography.input,
                  onChanged: (value) => onUpdate(index, unit: value),
                ),
              ),
            ],
          ),
          if (dose.name.isEmpty &&
              (recentRecommendations.isNotEmpty ||
                  commonRecommendations.isNotEmpty)) ...[
            VSpace.of(12),
            _recommendations(index),
          ],
        ],
      ),
    );
  }

  Widget _recommendations(int index) {
    final allRecommendations = {
      ...recentRecommendations,
      ...commonRecommendations,
    }.toList();

    if (allRecommendations.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Suggested', style: AppTypography.labelSmallPrimary),
        VSpace.xs,
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: allRecommendations
              .map((r) => _recommendationChip(index, r))
              .toList(),
        ),
      ],
    );
  }

  Widget _recommendationChip(int index, DrugDose recommendation) {
    return GestureDetector(
      onTap: () {
        onUpdate(
          index,
          name: recommendation.name,
          dosage: recommendation.dosage,
          unit: recommendation.unit,
        );
        controllers[index]?.name.text = recommendation.name;
        controllers[index]?.dosage.text = formatDecimalValue(
          recommendation.dosage,
        );
        controllers[index]?.unit.text = recommendation.unit;
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.backgroundTertiary,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.backgroundQuaternary),
        ),
        child: Text(
          '${recommendation.name} ${recommendation.displayDosage}',
          style: AppTypography.bodyMedium,
        ),
      ),
    );
  }
}
