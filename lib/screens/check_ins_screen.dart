import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_notes/models/check_in.dart';
import 'package:health_notes/models/check_in_metric.dart';
import 'package:health_notes/providers/check_in_metrics_provider.dart';
import 'package:health_notes/providers/check_ins_provider.dart';
import 'package:health_notes/screens/check_in_date_detail_screen.dart';
import 'package:health_notes/screens/check_in_form.dart';
import 'package:health_notes/screens/metrics_management_screen.dart';
import 'package:health_notes/theme/app_theme.dart';

import 'package:health_notes/widgets/log_out_button.dart';
import 'package:health_notes/utils/check_in_grouping.dart';
import 'package:health_notes/services/text_normalizer.dart';
import 'package:health_notes/widgets/activity_calendar.dart';
import 'package:health_notes/widgets/enhanced_ui_components.dart';
import 'package:health_notes/widgets/refreshable_list_view.dart';
import 'package:health_notes/widgets/spacing.dart';
import 'package:health_notes/widgets/sync_status_widget.dart';
import 'package:intl/intl.dart';

class CheckInsScreen extends ConsumerStatefulWidget {
  const CheckInsScreen();

  @override
  ConsumerState<CheckInsScreen> createState() => _CheckInsScreenState();
}

class _CheckInsScreenState extends ConsumerState<CheckInsScreen>
    with TickerProviderStateMixin {
  final Set<String> _expandedGroups = {};
  final Map<String, AnimationController> _animationControllers = {};

  void _toggleGroupExpansion(CheckInGroup group) {
    setState(() {
      if (!_animationControllers.containsKey(group.key)) {
        _animationControllers[group.key] = AnimationController(
          duration: const Duration(milliseconds: 400),
          vsync: this,
        );
      }

      final animation = _animationControllers[group.key]!;

      if (_expandedGroups.contains(group.key)) {
        animation.reverse();
        _expandedGroups.remove(group.key);
      } else {
        animation.forward();
        _expandedGroups.add(group.key);
      }
    });
  }

  bool _isGroupExpanded(CheckInGroup group) {
    return _expandedGroups.contains(group.key);
  }

  @override
  void dispose() {
    _animationControllers.values.forEach((c) => c.dispose());
    _animationControllers.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final checkInsAsync = ref.watch(checkInsNotifierProvider);
    final userMetricsAsync = ref.watch(checkInMetricsNotifierProvider);

    return CupertinoPageScaffold(
      navigationBar: EnhancedUIComponents.navigationBar(
        title: 'Check-ins',
        leading: const LogOutButton(),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CompactSyncStatusWidget(),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => Navigator.of(context).push(
                CupertinoPageRoute(
                  builder: (context) => const MetricsManagementScreen(),
                ),
              ),
              child: const Icon(CupertinoIcons.settings),
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => _showAddCheckInForm(),
              child: const Icon(CupertinoIcons.add),
            ),
          ],
        ),
      ),
      child: SafeArea(
        child: checkInsAsync.when(
          data: (checkIns) => userMetricsAsync.when(
            data: (userMetrics) => checkIns.isEmpty
                ? emptyState()
                : checkInsCalendar(checkIns, userMetrics),
            loading: () =>
                const SyncStatusWidget.loading(message: 'Loading metrics...'),
            error: (error, stack) => Center(
              child: Text(
                'Error loading metrics: $error',
                style: AppTypography.error,
              ),
            ),
          ),
          loading: () => const SyncStatusWidget.loading(
            message: 'Loading your check-ins...',
          ),
          error: (error, stack) =>
              Center(child: Text('Error: $error', style: AppTypography.error)),
        ),
      ),
    );
  }

  Widget emptyState() {
    return EnhancedUIComponents.emptyState(
      title: 'No check-ins yet',
      message: 'Tap the + button to add your first check-in',
      icon: CupertinoIcons.chart_bar_alt_fill,
      action: EnhancedUIComponents.button(
        text: 'Add Check-in',
        onPressed: () => _showAddCheckInForm(),
        icon: CupertinoIcons.add,
      ),
    );
  }

  Widget checkInsCalendar(
    List<CheckIn> checkIns,
    List<CheckInMetric> userMetrics,
  ) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: CheckInsActivityCalendar(
          checkIns: checkIns,
          onDateTap: (date) => _showCheckInsForDate(date, checkIns),
        ),
      ),
    );
  }

  Widget checkInsList(List<CheckIn> checkIns, List<CheckInMetric> userMetrics) {
    return Column(
      children: [
        Expanded(
          child: RefreshableListView<CheckInGroup>(
            onRefresh: () async {
              ref.invalidate(checkInsNotifierProvider);
            },
            items: CheckInGrouping.groupCheckIns(checkIns, userMetrics.length),
            itemBuilder: (group) => checkInGroupItem(group, userMetrics),
          ),
        ),
      ],
    );
  }

  Widget checkInGroupItem(CheckInGroup group, List<CheckInMetric> userMetrics) {
    final isExpanded = _isGroupExpanded(group);

    return Dismissible(
      key: Key('group_${group.key}'),
      direction: DismissDirection.endToStart,
      background: dismissBackground(),
      confirmDismiss: (direction) => showDeleteGroupConfirmation(group),
      onDismissed: (direction) => deleteCheckInGroup(group),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: AppComponents.primaryCard,
        child: Column(
          children: [
            groupHeader(group, userMetrics, isExpanded),
            expandedContent(group, userMetrics),
          ],
        ),
      ),
    );
  }

  Widget groupHeader(
    CheckInGroup group,
    List<CheckInMetric> userMetrics,
    bool isExpanded,
  ) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _toggleGroupExpansion(group),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(child: groupDateInfo(group)),
            groupCountIndicator(group, userMetrics),
            HSpace.s,
            expansionIcon(isExpanded),
          ],
        ),
      ),
    );
  }

  Widget groupDateInfo(CheckInGroup group) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          DateFormat(
            'EEEE, MMMM d',
          ).format(group.representativeCheckIn.dateTime),
          style: AppTypography.labelLargePrimary,
        ),
        VSpace.xs,
        Text(
          DateFormat('h:mm a').format(group.representativeCheckIn.dateTime),
          style: AppTypography.bodySmallTertiary,
        ),
      ],
    );
  }

  Widget expansionIcon(bool isExpanded) {
    return AnimatedRotation(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      turns: isExpanded ? 0.5 : 0.0,
      child: const Icon(
        CupertinoIcons.chevron_down,
        color: CupertinoColors.systemGrey,
        size: 16,
      ),
    );
  }

  Widget expandedContent(CheckInGroup group, List<CheckInMetric> userMetrics) {
    return Builder(
      builder: (context) {
        final controller = _animationControllers[group.key];

        if (controller == null) {
          return const SizedBox.shrink();
        }

        return ClipRect(
          child: AnimatedBuilder(
            animation: controller,
            builder: (context, child) {
              return Align(
                alignment: Alignment.topCenter,
                heightFactor: controller.value,
                child: controller.value > 0
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Divider(height: 1),
                          ...group.checkIns.map(
                            (checkIn) => checkInItem(checkIn, userMetrics),
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
              );
            },
          ),
        );
      },
    );
  }

  Container dismissBackground() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.destructive,
        borderRadius: BorderRadius.circular(AppRadius.medium),
      ),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: AppSpacing.l),
      child: const Icon(
        CupertinoIcons.delete,
        color: CupertinoColors.white,
        size: 24,
      ),
    );
  }

  Widget groupCountIndicator(
    CheckInGroup group,
    List<CheckInMetric> userMetrics,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        metricIcon(group, userMetrics),
        HSpace.of(6),
        countBadge(group),
      ],
    );
  }

  Widget metricIcon(CheckInGroup group, List<CheckInMetric> userMetrics) {
    final metric = _getMetricForGroup(group, userMetrics);

    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Icon(
        group.isMultiMetric ? CupertinoIcons.list_bullet : metric.icon,
        size: 14,
        color: group.isMultiMetric ? AppColors.primary : metric.color,
      ),
    );
  }

  Widget countBadge(CheckInGroup group) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: group.proportionColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '${group.checkIns.length}',
        style: AppTypography.buttonPrimaryBoldSmall,
      ),
    );
  }

  CheckInMetric _getMetricForGroup(
    CheckInGroup group,
    List<CheckInMetric> userMetrics,
  ) {
    try {
      return userMetrics.firstWhere(
        (m) => MetricNameNormalizer.areEqual(
          m.name,
          group.representativeCheckIn.metricName,
        ),
      );
    } catch (e) {
      return CheckInMetric.create(
        userId: '',
        name: '${group.representativeCheckIn.metricName} (Deleted)',
        type: MetricType.higherIsBetter,
      );
    }
  }

  Widget checkInItem(CheckIn checkIn, List<CheckInMetric> userMetrics) {
    CheckInMetric metric;
    try {
      metric = userMetrics.firstWhere(
        (m) => MetricNameNormalizer.areEqual(m.name, checkIn.metricName),
      );
    } catch (e) {
      metric = CheckInMetric.create(
        userId: '',
        name: '${checkIn.metricName} (Deleted)',
        type: MetricType.higherIsBetter,
      );
    }

    return Dismissible(
      key: Key(checkIn.id),
      direction: DismissDirection.endToStart,
      background: deleteBackground(),
      confirmDismiss: (direction) async {
        return await showDeleteConfirmation(checkIn);
      },
      onDismissed: (direction) {
        deleteCheckIn(checkIn.id);
      },
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () => _showEditCheckInForm(checkIn),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              metricIconContainer(metric),
              HSpace.of(12),
              Expanded(child: metricInfo(checkIn, metric)),
              ratingBadge(checkIn, metric),
              HSpace.s,
              const Icon(
                CupertinoIcons.chevron_right,
                color: CupertinoColors.systemGrey,
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget deleteBackground() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.destructive,
        borderRadius: BorderRadius.circular(AppRadius.medium),
      ),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: AppSpacing.l),
      child: const Icon(
        CupertinoIcons.delete,
        color: CupertinoColors.white,
        size: 24,
      ),
    );
  }

  Widget metricIconContainer(CheckInMetric metric) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: metric.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: metric.color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Icon(metric.icon, size: 18, color: metric.color),
    );
  }

  Widget metricInfo(CheckIn checkIn, CheckInMetric metric) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(checkIn.metricName, style: AppTypography.labelMedium),
        VSpace.of(2),
        EnhancedUIComponents.statusIndicator(
          text: '${checkIn.rating}/10',
          color: metric.getRatingColor(checkIn.rating),
        ),
      ],
    );
  }

  Widget ratingBadge(CheckIn checkIn, CheckInMetric metric) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: metric.getRatingColor(checkIn.rating),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: metric.getRatingColor(checkIn.rating).withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text('${checkIn.rating}', style: AppTypography.buttonPrimaryBold),
    );
  }

  Future<bool> showDeleteConfirmation(CheckIn checkIn) async {
    return await showCupertinoDialog<bool>(
          context: context,
          builder: (context) => AppAlertDialogs.confirmDestructive(
            title: 'Delete Check-in',
            content:
                'Are you sure you want to delete this check-in from ${DateFormat('M/d/yyyy').format(checkIn.dateTime)}?',
            confirmText: 'Delete',
          ),
        ) ??
        false;
  }

  void deleteCheckIn(String id) {
    ref.read(checkInsNotifierProvider.notifier).deleteCheckIn(id);
  }

  Future<bool> showDeleteGroupConfirmation(CheckInGroup group) async {
    return await showCupertinoDialog<bool>(
          context: context,
          builder: (context) {
            final groupDate = DateFormat(
              'M/d/yyyy',
            ).format(group.representativeCheckIn.dateTime);
            return AppAlertDialogs.confirmDestructive(
              title: 'Delete Check-in Group',
              content:
                  'Are you sure you want to delete all check-ins for $groupDate?',
              confirmText: 'Delete',
            );
          },
        ) ??
        false;
  }

  void deleteCheckInGroup(CheckInGroup group) {
    final checkInIds = group.checkIns.map((checkIn) => checkIn.id).toList();
    ref.read(checkInsNotifierProvider.notifier).deleteCheckInGroup(checkInIds);
  }

  void _showAddCheckInForm() {
    Navigator.of(
      context,
    ).push(CupertinoPageRoute(builder: (context) => const CheckInForm()));
  }

  void _showEditCheckInForm(CheckIn checkIn) {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => CheckInForm(
          checkIn: checkIn,
          title: 'Edit Check-in',
          saveButtonText: 'Update',
        ),
      ),
    );
  }

  void _showCheckInsForDate(DateTime date, List<CheckIn> allCheckIns) {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) =>
            CheckInDateDetailScreen(date: date, allCheckIns: allCheckIns),
      ),
    );
  }
}
