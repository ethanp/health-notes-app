import 'package:ethan_ui/ethan_ui.dart';
import 'package:ethan_utils/ethan_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_notes/models/condition.dart';
import 'package:health_notes/providers/conditions_provider.dart';
import 'package:health_notes/providers/sync_provider.dart';
import 'package:health_notes/screens/condition_detail_screen.dart';
import 'package:health_notes/screens/condition_form.dart';
import 'package:health_notes/theme/app_theme.dart';
import 'package:health_notes/widgets/condition_timeline_card.dart';
import 'package:health_notes/widgets/health_notes_page.dart';
import 'package:health_notes/widgets/sync_status_widget.dart';

class const ConditionsScreen() extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conditionsAsync = ref.watch(conditionsProvider);

    return HealthNotesPage(
      title: 'Conditions',
      actions: [
        const CompactSyncStatusWidget(),
        IconButton(
          tooltip: 'Add condition',
          onPressed: () => showAddConditionForm(context),
          icon: const Icon(Icons.add),
        ),
      ],
      body: conditionsAsync.when(
        data: (conditions) => conditions.isEmpty
            ? emptyState(context)
            : conditionsList(context, ref, conditions),
        loading: () =>
            const SyncStatusWidget.loading(message: 'Loading conditions...'),
        error: (error, stack) => SyncStatusWidget.error(
          errorMessage: 'Error: $error',
          onRetry: () => ref.invalidate(conditionsProvider),
        ),
      ),
    );
  }

  Widget emptyState(BuildContext context) {
    return EEmptyState(
      title: 'No conditions yet',
      message: 'Track health conditions like colds, migraines, or flare-ups',
      icon: Icons.healing_outlined,
      action: FilledButton.icon(
        onPressed: () => showAddConditionForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Condition'),
      ),
    );
  }

  Widget conditionsList(
    BuildContext context,
    WidgetRef ref,
    List<Condition> conditions,
  ) {
    final activeConditions = conditions.where((c) => c.isActive).toList();
    final resolvedConditions = conditions.where((c) => c.isResolved).toList();

    return RefreshIndicator(
      onRefresh: () => ref.read(syncProvider.notifier).syncAllData(),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          if (activeConditions.isNotEmpty) ...[
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            sliver: SliverToBoxAdapter(
              child: const ESectionHeader(title: 'Active'),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) =>
                    conditionCard(context, ref, activeConditions[index]),
                childCount: activeConditions.length,
              ),
            ),
          ),
        ],
        if (resolvedConditions.isNotEmpty) ...[
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            sliver: SliverToBoxAdapter(
              child: const ESectionHeader(title: 'Resolved'),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) =>
                    conditionCard(context, ref, resolvedConditions[index]),
                childCount: resolvedConditions.length,
              ),
            ),
          ),
        ],
          SliverToBoxAdapter(
            child: SizedBox(
              height: 32 + context.overlaidTabBarInset,
            ),
          ),
        ],
      ),
    );
  }

  Widget conditionCard(
    BuildContext context,
    WidgetRef ref,
    Condition condition,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        onTap: () => navigateToDetail(context, condition),
        child: ConditionTimelineCard(condition: condition),
      ),
    );
  }

  void navigateToDetail(BuildContext context, Condition condition) {
    context.push(ConditionDetailScreen(conditionId: condition.id));
  }

  void showAddConditionForm(BuildContext context) {
    context.push(const ConditionForm());
  }
}
