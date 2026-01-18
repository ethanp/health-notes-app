import 'package:ethan_utils/ethan_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_notes/models/condition.dart';
import 'package:health_notes/providers/conditions_provider.dart';
import 'package:health_notes/providers/sync_provider.dart';
import 'package:health_notes/screens/condition_detail_screen.dart';
import 'package:health_notes/screens/condition_form.dart';
import 'package:health_notes/widgets/log_out_button.dart';
import 'package:health_notes/widgets/condition_timeline_card.dart';
import 'package:health_notes/widgets/enhanced_ui_components.dart';
import 'package:health_notes/widgets/sync_status_widget.dart';

class ConditionsScreen extends ConsumerWidget {
  const ConditionsScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conditionsAsync = ref.watch(conditionsNotifierProvider);

    return CupertinoPageScaffold(
      navigationBar: EnhancedUIComponents.navigationBar(
        title: 'Conditions',
        leading: const LogOutButton(),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CompactSyncStatusWidget(),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => showAddConditionForm(context),
              child: const Icon(CupertinoIcons.add),
            ),
          ],
        ),
      ),
      child: SafeArea(
        child: conditionsAsync.when(
          data: (conditions) => conditions.isEmpty
              ? emptyState(context)
              : conditionsList(context, ref, conditions),
          loading: () =>
              const SyncStatusWidget.loading(message: 'Loading conditions...'),
          error: (error, stack) => SyncStatusWidget.error(
            errorMessage: 'Error: $error',
            onRetry: () => ref.invalidate(conditionsNotifierProvider),
          ),
        ),
      ),
    );
  }

  Widget emptyState(BuildContext context) {
    return EnhancedUIComponents.emptyState(
      title: 'No conditions yet',
      message: 'Track health conditions like colds, migraines, or flare-ups',
      icon: CupertinoIcons.bandage,
      action: EnhancedUIComponents.button(
        text: 'Add Condition',
        onPressed: () => showAddConditionForm(context),
        icon: CupertinoIcons.add,
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

    return CustomScrollView(
      slivers: [
        CupertinoSliverRefreshControl(
          onRefresh: () =>
              ref.read(syncNotifierProvider.notifier).syncAllData(),
        ),
        if (activeConditions.isNotEmpty) ...[
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            sliver: SliverToBoxAdapter(
              child: EnhancedUIComponents.sectionHeader(title: 'Active'),
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
              child: EnhancedUIComponents.sectionHeader(title: 'Resolved'),
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
        const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
      ],
    );
  }

  Widget conditionCard(
    BuildContext context,
    WidgetRef ref,
    Condition condition,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () => navigateToDetail(context, condition),
        child: ConditionTimelineCard(condition: condition),
      ),
    );
  }

  void navigateToDetail(BuildContext context, Condition condition) {
    context.push((_) => ConditionDetailScreen(conditionId: condition.id));
  }

  void showAddConditionForm(BuildContext context) {
    context.push((_) => const ConditionForm());
  }
}
