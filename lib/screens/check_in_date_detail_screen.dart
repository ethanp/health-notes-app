import 'package:ethan_ui/ethan_ui.dart';
import 'package:ethan_utils/ethan_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:health_notes/models/check_in.dart';
import 'package:health_notes/screens/check_in_form.dart';
import 'package:health_notes/theme/app_theme.dart';
import 'package:health_notes/theme/spacing.dart';
import 'package:health_notes/widgets/health_notes_page.dart';
import 'package:health_notes/utils/date_utils.dart';

class CheckInDateDetailScreen extends StatefulWidget {
  final DateTime date;
  final List<CheckIn> allCheckIns;

  const CheckInDateDetailScreen({
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
          duration: AppAnimation.medium,
          curve: Curves.easeOut,
        );
      }
    });
  }

  List<CheckIn> get filteredCheckIns {
    final targetDate = widget.date.startOfDay;
    return widget.allCheckIns
        .where((checkIn) => checkIn.dateTime.sameDayAs(targetDate))
        .toList();
  }

  void showEditCheckInForm(CheckIn checkIn) {
    context.push(
      CheckInForm(
        checkIn: checkIn,
        title: 'Edit Check-in',
        saveButtonText: 'Update',
      ),
    );
  }

  Widget header() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: EColors.backgroundLift,
        border: Border(
          bottom: BorderSide(
            color: EColors.textSecondary.withValues(alpha: 0.2),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            AppDateUtils.formatLongDate(widget.date),
            style: EText.headline.small.primary,
          ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => Navigator.of(context).pop(),
            child: Icon(CupertinoIcons.xmark, color: EColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget checkInItem(CheckIn checkIn) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: EColors.backgroundLift,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(
          color: EColors.textSecondary.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: CupertinoButton(
        padding: const EdgeInsets.all(AppSpacing.m),
        onPressed: () => showEditCheckInForm(checkIn),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(checkIn.metricName, style: EText.label.large.primary),
                  VSpace.xs,
                  Text(
                    AppDateUtils.formatTime(checkIn.dateTime),
                    style: EText.body.small.secondary,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.s,
              ),
              decoration: BoxDecoration(
                color: EColors.accent,
                borderRadius: BorderRadius.circular(AppRadius.large),
              ),
              child: Text(
                '${checkIn.rating}',
                style: EText.body.medium.semibold.white.bold,
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
      padding: const EdgeInsets.all(AppSpacing.m),
      itemCount: checkInsForDate.length,
      itemBuilder: (context, index) {
        return checkInItem(checkInsForDate[index]);
      },
    );
  }

  Widget emptyState() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.l),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.calendar,
              size: 48,
              color: EColors.textSecondary,
            ),
            VSpace.m,
            Text(
              'No check-ins for this date',
              style: EText.body.medium.primary,
            ),
            VSpace.s,
            Text(
              'Check-ins will appear here when you add them',
              style: EText.body.small.secondary,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return HealthNotesPage(
      title: 'Check-ins',
      body: Column(
        children: [
          header(),
          Expanded(child: checkInsList()),
        ],
      ),
    );
  }
}
