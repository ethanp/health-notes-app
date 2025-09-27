import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_notes/models/check_in.dart';
import 'package:health_notes/models/check_in_metric.dart';
import 'package:health_notes/providers/check_in_metrics_provider.dart';
import 'package:health_notes/providers/check_ins_provider.dart';
import 'package:health_notes/theme/app_theme.dart';

import 'package:health_notes/widgets/enhanced_ui_components.dart';

class CheckInForm extends ConsumerStatefulWidget {
  final CheckIn? checkIn;
  final String title;
  final String saveButtonText;
  final VoidCallback? onSuccess;
  final VoidCallback? onCancel;

  const CheckInForm({
    super.key,
    this.checkIn,
    this.title = 'Add Check-in',
    this.saveButtonText = 'Save',
    this.onSuccess,
    this.onCancel,
  });

  @override
  ConsumerState<CheckInForm> createState() => _CheckInFormState();
}

class _CheckInFormState extends ConsumerState<CheckInForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late DateTime _selectedDateTime;
  bool _isLoading = false;

  final Map<String, int> _selectedMetrics = {};

  @override
  void initState() {
    super.initState();
    _selectedDateTime = widget.checkIn?.dateTime ?? DateTime.now();

    if (widget.checkIn != null) {
      _selectedMetrics[widget.checkIn!.metricName] = widget.checkIn!.rating;
    }
  }

  @override
  Widget build(BuildContext context) {
    final userMetricsAsync = ref.watch(checkInMetricsNotifierProvider);

    return CupertinoPageScaffold(
      navigationBar: EnhancedUIComponents.navigationBar(
        title: widget.title,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: widget.onCancel ?? () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _isLoading || _selectedMetrics.isEmpty
              ? null
              : saveCheckIn,
          child: _isLoading
              ? const CupertinoActivityIndicator()
              : Text(widget.saveButtonText),
        ),
      ),
      child: SafeArea(
        child: Form(
          key: _formKey,
          child: userMetricsAsync.when(
            data: (userMetrics) => ListView(
              padding: const EdgeInsets.all(16),
              children: [
                metricsGridSection(userMetrics),
                if (_selectedMetrics.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  selectedMetricsSection(userMetrics),
                ],
                const SizedBox(height: 16),
                dateTimeSection(),
              ],
            ),
            loading: () => const Center(child: CupertinoActivityIndicator()),
            error: (error, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    CupertinoIcons.exclamationmark_triangle,
                    size: 48,
                    color: CupertinoColors.systemRed,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load metrics',
                    style: CupertinoTheme.of(
                      context,
                    ).textTheme.navTitleTextStyle,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error.toString(),
                    style: CupertinoTheme.of(context).textTheme.textStyle,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  CupertinoButton.filled(
                    onPressed: () =>
                        ref.invalidate(checkInMetricsNotifierProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget metricsGridSection(List<CheckInMetric> userMetrics) {
    if (userMetrics.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: AppComponents.primaryCard,
        child: Column(
          children: [
            const Icon(
              CupertinoIcons.chart_bar,
              size: 48,
              color: CupertinoColors.systemGrey,
            ),
            const SizedBox(height: 16),
            Text(
              'No metrics available',
              style: CupertinoTheme.of(context).textTheme.navTitleTextStyle,
            ),
            const SizedBox(height: 8),
            Text(
              'Add some metrics to start tracking your health',
              style: CupertinoTheme.of(context).textTheme.textStyle,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppComponents.primaryCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EnhancedUIComponents.sectionHeader(
            title: 'Add Metrics',
            subtitle: '${_selectedMetrics.length} selected',
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.2,
            ),
            itemCount: userMetrics.length,
            itemBuilder: (context, index) => metricGridItem(userMetrics[index]),
          ),
        ],
      ),
    );
  }

  Widget metricGridItem(CheckInMetric metric) {
    final isSelected = _selectedMetrics.containsKey(metric.name);
    final rating = _selectedMetrics[metric.name] ?? 5;

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedMetrics.remove(metric.name);
          } else {
            _selectedMetrics[metric.name] = rating;
          }
        });
      },
      child: Container(
        decoration: isSelected
            ? BoxDecoration(
                gradient: LinearGradient(
                  colors: [metric.color, metric.color.withValues(alpha: 0.8)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: metric.color.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              )
            : AppComponents.filterChip,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              metric.icon,
              size: 24,
              color: isSelected ? CupertinoColors.white : metric.color,
            ),
            const SizedBox(height: 8),
            Text(
              metric.name,
              style: AppTypography.bodySmall.copyWith(
                color: isSelected ? CupertinoColors.white : metric.color,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (isSelected) ratingBadge(rating),
          ],
        ),
      ),
    );
  }

  Widget ratingBadge(int rating) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: CupertinoColors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '$rating',
          style: AppTypography.bodySmall.copyWith(
            color: CupertinoColors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget selectedMetricsSection(List<CheckInMetric> userMetrics) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppComponents.primaryCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your Ratings', style: AppTypography.headlineSmall),
          const SizedBox(height: 16),
          ..._selectedMetrics.entries.map(
            (entry) => selectedMetricCard(entry, userMetrics),
          ),
        ],
      ),
    );
  }

  Widget selectedMetricCard(
    MapEntry<String, int> entry,
    List<CheckInMetric> userMetrics,
  ) {
    final metricName = entry.key;
    final rating = entry.value;
    final metric = userMetrics.firstWhere(
      (m) => m.name == metricName,
      orElse: () => throw Exception('Metric not found: $metricName'),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(metric.icon, size: 20, color: AppColors.textPrimary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(metric.name, style: AppTypography.labelLarge),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  setState(() {
                    _selectedMetrics.remove(metricName);
                  });
                },
                child: const Icon(
                  CupertinoIcons.xmark_circle_fill,
                  color: CupertinoColors.systemRed,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ratingSliderRow(metricName, rating),
          const SizedBox(height: 8),
          ratingSummary(metric, rating),
        ],
      ),
    );
  }

  Widget ratingSliderRow(String metricName, int rating) {
    return Row(
      children: [
        Text(
          '1',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textTertiary,
          ),
        ),
        Expanded(
          child: CupertinoSlider(
            value: rating.toDouble(),
            min: 1,
            max: 10,
            divisions: 9,
            onChanged: (value) {
              setState(() {
                _selectedMetrics[metricName] = value.round();
              });
            },
          ),
        ),
        Text(
          '10',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textTertiary,
          ),
        ),
      ],
    );
  }

  Widget ratingSummary(CheckInMetric metric, int rating) {
    final ratingColor = metric.type.getRatingColor(rating);

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: ratingColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          '$rating',
          style: AppTypography.headlineMedium.copyWith(
            color: ratingColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget dateTimeSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppComponents.primaryCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Date & Time', style: AppTypography.headlineSmall),
          const SizedBox(height: 16),
          Container(
            height: 200,
            decoration: AppComponents.inputField,
            child: CupertinoDatePicker(
              mode: CupertinoDatePickerMode.dateAndTime,
              initialDateTime: _selectedDateTime,
              backgroundColor: AppColors.backgroundTertiary,
              onDateTimeChanged: (DateTime newDateTime) {
                setState(() => _selectedDateTime = newDateTime);
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> saveCheckIn() async {
    if (!_formKey.currentState!.validate() || _selectedMetrics.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      for (final entry in _selectedMetrics.entries) {
        final metricName = entry.key;
        final rating = entry.value;
        final checkIn = CheckIn(
          id: '', // Will be set by the provider
          metricName: metricName,
          rating: rating,
          dateTime: _selectedDateTime,
          createdAt: DateTime.now(),
        );

        await ref.read(checkInsNotifierProvider.notifier).addCheckIn(checkIn);
      }

      if (mounted) {
        widget.onSuccess?.call();
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => AppAlertDialogs.error(
            title: 'Error',
            content: 'Failed to save check-ins: $e',
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
