import 'package:ethan_utils/ethan_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_notes/models/check_in_metric.dart';
import 'package:health_notes/providers/auth_provider.dart';
import 'package:health_notes/providers/check_in_metrics_provider.dart';
import 'package:health_notes/providers/sync_provider.dart';
import 'package:health_notes/screens/metric_edit_screen.dart';
import 'package:health_notes/services/offline_repository.dart';
import 'package:health_notes/theme/app_theme.dart';
import 'package:health_notes/widgets/enhanced_ui_components.dart';
import 'package:health_notes/theme/spacing.dart';
import 'package:health_notes/widgets/sync_status_widget.dart';

class MetricsManagementScreen extends ConsumerStatefulWidget {
  const MetricsManagementScreen({super.key});

  @override
  ConsumerState<MetricsManagementScreen> createState() =>
      _MetricsManagementScreenState();
}

class _MetricsManagementScreenState
    extends ConsumerState<MetricsManagementScreen> {
  @override
  Widget build(BuildContext context) {
    final metricsAsync = ref.watch(checkInMetricsNotifierProvider);

    return CupertinoPageScaffold(
      navigationBar: managementNavigationBar(),
      child: SafeArea(child: metricsBody(metricsAsync)),
    );
  }

  ObstructingPreferredSizeWidget managementNavigationBar() {
    return EnhancedUIComponents.navigationBar(
      title: 'Manage Metrics',
      leading: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Done'),
      ),
      trailing: managementActions(),
    );
  }

  Widget managementActions() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CompactSyncStatusWidget(),
        HSpace.s,
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () async {
            await ref.read(syncNotifierProvider.notifier).forceSyncAllData();
          },
          child: const Icon(CupertinoIcons.arrow_2_circlepath),
        ),
        HSpace.of(6),
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () async {
            final user = await ref.read(currentUserProvider.future);
            final userId = user?.id;
            if (userId != null) {
              await OfflineRepository.resyncAllCheckInMetrics(userId);
              await OfflineRepository.pushLocalOnly();
              await ref.read(syncNotifierProvider.notifier).forceSyncAllData();
            }
          },
          child: const Icon(CupertinoIcons.arrow_up_arrow_down_circle),
        ),
        HSpace.of(6),
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => _showAddMetricDialog(context),
          child: const Icon(CupertinoIcons.add),
        ),
      ],
    );
  }

  Widget metricsBody(AsyncValue<List<CheckInMetric>> metricsAsync) {
    return metricsAsync.when(
      data: (metrics) => metricsList(metrics),
      loading: () => const Center(child: CupertinoActivityIndicator()),
      error: (error, stack) => metricsError(error),
    );
  }

  Widget metricsError(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            CupertinoIcons.exclamationmark_triangle,
            size: 48,
            color: CupertinoColors.systemRed,
          ),
          VSpace.m,
          Text(
            'Failed to load metrics',
            style: AppTypography.navTitleTextStyle,
          ),
          VSpace.s,
          Text(
            error.toString(),
            style: AppTypography.baseTextStyle,
            textAlign: TextAlign.center,
          ),
          VSpace.m,
          CupertinoButton.filled(
            onPressed: () => ref.invalidate(checkInMetricsNotifierProvider),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget metricsList(List<CheckInMetric> metrics) {
    if (metrics.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              CupertinoIcons.chart_bar,
              size: 64,
              color: CupertinoColors.systemGrey,
            ),
            VSpace.m,
            Text('No metrics yet', style: AppTypography.navTitleTextStyle),
            VSpace.s,
            Text(
              'Add your first metric to start tracking your health',
              style: AppTypography.baseTextStyle,
              textAlign: TextAlign.center,
            ),
            VSpace.l,
            CupertinoButton.filled(
              onPressed: () => _showAddMetricDialog(context),
              child: const Text('Add Metric'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: metrics.length,
      itemBuilder: (context, index) => metricTile(metrics[index]),
    );
  }

  Widget metricTile(CheckInMetric metric) {
    // ignore: avoid_unnecessary_containers
    return Container(
      key: ValueKey(metric.id),
      margin: const EdgeInsets.only(bottom: 6),
      child: EnhancedUIComponents.card(
        child: CupertinoListTile(
          padding: const EdgeInsetsDirectional.fromSTEB(12, 10, 12, 10),
          leading: metricIcon(metric),
          title: metricTitle(metric),
          subtitle: metricSubtitle(metric),
          trailing: metricActions(metric),
        ),
      ),
    );
  }

  Widget metricIcon(CheckInMetric metric) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: metric.color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(metric.icon, color: metric.color, size: 16),
    );
  }

  Widget metricTitle(CheckInMetric metric) {
    return Text(
      metric.name,
      style: CupertinoTheme.of(
        context,
      ).textTheme.textStyle.copyWith(fontWeight: FontWeight.w600),
    );
  }

  Widget metricSubtitle(CheckInMetric metric) {
    return Text(
      metric.type.description,
      style: CupertinoTheme.of(
        context,
      ).textTheme.textStyle.copyWith(color: CupertinoColors.systemGrey),
    );
  }

  Widget metricActions(CheckInMetric metric) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => _showEditMetricDialog(context, metric),
          child: const Icon(
            CupertinoIcons.pencil,
            size: 18,
            color: CupertinoColors.systemBlue,
          ),
        ),
        HSpace.of(6),
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => _showDeleteMetricDialog(context, metric),
          child: const Icon(
            CupertinoIcons.delete,
            size: 18,
            color: CupertinoColors.systemRed,
          ),
        ),
      ],
    );
  }

  void _showAddMetricDialog(BuildContext context) {
    context.push((_) => const MetricEditScreen());
  }

  void _showEditMetricDialog(BuildContext context, CheckInMetric metric) {
    context.push((_) => MetricEditScreen(metric: metric));
  }

  void _showDeleteMetricDialog(BuildContext context, CheckInMetric metric) {
    showCupertinoDialog(
      context: context,
      builder: (context) => AppAlertDialogs.confirmDestructive(
        title: 'Delete Metric',
        content:
            'Are you sure you want to delete "${metric.name}"? This action cannot be undone.',
        confirmText: 'Delete',
        cancelText: 'Cancel',
        isDestructive: true,
      ),
    ).then((result) async {
      if (result == true) {
        await ref
            .read(checkInMetricsNotifierProvider.notifier)
            .deleteCheckInMetric(metric.id);
      }
    });
  }
}
