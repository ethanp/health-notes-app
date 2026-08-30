import 'package:ethan_ui/ethan_ui.dart';
import 'package:flutter/material.dart';
import 'package:health_notes/models/medication_schedule.dart';
import 'package:health_notes/theme/app_theme.dart';

class const DueDoseChip({
  required final ScheduledDoseOccurrence occurrence,
  required final bool isNearest,
  required final VoidCallback onActivated,
}) extends StatelessWidget {
  static const _nowLabelHeight = 14.0;
  static const _nowLabelOverlap = 4.0;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [_plate(), if (isNearest) _nowLabel()],
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
          decoration: AppComponents.tintedSolidDecoration(EColors.accentGlow)
              .copyWith(
                border: const Border(
                  left: BorderSide(color: EColors.accentGlow, width: 3),
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
          style: EText.label.medium.primary,
        ),
        Text(
          '${occurrence.amountCaption} · ${occurrence.whenCaption}',
          style: EText.body.small.copyWith(fontWeight: FontWeight.w600),
        ),
        if (occurrence.stepProgressCaption != null)
          Text(occurrence.stepProgressCaption!, style: EText.caption.tertiary),
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
          style: EText.label.small.copyWith(color: EColors.accentGlow),
        ),
      ),
    );
  }
}
