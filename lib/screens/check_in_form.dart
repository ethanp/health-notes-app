import 'package:ethan_utils/ethan_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_notes/models/check_in.dart';
import 'package:health_notes/models/check_in_metric.dart';
import 'package:health_notes/models/condition_entry.dart';
import 'package:health_notes/providers/check_in_metrics_provider.dart';
import 'package:health_notes/providers/check_ins_provider.dart';
import 'package:health_notes/providers/conditions_provider.dart';
import 'package:health_notes/screens/condition_form.dart';
import 'package:health_notes/theme/app_theme.dart';
import 'package:health_notes/utils/data_utils.dart';
import 'package:health_notes/widgets/enhanced_ui_components.dart';
import 'package:health_notes/theme/spacing.dart';

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
  bool _conditionsLoaded = false;

  final Map<String, int> _selectedMetrics = {};
  final List<ConditionEntryDraft> _conditionDrafts = [];

  @override
  void initState() {
    super.initState();
    _selectedDateTime = widget.checkIn?.dateTime ?? DateTime.now();

    if (widget.checkIn != null) {
      _selectedMetrics[widget.checkIn!.metricName] = widget.checkIn!.rating;
    }

    _loadActiveConditions();
  }

  Future<void> _loadActiveConditions() async {
    if (widget.checkIn != null) return;
    
    final activeConditions = await ref.read(conditionsNotifierProvider.notifier).getActiveConditions();
    if (mounted) {
      setState(() {
        _conditionDrafts.clear();
        for (final condition in activeConditions) {
          _conditionDrafts.add(ConditionEntryDraft(
            conditionId: condition.id,
            conditionName: condition.name,
            conditionColor: condition.color,
          ));
        }
        _conditionsLoaded = true;
      });
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
      userMetrics.forEach((m) => _selectedMetrics[m.name] = 5);
    }

    final sections = <Widget>[
      dateTimeSection(),
      metricSlidersSection(userMetrics),
      if (widget.checkIn == null) conditionsSection(),
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: sections
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

  Widget conditionsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppComponents.primaryCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Active Conditions', style: AppTypography.headlineSmall),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: showAddConditionOptions,
                child: Row(
                  children: [
                    Icon(CupertinoIcons.add, size: 18, color: CupertinoColors.systemBlue),
                    HSpace.xs,
                    Text('Add', style: AppTypography.bodyMediumSemiboldBlue),
                  ],
                ),
              ),
            ],
          ),
          VSpace.s,
          Text(
            'Log entries for active conditions',
            style: AppTypography.bodySmallTertiary,
          ),
          VSpace.m,
          if (!_conditionsLoaded)
            const Center(child: CupertinoActivityIndicator())
          else if (_conditionDrafts.isEmpty)
            noConditionsMessage()
          else
            ..._conditionDrafts.asMap().entries.map(
              (entry) => conditionEntryCard(entry.key, entry.value),
            ),
        ],
      ),
    );
  }

  Widget noConditionsMessage() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundTertiary,
        borderRadius: BorderRadius.circular(AppRadius.small),
      ),
      child: Center(
        child: Text(
          'No active conditions to log',
          style: AppTypography.bodyMediumSystemGrey,
        ),
      ),
    );
  }

  Widget conditionEntryCard(int index, ConditionEntryDraft draft) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundTertiary,
        borderRadius: BorderRadius.circular(AppRadius.small),
        border: Border.all(
          color: draft.conditionColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          conditionEntryHeader(index, draft),
          VSpace.m,
          conditionSeveritySlider(index, draft),
          VSpace.m,
          conditionPhasePicker(index, draft),
          VSpace.m,
          conditionNotesField(index, draft),
          VSpace.m,
          conditionResolveToggle(index, draft),
        ],
      ),
    );
  }

  Widget conditionEntryHeader(int index, ConditionEntryDraft draft) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: draft.conditionColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            CupertinoIcons.bandage,
            size: 14,
            color: draft.conditionColor,
          ),
        ),
        HSpace.s,
        Expanded(
          child: Text(draft.conditionName, style: AppTypography.labelLargePrimary),
        ),
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => setState(() => _conditionDrafts.removeAt(index)),
          child: Icon(
            CupertinoIcons.xmark_circle_fill,
            color: CupertinoColors.systemRed.withValues(alpha: 0.7),
            size: 20,
          ),
        ),
      ],
    );
  }

  Widget conditionSeveritySlider(int index, ConditionEntryDraft draft) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Severity', style: AppTypography.labelMedium),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: severityColor(draft.severity),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${draft.severity}/10',
                style: AppTypography.labelSmall.copyWith(color: CupertinoColors.white),
              ),
            ),
          ],
        ),
        VSpace.xs,
        CupertinoSlider(
          value: draft.severity.toDouble(),
          min: 1,
          max: 10,
          divisions: 9,
          activeColor: severityColor(draft.severity),
          onChanged: (value) => setState(() => draft.severity = value.round()),
        ),
      ],
    );
  }

  Widget conditionPhasePicker(int index, ConditionEntryDraft draft) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Phase', style: AppTypography.labelMedium),
        VSpace.xs,
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: ConditionPhase.values.map((p) {
            final isSelected = draft.phase == p;
            return GestureDetector(
              onTap: () => setState(() => draft.phase = p),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? p.color.withValues(alpha: 0.2) : AppColors.backgroundQuaternary,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? p.color : AppColors.backgroundQuinary,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Text(
                  p.displayName,
                  style: AppTypography.caption.copyWith(
                    color: isSelected ? p.color : AppColors.textSecondary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget conditionNotesField(int index, ConditionEntryDraft draft) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Notes', style: AppTypography.labelMedium),
        VSpace.xs,
        CupertinoTextField(
          placeholder: 'Optional notes for this condition...',
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.backgroundQuaternary,
            borderRadius: BorderRadius.circular(8),
          ),
          style: AppTypography.bodySmall,
          placeholderStyle: AppTypography.inputPlaceholder.copyWith(fontSize: 13),
          maxLines: 2,
          onChanged: (value) => draft.notes = value,
        ),
      ],
    );
  }

  Widget conditionResolveToggle(int index, ConditionEntryDraft draft) {
    return Row(
      children: [
        CupertinoSwitch(
          value: draft.markResolved,
          onChanged: (value) => setState(() => draft.markResolved = value),
          activeTrackColor: CupertinoColors.systemGreen,
        ),
        HSpace.s,
        Expanded(
          child: Text(
            'Mark as resolved after this entry',
            style: AppTypography.bodySmallSecondary,
          ),
        ),
      ],
    );
  }

  Color severityColor(int severity) {
    if (severity <= 3) return CupertinoColors.systemGreen;
    if (severity <= 5) return CupertinoColors.systemYellow;
    if (severity <= 7) return CupertinoColors.systemOrange;
    return CupertinoColors.systemRed;
  }

  void showAddConditionOptions() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Add Condition'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () async {
              Navigator.of(context).pop();
              await context.push((_) => const ConditionForm());
              await _loadActiveConditions();
            },
            child: const Text('Create New Condition'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  Future<void> saveCheckIn() async {
    if (!_formKey.currentState!.validate() || _selectedMetrics.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final notifier = ref.read(checkInsNotifierProvider.notifier);
      late String checkInId;

      if (widget.checkIn != null) {
        final entry = _selectedMetrics.entries.first;
        await notifier.updateCheckIn(widget.checkIn!.copyWith(
          metricName: entry.key,
          rating: entry.value,
          dateTime: _selectedDateTime,
        ));
        checkInId = widget.checkIn!.id;
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

        final allCheckIns = await ref.read(checkInsNotifierProvider.future);
        final latestCheckIn = allCheckIns
            .where((c) => c.dateTime.isAtSameMomentAs(_selectedDateTime) || 
                          c.dateTime.difference(_selectedDateTime).inSeconds.abs() < 5)
            .toList();
        if (latestCheckIn.isNotEmpty) {
          checkInId = latestCheckIn.first.id;
        } else {
          checkInId = DataUtils.uuid.v4();
        }
      }

      for (final draft in _conditionDrafts) {
        final conditionsNotifier = ref.read(conditionsNotifierProvider.notifier);
        final entriesNotifier = ref.read(conditionEntriesNotifierProvider(draft.conditionId).notifier);

        await entriesNotifier.addEntry(
          entryDate: _selectedDateTime,
          severity: draft.severity,
          phase: draft.phase,
          notes: draft.notes,
          linkedCheckInId: checkInId,
        );

        if (draft.markResolved) {
          await conditionsNotifier.resolveCondition(draft.conditionId, endDate: _selectedDateTime);
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
