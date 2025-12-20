import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_notes/models/condition.dart';
import 'package:health_notes/models/condition_entry.dart';
import 'package:health_notes/providers/conditions_provider.dart';
import 'package:health_notes/screens/condition_form.dart';
import 'package:health_notes/theme/app_theme.dart';
import 'package:health_notes/widgets/condition_activity_calendar.dart';
import 'package:health_notes/widgets/condition_entry_edit_modal.dart';
import 'package:health_notes/widgets/enhanced_ui_components.dart';
import 'package:health_notes/widgets/spacing.dart';
import 'package:health_notes/widgets/sync_status_widget.dart';
import 'package:intl/intl.dart';

class ConditionDetailScreen extends ConsumerWidget {
  final String conditionId;

  const ConditionDetailScreen({required this.conditionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conditionsAsync = ref.watch(conditionsNotifierProvider);
    final entriesAsync = ref.watch(conditionEntriesNotifierProvider(conditionId));

    return conditionsAsync.when(
      data: (conditions) {
        final condition = conditions.where((c) => c.id == conditionId).firstOrNull;
        if (condition == null) {
          return CupertinoPageScaffold(
            navigationBar: EnhancedUIComponents.navigationBar(title: 'Condition'),
            child: const Center(child: Text('Condition not found')),
          );
        }

        return entriesAsync.when(
          data: (entries) => conditionDetailContent(context, ref, condition, entries),
          loading: () => CupertinoPageScaffold(
            navigationBar: EnhancedUIComponents.navigationBar(title: condition.name),
            child: const SyncStatusWidget.loading(message: 'Loading entries...'),
          ),
          error: (error, stack) => CupertinoPageScaffold(
            navigationBar: EnhancedUIComponents.navigationBar(title: condition.name),
            child: SyncStatusWidget.error(
              errorMessage: 'Error: $error',
              onRetry: () => ref.invalidate(conditionEntriesNotifierProvider(conditionId)),
            ),
          ),
        );
      },
      loading: () => CupertinoPageScaffold(
        navigationBar: EnhancedUIComponents.navigationBar(title: 'Loading...'),
        child: const SyncStatusWidget.loading(message: 'Loading condition...'),
      ),
      error: (error, stack) => CupertinoPageScaffold(
        navigationBar: EnhancedUIComponents.navigationBar(title: 'Error'),
        child: Center(child: Text('Error: $error', style: AppTypography.error)),
      ),
    );
  }

  Widget conditionDetailContent(
    BuildContext context,
    WidgetRef ref,
    Condition condition,
    List<ConditionEntry> entries,
  ) {
    return CupertinoPageScaffold(
      navigationBar: EnhancedUIComponents.navigationBar(
        title: condition.name,
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => showActionsMenu(context, ref, condition),
          child: const Icon(CupertinoIcons.ellipsis_vertical),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              conditionHeader(condition),
              VSpace.l,
              if (condition.notes.isNotEmpty) ...[
                notesSection(condition),
                VSpace.l,
              ],
              statisticsSection(condition, entries),
              VSpace.l,
              ConditionActivityCalendar(
                condition: condition,
                entries: entries,
                onEntryTap: (entry) => showEntryEditModal(context, ref, entry),
              ),
              VSpace.l,
              EnhancedUIComponents.sectionHeader(title: 'Daily Entries'),
              VSpace.s,
              entriesList(context, ref, entries),
            ],
          ),
        ),
      ),
    );
  }

  Widget conditionHeader(Condition condition) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppComponents.primaryCard,
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: condition.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: condition.color.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Icon(condition.icon, size: 28, color: condition.color),
          ),
          HSpace.m,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(condition.name, style: AppTypography.headlineSmall),
                VSpace.xs,
                Text(
                  formatDateRange(condition),
                  style: AppTypography.bodySmallTertiary,
                ),
              ],
            ),
          ),
          statusBadge(condition),
        ],
      ),
    );
  }

  Widget statusBadge(Condition condition) {
    final color = condition.isActive
        ? CupertinoColors.systemOrange
        : CupertinoColors.systemGreen;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Text(
        condition.status.displayName,
        style: AppTypography.labelMedium.copyWith(color: color),
      ),
    );
  }

  Widget notesSection(Condition condition) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppComponents.primaryCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Notes', style: AppTypography.labelMedium),
          VSpace.s,
          Text(condition.notes, style: AppTypography.bodyMediumSecondary),
        ],
      ),
    );
  }

  Widget statisticsSection(Condition condition, List<ConditionEntry> entries) {
    final avgSeverity = entries.isEmpty
        ? 0.0
        : entries.map((e) => e.severity).reduce((a, b) => a + b) / entries.length;
    
    final peakSeverity = entries.isEmpty
        ? 0
        : entries.map((e) => e.severity).reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppComponents.primaryCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Statistics', style: AppTypography.labelLargePrimary),
          VSpace.m,
          Row(
            children: [
              Expanded(child: statCard('Duration', '${condition.durationDays}', 'days')),
              HSpace.m,
              Expanded(child: statCard('Entries', '${entries.length}', 'logged')),
            ],
          ),
          VSpace.m,
          Row(
            children: [
              Expanded(child: statCard('Avg Severity', avgSeverity.toStringAsFixed(1), '/10')),
              HSpace.m,
              Expanded(child: statCard('Peak', '$peakSeverity', '/10')),
            ],
          ),
        ],
      ),
    );
  }

  Widget statCard(String label, String value, String unit) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundTertiary,
        borderRadius: BorderRadius.circular(AppRadius.small),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.caption),
          VSpace.xs,
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: AppTypography.headlineMedium),
              HSpace.xs,
              Text(unit, style: AppTypography.caption),
            ],
          ),
        ],
      ),
    );
  }

  Widget entriesList(BuildContext context, WidgetRef ref, List<ConditionEntry> entries) {
    if (entries.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: AppComponents.primaryCard,
        child: Center(
          child: Text(
            'No entries yet. Add entries via check-ins.',
            style: AppTypography.bodyMediumSystemGrey,
          ),
        ),
      );
    }

    final sortedEntries = [...entries]..sort((a, b) => b.entryDate.compareTo(a.entryDate));

    return Column(
      children: sortedEntries.map((entry) => entryCard(context, ref, entry)).toList(),
    );
  }

  Widget entryCard(BuildContext context, WidgetRef ref, ConditionEntry entry) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () => showEntryEditModal(context, ref, entry),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: AppComponents.primaryCard,
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('EEE, MMM d').format(entry.entryDate),
                    style: AppTypography.labelMedium,
                  ),
                  VSpace.xs,
                  Row(
                    children: [
                      phaseBadge(entry.phase),
                      if (entry.notes.isNotEmpty) ...[
                        HSpace.s,
                        Icon(
                          CupertinoIcons.text_bubble,
                          size: 14,
                          color: AppColors.textQuaternary,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              const Spacer(),
              severityIndicator(entry.severity),
              HSpace.s,
              Icon(
                CupertinoIcons.chevron_right,
                size: 14,
                color: AppColors.textQuaternary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget phaseBadge(ConditionPhase phase) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: phase.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: phase.color.withValues(alpha: 0.3), width: 1),
      ),
      child: Text(
        phase.displayName,
        style: AppTypography.caption.copyWith(color: phase.color),
      ),
    );
  }

  Widget severityIndicator(int severity) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: severityColor(severity),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$severity',
        style: AppTypography.labelMediumWhite,
      ),
    );
  }

  Color severityColor(int severity) {
    if (severity <= 3) return CupertinoColors.systemGreen;
    if (severity <= 5) return CupertinoColors.systemYellow;
    if (severity <= 7) return CupertinoColors.systemOrange;
    return CupertinoColors.systemRed;
  }

  String formatDateRange(Condition condition) {
    final startStr = DateFormat('MMM d, y').format(condition.startDate);
    if (condition.endDate != null) {
      final endStr = DateFormat('MMM d, y').format(condition.endDate!);
      return '$startStr - $endStr';
    }
    return 'Started $startStr';
  }

  void showActionsMenu(BuildContext context, WidgetRef ref, Condition condition) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                CupertinoPageRoute(
                  builder: (context) => ConditionForm(
                    condition: condition,
                    title: 'Edit Condition',
                    saveButtonText: 'Save',
                  ),
                ),
              );
            },
            child: const Text('Edit Condition'),
          ),
          if (condition.isActive)
            CupertinoActionSheetAction(
              onPressed: () async {
                Navigator.of(context).pop();
                await ref
                    .read(conditionsNotifierProvider.notifier)
                    .resolveCondition(conditionId);
              },
              child: const Text('Mark as Resolved'),
            ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.of(context).pop();
              final confirmed = await showCupertinoDialog<bool>(
                context: context,
                builder: (context) => CupertinoAlertDialog(
                  title: const Text('Delete Condition'),
                  content: const Text(
                    'Are you sure you want to delete this condition and all its entries? This cannot be undone.',
                  ),
                  actions: [
                    CupertinoDialogAction(
                      child: const Text('Cancel'),
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                    CupertinoDialogAction(
                      isDestructiveAction: true,
                      child: const Text('Delete'),
                      onPressed: () => Navigator.of(context).pop(true),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                await ref.read(conditionsNotifierProvider.notifier).deleteCondition(conditionId);
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              }
            },
            child: const Text('Delete Condition'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  void showEntryEditModal(BuildContext context, WidgetRef ref, ConditionEntry entry) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => ConditionEntryEditModal(
        entry: entry,
        onSave: (updatedEntry) async {
          await ref
              .read(conditionEntriesNotifierProvider(conditionId).notifier)
              .updateEntry(updatedEntry);
          if (context.mounted) {
            Navigator.of(context).pop();
          }
        },
      ),
    );
  }
}

