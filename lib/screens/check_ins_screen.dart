import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_notes/models/check_in.dart';
import 'package:health_notes/providers/check_ins_provider.dart';
import 'package:health_notes/screens/check_in_form.dart';
import 'package:health_notes/theme/app_theme.dart';
import 'package:health_notes/utils/auth_utils.dart';
import 'package:health_notes/utils/check_in_utils.dart';
import 'package:health_notes/utils/check_in_grouping.dart';
import 'package:health_notes/utils/metric_colors.dart';
import 'package:health_notes/utils/metric_icons.dart';
import 'package:intl/intl.dart';

class CheckInsScreen extends ConsumerStatefulWidget {
  const CheckInsScreen();

  @override
  ConsumerState<CheckInsScreen> createState() => _CheckInsScreenState();
}

class _CheckInsScreenState extends ConsumerState<CheckInsScreen> {
  final Set<String> _expandedGroups = <String>{};

  void _toggleGroupExpansion(CheckInGroup group) {
    setState(() {
      final groupKey =
          '${group.primaryCheckIn.id}_${group.primaryCheckIn.dateTime.millisecondsSinceEpoch}';
      if (_expandedGroups.contains(groupKey)) {
        _expandedGroups.remove(groupKey);
      } else {
        _expandedGroups.add(groupKey);
      }
    });
  }

  bool _isGroupExpanded(CheckInGroup group) {
    final groupKey =
        '${group.primaryCheckIn.id}_${group.primaryCheckIn.dateTime.millisecondsSinceEpoch}';
    return _expandedGroups.contains(groupKey);
  }

  @override
  Widget build(BuildContext context) {
    final checkInsAsync = ref.watch(checkInsNotifierProvider);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('Check-ins', style: AppTheme.headlineSmall),
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
          loading: () => const Center(child: CupertinoActivityIndicator()),
          error: (error, stack) =>
              Center(child: Text('Error: $error', style: AppTheme.error)),
        ),
      ),
    );
  }

  Widget buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.chart_bar_alt_fill,
            size: 48,
            color: CupertinoColors.systemGrey,
          ),
          const SizedBox(height: 16),
          Text(
            'No check-ins yet',
            style: AppTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to add your first check-in',
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.textTertiary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          CupertinoButton.filled(
            onPressed: () => _showAddCheckInForm(),
            child: const Text('Add Check-in'),
          ),
        ],
      ),
    );
  }

  Widget buildCheckInsList(List<CheckIn> checkIns) {
    final groups = CheckInGrouping.groupCheckIns(checkIns);

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groups.length,
      itemBuilder: (context, index) {
        final group = groups[index];
        return buildCheckInGroupCard(group);
      },
    );
  }

  Widget buildCheckInGroupCard(CheckInGroup group) {
    final isExpanded = _isGroupExpanded(group);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: AppTheme.primaryCard,
      child: Column(
        children: [
          // Header with date/time and metric count - now tappable
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => _toggleGroupExpansion(group),
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Time indicator
                  Container(
                    width: 4,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat(
                            'MMM d, yyyy',
                          ).format(group.primaryCheckIn.dateTime),
                          style: AppTheme.labelLarge.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat(
                            'h:mm a',
                          ).format(group.primaryCheckIn.dateTime),
                          style: AppTheme.bodyMedium.copyWith(
                            color: AppTheme.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Metric count badge
                  if (group.isMultiMetric) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppTheme.primary.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            CupertinoIcons.chart_bar_alt_fill,
                            size: 12,
                            color: AppTheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${group.checkIns.length}',
                            style: AppTheme.bodySmall.copyWith(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Expand/collapse chevron
                  const SizedBox(width: 8),
                  Icon(
                    isExpanded
                        ? CupertinoIcons.chevron_up
                        : CupertinoIcons.chevron_down,
                    color: AppTheme.textTertiary,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),

          // Show collapsed view or expanded view
          if (isExpanded) ...[
            // Divider
            Container(
              height: 1,
              color: AppTheme.backgroundTertiary,
              margin: const EdgeInsets.symmetric(horizontal: 16),
            ),

            // Check-ins list
            ...group.checkIns.map((checkIn) => buildCheckInItem(checkIn)),
          ] else ...[
            // Collapsed view - show icons and ratings only
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: group.checkIns
                    .map((checkIn) => buildCollapsedCheckInItem(checkIn))
                    .toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget buildCollapsedCheckInItem(CheckIn checkIn) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () => _showEditCheckInForm(checkIn),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Metric icon with background
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: MetricColors.getColor(
                checkIn.metricName,
              ).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: MetricColors.getColor(
                  checkIn.metricName,
                ).withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Icon(
              MetricIcons.getIcon(checkIn.metricName),
              size: 14,
              color: MetricColors.getColor(checkIn.metricName),
            ),
          ),

          const SizedBox(width: 6),

          // Rating indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: CheckInUtils.getRatingColor(
                checkIn.rating,
                checkIn.metricName,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${checkIn.rating}',
              style: AppTheme.bodySmall.copyWith(
                color: CupertinoColors.white,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildCheckInItem(CheckIn checkIn) {
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
                  color: MetricColors.getColor(
                    checkIn.metricName,
                  ).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: MetricColors.getColor(
                      checkIn.metricName,
                    ).withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Icon(
                  MetricIcons.getIcon(checkIn.metricName),
                  size: 18,
                  color: MetricColors.getColor(checkIn.metricName),
                ),
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
                    Text(
                      'Rating: ${checkIn.rating}/10',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.textTertiary,
                      ),
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
                  color: CheckInUtils.getRatingColor(
                    checkIn.rating,
                    checkIn.metricName,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: CheckInUtils.getRatingColor(
                        checkIn.rating,
                        checkIn.metricName,
                      ).withValues(alpha: 0.3),
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
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Delete Check-in'),
            content: Text(
              'Are you sure you want to delete this check-in from ${DateFormat('M/d/yyyy').format(checkIn.dateTime)}?',
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
        ) ??
        false;
  }

  void deleteCheckIn(String checkInId) {
    ref.read(checkInsNotifierProvider.notifier).deleteCheckIn(checkInId);
  }

  void _showAddCheckInForm() {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) =>
            const CheckInForm(title: 'Add Check-in', saveButtonText: 'Save'),
      ),
    );
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
