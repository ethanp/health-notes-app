import 'package:flutter/cupertino.dart';
import 'package:health_notes/models/health_note.dart';
import 'package:health_notes/screens/drug_trends_screen.dart';
import 'package:health_notes/screens/symptom_trends_screen.dart';
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
            if (_hasContent()) ...[VSpace.of(12), _buildContent(context)],
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
        note.appliedTools.isNotEmpty ||
        note.notes.isNotEmpty;
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (note.hasSymptoms) _buildSymptoms(context),
        if (note.appliedTools.isNotEmpty) _buildAppliedTools(),
        if (note.drugDoses.isNotEmpty) _buildDrugDoses(context),
        if (note.notes.isNotEmpty) _buildGeneralNotes(),
      ],
    );
  }

  Widget _buildAppliedTools() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: note.appliedTools
            .map((tool) => _ToolChip(toolName: tool.toolName))
            .toList(),
      ),
    );
  }

  Widget _buildSymptoms(BuildContext context) {
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
                onTap: () => Navigator.of(context).push(
                  CupertinoPageRoute(
                    builder: (_) => SymptomTrendsScreen(
                      symptomName: symptom.majorComponent,
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildDrugDoses(BuildContext context) {
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
                onTap: () => Navigator.of(context).push(
                  CupertinoPageRoute(
                    builder: (_) => DrugTrendsScreen(drugName: drug.name),
                  ),
                ),
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
  final VoidCallback onTap;

  const _SymptomChip({
    required this.symptomName,
    required this.severity,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
      ),
    );
  }
}

/// Drug dose chip
class _DrugChip extends StatelessWidget {
  final String drugName;
  final double dosage;
  final String unit;
  final VoidCallback onTap;

  const _DrugChip({
    required this.drugName,
    required this.dosage,
    required this.unit,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
      ),
    );
  }
}

/// Applied tool chip
class _ToolChip extends StatelessWidget {
  final String toolName;

  const _ToolChip({required this.toolName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.accentWarm.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accentWarm.withValues(alpha: 0.3)),
      ),
      child: Text(
        toolName,
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
