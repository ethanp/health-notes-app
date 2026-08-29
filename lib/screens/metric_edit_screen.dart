import 'package:ethan_ui/ethan_ui.dart';
import 'package:ethan_utils/ethan_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_notes/models/check_in_metric.dart';
import 'package:health_notes/providers/check_in_metrics_provider.dart';
import 'package:health_notes/theme/app_theme.dart';
import 'package:health_notes/widgets/color_picker_grid.dart';
import 'package:health_notes/widgets/app_dialogs.dart';
import 'package:health_notes/widgets/health_notes_page.dart';
import 'package:health_notes/theme/spacing.dart';

class MetricEditScreen extends ConsumerStatefulWidget {
  final CheckInMetric? metric;

  const MetricEditScreen({this.metric});

  @override
  ConsumerState<MetricEditScreen> createState() => _MetricEditScreenState();
}

class _MetricEditScreenState extends ConsumerState<MetricEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  MetricType _selectedType = MetricType.higherIsBetter;
  Color _selectedColor = CupertinoColors.systemBlue;
  IconData _selectedIcon = CupertinoIcons.circle;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.metric != null) {
      _nameController.text = widget.metric!.name;
      _selectedType = widget.metric!.type;
      _selectedColor = widget.metric!.color;
      _selectedIcon = widget.metric!.icon;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return HealthNotesPage(
      title: widget.metric == null ? 'Add Metric' : 'Edit Metric',
      leading: TextButton(
        onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
        child: const Text('Cancel'),
      ),
      actions: [
        if (_isLoading)
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        else
          TextButton(
            onPressed: _saveMetric,
            child: Text(widget.metric == null ? 'Add' : 'Save'),
          ),
      ],
      body: metricEditForm(),
    );
  }

  Widget metricEditForm() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.m),
        children: [
          nameSection(),
          VSpace.l,
          typeSection(),
          VSpace.l,
          colorSection(),
          VSpace.l,
          iconSection(),
        ],
      ),
    );
  }

  Widget nameSection() {
    return ECard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Metric Name',
            style: CupertinoTheme.of(
              context,
            ).textTheme.textStyle.copyWith(fontWeight: FontWeight.w600),
          ),
          VSpace.s,
          CupertinoTextField(
            controller: _nameController,
            placeholder: 'Enter metric name',
            decoration: BoxDecoration(
              border: Border.all(color: CupertinoColors.systemGrey4),
              borderRadius: BorderRadius.circular(AppRadius.small),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.s,
            ),
          ),
        ],
      ),
    );
  }

  Widget typeSection() {
    return ECard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Value Preference',
            style: CupertinoTheme.of(
              context,
            ).textTheme.textStyle.copyWith(fontWeight: FontWeight.w600),
          ),
          VSpace.sm,
          ...MetricType.values.map(typeOption),
        ],
      ),
    );
  }

  String _getMetricTypeDisplayName(MetricType type) {
    switch (type) {
      case MetricType.lowerIsBetter:
        return 'Lower is Better';
      case MetricType.middleIsBest:
        return 'Middle is Best';
      case MetricType.higherIsBetter:
        return 'Higher is Better';
    }
  }

  Widget typeOption(MetricType type) {
    final isSelected = _selectedType == type;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () => setState(() => _selectedType = type),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: isSelected
                ? CupertinoColors.systemBlue.withValues(alpha: 0.1)
                : CupertinoColors.systemGrey4.darkColor,
            borderRadius: BorderRadius.circular(AppRadius.small),
            border: Border.all(
              color: isSelected
                  ? CupertinoColors.systemBlue
                  : CupertinoColors.systemGrey4,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isSelected
                    ? CupertinoIcons.checkmark_circle_fill
                    : CupertinoIcons.circle,
                color: isSelected
                    ? CupertinoColors.systemBlue
                    : CupertinoColors.systemGrey,
                size: 20,
              ),
              HSpace.sm,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getMetricTypeDisplayName(type),
                      style: isSelected
                          ? EText.body.medium.semibold.accent
                          : EText.body.medium.white,
                    ),
                    VSpace.of(2),
                    Text(
                      type.description,
                      style: isSelected
                          ? EText.body.small.accent.size(12)
                          : EText.body.small.white.size(12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget colorSection() {
    return ECard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Color',
            style: CupertinoTheme.of(
              context,
            ).textTheme.textStyle.copyWith(fontWeight: FontWeight.w600),
          ),
          VSpace.sm,
          ColorPickerGrid(
            colors: MetricColorPalette.colors,
            selectedColor: _selectedColor,
            onColorSelected: (color) => setState(() => _selectedColor = color),
            useCircles: false,
          ),
        ],
      ),
    );
  }

  Widget iconSection() {
    return ECard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Icon',
            style: CupertinoTheme.of(
              context,
            ).textTheme.textStyle.copyWith(fontWeight: FontWeight.w600),
          ),
          VSpace.sm,
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: MetricIconPalette.icons.mapL(iconOption),
          ),
        ],
      ),
    );
  }

  Widget iconOption(IconData icon) {
    final isSelected = _selectedIcon.codePoint == icon.codePoint;

    return GestureDetector(
      onTap: () => setState(() => _selectedIcon = icon),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isSelected
              ? _selectedColor.withValues(alpha: 0.2)
              : CupertinoColors.systemGrey6,
          borderRadius: BorderRadius.circular(AppRadius.small),
          border: Border.all(
            color: isSelected ? _selectedColor : CupertinoColors.systemGrey4,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Icon(
          icon,
          color: isSelected ? _selectedColor : CupertinoColors.systemGrey,
          size: 20,
        ),
      ),
    );
  }

  Future<void> _saveMetric() async {
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => AppAlertDialogs.error(
            title: 'Error',
            content: 'Please enter a metric name.',
          ),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      final nameExists = await ref
          .read(checkInMetricsNotifierProvider.notifier)
          .metricNameExists(name, excludeId: widget.metric?.id);

      if (nameExists) {
        if (mounted) {
          showCupertinoDialog(
            context: context,
            builder: (context) => AppAlertDialogs.error(
              title: 'Error',
              content: 'A metric with this name already exists.',
            ),
          );
        }
        return;
      }

      if (widget.metric == null) {
        await ref
            .read(checkInMetricsNotifierProvider.notifier)
            .addCheckInMetric(
              name: name,
              type: _selectedType,
              color: _selectedColor,
              icon: _selectedIcon,
            );
      } else {
        final updatedMetric = widget.metric!.copyWith(
          name: name,
          type: _selectedType,
          colorValue: _selectedColor.toARGB32(),
          iconCodePoint: _selectedIcon.codePoint,
        );
        await ref
            .read(checkInMetricsNotifierProvider.notifier)
            .updateCheckInMetric(updatedMetric);
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => AppAlertDialogs.error(
            title: 'Error',
            content: 'Failed to save metric: $e',
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
