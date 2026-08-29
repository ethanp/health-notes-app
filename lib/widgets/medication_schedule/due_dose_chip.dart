import 'package:flutter/material.dart';
import 'package:health_notes/models/medication_schedule.dart';
import 'package:health_notes/theme/app_theme.dart';

class DueDoseChip extends StatelessWidget {
  final ScheduledDoseOccurrence occurrence;
  final bool isNearest;
  final VoidCallback onActivated;

  const DueDoseChip({
    required this.occurrence,
    required this.isNearest,
    required this.onActivated,
  });

  static const _nowLabelHeight = 14.0;
  static const _nowLabelOverlap = 4.0;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _plate(),
        if (isNearest) _nowLabel(),
      ],
    );
  }

  Widget _plate() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onActivated,
        borderRadius: BorderRadius.circular(AppRadius.small),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.m,
            vertical: AppSpacing.s,
          ),
          decoration: AppComponents.tintedSolidDecoration(
            AppColors.secondary,
          ).copyWith(
            border: const Border(
              left: BorderSide(color: AppColors.secondary, width: 3),
            ),
          ),
          child: _labels(),
        ),
      ),
    );
  }

  Widget _labels() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          occurrence.medicationName.display,
          style: AppText.label.medium.primary,
        ),
        Text(
          '${occurrence.amountCaption} · ${occurrence.whenCaption}',
          style: AppText.body.small.copyWith(fontWeight: FontWeight.w600),
        ),
        if (occurrence.stepProgressCaption != null)
          Text(
            occurrence.stepProgressCaption!,
            style: AppText.caption.tertiary,
          ),
      ],
    );
  }

  Widget _nowLabel() {
    return Positioned(
      left: 0,
      right: 0,
      top: -(_nowLabelHeight - _nowLabelOverlap),
      child: Center(
        child: Text(
          'now',
          style: AppText.label.small.copyWith(color: AppColors.secondary),
        ),
      ),
    );
  }
}
