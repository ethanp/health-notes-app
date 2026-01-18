import 'package:ethan_utils/ethan_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:health_notes/models/health_note.dart';
import 'package:health_notes/screens/drug_trends_screen.dart';
import 'package:health_notes/screens/symptom_trends_screen.dart';
import 'package:health_notes/screens/tool_detail_screen.dart';
import 'package:health_notes/theme/app_theme.dart';
import 'package:health_notes/theme/spacing.dart';
import 'package:health_notes/utils/date_utils.dart';
import 'package:health_notes/utils/number_formatter.dart';
import 'package:health_notes/widgets/enhanced_ui_components.dart';

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
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 8),
        decoration: AppComponents.primaryCard,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            if (_hasContent()) ...[VSpace.of(6), _buildContent(context)],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        AppDateUtils.formatTime(note.dateTime),
        style: AppTypography.bodySmallSystemGrey,
      ),
    );
  }

  bool _hasContent() {
    return note.hasSymptoms ||
        note.drugDoses.isNotEmpty ||
        note.appliedTools.isNotEmpty ||
        note.notes.isNotEmpty;
  }

  Widget _buildContent(BuildContext context) {
    final hasChips =
        note.hasSymptoms ||
        note.drugDoses.isNotEmpty ||
        note.appliedTools.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasChips) _buildChips(context),
        if (note.notes.isNotEmpty) _buildGeneralNotes(),
      ],
    );
  }

  Widget _buildChips(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [...symptoms(context), ...meds(context), ...tools(context)],
      ),
    );
  }

  Iterable<Widget> tools(BuildContext context) {
    return note.appliedTools.map(
      (tool) => _ToolChip(toolId: tool.toolId, toolName: tool.toolName),
    );
  }

  Iterable<Widget> meds(BuildContext context) {
    return note.drugDoses.map(
      (drug) =>
          _DrugChip(drugName: drug.name, dosage: drug.dosage, unit: drug.unit),
    );
  }

  Iterable<Widget> symptoms(BuildContext context) {
    return note.validSymptoms.map(
      (symptom) => _SymptomChip(
        symptomName: symptom.majorComponent,
        severity: symptom.severityLevel,
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

/// Base chip widget with consistent styling and optional badge
class _NoteChip extends StatelessWidget {
  final Color color;
  final String label;
  final String? badge;
  final VoidCallback onTap;

  const _NoteChip({
    required this.color,
    required this.label,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (badge != null) ...[
              HSpace.xs,
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badge!,
                  style: AppTypography.bodySmall.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: color,
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

/// Symptom chip with severity indicator
class _SymptomChip extends StatelessWidget {
  final String symptomName;
  final int severity;

  const _SymptomChip({required this.symptomName, required this.severity});

  @override
  Widget build(BuildContext context) {
    return _NoteChip(
      color: AppColors.primary,
      label: symptomName,
      badge: severity > 0 ? severity.toString() : null,
      onTap: () =>
          context.push((_) => SymptomTrendsScreen(symptomName: symptomName)),
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
    return _NoteChip(
      color: AppColors.accent,
      label: drugName,
      badge: dosage > 0 ? '${formatDecimalValue(dosage)}$unit' : null,
      onTap: () => context.push((_) => DrugTrendsScreen(drugName: drugName)),
    );
  }
}

/// Applied tool chip
class _ToolChip extends StatelessWidget {
  final String toolId;
  final String toolName;

  const _ToolChip({required this.toolId, required this.toolName});

  @override
  Widget build(BuildContext context) {
    return _NoteChip(
      color: AppColors.accentWarm,
      label: toolName,
      onTap: () => context.push(
        (_) => ToolDetailScreen(toolId: toolId, toolName: toolName),
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
