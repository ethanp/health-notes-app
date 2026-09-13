import 'package:ethan_ui/ethan_ui.dart';
import 'package:ethan_utils/ethan_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_notes/models/drug_name.dart';
import 'package:health_notes/models/medication_schedule.dart';
import 'package:health_notes/app_identity.dart';
import 'package:health_notes/providers/medication_recommendations_provider.dart';
import 'package:health_notes/providers/medication_schedules_provider.dart';
import 'package:health_notes/theme/app_theme.dart';
import 'package:health_notes/theme/spacing.dart';
import 'package:health_notes/utils/data_utils.dart';
import 'package:health_notes/utils/health_date_format.dart';
import 'package:health_notes/widgets/medication_suggestion_chips.dart';
import 'package:health_notes/widgets/medication_schedule/daily_times_editor.dart';
import 'package:health_notes/widgets/medication_schedule/schedule_form_fields.dart';
import 'package:health_notes/widgets/medication_schedule/schedule_kind_starter.dart';
import 'package:health_notes/widgets/medication_schedule/schedule_scaffold.dart';
import 'package:health_notes/widgets/medication_schedule/schedule_step_draft.dart';
import 'package:health_notes/widgets/medication_schedule/taper_schedule_editor.dart';

class const MedicationScheduleForm({final MedicationSchedule? existing})
    extends ConsumerStatefulWidget {
  @override
  ConsumerState<MedicationScheduleForm> createState() =>
      _MedicationScheduleFormState();
}

