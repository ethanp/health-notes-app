import 'package:ethan_ui/ethan_ui.dart';
import 'package:ethan_utils/ethan_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_notes/models/drug_name.dart';
import 'package:health_notes/models/medication_schedule.dart';
import 'package:health_notes/providers/auth_provider.dart';
import 'package:health_notes/providers/medication_recommendations_provider.dart';
import 'package:health_notes/providers/medication_schedules_provider.dart';
import 'package:health_notes/theme/app_theme.dart';
import 'package:health_notes/theme/spacing.dart';
import 'package:health_notes/utils/data_utils.dart';
import 'package:health_notes/utils/date_utils.dart';
import 'package:health_notes/widgets/medication_suggestion_chips.dart';
import 'package:health_notes/widgets/medication_schedule/schedule_scaffold.dart';

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
  late List<_StepDraft> _steps;
  ScheduleKind? _scheduleKind;
  bool _isSaving = false;

  bool get _isEditing => widget.existing != null;

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
        : existing.steps.map(_StepDraft.fromStep).toList();
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
    _steps.forEach((step) => step.dispose());
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
      body: _scheduleKind == null ? _starterChoices() : _editor(),
    );
  }

  Widget _starterChoices() {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.m),
      children: [
        Text('What kind of course?', style: EText.headline.small),
        VSpace.m,
        _starterCard(
          title: 'Taper',
          caption: '40mg for 7 mornings, then 30mg for 3 mornings',
          onActivated: () => _startAs(ScheduleKind.taper),
        ),
        _starterCard(
          title: 'Times each day',
          caption: '200mg at 10:30 AM, 200mg at 4:30 PM, 300mg at 10:30 PM',
          onActivated: () => _startAs(ScheduleKind.daily),
        ),
      ],
    );
  }

  Widget _starterCard({
    required String title,
    required String caption,
    required VoidCallback onActivated,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.m),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onActivated,
          borderRadius: BorderRadius.circular(AppRadius.medium),
          child: ECard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: EText.label.large.primary),
                VSpace.s,
                Text(caption, style: EText.body.medium.tertiary),
              ],
            ),
          ),
        ),
      ),
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
        _labeledField(label: 'Medication', controller: _nameController),
        MedicationNameSuggestionChips(
          typedName: _nameController.text,
          onNameSelected: _selectSuggestedMedicationName,
        ),
        VSpace.m,
        _labeledField(label: 'Unit', controller: _unitController),
        VSpace.m,
        _startDateRow(),
        VSpace.m,
        _labeledField(
          label: 'Note',
          controller: _notesController,
          hint: 'from ENT',
        ),
        VSpace.l,
        if (_scheduleKind == ScheduleKind.taper) ..._taperEditor(),
        if (_scheduleKind == ScheduleKind.daily) ..._timesEditor(),
      ],
    );
  }

  EdgeInsets get _editorPadding {
    return EdgeInsets.fromLTRB(
      AppSpacing.m,
      AppSpacing.m,
      AppSpacing.m,
      AppSpacing.l +
          ETabBar.occupiedHeight +
          MediaQuery.paddingOf(context).bottom,
    );
  }

  Widget _labeledField({
    required String label,
    required TextEditingController controller,
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: EText.label.medium),
        VSpace.s,
        TextField(
          controller: controller,
          style: EText.body.medium,
          decoration: _fieldDecoration(hint: hint),
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  Widget _startDateRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Start date', style: EText.label.medium),
        VSpace.s,
        OutlinedButton(
          onPressed: _pickStartDate,
          child: Text(AppDateUtils.formatShortDate(_startDate)),
        ),
      ],
    );
  }

  List<Widget> _taperEditor() {
    return [
      for (final stepIndex in _steps.asMap().keys) ...[
        if (stepIndex > 0)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
            child: Text('then', style: EText.label.medium.tertiary),
          ),
        _taperStepCard(stepIndex),
      ],
      VSpace.m,
      OutlinedButton(onPressed: _addTaperStep, child: const Text('Then')),
    ];
  }

  Widget _taperStepCard(int stepIndex) {
    final step = _steps[stepIndex];
    final dose = step.doses.first;
    return ECard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: dose.amount,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: EText.body.medium,
                  decoration: _fieldDecoration(hint: '40'),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              HSpace.s,
              Text(
                _unitController.text.trim().isEmpty
                    ? 'mg'
                    : _unitController.text.trim(),
              ),
              HSpace.m,
              const Text('for'),
              HSpace.s,
              SizedBox(
                width: 64,
                child: TextField(
                  controller: step.duration,
                  keyboardType: TextInputType.number,
                  style: EText.body.medium,
                  decoration: _fieldDecoration(hint: '7'),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          VSpace.s,
          _partOfDayChoices(dose),
          if (_steps.length > 1)
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                tooltip: 'Remove step',
                onPressed: () => _removeStep(stepIndex),
                icon: const Icon(Icons.delete_outline, color: EColors.danger),
              ),
            ),
        ],
      ),
    );
  }

  Widget _partOfDayChoices(_DoseDraft dose) {
    return Wrap(
      spacing: 8,
      children: PartOfDay.values.map((part) {
        final isSelected =
            dose.when is PartOfDayDoseWhen &&
            (dose.when as PartOfDayDoseWhen).part == part;
        return FilterChip(
          label: Text(
            part.pluralLabel,
            style: isSelected ? EText.label.medium : EText.label.medium.white,
          ),
          selected: isSelected,
          backgroundColor: EColors.surfaceRaised,
          selectedColor: EColors.accentGlow.withValues(alpha: 0.35),
          onSelected: (_) => setState(() {
            dose.when = DoseWhen.partOfDay(part);
          }),
        );
      }).toList(),
    );
  }

  List<Widget> _timesEditor() {
    final step = _steps.first;
    return [
      for (final doseIndex in step.doses.asMap().keys)
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.s),
          child: _timeDoseCard(step, doseIndex),
        ),
      TextButton(onPressed: _addClockDose, child: const Text('Add time')),
    ];
  }

  Widget _timeDoseCard(_StepDraft step, int doseIndex) {
    final dose = step.doses[doseIndex];
    return ECard(
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: dose.amount,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: EText.body.medium,
              decoration: _fieldDecoration(hint: '200'),
              onChanged: (_) => setState(() {}),
            ),
          ),
          HSpace.s,
          Text(
            _unitController.text.trim().isEmpty
                ? 'mg'
                : _unitController.text.trim(),
          ),
          HSpace.m,
          TextButton(
            onPressed: () => _pickClockTime(dose),
            child: Text(dose.when.caption),
          ),
          if (step.doses.length > 1)
            IconButton(
              tooltip: 'Remove time',
              onPressed: () => _removeClockDose(doseIndex),
              icon: const Icon(Icons.delete_outline, color: EColors.danger),
            ),
        ],
      ),
    );
  }

  InputDecoration _fieldDecoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: EText.body.medium.muted,
      filled: true,
      fillColor: EColors.surface,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.m,
        vertical: AppSpacing.s,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.small),
        borderSide: const BorderSide(color: EColors.surfaceRaised),
      ),
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
      _steps.forEach((step) => step.dispose());
      _steps = [
        if (scheduleKind == ScheduleKind.taper)
          _StepDraft.taper(when: const DoseWhen.partOfDay(PartOfDay.morning))
        else
          _StepDraft.dailyTimes(
            when: const DoseWhen.clock(hour: 10, minute: 30),
          ),
      ];
    });
  }

  void _addTaperStep() {
    final previousWhen = _steps.last.doses.first.when;
    setState(() {
      _steps.add(_StepDraft.taper(when: previousWhen));
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
        _DoseDraft(when: const DoseWhen.clock(hour: 20, minute: 0)),
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

  Future<void> _pickClockTime(_DoseDraft dose) async {
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
      unit: _unitController.text.trim().isEmpty
          ? 'mg'
          : _unitController.text.trim(),
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
      final user = await ref.read(currentUserProvider.future);
      if (user == null) throw Exception('User not authenticated');
      final now = DateTime.now();
      final existing = widget.existing;
      final schedule = _draftSchedule(
        id: existing?.id ?? DataUtils.uuid.v4(),
        userId: user.id,
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

class _StepDraft({
  required final String id,
  required final TextEditingController duration,
  required final List<_DoseDraft> doses,
}) {
  factory taper({required DoseWhen when}) {
    return _StepDraft(
      id: DataUtils.uuid.v4(),
      duration: TextEditingController(),
      doses: [_DoseDraft(when: when)],
    );
  }

  factory dailyTimes({required DoseWhen when}) {
    return _StepDraft(
      id: DataUtils.uuid.v4(),
      duration: TextEditingController(),
      doses: [_DoseDraft(when: when)],
    );
  }

  factory fromStep(ScheduleStep step) {
    return _StepDraft(
      id: step.id,
      duration: TextEditingController(
        text: step.durationDays?.toString() ?? '',
      ),
      doses: step.doses.map(_DoseDraft.fromDose).toList(),
    );
  }

  void dispose() {
    duration.dispose();
    doses.forEach((dose) => dose.dispose());
  }

  ScheduleStep toStep() {
    final durationDays = int.tryParse(duration.text.trim());
    return ScheduleStep(
      id: id,
      durationDays: durationDays != null && durationDays > 0
          ? durationDays
          : null,
      doses: doses
          .where((dose) => dose.parsedAmount != null)
          .map((dose) => dose.toDose())
          .toList(),
    );
  }
}

class _DoseDraft({required var DoseWhen when, String amountText = ''}) {
  factory fromDose(ScheduledDose dose) {
    return _DoseDraft(when: dose.when, amountText: _amountText(dose.amount))
      ..id = dose.id;
  }

  static String _amountText(double amount) {
    if (amount == amount.truncateToDouble()) return amount.toInt().toString();
    return amount.toString();
  }

  String id = DataUtils.uuid.v4();
  final TextEditingController amount = TextEditingController(text: amountText);
  double? get parsedAmount {
    final parsed = double.tryParse(amount.text.trim());
    if (parsed == null || parsed <= 0) return null;
    return parsed;
  }

  void dispose() => amount.dispose();

  ScheduledDose toDose() {
    return ScheduledDose(id: id, amount: parsedAmount ?? 0, when: when);
  }
}
