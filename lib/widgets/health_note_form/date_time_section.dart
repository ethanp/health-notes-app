import 'package:ethan_ui/ethan_ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:health_notes/theme/app_theme.dart';
import 'package:health_notes/theme/spacing.dart';
import 'package:intl/intl.dart';

class DateTimeSection extends StatelessWidget {
  final bool isEditable;
  final DateTime selectedDateTime;
  final Function(DateTime) onDateTimeChanged;

  const DateTimeSection({
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
    return ECard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Date & Time', style: EText.headline.small),
          VSpace.m,
          Container(
            height: 200,
            decoration: AppComponents.inputField,
            child: CupertinoDatePicker(
              mode: CupertinoDatePickerMode.dateAndTime,
              initialDateTime: selectedDateTime,
              backgroundColor: EColors.surface,
              onDateTimeChanged: onDateTimeChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _readOnlyLayout() {
    return ECard(
      child: Row(
        children: [
          Expanded(
            child: Text(
              DateFormat('EEEE, MMMM d, yyyy').format(selectedDateTime),
              style: EText.body.large.primary,
            ),
          ),
          HSpace.m,
          Text(
            DateFormat('h:mm a').format(selectedDateTime),
            style: EText.body.medium.tertiary,
          ),
        ],
      ),
    );
  }
}
