import 'package:ethan_ui/ethan_ui.dart';
import 'package:flutter/material.dart';
import 'package:health_notes/models/medication_schedule.dart';
import 'package:health_notes/theme/app_theme.dart';
import 'package:health_notes/theme/spacing.dart';

import 'schedule_kind_chip.dart';

class const ScheduleCard({
  required final MedicationSchedule schedule,
  required final VoidCallback onActivated,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onActivated,
          borderRadius: BorderRadius.circular(AppRadius.medium),
          child: ECard(child: _cardBody()),
        ),
      ),
    );
  }

  Widget _cardBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                schedule.medicationName.display,
                style: EText.label.large.primary,
              ),
            ),
            HSpace.s,
            ScheduleKindChip(kind: schedule.kind),
          ],
        ),
        VSpace.s,
        Text(schedule.sentence, style: EText.body.medium),
        VSpace.xs,
        Text(schedule.listCaption, style: EText.caption.tertiary),
      ],
    );
  }
}
