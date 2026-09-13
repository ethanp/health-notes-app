import 'package:ethan_ui/ethan_ui.dart';
import 'package:ethan_utils/ethan_utils.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
import 'package:health_notes/utils/symptom_severity.dart';
import 'package:health_notes/widgets/app_dialogs.dart';
import 'package:health_notes/widgets/health_notes_page.dart';
import 'package:health_notes/theme/spacing.dart';

class const CheckInForm({
  final CheckIn? checkIn,
  final String title = 'Add Check-in',
  final String saveButtonText = 'Save',
  final VoidCallback? onSuccess,
  final VoidCallback? onCancel,
}) extends ConsumerStatefulWidget {
  @override
  ConsumerState<CheckInForm> createState() => _CheckInFormState();
}

class _CheckInFormState() extends ConsumerState<CheckInForm> {
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

    final activeConditions = await ref
        .read(conditionsProvider.notifier)
        .getActiveConditions();
    if (mounted) {
      setState(() {
        _conditionDrafts.clear();
        for (final condition in activeConditions) {
          _conditionDrafts.add(
            ConditionEntryDraft(
              conditionId: condition.id,
              conditionName: condition.name,
              conditionColor: condition.color,
            ),
          );
        }
        _conditionsLoaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userMetricsAsync = ref.watch(checkInMetricsProvider);

    return HealthNotesPage(
      title: widget.title,
      leading: TextButton(
        onPressed: widget.onCancel ?? () => Navigator.of(context).pop(),
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
            onPressed: _selectedMetrics.isEmpty ? null : saveCheckIn,
            child: Text(widget.saveButtonText),
          ),
      ],
      body: checkInFormBody(userMetricsAsync),
    );
  }

  Widget checkInFormBody(AsyncValue<List<CheckInMetric>> userMetricsAsync) {
    return Form(
      key: _formKey,
      child: userMetricsAsync.when(
        data: checkInFormContent,
        loading: () => const Center(child: CircularProgressIndicator()),
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
      padding: const EdgeInsets.all(AppSpacing.m).withOverlaidTabBar(context),
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
    return ECard(
      child: Column(
        children: [
          const Icon(Icons.bar_chart, size: 48, color: EColors.textMuted),
          VSpace.m,
          Text('No metrics available', style: EText.headline.small),
          VSpace.s,
          Text(
            'Add some metrics to start tracking your health',
            style: EText.body.medium,
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
            Icons.warning_amber,
            size: 48,
            color: EColors.danger,
          ),
          VSpace.m,
          Text('Failed to load metrics', style: EText.headline.small),
          VSpace.s,
          Text(
            error.toString(),
            style: EText.body.medium,
            textAlign: TextAlign.center,
          ),
          VSpace.m,
          FilledButton(
            onPressed: () => ref.invalidate(checkInMetricsProvider),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget metricSlidersSection(List<CheckInMetric> userMetrics) {
    return ECard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your Ratings', style: EText.headline.small),
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
        VSpace.sm,
      ],
    );
  }

  Widget sliderMetadata(CheckInMetric metric, int rating, String metricName) {
    return Row(
      children: [
        _ratingPill(metric, rating),
        HSpace.m,
        Icon(metric.icon, size: 20, color: EColors.textPrimary),
        HSpace.sm,
        Expanded(child: Text(metric.name, style: EText.label.large)),
        IconButton(
          tooltip: 'Remove metric',
          onPressed: () => setState(() => _selectedMetrics.remove(metricName)),
          icon: Icon(
            Icons.cancel,
            color: EColors.danger.withValues(alpha: .7),
            size: 20,
          ),
        ),
      ],
    );
  }

  Widget ratingSliderRow(String metricName, int rating) {
    return Row(
      children: [
        Text('1', style: EText.body.small.tertiary),
        Expanded(
          child: Slider(
            value: rating.toDouble(),
            min: 1,
            max: 10,
            divisions: 9,
            onChanged: (value) =>
                setState(() => _selectedMetrics[metricName] = value.round()),
          ),
        ),
        Text('10', style: EText.body.small.tertiary),
      ],
    );
  }

  Widget _ratingPill(CheckInMetric metric, int rating) {
    final ratingColor = metric.type.improvementColor(rating);
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
            style: EText.body.small.copyWith(
              color: ratingColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  Widget dateTimeSection() {
    return ECard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Date & Time', style: EText.headline.small),
          VSpace.m,
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.calendar_today),
            title: Text(DateFormat('EEEE, MMMM d, y').format(_selectedDateTime)),
            subtitle: Text(DateFormat.jm().format(_selectedDateTime)),
            onTap: _pickDateTime,
          ),
        ],
      ),
    );
  }

  Widget conditionsSection() {
    return ECard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Active Conditions', style: EText.headline.small),
              TextButton.icon(
                onPressed: showAddConditionOptions,
                icon: const Icon(Icons.add, size: 18),
                label: Text('Add', style: EText.body.medium.semibold.accent),
              ),
            ],
          ),
          VSpace.s,
          Text(
            'Log entries for active conditions',
            style: EText.body.small.tertiary,
          ),
          VSpace.m,
          if (!_conditionsLoaded)
            const Center(child: CircularProgressIndicator())
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
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: EColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.small),
      ),
      child: Center(
        child: Text(
          'No active conditions to log',
          style: EText.body.medium.muted,
        ),
      ),
    );
  }

  Widget conditionEntryCard(int index, ConditionEntryDraft draft) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: EColors.surface,
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
          decoration: AppComponents.tintedSolidDecoration(
            draft.conditionColor,
            radius: 14,
            borderWidth: 0,
          ),
          child: Icon(
            Icons.healing,
            size: 14,
            color: draft.conditionColor,
          ),
        ),
        HSpace.s,
        Expanded(
          child: Text(draft.conditionName, style: EText.label.large.primary),
        ),
        IconButton(
          tooltip: 'Remove condition',
          onPressed: () => setState(() => _conditionDrafts.removeAt(index)),
          icon: Icon(
            Icons.cancel,
            color: EColors.danger.withValues(alpha: 0.7),
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
            Text('Severity', style: EText.label.medium),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: SymptomSeverity.fourBucketGreenYellowOrangeRed(draft.severity),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${draft.severity}/10',
                style: EText.label.small.copyWith(color: Colors.white),
              ),
            ),
          ],
        ),
        VSpace.xs,
        Slider(
          value: draft.severity.toDouble(),
          min: 1,
          max: 10,
          divisions: 9,
          activeColor: SymptomSeverity.fourBucketGreenYellowOrangeRed(draft.severity),
          onChanged: (value) => setState(() => draft.severity = value.round()),
        ),
      ],
    );
  }

  Widget conditionPhasePicker(int index, ConditionEntryDraft draft) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Phase', style: EText.label.medium),
        VSpace.xs,
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: ConditionPhase.values.map((p) {
            final isSelected = draft.phase == p;
            return GestureDetector(
              onTap: () => setState(() => draft.phase = p),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.s,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? p.color.withValues(alpha: 0.2)
                      : EColors.surfaceRaised,
                  borderRadius: BorderRadius.circular(AppRadius.large),
                  border: Border.all(
                    color: isSelected ? p.color : EColors.borderStrong,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Text(
                  p.displayName,
                  style: EText.caption.copyWith(
                    color: isSelected ? p.color : EColors.textSecondary,
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
        Text('Notes', style: EText.label.medium),
        VSpace.xs,
        TextField(
          maxLines: 2,
          style: EText.body.small,
          onChanged: (value) => draft.notes = value,
          decoration: InputDecoration(
            hintText: 'Optional notes for this condition...',
            hintStyle: EText.body.medium.muted.size(13),
            filled: true,
            fillColor: EColors.surfaceRaised,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.small),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget conditionResolveToggle(int index, ConditionEntryDraft draft) {
    return Row(
      children: [
        Switch(
          value: draft.markResolved,
          onChanged: (value) => setState(() => draft.markResolved = value),
          activeThumbColor: EColors.success,
        ),
        HSpace.s,
        Expanded(
          child: Text(
            'Mark as resolved after this entry',
            style: EText.body.small.secondary,
          ),
        ),
      ],
    );
  }

  Future<void> _pickDateTime() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (pickedDate == null || !mounted) return;
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
    );
    if (pickedTime == null || !mounted) return;
    setState(() {
      _selectedDateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  void showAddConditionOptions() {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Create New Condition'),
              onTap: () async {
                Navigator.of(sheetContext).pop();
                await context.push(const ConditionForm());
                await _loadActiveConditions();
              },
            ),
            ListTile(
              title: const Text('Cancel'),
              onTap: () => Navigator.of(sheetContext).pop(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> saveCheckIn() async {
    if (!_formKey.currentState!.validate() || _selectedMetrics.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final notifier = ref.read(checkInsProvider.notifier);
      late String checkInId;

      if (widget.checkIn != null) {
        final entry = _selectedMetrics.entries.first;
        await notifier.updateCheckIn(
          widget.checkIn!.copyWith(
            metricName: entry.key,
            rating: entry.value,
            dateTime: _selectedDateTime,
          ),
        );
        checkInId = widget.checkIn!.id;
      } else {
        for (final entry in _selectedMetrics.entries) {
          await notifier.addCheckIn(
            CheckIn(
              id: '',
              metricName: entry.key,
              rating: entry.value,
              dateTime: _selectedDateTime,
              createdAt: DateTime.now(),
            ),
          );
        }

        final allCheckIns = await ref.read(checkInsProvider.future);
        final latestCheckIn = allCheckIns
            .where(
              (c) =>
                  c.dateTime.isAtSameMomentAs(_selectedDateTime) ||
                  c.dateTime.difference(_selectedDateTime).inSeconds.abs() < 5,
            )
            .toList();
        if (latestCheckIn.isNotEmpty) {
          checkInId = latestCheckIn.first.id;
        } else {
          checkInId = DataUtils.uuid.v4();
        }
      }

      for (final draft in _conditionDrafts) {
        final conditionsNotifier = ref.read(conditionsProvider.notifier);
        final entriesNotifier = ref.read(
          conditionEntriesProvider(draft.conditionId).notifier,
        );

        await entriesNotifier.addEntry(
          entryDate: _selectedDateTime,
          severity: draft.severity,
          phase: draft.phase,
          notes: draft.notes,
          linkedCheckInId: checkInId,
        );

        if (draft.markResolved) {
          await conditionsNotifier.resolveCondition(
            draft.conditionId,
            endDate: _selectedDateTime,
          );
        }
      }

      if (mounted) {
        widget.onSuccess?.call();
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        showDialog(
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
