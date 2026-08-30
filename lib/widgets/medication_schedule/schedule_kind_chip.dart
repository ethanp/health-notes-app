import 'package:ethan_ui/ethan_ui.dart';
import 'package:flutter/material.dart';
import 'package:health_notes/models/medication_schedule.dart';

class const ScheduleKindChip({required final ScheduleKind kind})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return EStatusChip(
      label: kind.label,
      tone: switch (kind) {
        ScheduleKind.taper => EStatusTone.accent,
        ScheduleKind.daily => EStatusTone.muted,
      },
    );
  }
}
