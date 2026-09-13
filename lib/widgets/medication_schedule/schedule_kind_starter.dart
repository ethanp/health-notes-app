import 'package:ethan_ui/ethan_ui.dart';
import 'package:flutter/material.dart';
import 'package:health_notes/models/medication_schedule.dart';
import 'package:health_notes/theme/app_theme.dart';
import 'package:health_notes/theme/spacing.dart';

class const ScheduleKindStarter({
  required final ValueChanged<ScheduleKind> onKindSelected,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.m).withOverlaidTabBar(context),
      children: [
        Text('What kind of course?', style: EText.headline.small),
        VSpace.m,
        ScheduleKindStarterCard(
          title: 'Taper',
          caption: '40mg for 7 mornings, then 30mg for 3 mornings',
          onActivated: () => onKindSelected(ScheduleKind.taper),
        ),
        ScheduleKindStarterCard(
          title: 'Times each day',
          caption: '200mg at 10:30 AM, 200mg at 4:30 PM, 300mg at 10:30 PM',
          onActivated: () => onKindSelected(ScheduleKind.daily),
        ),
      ],
    );
  }
}

class const ScheduleKindStarterCard({
  required final String title,
  required final String caption,
  required final VoidCallback onActivated,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.m),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onActivated,
          borderRadius: BorderRadius.circular(AppRadius.medium),
          child: ECard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: EText.label.large.primary),
                VSpace.s,
                Text(caption, style: EText.body.medium.tertiary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
