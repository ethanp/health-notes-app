import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_notes/models/check_in.dart';
import 'package:health_notes/models/metric.dart';
import 'package:health_notes/providers/check_ins_provider.dart';
import 'package:health_notes/screens/check_in_form.dart';
import 'package:health_notes/theme/app_theme.dart';
import 'package:health_notes/utils/auth_utils.dart';
import 'package:health_notes/utils/check_in_grouping.dart';
import 'package:health_notes/widgets/enhanced_ui_components.dart';
import 'package:health_notes/widgets/refreshable_list_view.dart';
import 'package:intl/intl.dart';

class CheckInsScreen extends ConsumerStatefulWidget {
  const CheckInsScreen();

  @override
  ConsumerState<CheckInsScreen> createState() => _CheckInsScreenState();
}

class _CheckInsScreenState extends ConsumerState<CheckInsScreen>
    with TickerProviderStateMixin {
  final Set<String> _expandedGroups = <String>{};
  final Map<String, AnimationController> _animationControllers = {};

  void _toggleGroupExpansion(CheckInGroup group) {
    setState(() {
      final groupKey =
          '${group.representativeCheckIn.id}_${group.representativeCheckIn.dateTime.millisecondsSinceEpoch}';

      if (!_animationControllers.containsKey(groupKey)) {
        _animationControllers[groupKey] = AnimationController(
          duration: const Duration(milliseconds: 400),
          vsync: this,
        );
      }

      final controller = _animationControllers[groupKey]!;

      if (_expandedGroups.contains(groupKey)) {
        controller.reverse();
        _expandedGroups.remove(groupKey);
      } else {
        controller.forward();
        _expandedGroups.add(groupKey);
      }
    });
  }

  bool _isGroupExpanded(CheckInGroup group) {
    final groupKey =
        '${group.representativeCheckIn.id}_${group.representativeCheckIn.dateTime.millisecondsSinceEpoch}';
    return _expandedGroups.contains(groupKey);
  }

  @override
  void dispose() {
    for (final controller in _animationControllers.values) {
      controller.dispose();
    }
    _animationControllers.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final checkInsAsync = ref.watch(checkInsNotifierProvider);

    return CupertinoPageScaffold(
      navigationBar: EnhancedUIComponents.enhancedNavigationBar(
        title: 'Check-ins',
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => AuthUtils.showSignOutDialog(context),
          child: const Icon(CupertinoIcons.person_circle),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => _showAddCheckInForm(),
          child: const Icon(CupertinoIcons.add),
        ),
      ),
      child: SafeArea(
        child: checkInsAsync.when(
          data: (checkIns) => checkIns.isEmpty
              ? buildEmptyState()
              : buildCheckInsList(checkIns),
          loading: () => EnhancedUIComponents.enhancedLoadingIndicator(
            message: 'Loading your check-ins...',
          ),
          error: (error, stack) =>
              Center(child: Text('Error: $error', style: AppTheme.error)),
        ),
      ),
    );
  }

  Widget buildEmptyState() {
    return EnhancedUIComponents.enhancedEmptyState(
      title: 'No check-ins yet',
      message: 'Tap the + button to add your first check-in',
      icon: CupertinoIcons.chart_bar_alt_fill,
      action: EnhancedUIComponents.enhancedButton(
        text: 'Add Check-in',
        onPressed: () => _showAddCheckInForm(),
        icon: CupertinoIcons.add,
      ),
    );
  }

  Widget buildCheckInsList(List<CheckIn> checkIns) {
    final groupedCheckIns = CheckInGrouping.groupCheckIns(checkIns);

    return RefreshableListView<CheckInGroup>(
      onRefresh: () async {
        ref.invalidate(checkInsNotifierProvider);
      },
      items: groupedCheckIns,
      itemBuilder: (group) {
        final isExpanded = _isGroupExpanded(group);

        return Dismissible(
          key: Key(
            'group_${group.representativeCheckIn.id}_${group.representativeCheckIn.dateTime.millisecondsSinceEpoch}',
          ),
          direction: DismissDirection.endToStart,
          background: Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppTheme.destructive,
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: AppTheme.spacingL),
            child: const Icon(
              CupertinoIcons.delete,
              color: CupertinoColors.white,
              size: 24,
            ),
          ),
          confirmDismiss: (direction) async {
            return await showDeleteGroupConfirmation(group);
          },
          onDismissed: (direction) {
            deleteCheckInGroup(group);
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: AppTheme.primaryCard,
            child: Column(
              children: [
                // Header with date and primary check-in
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _toggleGroupExpansion(group),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // Date
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                DateFormat(
                                  'EEEE, MMMM d',
                                ).format(group.representativeCheckIn.dateTime),
                                style: AppTheme.labelLarge.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat(
                                  'h:mm a',
                                ).format(group.representativeCheckIn.dateTime),
                                style: AppTheme.bodySmall.copyWith(
                                  color: AppTheme.textTertiary,
                                ),
                              ),
                            ],
                          ),
                        ),

                        buildGroupCountIndicator(group),

                        const SizedBox(width: 8),

                        // Expand/collapse indicator
                        AnimatedRotation(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOut,
                          turns: isExpanded ? 0.5 : 0.0,
                          child: const Icon(
                            CupertinoIcons.chevron_down,
                            color: CupertinoColors.systemGrey,
                            size: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Expanded check-ins
                Builder(
                  builder: (context) {
                    final groupKey =
                        '${group.representativeCheckIn.id}_${group.representativeCheckIn.dateTime.millisecondsSinceEpoch}';
                    final controller = _animationControllers[groupKey];

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
                                        (checkIn) => buildCheckInItem(checkIn),
                                      ),
                                    ],
                                  )
                                : const SizedBox.shrink(),
                          );
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget buildGroupCountIndicator(CheckInGroup group) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Group icon (showing multiple metrics if applicable)
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppTheme.primary.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Icon(
            group.isMultiMetric
                ? CupertinoIcons.list_bullet
                : group.representativeCheckIn.metricIcon,
            size: 14,
            color: group.isMultiMetric
                ? AppTheme.primary
                : group.representativeCheckIn.metricColor,
          ),
        ),

        const SizedBox(width: 6),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: group.proportionColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${group.checkIns.length}',
            style: AppTheme.bodySmall.copyWith(
              color: CupertinoColors.white,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
        ),
      ],
    );
  }

  Widget buildCheckInItem(CheckIn checkIn) {
    final metric = checkIn.metric;
    if (metric == null) return const SizedBox.shrink();

    return Dismissible(
      key: Key(checkIn.id),
      direction: DismissDirection.endToStart,
      background: Container(
        decoration: BoxDecoration(
          color: AppTheme.destructive,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppTheme.spacingL),
        child: const Icon(
          CupertinoIcons.delete,
          color: CupertinoColors.white,
          size: 24,
        ),
      ),
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
              // Metric icon with background
              Container(
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
              ),

              const SizedBox(width: 12),

              // Metric details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      checkIn.metricName,
                      style: AppTheme.labelLarge.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    EnhancedUIComponents.enhancedStatusIndicator(
                      text: '${checkIn.rating}/10',
                      color: checkIn.ratingColor,
                    ),
                  ],
                ),
              ),

              // Rating indicator with improved styling
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: checkIn.ratingColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: checkIn.ratingColor.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  '${checkIn.rating}',
                  style: AppTheme.bodySmall.copyWith(
                    color: CupertinoColors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Chevron
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
}
