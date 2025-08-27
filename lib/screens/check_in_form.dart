import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_notes/models/check_in.dart';
import 'package:health_notes/providers/check_ins_provider.dart';
import 'package:health_notes/theme/app_theme.dart';

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
  late String _selectedMetric;
  late int _rating;
  late DateTime _selectedDateTime;
  bool _isLoading = false;

  // Predefined metrics for check-ins
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
    _selectedMetric = widget.checkIn?.metricName ?? availableMetrics.first;
    _rating = widget.checkIn?.rating ?? 5;
    _selectedDateTime = widget.checkIn?.dateTime ?? DateTime.now();
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
          onPressed: _isLoading ? null : saveCheckIn,
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
              buildMetricSection(),
              const SizedBox(height: 16),
              buildRatingSection(),
              const SizedBox(height: 16),
              buildDateTimeSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildMetricSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.primaryCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Metric', style: AppTheme.headlineSmall),
          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: availableMetrics.length,
              itemBuilder: (context, index) {
                final metric = availableMetrics[index];
                final isSelected = _selectedMetric == metric;

                return Padding(
                  padding: EdgeInsets.only(
                    right: index < availableMetrics.length - 1 ? 12 : 0,
                  ),
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _selectedMetric = metric);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: isSelected
                          ? AppTheme.activeFilterChip
                          : AppTheme.filterChip,
                      child: Text(
                        metric,
                        style: AppTheme.labelMedium.copyWith(
                          color: isSelected
                              ? CupertinoColors.white
                              : AppTheme.textPrimary,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget buildRatingSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.primaryCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Rating', style: AppTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            'Rate your $_selectedMetric on a scale of 1-10',
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.textTertiary),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '1',
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.textTertiary,
                ),
              ),
              Expanded(
                child: CupertinoSlider(
                  value: _rating.toDouble(),
                  min: 1,
                  max: 10,
                  divisions: 9,
                  onChanged: (value) {
                    setState(() => _rating = value.round());
                  },
                ),
              ),
              Text(
                '10',
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$_rating',
                style: AppTheme.headlineLarge.copyWith(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
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
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final checkIn =
          widget.checkIn?.copyWith(
            metricName: _selectedMetric,
            rating: _rating,
            dateTime: _selectedDateTime,
          ) ??
          CheckIn(
            id: '', // Will be set by the provider
            metricName: _selectedMetric,
            rating: _rating,
            dateTime: _selectedDateTime,
            createdAt: DateTime.now(),
          );

      await ref.read(checkInsNotifierProvider.notifier).addCheckIn(checkIn);

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
            content: Text('Failed to save check-in: $e'),
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
