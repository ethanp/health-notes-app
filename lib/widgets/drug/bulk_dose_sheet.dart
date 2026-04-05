import 'package:flutter/cupertino.dart';
import 'package:health_notes/theme/app_theme.dart';
import 'package:health_notes/theme/spacing.dart';
import 'package:health_notes/utils/date_utils.dart';

class BulkDoseSheet extends StatefulWidget {
  final String drugName;
  final String initialUnit;
  final List<DateTime> dates;
  final void Function(double dosage, String unit) onConfirm;

  const BulkDoseSheet({
    super.key,
    required this.drugName,
    required this.initialUnit,
    required this.dates,
    required this.onConfirm,
  });

  @override
  State<BulkDoseSheet> createState() => _BulkDoseSheetState();
}

class _BulkDoseSheetState extends State<BulkDoseSheet> {
  late final TextEditingController _dosageController;
  late final TextEditingController _unitController;
  double _dragOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _dosageController = TextEditingController();
    _unitController = TextEditingController(text: widget.initialUnit);
  }

  @override
  void dispose() {
    _dosageController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  double? get _parsedDosage => double.tryParse(_dosageController.text.trim());

  bool get _canSubmit =>
      _parsedDosage != null &&
      _parsedDosage! > 0 &&
      _unitController.text.trim().isNotEmpty;

  void _submit() {
    if (!_canSubmit) return;
    widget.onConfirm(_parsedDosage!, _unitController.text.trim());
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragUpdate: (dragDetails) {
        final offset = _dragOffset + dragDetails.delta.dy;
        if (offset >= 0) setState(() => _dragOffset = offset);
      },
      onVerticalDragEnd: (dragDetails) {
        final velocity = dragDetails.primaryVelocity ?? 0.0;
        if (_dragOffset > 120 || velocity > 800) {
          Navigator.of(context).pop();
        } else {
          setState(() => _dragOffset = 0.0);
        }
      },
      child: Transform.translate(
        offset: Offset(0, _dragOffset),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(AppRadius.extraLarge),
              topRight: Radius.circular(AppRadius.extraLarge),
            ),
            child: Container(
              color: AppColors.backgroundSecondary,
              child: SafeArea(
                top: false,
                child: Builder(
                  builder: (context) {
                    final screenHeight = MediaQuery.sizeOf(context).height;
                    final keyboardInset =
                        MediaQuery.viewInsetsOf(context).bottom;
                    return ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: screenHeight * 0.92,
                      ),
                      child: AnimatedPadding(
                        duration: const Duration(milliseconds: 120),
                        curve: Curves.easeOut,
                        padding: EdgeInsets.only(bottom: keyboardInset),
                        child: _sheetContent(),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sheetContent() {
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.m,
          AppSpacing.s,
          AppSpacing.m,
          AppSpacing.l,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _grabber(),
            VSpace.of(12),
            _header(),
            VSpace.s,
            _datesSummary(),
            VSpace.l,
            _dosageField(),
            VSpace.m,
            _unitField(),
            VSpace.l,
            _addButton(),
          ],
        ),
      ),
    );
  }

  Widget _grabber() {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.backgroundQuinary,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _header() {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Add ${widget.drugName}',
            style: AppTypography.headlineSmall,
          ),
        ),
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).pop(),
          child: const Icon(CupertinoIcons.xmark),
        ),
      ],
    );
  }

  Widget _datesSummary() {
    final count = widget.dates.length;
    final dayWord = count == 1 ? 'day' : 'days';
    final sortedDates = widget.dates.toList()..sort();
    final previewDates = sortedDates.take(3).toList();
    final preview = previewDates
        .map((date) => AppDateUtils.formatShortDate(date))
        .join(', ');
    final overflowSuffix = count > 3 ? ' +${count - 3} more' : '';
    return Text(
      '$count $dayWord: $preview$overflowSuffix',
      style: AppTypography.bodySmallSystemGrey,
    );
  }

  Widget _dosageField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Dosage amount', style: AppTypography.labelMedium),
        VSpace.s,
        CupertinoTextField(
          controller: _dosageController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          placeholder: 'e.g. 10',
          autofocus: true,
          style: AppTypography.bodyMedium,
          placeholderStyle: AppTypography.bodyMediumSystemGrey,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.backgroundTertiary,
            borderRadius: BorderRadius.circular(AppRadius.small),
            border: Border.all(color: AppColors.backgroundQuaternary),
          ),
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) => _submit(),
        ),
      ],
    );
  }

  Widget _unitField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Unit', style: AppTypography.labelMedium),
        VSpace.s,
        CupertinoTextField(
          controller: _unitController,
          placeholder: 'mg',
          style: AppTypography.bodyMedium,
          placeholderStyle: AppTypography.bodyMediumSystemGrey,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.backgroundTertiary,
            borderRadius: BorderRadius.circular(AppRadius.small),
            border: Border.all(color: AppColors.backgroundQuaternary),
          ),
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) => _submit(),
        ),
      ],
    );
  }

  Widget _addButton() {
    final count = widget.dates.length;
    final dayWord = count == 1 ? 'day' : 'days';
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: _canSubmit ? _submit : null,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: _canSubmit
            ? AppComponents.primaryButton
            : AppComponents.secondaryButton,
        child: Center(
          child: Text(
            _canSubmit
                ? 'Add to $count $dayWord'
                : 'Enter a dosage amount',
            style: _canSubmit
                ? AppTypography.buttonPrimary
                : AppTypography.bodyMediumSystemGrey,
          ),
        ),
      ),
    );
  }
}
