import 'package:ethan_ui/ethan_ui.dart';
import 'package:ethan_utils/ethan_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_notes/models/medication_schedule.dart';
import 'package:health_notes/providers/medication_schedules_provider.dart';
import 'package:health_notes/providers/sync_provider.dart';
import 'package:health_notes/screens/medication_schedule_detail_screen.dart';
import 'package:health_notes/screens/medication_schedule_form.dart';
import 'package:health_notes/theme/app_theme.dart';
import 'package:health_notes/theme/spacing.dart';
import 'package:health_notes/widgets/medication_schedule/schedule_card.dart';
import 'package:health_notes/widgets/medication_schedule/schedule_scaffold.dart';
import 'package:health_notes/widgets/sync_status_widget.dart';

class const MedicationSchedulesScreen() extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schedulesAsync = ref.watch(medicationSchedulesProvider);
    return MedicationScheduleScaffold(
      title: 'Schedules',
      actions: [
        IconButton(
          tooltip: 'Add schedule',
          onPressed: () => _showScheduleForm(context),
          icon: const Icon(Icons.add),
        ),
      ],
      body: schedulesAsync.when(
        data: (schedules) => schedules.isEmpty
            ? _emptyState(context, ref)
            : _schedulesList(context, ref, schedules),
        loading: () =>
            const SyncStatusWidget.loading(message: 'Loading schedules...'),
        error: (error, stack) => SyncStatusWidget.error(
          errorMessage: 'Error: $error',
          onRetry: () => ref.invalidate(medicationSchedulesProvider),
        ),
      ),
    );
  }

  Widget _emptyState(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () => ref.read(syncProvider.notifier).syncAllData(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.l),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.medication_outlined,
                        size: 48,
                        color: EColors.accentGlow,
                      ),
                      VSpace.m,
                      Text('No schedules yet', style: EText.headline.small),
                      VSpace.s,
                      Text(
                        'A taper like prednisone, or times each day like gabapentin.',
                        style: EText.body.medium.tertiary,
                        textAlign: TextAlign.center,
                      ),
                      VSpace.l,
                      FilledButton(
                        onPressed: () => _showScheduleForm(context),
                        child: const Text('Set up a schedule'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _schedulesList(
    BuildContext context,
    WidgetRef ref,
    List<MedicationSchedule> schedules,
  ) {
    final active = schedules
        .where((schedule) => schedule.isListedAsActive)
        .toList();
    final ended = schedules.where((schedule) => schedule.hasEnded).toList();
    return RefreshIndicator(
      onRefresh: () => ref.read(syncProvider.notifier).syncAllData(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.m).withOverlaidTabBar(context),
        children: [
          ..._section(context, title: 'Active', schedules: active),
          if (active.isNotEmpty && ended.isNotEmpty) VSpace.l,
          ..._section(context, title: 'Ended', schedules: ended),
        ],
      ),
    );
  }

  List<Widget> _section(
    BuildContext context, {
    required String title,
    required List<MedicationSchedule> schedules,
  }) {
    if (schedules.isEmpty) return [];
    return [
      Text(title, style: EText.label.large.primary),
      VSpace.s,
      ...schedules.map(
        (schedule) => ScheduleCard(
          schedule: schedule,
          onActivated: () => context.push(
            MedicationScheduleDetailScreen(scheduleId: schedule.id),
          ),
        ),
      ),
    ];
  }

  void _showScheduleForm(BuildContext context) {
    context.push(const MedicationScheduleForm());
  }
}
