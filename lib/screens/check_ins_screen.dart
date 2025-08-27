import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_notes/models/check_in.dart';
import 'package:health_notes/providers/check_ins_provider.dart';
import 'package:health_notes/screens/check_in_form.dart';
import 'package:health_notes/theme/app_theme.dart';
import 'package:health_notes/utils/auth_utils.dart';
import 'package:health_notes/utils/check_in_utils.dart';
import 'package:intl/intl.dart';

class CheckInsScreen extends ConsumerStatefulWidget {
  const CheckInsScreen();

  @override
  ConsumerState<CheckInsScreen> createState() => _CheckInsScreenState();
}

class _CheckInsScreenState extends ConsumerState<CheckInsScreen> {
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
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: checkIns.length,
      itemBuilder: (context, index) {
        final checkIn = checkIns[index];
        return buildCheckInCard(checkIn);
      },
    );
  }

  Widget buildCheckInCard(CheckIn checkIn) {
    return Dismissible(
      key: Key(checkIn.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppTheme.destructive,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppTheme.spacingL),
        child: const Icon(
          CupertinoIcons.delete,
          color: CupertinoColors.white,
          size: 30,
        ),
      ),
      confirmDismiss: (direction) async {
        return await showDeleteConfirmation(checkIn);
      },
      onDismissed: (direction) {
        deleteCheckIn(checkIn.id);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: AppTheme.primaryCard,
        child: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => _showEditCheckInForm(checkIn),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              checkIn.metricName,
                              style: AppTheme.labelLarge,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: CheckInUtils.getRatingColor(
                                checkIn.rating,
                                checkIn.metricName,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${checkIn.rating}/10',
                              style: AppTheme.bodySmall.copyWith(
                                color: CupertinoColors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat(
                          'MMM d, yyyy • h:mm a',
                        ).format(checkIn.dateTime),
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  CupertinoIcons.chevron_right,
                  color: CupertinoColors.systemGrey,
                  size: 16,
                ),
              ],
            ),
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
