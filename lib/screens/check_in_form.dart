import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_notes/models/check_in.dart';
import 'package:health_notes/providers/check_ins_provider.dart';
import 'package:health_notes/theme/app_theme.dart';
import 'package:health_notes/utils/metric_icons.dart';

class CheckInForm extends ConsumerStatefulWidget {
  final CheckIn? checkIn;
  final String title;
  final String saveButtonText;
  final Function()? onCancel;
  final Function()? onSuccess;

  const CheckInForm({
    this.checkIn,
    required this.title,
    required this.saveButtonText,
    this.onCancel,
    this.onSuccess,
  });

  @override
  ConsumerState<CheckInForm> createState() => _CheckInFormState();
}

class _CheckInFormState extends ConsumerState<CheckInForm> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _selectedDateTime;
  bool _isLoading = false;

  // Map to store metric -> rating pairs
  final Map<String, int> _selectedMetrics = {};

  static const List<String> availableMetrics = [
    'Anxiety',
    'Nausea',
    'Poop Scale',
    'Energy Level',
    'Pain Level',
    'Mood',
    'Sleep Quality',
    'Stress Level',
    'Appetite',
    'Focus',
  ];

  @override
  void initState() {
    super.initState();
    _selectedDateTime = widget.checkIn?.dateTime ?? DateTime.now();

    // Initialize with existing check-in data if editing
    if (widget.checkIn != null) {
      _selectedMetrics[widget.checkIn!.metricName] = widget.checkIn!.rating;
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(widget.title, style: AppTheme.headlineSmall),
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
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              buildMetricsGridSection(),
              if (_selectedMetrics.isNotEmpty) ...[
                const SizedBox(height: 16),
                buildSelectedMetricsSection(),
              ],
              const SizedBox(height: 16),
              buildDateTimeSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildMetricsGridSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.primaryCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Add Metrics', style: AppTheme.headlineSmall),
              Text(
                '${_selectedMetrics.length} selected',
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.textTertiary,
                ),
              ),
            ],
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
            itemCount: availableMetrics.length,
            itemBuilder: (context, index) {
              final metric = availableMetrics[index];
              final isSelected = _selectedMetrics.containsKey(metric);
              final rating = _selectedMetrics[metric] ?? 5;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedMetrics.remove(metric);
                    } else {
                      _selectedMetrics[metric] = rating;
                    }
                  });
                },
                child: Container(
                  decoration: isSelected
                      ? AppTheme.activeFilterChip
                      : AppTheme.filterChip,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        MetricIcons.getIcon(metric),
                        size: 24,
                        color: isSelected
                            ? CupertinoColors.white
                            : AppTheme.textPrimary,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        metric,
                        style: AppTheme.bodySmall.copyWith(
                          color: isSelected
                              ? CupertinoColors.white
                              : AppTheme.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (isSelected) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: CupertinoColors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$rating',
                            style: AppTheme.bodySmall.copyWith(
                              color: CupertinoColors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget buildSelectedMetricsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.primaryCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your Ratings', style: AppTheme.headlineSmall),
          const SizedBox(height: 16),
          ...(_selectedMetrics.entries.map((entry) {
            final metric = entry.key;
            final rating = entry.value;

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        MetricIcons.getIcon(metric),
                        size: 20,
                        color: AppTheme.textPrimary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(metric, style: AppTheme.labelLarge)),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () {
                          setState(() {
                            _selectedMetrics.remove(metric);
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
                  Row(
                    children: [
                      Text(
                        '1',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.textTertiary,
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
                              _selectedMetrics[metric] = value.round();
                            });
                          },
                        ),
                      ),
                      Text(
                        '10',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.textTertiary,
                        ),
                      ),
                    ],
                  ),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$rating',
                        style: AppTheme.headlineMedium.copyWith(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList()),
        ],
      ),
    );
  }

  Widget buildDateTimeSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.primaryCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Date & Time', style: AppTheme.headlineSmall),
          const SizedBox(height: 16),
          Container(
            height: 200,
            decoration: AppTheme.inputField,
            child: CupertinoDatePicker(
              mode: CupertinoDatePickerMode.dateAndTime,
              initialDateTime: _selectedDateTime,
              backgroundColor: AppTheme.backgroundTertiary,
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
      // Create multiple check-ins for each selected metric
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
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: Text('Failed to save check-ins: $e'),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
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
