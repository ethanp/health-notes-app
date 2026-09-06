import 'package:ethan_ui/ethan_ui.dart';
import 'package:flutter/material.dart';
import 'package:health_notes/models/drug_name.dart';
import 'package:health_notes/theme/app_theme.dart';
import 'package:health_notes/widgets/app_filter_chip.dart';
import 'package:health_notes/widgets/health_notes_page.dart';
import 'package:health_notes/theme/spacing.dart';
import 'package:intl/intl.dart';

class const FilterModal({
  required final DateTime? selectedDate,
  required final DrugName? selectedDrug,
  required final List<DrugName> availableDrugs,
  required final Function(DateTime?) onDateChanged,
  required final Function(DrugName?) onDrugChanged,
}) extends StatefulWidget {
  @override
  State<FilterModal> createState() => _FilterModalState();
}

class _FilterModalState() extends State<FilterModal> {
  DateTime? _tempSelectedDate;
  DrugName? _tempSelectedDrug;
  bool _isDatePickerVisible = false;

  @override
  void initState() {
    super.initState();
    _tempSelectedDate = widget.selectedDate;
    _tempSelectedDrug = widget.selectedDrug;
  }

  @override
  Widget build(BuildContext context) {
    return HealthNotesPage(
      title: 'Filters',
      leading: IconButton(
        tooltip: 'Back',
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(Icons.arrow_back_rounded),
      ),
      actions: [
        TextButton(
          onPressed: applyFilters,
          child: Text('Apply', style: EText.body.medium.semibold.accent),
        ),
      ],
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.m),
        children: [
          VSpace.of(20),
          dateFilterSection(),
          VSpace.of(20),
          drugFilterSection(),
          if (_isDatePickerVisible) ...[VSpace.of(20), inlineDatePicker()],
          VSpace.of(40),
        ],
      ),
    );
  }

  Widget dateFilterSection() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: AppComponents.filterChip,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Filter by Date', style: EText.headline.small),
          VSpace.m,
          Row(
            children: [
              Expanded(child: dateSelectorButton()),
              if (_tempSelectedDate != null) ...[HSpace.s, clearDateButton()],
            ],
          ),
        ],
      ),
    );
  }

  Widget dateSelectorButton() {
    return FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: _tempSelectedDate != null
            ? EColors.accent
            : EColors.surface,
        foregroundColor: _tempSelectedDate != null
            ? Colors.white
            : EColors.textPrimary,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.small),
        ),
      ),
      onPressed: () =>
          setState(() => _isDatePickerVisible = !_isDatePickerVisible),
      child: Text(
        _tempSelectedDate != null
            ? DateFormat('M/d/yyyy').format(_tempSelectedDate!)
            : 'Select Date',
        style: _tempSelectedDate != null
            ? EText.body.medium.semibold.white
            : EText.body.medium,
      ),
    );
  }

  Widget clearDateButton() {
    return IconButton.filled(
      tooltip: 'Clear date',
      style: IconButton.styleFrom(backgroundColor: EColors.danger),
      onPressed: () => setState(() => _tempSelectedDate = null),
      icon: const Icon(Icons.close, color: Colors.white, size: 16),
    );
  }

  Widget drugFilterSection() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: AppComponents.filterChip,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Filter by Drug', style: EText.headline.small),
          VSpace.m,
          if (widget.availableDrugs.isEmpty)
            Text('No drugs recorded yet', style: EText.body.medium.tertiary)
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.availableDrugs
                  .map((drug) => drugChip(drug))
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget drugChip(DrugName drug) {
    return AppFilterChip(
      label: drug.display,
      isActive: _tempSelectedDrug == drug,
      onTap: () => setState(
        () => _tempSelectedDrug = _tempSelectedDrug == drug ? null : drug,
      ),
    );
  }

  Widget inlineDatePicker() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: AppComponents.inputField,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Select Date', style: EText.headline.small),
              IconButton(
                tooltip: 'Close date picker',
                onPressed: () => setState(() => _isDatePickerVisible = false),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          VSpace.m,
          CalendarDatePicker(
            initialDate: _tempSelectedDate ?? DateTime.now(),
            firstDate: DateTime(DateTime.now().year - 5),
            lastDate: DateTime(DateTime.now().year + 5),
            onDateChanged: (date) => setState(() => _tempSelectedDate = date),
          ),
        ],
      ),
    );
  }

  void applyFilters() {
    widget.onDateChanged(_tempSelectedDate);
    widget.onDrugChanged(_tempSelectedDrug);
    Navigator.of(context).pop();
  }
}
