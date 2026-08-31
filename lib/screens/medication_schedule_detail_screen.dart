import 'package:ethan_ui/ethan_ui.dart';
import 'package:ethan_utils/ethan_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_notes/models/medication_schedule.dart';
import 'package:health_notes/providers/medication_schedules_provider.dart';
import 'package:health_notes/screens/medication_schedule_form.dart';
import 'package:health_notes/theme/app_theme.dart';
import 'package:health_notes/theme/spacing.dart';
import 'package:health_notes/utils/health_date_format.dart';
import 'package:health_notes/widgets/medication_schedule/schedule_kind_chip.dart';
import 'package:health_notes/widgets/medication_schedule/schedule_scaffold.dart';
import 'package:health_notes/widgets/sync_status_widget.dart';

class const MedicationScheduleDetailScreen({required final String scheduleId})
    extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schedulesAsync = ref.watch(medicationSchedulesProvider);
    return schedulesAsync.when(
      data: (schedules) {
        final schedule = schedules
            .where((item) => item.id == scheduleId)
            .firstOrNull;
        if (schedule == null) {
          return const MedicationScheduleScaffold(
            title: 'Schedule',
            body: Center(child: Text('Schedule not found')),
          );
        }
        return _scheduleDetail(context, ref, schedule);
      },
      loading: () => const MedicationScheduleScaffold(
        title: 'Schedule',
        body: SyncStatusWidget.loading(message: 'Loading schedule...'),
      ),
      error: (error, stack) => MedicationScheduleScaffold(
        title: 'Schedule',
        body: SyncStatusWidget.error(
          errorMessage: 'Error: $error',
          onRetry: () => ref.invalidate(medicationSchedulesProvider),
        ),
      ),
    );
  }

  Widget _scheduleDetail(
    BuildContext context,
    WidgetRef ref,
    MedicationSchedule schedule,
  ) {
    return MedicationScheduleScaffold(
      title: schedule.medicationName.display,
      actions: [
        IconButton(
          tooltip: 'Edit schedule',
          onPressed: () =>
              context.push(MedicationScheduleForm(existing: schedule)),
          icon: const Icon(Icons.edit),
        ),
      ],
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.m),
        children: [
          Row(
            children: [
              ScheduleKindChip(kind: schedule.kind),
              HSpace.s,
              Expanded(
                child: Text(
                  schedule.listCaption,
                  style: EText.body.medium.tertiary,
                ),
              ),
            ],
          ),
          if (schedule.notes.isNotEmpty) ...[
            VSpace.s,
            Text(schedule.notes, style: EText.body.medium),
          ],
          VSpace.l,
          ..._stepCards(schedule),
          if (schedule.isListedAsActive) ...[
            VSpace.l,
            OutlinedButton(
              onPressed: () => _stopSchedule(context, ref, schedule),
              child: const Text('Stop schedule'),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _stepCards(MedicationSchedule schedule) {
    final cards = <Widget>[];
    var cursor = schedule.startDay;
    for (final step in schedule.steps) {
      final stepEnd = step.durationDays == null
          ? schedule.lastCoveredDay
          : DateTime(
              cursor.year,
              cursor.month,
              cursor.day + step.durationDays! - 1,
            );
      cards.add(
        _stepCard(schedule, step, _StepDateRange(start: cursor, end: stepEnd)),
      );
      if (step.durationDays != null) {
        cursor = DateTime(
          cursor.year,
          cursor.month,
          cursor.day + step.durationDays!,
        );
      }
    }
    return cards;
  }

  Widget _stepCard(
    MedicationSchedule schedule,
    ScheduleStep step,
    _StepDateRange range,
  ) {
    final today = DateTime.now();
    final isCurrent = schedule.stepOn(today)?.id == step.id;
    final isPast =
        range.end != null &&
        range.end!.isBefore(today.startOfDay) &&
        !isCurrent;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s),
      child: Opacity(
        opacity: isPast ? 0.55 : 1,
        child: ECard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                step.sentenceFragment(unit: schedule.unit, omitWhen: false),
                style: EText.label.large.copyWith(
                  color: isCurrent ? EColors.accentGlow : EColors.textPrimary,
                ),
              ),
              VSpace.xs,
              Text(_rangeCaption(range), style: EText.caption.tertiary),
            ],
          ),
        ),
      ),
    );
  }

  String _rangeCaption(_StepDateRange range) {
    final start = range.start.monthDayYear;
    if (range.end == null) return 'From $start';
    return '$start – ${range.end!.monthDayYear}';
  }

  Future<void> _stopSchedule(
    BuildContext context,
    WidgetRef ref,
    MedicationSchedule schedule,
  ) async {
    await ref
        .read(medicationSchedulesProvider.notifier)
        .stopSchedule(schedule.id);
    if (context.mounted) context.pop();
  }
}

class const _StepDateRange({
  required final DateTime start,
  required final DateTime? end,
});
