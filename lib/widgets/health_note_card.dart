import 'package:ethan_ui/ethan_ui.dart';
import 'package:ethan_utils/ethan_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:health_notes/models/health_note.dart';
import 'package:health_notes/theme/spacing.dart';
import 'package:health_notes/utils/date_utils.dart';
import 'package:health_notes/widgets/app_filter_chip.dart';
import 'package:health_notes/widgets/note_summary_rows.dart';

/// Health note card for displaying in lists
class HealthNoteCard extends StatelessWidget {
  final HealthNote note;
  final VoidCallback onTap;

  const HealthNoteCard({required this.note, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: ECard(
        margin: const EdgeInsets.only(bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            if (_hasContent()) ...[VSpace.of(6), _buildContent()],
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
        style: EText.body.small.muted,
      ),
    );
  }

  bool _hasContent() {
    return note.hasSymptoms ||
        note.drugDoses.isNotEmpty ||
        note.appliedTools.isNotEmpty ||
        note.notes.isNotEmpty;
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...note.validSymptoms.mapL(
          (symptom) => SymptomSummaryRow(symptom: symptom),
        ),
        ...note.validDrugDoses.mapL((dose) => MedicationSummaryRow(dose: dose)),
        ...note.appliedTools.mapL(
          (tool) => AppliedToolSummaryRow(appliedTool: tool),
        ),
        if (note.notes.isNotEmpty) _buildGeneralNotes(),
      ],
    );
  }

  Widget _buildGeneralNotes() {
    return Text(
      note.notes,
      style: EText.body.small,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// Filter chip for note filtering
class FilterChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const FilterChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppFilterChip(label: label, isActive: isActive, onTap: onTap);
  }
}
