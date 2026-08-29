import 'package:flutter/material.dart';
import 'package:health_notes/models/medication_schedule.dart';
import 'package:health_notes/theme/app_theme.dart';
import 'package:health_notes/theme/spacing.dart';
import 'package:health_notes/widgets/app_card.dart';

class ScheduleCard extends StatelessWidget {
  final MedicationSchedule schedule;
  final VoidCallback onActivated;

  const ScheduleCard({required this.schedule, required this.onActivated});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onActivated,
          borderRadius: BorderRadius.circular(AppRadius.medium),
          child: AppCard(child: _cardBody()),
        ),
      ),
    );
  }

  Widget _cardBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          schedule.medicationName.display,
          style: AppText.label.large.primary,
        ),
        VSpace.s,
        Text(schedule.sentence, style: AppText.body.medium),
        VSpace.xs,
        Text(schedule.listCaption, style: AppText.caption.tertiary),
      ],
    );
  }
}
