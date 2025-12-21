import 'package:flutter/cupertino.dart';
import 'package:health_notes/models/check_in.dart';
import 'package:health_notes/screens/check_in_form.dart';
import 'package:health_notes/theme/app_theme.dart';
import 'package:health_notes/theme/spacing.dart';
import 'package:health_notes/utils/date_utils.dart';

class CheckInDateDetailScreen extends StatefulWidget {
  final DateTime date;
  final List<CheckIn> allCheckIns;

  const CheckInDateDetailScreen({
    super.key,
    required this.date,
    required this.allCheckIns,
  });

  @override
  State<CheckInDateDetailScreen> createState() =>
      _CheckInDateDetailScreenState();
}

class _CheckInDateDetailScreenState extends State<CheckInDateDetailScreen> {
  late final ScrollController scrollController;
  late final List<CheckIn> checkInsForDate;

  @override
  void initState() {
    super.initState();
    scrollController = ScrollController();
    checkInsForDate = filteredCheckIns;
    scrollToCheckIns();
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  void scrollToCheckIns() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients && checkInsForDate.isNotEmpty) {
        scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  List<CheckIn> get filteredCheckIns {
    final targetDate = AppDateUtils.dateOnly(widget.date);
    return widget.allCheckIns
        .where(
          (checkIn) => AppDateUtils.isSameDay(checkIn.dateTime, targetDate),
        )
        .toList();
  }

  void showEditCheckInForm(CheckIn checkIn) {
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

  Widget header() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        border: Border(
          bottom: BorderSide(
            color: AppColors.textSecondary.withValues(alpha: 0.2),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            AppDateUtils.formatLongDate(widget.date),
            style: AppTypography.headlineSmallPrimary,
          ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => Navigator.of(context).pop(),
            child: Icon(CupertinoIcons.xmark, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget checkInItem(CheckIn checkIn) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(
          color: AppColors.textSecondary.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: CupertinoButton(
        padding: const EdgeInsets.all(16),
        onPressed: () => showEditCheckInForm(checkIn),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    checkIn.metricName,
                    style: AppTypography.labelLargePrimary,
                  ),
                  VSpace.xs,
                  Text(
                    AppDateUtils.formatTime(checkIn.dateTime),
                    style: AppTypography.bodySmallSecondary,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '${checkIn.rating}',
                style: AppTypography.buttonPrimaryBold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget checkInsList() {
    if (checkInsForDate.isEmpty) {
      return emptyState();
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: checkInsForDate.length,
      itemBuilder: (context, index) {
        return checkInItem(checkInsForDate[index]);
      },
    );
  }

  Widget emptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.calendar,
              size: 48,
              color: AppColors.textSecondary,
            ),
            VSpace.m,
            Text(
              'No check-ins for this date',
              style: AppTypography.bodyMediumPrimary,
            ),
            VSpace.s,
            Text(
              'Check-ins will appear here when you add them',
              style: AppTypography.bodySmallSecondary,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: headerNavigationBar(),
      child: SafeArea(
        child: Column(
          children: [
            header(),
            Expanded(child: checkInsList()),
          ],
        ),
      ),
    );
  }

  ObstructingPreferredSizeWidget headerNavigationBar() {
    return CupertinoNavigationBar(
      middle: Text('Check-ins', style: AppTypography.bodyLargePrimary),
      backgroundColor: AppColors.backgroundSecondary,
      border: Border.all(color: AppColors.textSecondary.withValues(alpha: 0.2)),
      leading: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () => Navigator.of(context).pop(),
        child: Icon(CupertinoIcons.back, color: AppColors.textSecondary),
      ),
    );
  }
}
