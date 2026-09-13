import 'package:ethan_ui/ethan_ui.dart';
import 'package:flutter/material.dart';
import 'package:health_notes/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_notes/models/check_in.dart';
import 'package:health_notes/models/check_in_metric.dart';
import 'package:health_notes/models/condition_entry.dart';
import 'package:health_notes/providers/check_in_metrics_provider.dart';
import 'package:health_notes/providers/conditions_provider.dart';
import 'package:health_notes/widgets/app_dialogs.dart';
import 'package:health_notes/widgets/check_in_form/check_in_conditions_section.dart';
import 'package:health_notes/widgets/check_in_form/check_in_metrics_section.dart';
import 'package:health_notes/widgets/check_in_form/check_in_save_coordinator.dart';
import 'package:health_notes/widgets/health_note_form/date_time_section.dart';
import 'package:health_notes/widgets/health_notes_page.dart';

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
              colorValue: condition.colorValue,
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
            onPressed: _selectedMetrics.isEmpty ? null : _saveCheckIn,
            child: Text(widget.saveButtonText),
          ),
      ],
      body: _formBody(userMetricsAsync),
    );
  }

  Widget _formBody(AsyncValue<List<CheckInMetric>> userMetricsAsync) {
    return Form(
      key: _formKey,
      child: userMetricsAsync.when(
        data: _formContent,
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => CheckInMetricsErrorState(
          error: error,
          onRetry: () => ref.invalidate(checkInMetricsProvider),
        ),
      ),
    );
  }

  Widget _formContent(List<CheckInMetric> userMetrics) {
    if (userMetrics.isEmpty) return const CheckInMetricsEmptyState();

    if (_selectedMetrics.isEmpty && widget.checkIn == null) {
      for (final metric in userMetrics) {
        _selectedMetrics[metric.name] = 5;
      }
    }

    final sections = <Widget>[
      DateTimeSection(
        isEditable: true,
        selectedDateTime: _selectedDateTime,
        onDateTimeChanged: (dateTime) =>
            setState(() => _selectedDateTime = dateTime),
      ),
      CheckInMetricsSection(
        selectedMetrics: _selectedMetrics,
        userMetrics: userMetrics,
        onRatingChanged: (metricName, rating) =>
            setState(() => _selectedMetrics[metricName] = rating),
        onMetricRemoved: (metricName) =>
            setState(() => _selectedMetrics.remove(metricName)),
      ),
      if (widget.checkIn == null)
        CheckInConditionsSection(
          conditionsLoaded: _conditionsLoaded,
          conditionDrafts: _conditionDrafts,
          onAddCondition: () => CheckInConditionsSection.showAddConditionOptions(
            context: context,
            onAfterConditionCreated: _loadActiveConditions,
          ),
          onConditionRemoved: (index) =>
              setState(() => _conditionDrafts.removeAt(index)),
          onDraftChanged: () => setState(() {}),
        ),
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

  Future<void> _saveCheckIn() async {
    if (!_formKey.currentState!.validate() || _selectedMetrics.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      await CheckInSaveCoordinator(ref: ref).save(
        existing: widget.checkIn,
        dateTime: _selectedDateTime,
        selectedMetrics: _selectedMetrics,
        conditionDrafts: _conditionDrafts,
      );
      if (mounted) {
        widget.onSuccess?.call();
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AppAlertDialogs.error(
            title: 'Error',
            content: 'Failed to save check-ins: $error',
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
