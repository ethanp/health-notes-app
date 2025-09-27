import 'package:flutter/cupertino.dart';
import 'package:health_notes/theme/app_theme.dart';

import 'package:health_notes/widgets/enhanced_ui_components.dart';
import 'package:intl/intl.dart';

class FilterModal extends StatefulWidget {
  final DateTime? selectedDate;
  final String? selectedDrug;
  final List<String> availableDrugs;
  final Function(DateTime?) onDateChanged;
  final Function(String?) onDrugChanged;

  const FilterModal({
    required this.selectedDate,
    required this.selectedDrug,
    required this.availableDrugs,
    required this.onDateChanged,
    required this.onDrugChanged,
  });

  @override
  State<FilterModal> createState() => _FilterModalState();
}

class _FilterModalState extends State<FilterModal> {
  DateTime? _tempSelectedDate;
  String? _tempSelectedDrug;
  bool _isDatePickerVisible = false;

  @override
  void initState() {
    super.initState();
    _tempSelectedDate = widget.selectedDate;
    _tempSelectedDrug = widget.selectedDrug;
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: EnhancedUIComponents.navigationBar(
        title: 'Filters',
        leading: CupertinoNavigationBarBackButton(
          onPressed: () => Navigator.of(context).pop(),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: applyFilters,
          child: Text('Apply', style: AppTypography.buttonSecondary),
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SizedBox(height: 20),
            dateFilterSection(),
            const SizedBox(height: 20),
            drugFilterSection(),
            if (_isDatePickerVisible) ...[
              const SizedBox(height: 20),
              datePickerOverlay(),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget dateFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppComponents.filterChip,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Filter by Date', style: AppTypography.headlineSmall),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: dateSelectorButton()),
              if (_tempSelectedDate != null) ...[
                const SizedBox(width: 8),
                clearDateButton(),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget dateSelectorButton() {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(vertical: 12),
      color: _tempSelectedDate != null
          ? CupertinoColors.systemBlue
          : CupertinoColors.systemGrey6,
      borderRadius: BorderRadius.circular(8),
      onPressed: () =>
          setState(() => _isDatePickerVisible = !_isDatePickerVisible),
      child: Text(
        _tempSelectedDate != null
            ? DateFormat('M/d/yyyy').format(_tempSelectedDate!)
            : 'Select Date',
        style: _tempSelectedDate != null
            ? AppTypography.buttonPrimary
            : AppTypography.bodyMedium,
      ),
    );
  }

  Widget clearDateButton() {
    return CupertinoButton(
      padding: const EdgeInsets.all(8),
      color: CupertinoColors.destructiveRed,
      borderRadius: BorderRadius.circular(8),
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
      padding: const EdgeInsets.all(16),
      decoration: AppComponents.filterChip,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Filter by Drug', style: AppTypography.headlineSmall),
          const SizedBox(height: 16),
          if (widget.availableDrugs.isEmpty)
            Text(
              'No drugs recorded yet',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textTertiary),
            )
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

  Widget drugChip(String drug) {
    return EnhancedUIComponents.filterChip(
      label: drug,
      isActive: _tempSelectedDrug == drug,
      onTap: () => setState(
        () => _tempSelectedDrug = _tempSelectedDrug == drug ? null : drug,
      ),
    );
  }

  Widget datePickerOverlay() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppComponents.inputField,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Select Date', style: AppTypography.headlineSmall),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => setState(() => _isDatePickerVisible = false),
                child: const Icon(CupertinoIcons.xmark),
              ),
            ],
          ),
          const SizedBox(height: 16),
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
          .map(
            (month) => Center(child: Text(month, style: AppTypography.bodyMedium)),
          )
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
          .map((day) => Center(child: Text(day, style: AppTypography.bodyMedium)))
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
          .map((year) => Center(child: Text(year, style: AppTypography.bodyMedium)))
          .toList(),
    );
  }

  void applyFilters() {
    widget.onDateChanged(_tempSelectedDate);
    widget.onDrugChanged(_tempSelectedDrug);
    Navigator.of(context).pop();
  }
}
