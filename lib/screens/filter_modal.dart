import 'package:ethan_ui/ethan_ui.dart';
import 'package:flutter/cupertino.dart';
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
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      color: _tempSelectedDate != null
          ? CupertinoColors.systemBlue
          : CupertinoColors.systemGrey6,
      borderRadius: BorderRadius.circular(AppRadius.small),
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
    return CupertinoButton(
      padding: const EdgeInsets.all(8),
      color: CupertinoColors.destructiveRed,
      borderRadius: BorderRadius.circular(AppRadius.small),
      onPressed: () => setState(() => _tempSelectedDate = null),
      child: const Icon(
        CupertinoIcons.xmark,
        color: CupertinoColors.white,
        size: 16,
      ),
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
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => setState(() => _isDatePickerVisible = false),
                child: const Icon(CupertinoIcons.xmark),
              ),
            ],
          ),
          VSpace.m,
          Container(
            height: 300,
            decoration: AppComponents.inputField,
            child: customDatePicker(),
          ),
        ],
      ),
    );
  }

  Widget customDatePicker() {
    final currentDate = _tempSelectedDate ?? DateTime.now();
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final days = List.generate(31, (index) => (index + 1).toString());
    final years = List.generate(
      11,
      (index) => (currentDate.year - 5 + index).toString(),
    );

    return Row(
      children: [
        Expanded(child: monthPicker(months, currentDate)),
        Expanded(child: dayPicker(days, currentDate)),
        Expanded(child: yearPicker(years, currentDate)),
      ],
    );
  }

  Widget monthPicker(List<String> months, DateTime currentDate) {
    return CupertinoPicker(
      itemExtent: 40,
      backgroundColor: CupertinoColors.systemGrey5,
      onSelectedItemChanged: (index) => setState(
        () => _tempSelectedDate = DateTime(
          currentDate.year,
          index + 1,
          currentDate.day,
        ),
      ),
      children: months
          .map((month) => Center(child: Text(month, style: EText.body.medium)))
          .toList(),
    );
  }

  Widget dayPicker(List<String> days, DateTime currentDate) {
    return CupertinoPicker(
      itemExtent: 40,
      backgroundColor: CupertinoColors.systemGrey5,
      onSelectedItemChanged: (index) => setState(
        () => _tempSelectedDate = DateTime(
          currentDate.year,
          currentDate.month,
          index + 1,
        ),
      ),
      children: days
          .map((day) => Center(child: Text(day, style: EText.body.medium)))
          .toList(),
    );
  }

  Widget yearPicker(List<String> years, DateTime currentDate) {
    return CupertinoPicker(
      itemExtent: 40,
      backgroundColor: CupertinoColors.systemGrey5,
      onSelectedItemChanged: (index) => setState(
        () => _tempSelectedDate = DateTime(
          int.parse(years[index]),
          currentDate.month,
          currentDate.day,
        ),
      ),
      children: years
          .map((year) => Center(child: Text(year, style: EText.body.medium)))
          .toList(),
    );
  }

  void applyFilters() {
    widget.onDateChanged(_tempSelectedDate);
    widget.onDrugChanged(_tempSelectedDrug);
    Navigator.of(context).pop();
  }
}
