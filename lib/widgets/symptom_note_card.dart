import 'package:flutter/cupertino.dart';
import 'package:health_notes/models/health_note.dart';
import 'package:health_notes/models/symptom.dart';
import 'package:health_notes/theme/app_theme.dart';
import 'package:health_notes/utils/date_utils.dart';
import 'package:health_notes/utils/severity_utils.dart';
import 'package:health_notes/widgets/spacing.dart';

/// Reusable note card component for displaying symptom information
class SymptomNoteCard extends StatelessWidget {
  final HealthNote note;
  final String symptomName;

  const SymptomNoteCard({
    super.key,
    required this.note,
    required this.symptomName,
  });

  @override
  Widget build(BuildContext context) {
    final symptom = note.symptomsList.firstWhere(
      (s) => s.majorComponent == symptomName,
    );

    return Container(
      decoration: AppComponents.primaryCard,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(symptom),
          if (_hasDetails(symptom)) _buildDetails(symptom),
          if (note.notes.isNotEmpty) _buildGeneralNotes(),
        ],
      ),
    );
  }

  Widget _buildHeader(Symptom symptom) {
    return Row(
      children: [
        Expanded(
          child: Text(
            AppDateUtils.formatShortDate(note.dateTime),
            style: AppTypography.labelLarge,
          ),
        ),
        _SeverityIndicator(severity: symptom.severityLevel),
      ],
    );
  }

  bool _hasDetails(Symptom symptom) {
    return symptom.minorComponent.isNotEmpty ||
        symptom.additionalNotes.isNotEmpty;
  }

  Widget _buildDetails(Symptom symptom) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (symptom.minorComponent.isNotEmpty) ...[
          VSpace.s,
          Text(
            symptom.minorComponent,
            style: AppTypography.bodyMediumSystemGrey,
          ),
        ],
        if (symptom.additionalNotes.isNotEmpty) ...[
          VSpace.s,
          Text(symptom.additionalNotes, style: AppTypography.bodyMedium),
        ],
      ],
    );
  }

  Widget _buildGeneralNotes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        VSpace.s,
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: CupertinoColors.systemGrey6,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(note.notes, style: AppTypography.bodySmall),
        ),
      ],
    );
  }
}

/// Severity indicator widget showing color-coded severity level
class _SeverityIndicator extends StatelessWidget {
  final int severity;

  const _SeverityIndicator({required this.severity});

  @override
  Widget build(BuildContext context) {
    final severityColor = SeverityUtils.colorForSeverity(severity);
    final severityText = SeverityUtils.displayText(severity);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: severityColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: severityColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        severityText,
        style: AppTypography.labelSmall.copyWith(color: severityColor),
      ),
    );
  }
}
