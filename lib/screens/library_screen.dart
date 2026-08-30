import 'package:ethan_ui/ethan_ui.dart';
import 'package:ethan_utils/ethan_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_notes/providers/sync_provider.dart';
import 'package:health_notes/screens/conditions_screen.dart';
import 'package:health_notes/screens/medication_schedules_screen.dart';
import 'package:health_notes/screens/my_tools_screen.dart';
import 'package:health_notes/theme/app_theme.dart';
import 'package:health_notes/theme/spacing.dart';
import 'package:health_notes/widgets/log_out_button.dart';
import 'package:health_notes/widgets/sync_status_widget.dart';

enum LibrarySlot({
  required final String label,
  required final IconData icon,
  required final String subtitle,
}) {
  conditions(
    label: 'Conditions',
    icon: Icons.healing_outlined,
    subtitle: 'Illnesses and flare-ups you track',
  ),
  schedules(
    label: 'Schedules',
    icon: Icons.calendar_month_outlined,
    subtitle: 'Tapers and times each day',
  ),
  tools(
    label: 'Tools',
    icon: Icons.handyman_outlined,
    subtitle: 'Practices you apply on a note',
  );

  Widget get screen => switch (this) {
    conditions => const ConditionsScreen(),
    schedules => const MedicationSchedulesScreen(),
    tools => const MyToolsScreen(),
  };
}

class const LibraryScreen() extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return EScaffoldShell(
      contentMaxWidth: double.infinity,
      appBar: const EAppHeader(
        title: 'Library',
        leading: LogOutButton(),
        actions: [CompactSyncStatusWidget()],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(syncProvider.notifier).syncAllData(),
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.m),
          itemCount: LibrarySlot.values.length,
          separatorBuilder: (_, _) => VSpace.s,
          itemBuilder: (context, slotIndex) {
            final slot = LibrarySlot.values[slotIndex];
            return _LibrarySlotRow(
              slot: slot,
              onActivated: () => context.push(slot.screen),
            );
          },
        ),
      ),
    );
  }
}

class const _LibrarySlotRow({
  required final LibrarySlot slot,
  required final VoidCallback onActivated,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onActivated,
      borderRadius: BorderRadius.circular(AppRadius.medium),
      child: ECard(
        child: Row(
          children: [
            _slotIcon(),
            HSpace.m,
            Expanded(child: _slotLabels()),
            const Icon(Icons.chevron_right, color: EColors.textTertiary),
          ],
        ),
      ),
    );
  }

  Widget _slotIcon() {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: EColors.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.small),
      ),
      child: Icon(slot.icon, size: 18, color: EColors.accent),
    );
  }

  Widget _slotLabels() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(slot.label, style: EText.label.large.primary),
        VSpace.xs,
        Text(slot.subtitle, style: EText.body.small.tertiary),
      ],
    );
  }
}