class _MedicationScheduleFormState()
    extends ConsumerState<MedicationScheduleForm> {
  late final TextEditingController _nameController;
  late final TextEditingController _unitController;
  late final TextEditingController _notesController;
  final _editorScrollController = ScrollController();
  late DateTime _startDate;
  late List<ScheduleStepDraft> _steps;
  ScheduleKind? _scheduleKind;
  bool _isSaving = false;

  bool get _isEditing => widget.existing != null;

  String get _unitLabel {
    final unit = _unitController.text.trim();
    return unit.isEmpty ? 'mg' : unit;
  }

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _nameController = TextEditingController(
      text: existing?.medicationName.display ?? '',
    );
    _unitController = TextEditingController(text: existing?.unit ?? 'mg');
    _notesController = TextEditingController(text: existing?.notes ?? '');
    _startDate = existing?.startDate ?? DateTime.now().startOfDay;
    _steps = existing == null
        ? []
        : existing.steps.map(ScheduleStepDraft.fromStep).toList();
    if (existing != null) {
      _scheduleKind = existing.kind;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _unitController.dispose();
    _notesController.dispose();
    _editorScrollController.dispose();
    for (final step in _steps) {
      step.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MedicationScheduleScaffold(
      title: _isEditing ? 'Edit schedule' : 'New schedule',
      actions: [
        TextButton(
          onPressed: _isSaving || !_canSave ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
      body: _scheduleKind == null
          ? ScheduleKindStarter(onKindSelected: _startAs)
          : _editor(),
    );
  }

  Widget _editor() {
    return ListView(
      controller: _editorScrollController,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: _editorPadding,
      children: [
        if (_previewSentence.isNotEmpty) ...[
          Text(_previewSentence, style: EText.headline.small),
          VSpace.l,
        ],
        ScheduleFormFields.labeled(
          label: 'Medication',
          controller: _nameController,
          onChanged: (_) => setState(() {}),
        ),
        MedicationNameSuggestionChips(
          typedName: _nameController.text,
          onNameSelected: _selectSuggestedMedicationName,
        ),
        VSpace.m,
        ScheduleFormFields.labeled(
          label: 'Unit',
          controller: _unitController,
          onChanged: (_) => setState(() {}),
        ),
        VSpace.m,
        _startDateRow(),
        VSpace.m,
        ScheduleFormFields.labeled(
          label: 'Note',
          controller: _notesController,
          hint: 'from ENT',
          onChanged: (_) => setState(() {}),
        ),
        VSpace.l,
        if (_scheduleKind == ScheduleKind.taper)
          TaperScheduleEditor(
            steps: _steps,
            unit: _unitLabel,
            onChanged: () => setState(() {}),
            onAddStep: _addTaperStep,
            onRemoveStep: _removeStep,
          ),
        if (_scheduleKind == ScheduleKind.daily)
          DailyTimesEditor(
            step: _steps.first,
            unit: _unitLabel,
            onChanged: () => setState(() {}),
            onAddDose: _addClockDose,
            onRemoveDose: _removeClockDose,
            onPickClockTime: _pickClockTime,
          ),
      ],
    );
  }

  EdgeInsets get _editorPadding {
    return const EdgeInsets.fromLTRB(
      AppSpacing.m,
      AppSpacing.m,
      AppSpacing.m,
      AppSpacing.l,
    ).withOverlaidTabBar(context);
  }

  Widget _startDateRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Start date', style: EText.label.medium),
        VSpace.s,
        OutlinedButton(
          onPressed: _pickStartDate,
          child: Text(_startDate.monthDayYear),
        ),
      ],
    );
  }

  void _selectSuggestedMedicationName(DrugName name) {
    _nameController.text = name.display;
    final String? unit = _unitForSuggestedName(name);
    if (unit != null) _unitController.text = unit;
    setState(() {});
  }

  String? _unitForSuggestedName(DrugName name) {
    final MedicationRecommendationsState? recommendations = ref
        .read(medicationRecommendationsProvider)
        .asData
        ?.value;
    final String? fromNotes = recommendations?.unitForName(name);
    if (fromNotes != null) return fromNotes;
    final List<MedicationSchedule> schedules =
        ref.read(medicationSchedulesProvider).asData?.value ?? const [];
    for (final schedule in schedules) {
      if (schedule.medicationName == name && schedule.unit.isNotEmpty) {
        return schedule.unit;
      }
    }
    return null;
  }

  void _startAs(ScheduleKind scheduleKind) {
    setState(() {
      _scheduleKind = scheduleKind;
      for (final step in _steps) {
        step.dispose();
      }
      _steps = [
        if (scheduleKind == ScheduleKind.taper)
          ScheduleStepDraft.taper(
            when: const DoseWhen.partOfDay(PartOfDay.morning),
          )
        else
          ScheduleStepDraft.dailyTimes(
            when: const DoseWhen.clock(hour: 10, minute: 30),
          ),
      ];
    });
  }

  void _addTaperStep() {
    final previousWhen = _steps.last.doses.first.when;
    setState(() {
      _steps.add(ScheduleStepDraft.taper(when: previousWhen));
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _revealThenButton();
    });
  }

  void _revealThenButton() {
    if (!mounted || !_editorScrollController.hasClients) return;
    _editorScrollController.animateTo(
      _editorScrollController.position.maxScrollExtent,
      duration: AppAnimation.medium,
      curve: AppAnimation.slideCurve,
    );
  }

  void _addClockDose() {
    setState(() {
      _steps.first.doses.add(
        ScheduleDoseDraft(when: const DoseWhen.clock(hour: 20, minute: 0)),
      );
    });
  }

  void _removeStep(int stepIndex) {
    setState(() {
      _steps.removeAt(stepIndex).dispose();
    });
  }

  void _removeClockDose(int doseIndex) {
    setState(() {
      _steps.first.doses.removeAt(doseIndex).dispose();
    });
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() => _startDate = picked.startOfDay);
  }

  Future<void> _pickClockTime(ScheduleDoseDraft dose) async {
    final initial = switch (dose.when) {
      ClockDoseWhen(:final hour, :final minute) => TimeOfDay(
        hour: hour,
        minute: minute,
      ),
      PartOfDayDoseWhen() => const TimeOfDay(hour: 10, minute: 30),
    };
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return;
    setState(() {
      dose.when = DoseWhen.clock(hour: picked.hour, minute: picked.minute);
    });
  }

  MedicationSchedule _draftSchedule({
    required String id,
    required String userId,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? endDate,
  }) {
    return MedicationSchedule(
      id: id,
      userId: userId,
      medicationName: DrugName(_nameController.text.trim()),
      unit: _unitLabel,
      startDate: _startDate,
      endDate: endDate,
      steps: _steps.map((step) => step.toStep()).toList(),
      notes: _notesController.text.trim(),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  String get _previewSentence {
    if (_steps.isEmpty) return '';
    return _draftSchedule(
      id: 'preview',
      userId: 'preview',
      createdAt: _startDate,
      updatedAt: _startDate,
    ).sentence;
  }

  bool get _canSave {
    if (_nameController.text.trim().isEmpty) return false;
    if (_steps.isEmpty) return false;
    return _steps.any(
      (step) => step.doses.any((dose) => dose.parsedAmount != null),
    );
  }

  Future<void> _save() async {
    if (!_canSave) return;
    setState(() => _isSaving = true);
    try {
      final now = DateTime.now();
      final existing = widget.existing;
      final schedule = _draftSchedule(
        id: existing?.id ?? DataUtils.uuid.v4(),
        userId: AppIdentity.localUserId,
        createdAt: existing?.createdAt ?? now,
        updatedAt: now,
        endDate: existing?.endDate,
      );
      final notifier = ref.read(medicationSchedulesProvider.notifier);
      if (existing == null) {
        await notifier.addSchedule(schedule);
      } else {
        await notifier.updateSchedule(schedule);
      }
      if (mounted) context.pop();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
