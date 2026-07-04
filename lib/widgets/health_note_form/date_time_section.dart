import 'package:flutter/cupertino.dart';
import 'package:health_notes/theme/app_theme.dart';
import 'package:health_notes/theme/spacing.dart';
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
    if (isEditable) return _editableLayout();
    return _readOnlyLayout();
  }

  Widget _editableLayout() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppComponents.primaryCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Date & Time', style: AppTypography.headlineSmall),
          VSpace.m,
          Container(
            height: 200,
            decoration: AppComponents.inputField,
            child: CupertinoDatePicker(
              mode: CupertinoDatePickerMode.dateAndTime,
              initialDateTime: selectedDateTime,
              backgroundColor: AppColors.backgroundTertiary,
              onDateTimeChanged: onDateTimeChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _readOnlyLayout() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: AppComponents.primaryCard,
      child: Row(
        children: [
          Expanded(
            child: Text(
              DateFormat('EEEE, MMMM d, yyyy').format(selectedDateTime),
              style: AppTypography.bodyLargePrimary,
            ),
          ),
          HSpace.m,
          Text(
            DateFormat('h:mm a').format(selectedDateTime),
            style: AppTypography.bodyMediumTertiary,
          ),
        ],
      ),
    );
  }
}
