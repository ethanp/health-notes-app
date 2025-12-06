import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_notes/models/check_in.dart';
import 'package:health_notes/models/check_in_metric.dart';
import 'package:health_notes/providers/check_in_metrics_provider.dart';
import 'package:health_notes/providers/check_ins_provider.dart';
import 'package:health_notes/theme/app_theme.dart';
import 'package:health_notes/widgets/enhanced_ui_components.dart';
import 'package:health_notes/widgets/spacing.dart';

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
      child: SafeArea(child: checkInFormBody(userMetricsAsync)),
    );
  }

  Widget checkInFormBody(AsyncValue<List<CheckInMetric>> userMetricsAsync) {
    return Form(
      key: _formKey,
      child: userMetricsAsync.when(
        data: checkInFormContent,
        loading: () => const Center(child: CupertinoActivityIndicator()),
        error: (error, stack) => metricsErrorState(error),
      ),
    );
  }

  Widget checkInFormContent(List<CheckInMetric> userMetrics) {
    if (userMetrics.isEmpty) return noMetricsAvailable();

    if (_selectedMetrics.isEmpty && widget.checkIn == null) {
      // All metrics start with a default rating of "5".
      userMetrics.forEach((m) => _selectedMetrics[m.name] = 5);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [dateTimeSection(), metricSlidersSection(userMetrics)]
          .map(
            (section) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: section,
            ),
          )
          .toList(),
    );
  }

  Widget noMetricsAvailable() {
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
          VSpace.m,
          Text('No metrics available', style: AppTypography.navTitleTextStyle),
          VSpace.s,
          Text(
            'Add some metrics to start tracking your health',
            style: AppTypography.baseTextStyle,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget metricsErrorState(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            CupertinoIcons.exclamationmark_triangle,
            size: 48,
            color: CupertinoColors.systemRed,
          ),
          VSpace.m,
          Text(
            'Failed to load metrics',
            style: AppTypography.navTitleTextStyle,
          ),
          VSpace.s,
          Text(
            error.toString(),
            style: AppTypography.baseTextStyle,
            textAlign: TextAlign.center,
          ),
          VSpace.m,
          CupertinoButton.filled(
            onPressed: () => ref.invalidate(checkInMetricsNotifierProvider),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget metricSlidersSection(List<CheckInMetric> userMetrics) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppComponents.primaryCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your Ratings', style: AppTypography.headlineSmall),
          VSpace.m,
          ..._selectedMetrics.entries.map(
            (entry) => metricRatingSelector(entry, userMetrics),
          ),
        ],
      ),
    );
  }

  Widget metricRatingSelector(
    MapEntry<String, int> entry,
    List<CheckInMetric> userMetrics,
  ) {
    final metricName = entry.key;
    final rating = entry.value;
    final metric = userMetrics.firstWhere(
      (m) => m.name == metricName,
      orElse: () => throw Exception('Metric not found: $metricName'),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        sliderMetadata(metric, rating, metricName),
        ratingSliderRow(metricName, rating),
        VSpace.of(12),
      ],
    );
  }

  Widget sliderMetadata(CheckInMetric metric, int rating, String metricName) {
    return Row(
      children: [
        _ratingPill(metric, rating),
        HSpace.m,
        Icon(metric.icon, size: 20, color: AppColors.textPrimary),
        HSpace.of(12),
        Expanded(child: Text(metric.name, style: AppTypography.labelLarge)),
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => setState(() => _selectedMetrics.remove(metricName)),
          child: Icon(
            CupertinoIcons.xmark_circle_fill,
            color: CupertinoColors.systemRed.color.withValues(alpha: .7),
            size: 20,
          ),
        ),
      ],
    );
  }

  Widget ratingSliderRow(String metricName, int rating) {
    return Row(
      children: [
        Text('1', style: AppTypography.bodySmallTertiary),
        Expanded(
          child: CupertinoSlider(
            value: rating.toDouble(),
            min: 1,
            max: 10,
            divisions: 9,
            onChanged: (value) =>
                setState(() => _selectedMetrics[metricName] = value.round()),
          ),
        ),
        Text('10', style: AppTypography.bodySmallTertiary),
      ],
    );
  }

  Widget _ratingPill(CheckInMetric metric, int rating) {
    final ratingColor = metric.type.getRatingColor(rating);
    return SizedBox(
      width: 40,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: ratingColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            '$rating',
            style: AppTypography.bodySmall.copyWith(
              color: ratingColor,
              fontWeight: FontWeight.w700,
            ),
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
          VSpace.m,
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

    setState(() => _isLoading = true);

    try {
      final notifier = ref.read(checkInsNotifierProvider.notifier);
      if (widget.checkIn != null) {
        final entry = _selectedMetrics.entries.first;
        await notifier.updateCheckIn(widget.checkIn!.copyWith(
          metricName: entry.key,
          rating: entry.value,
          dateTime: _selectedDateTime,
        ));
      } else {
        for (final entry in _selectedMetrics.entries) {
          await notifier.addCheckIn(CheckIn(
            id: '',
            metricName: entry.key,
            rating: entry.value,
            dateTime: _selectedDateTime,
            createdAt: DateTime.now(),
          ));
        }
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
        setState(() => _isLoading = false);
      }
    }
  }
}
