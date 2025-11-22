import 'package:flutter/cupertino.dart';
import 'package:health_notes/models/health_note.dart';
import 'package:health_notes/theme/app_theme.dart';
import 'package:health_notes/utils/date_utils.dart';
import 'package:health_notes/utils/number_formatter.dart';
import 'package:health_notes/widgets/enhanced_ui_components.dart';
import 'package:health_notes/widgets/spacing.dart';

/// Health note card for displaying in lists
class HealthNoteCard extends StatelessWidget {
  final HealthNote note;
  final VoidCallback onTap;

  const HealthNoteCard({super.key, required this.note, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: AppComponents.primaryCard,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            if (_hasContent()) ...[VSpace.of(12), _buildContent()],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          AppDateUtils.formatShortDate(note.dateTime),
          style: AppTypography.labelLarge,
        ),
        Text(
          AppDateUtils.formatTime(note.dateTime),
          style: AppTypography.bodySmallSystemGrey,
        ),
      ],
    );
  }

  bool _hasContent() {
    return note.hasSymptoms ||
        note.drugDoses.isNotEmpty ||
        note.notes.isNotEmpty;
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (note.hasSymptoms) _buildSymptoms(),
        if (note.drugDoses.isNotEmpty) _buildDrugDoses(),
        if (note.notes.isNotEmpty) _buildGeneralNotes(),
      ],
    );
  }

  Widget _buildSymptoms() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: note.validSymptoms
            .map(
              (symptom) => _SymptomChip(
                symptomName: symptom.majorComponent,
                severity: symptom.severityLevel,
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildDrugDoses() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: note.drugDoses
            .map(
              (drug) => _DrugChip(
                drugName: drug.name,
                dosage: drug.dosage,
                unit: drug.unit,
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildGeneralNotes() {
    return Text(
      note.notes,
      style: AppTypography.bodySmall,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// Symptom chip with severity indicator
class _SymptomChip extends StatelessWidget {
  final String symptomName;
  final int severity;

  const _SymptomChip({required this.symptomName, required this.severity});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            symptomName,
            style: AppTypography.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          if (severity > 0) ...[
            HSpace.xs,
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                severity.toString(),
                style: AppTypography.bodySmall.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Drug dose chip
class _DrugChip extends StatelessWidget {
  final String drugName;
  final double dosage;
  final String unit;

  const _DrugChip({
    required this.drugName,
    required this.dosage,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
      ),
      child: Text(
        dosage > 0
            ? '$drugName (${formatDecimalValue(dosage)}$unit)'
            : drugName,
        style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// Filter chip for note filtering
class FilterChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const FilterChip({
    super.key,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return EnhancedUIComponents.filterChip(
      label: label,
      isActive: isActive,
      onTap: onTap,
    );
  }
}
