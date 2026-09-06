import 'package:ethan_ui/ethan_ui.dart';
import 'package:flutter/material.dart';
import 'package:health_notes/theme/spacing.dart';
import 'package:intl/intl.dart';

class const DateTimeSection({
  required final bool isEditable,
  required final DateTime selectedDateTime,
  required final Function(DateTime) onDateTimeChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (isEditable) return _editableLayout(context);
    return _readOnlyLayout();
  }

  Widget _editableLayout(BuildContext context) {
    return ECard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Date & Time', style: EText.headline.small),
          VSpace.m,
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.calendar_today),
            title: Text(
              DateFormat('EEEE, MMMM d, yyyy').format(selectedDateTime),
            ),
            subtitle: Text(DateFormat('h:mm a').format(selectedDateTime)),
            onTap: () => _pickDateTime(context),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDateTime(BuildContext context) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDateTime,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (pickedDate == null || !context.mounted) return;
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(selectedDateTime),
    );
    if (pickedTime == null) return;
    onDateTimeChanged(
      DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
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
