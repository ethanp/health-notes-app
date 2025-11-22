import 'package:flutter/cupertino.dart';
import 'package:health_notes/theme/app_theme.dart';
import 'package:health_notes/widgets/spacing.dart';
import 'package:intl/intl.dart';

class DateTimeSection extends StatelessWidget {
  final bool isEditable;
  final DateTime selectedDateTime;
  final Function(DateTime) onDateTimeChanged;

  const DateTimeSection({
    super.key,
    required this.isEditable,
    required this.selectedDateTime,
    required this.onDateTimeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppComponents.primaryCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Date & Time', style: AppTypography.headlineSmall),
          VSpace.m,
          if (isEditable)
            Container(
              height: 200,
              decoration: AppComponents.inputField,
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.dateAndTime,
                initialDateTime: selectedDateTime,
                backgroundColor: AppColors.backgroundTertiary,
                onDateTimeChanged: onDateTimeChanged,
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('EEEE, MMMM d, yyyy').format(selectedDateTime),
                  style: AppTypography.headlineSmall,
                ),
                VSpace.xs,
                Text(
                  DateFormat('h:mm a').format(selectedDateTime),
                  style: AppTypography.bodyMediumTertiary,
                ),
              ],
            ),
        ],
      ),
    );
  }
}
