import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_notes/models/check_in_metric.dart';
import 'package:health_notes/providers/check_in_metrics_provider.dart';
import 'package:health_notes/theme/app_theme.dart';
import 'package:health_notes/widgets/enhanced_ui_components.dart';

class MetricEditScreen extends ConsumerStatefulWidget {
  final CheckInMetric? metric;

  const MetricEditScreen({super.key, this.metric});

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
    return CupertinoPageScaffold(
      navigationBar: EnhancedUIComponents.navigationBar(
        title: widget.metric == null ? 'Add Metric' : 'Edit Metric',
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _isLoading ? null : _saveMetric,
          child: _isLoading
              ? const CupertinoActivityIndicator()
              : Text(widget.metric == null ? 'Add' : 'Save'),
        ),
      ),
      child: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              nameSection(),
              const SizedBox(height: 24),
              typeSection(),
              const SizedBox(height: 24),
              colorSection(),
              const SizedBox(height: 24),
              iconSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget nameSection() {
    return EnhancedUIComponents.card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Metric Name',
            style: CupertinoTheme.of(
              context,
            ).textTheme.textStyle.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          CupertinoTextField(
            controller: _nameController,
            placeholder: 'Enter metric name',
            decoration: BoxDecoration(
              border: Border.all(color: CupertinoColors.systemGrey4),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ],
      ),
    );
  }

  Widget typeSection() {
    return EnhancedUIComponents.card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Value Preference',
            style: CupertinoTheme.of(
              context,
            ).textTheme.textStyle.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
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
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected
                ? CupertinoColors.systemBlue.withValues(alpha: 0.1)
                : CupertinoColors.systemGrey4.darkColor,
            borderRadius: BorderRadius.circular(8),
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
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getMetricTypeDisplayName(type),
                      style: isSelected
                          ? AppTypography.bodyMediumSemiboldBlue
                          : AppTypography.bodyMediumWhite,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      type.description,
                      style: isSelected
                          ? AppTypography.bodySmall.copyWith(
                              color: CupertinoColors.systemBlue.withValues(
                                alpha: 0.8,
                              ),
                              fontSize: 12,
                            )
                          : AppTypography.bodySmall.copyWith(
                              color: CupertinoColors.white.withValues(
                                alpha: 0.7,
                              ),
                              fontSize: 12,
                            ),
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
    return EnhancedUIComponents.card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Color',
            style: CupertinoTheme.of(
              context,
            ).textTheme.textStyle.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: MetricColorPalette.colors.map(colorOption).toList(),
          ),
        ],
      ),
    );
  }

  Widget colorOption(Color color) {
    final isSelected = _selectedColor.toARGB32() == color.toARGB32();

    return GestureDetector(
      onTap: () => setState(() => _selectedColor = color),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? CupertinoColors.white
                : CupertinoColors.systemGrey4,
            width: isSelected ? 3 : 1,
          ),
        ),
        child: isSelected
            ? const Icon(
                CupertinoIcons.checkmark,
                color: CupertinoColors.white,
                size: 20,
              )
            : null,
      ),
    );
  }

  Widget iconSection() {
    return EnhancedUIComponents.card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Icon',
            style: CupertinoTheme.of(
              context,
            ).textTheme.textStyle.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: MetricIconPalette.icons.map(iconOption).toList(),
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
          borderRadius: BorderRadius.circular(8),
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
