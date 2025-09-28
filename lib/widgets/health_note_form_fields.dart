import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_notes/models/drug_dose.dart';
import 'package:health_notes/models/health_note.dart';
import 'package:health_notes/models/symptom.dart';
import 'package:health_notes/models/applied_tool.dart';
import 'package:health_notes/models/health_tool.dart';
import 'package:health_notes/providers/health_tools_provider.dart';
import 'package:health_notes/providers/symptom_suggestions_provider.dart';
import 'package:health_notes/services/symptom_suggestions_service.dart';
import 'package:health_notes/services/text_normalizer.dart';
import 'package:health_notes/theme/app_theme.dart';

import 'package:health_notes/widgets/enhanced_ui_components.dart';
import 'package:intl/intl.dart';

class HealthNoteFormFields extends ConsumerStatefulWidget {
  final HealthNote? note;
  final bool isEditable;
  final Function(DateTime)? onDateTimeChanged;
  final Function(String)? onNotesChanged;
  final Function(List<DrugDose>)? onDrugDosesChanged;

  const HealthNoteFormFields({
    super.key,
    this.note,
    required this.isEditable,
    this.onDateTimeChanged,
    this.onNotesChanged,
    this.onDrugDosesChanged,
  });

  @override
  ConsumerState<HealthNoteFormFields> createState() =>
      HealthNoteFormFieldsState();
}

class HealthNoteFormFieldsState extends ConsumerState<HealthNoteFormFields> {
  TextEditingController? _notesController;
  late DateTime _selectedDateTime;
  late List<DrugDose> _drugDoses;
  late List<Symptom> _symptoms;
  late List<AppliedTool> _appliedTools;
  Map<int, DrugDoseControllers> _drugDoseControllers = {};
  Map<int, SymptomControllers> _symptomControllers = {};
  Map<int, TextEditingController> _appliedToolNoteControllers = {};
  final Set<String> _usedSuggestions = {};

  @override
  void initState() {
    super.initState();
    initializeControllers();
  }

  @override
  void didUpdateWidget(HealthNoteFormFields oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.note?.id != widget.note?.id ||
        oldWidget.note?.dateTime != widget.note?.dateTime ||
        oldWidget.note?.notes != widget.note?.notes ||
        !_areListsEqual(
          oldWidget.note?.drugDoses ?? [],
          widget.note?.drugDoses ?? [],
        ) ||
        !_areSymptomListsEqual(
          oldWidget.note?.symptomsList ?? [],
          widget.note?.symptomsList ?? [],
        )) {
      initializeControllers();
    }
  }

  bool _areListsEqual(List<DrugDose> list1, List<DrugDose> list2) {
    if (list1.length != list2.length) return false;
    return list1.asMap().entries.every((entry) {
      final i = entry.key;
      final dose1 = entry.value;
      final dose2 = list2[i];
      return dose1.name == dose2.name &&
          dose1.dosage == dose2.dosage &&
          dose1.unit == dose2.unit;
    });
  }

  bool _areSymptomListsEqual(List<Symptom> list1, List<Symptom> list2) {
    if (list1.length != list2.length) return false;
    return list1.asMap().entries.every((entry) {
      final i = entry.key;
      final symptom1 = entry.value;
      final symptom2 = list2[i];
      return symptom1.majorComponent == symptom2.majorComponent &&
          symptom1.minorComponent == symptom2.minorComponent &&
          symptom1.severityLevel == symptom2.severityLevel;
    });
  }

  void initializeControllers() {
    _notesController?.dispose();
    if (_drugDoseControllers.isNotEmpty) {
      _drugDoseControllers.values.forEach(
        (controllers) => controllers.dispose(),
      );
    }
    if (_symptomControllers.isNotEmpty) {
      _symptomControllers.values.forEach(
        (controllers) => controllers.dispose(),
      );
    }

    _drugDoseControllers.clear();
    _symptomControllers.clear();
    _usedSuggestions.clear();

    if (widget.note != null) {
      final note = widget.note!;
      _notesController = TextEditingController(text: note.notes);
      _selectedDateTime = note.dateTime;
      _drugDoses = List.from(note.drugDoses);
      _symptoms = List.from(note.symptomsList);
      _appliedTools = List.from(note.appliedTools);
    } else {
      _notesController = TextEditingController();
      _selectedDateTime = DateTime.now();
      _drugDoses = <DrugDose>[];
      _symptoms = <Symptom>[];
      _appliedTools = <AppliedTool>[];
    }

    _drugDoseControllers = _drugDoses.asMap().map(
      (key, value) => MapEntry(key, DrugDoseControllers(value)),
    );
    _symptomControllers = _symptoms.asMap().map(
      (key, value) => MapEntry(key, SymptomControllers(value)),
    );

    _appliedToolNoteControllers = _appliedTools.asMap().map(
      (key, value) => MapEntry(key, TextEditingController(text: value.note)),
    );

    for (final symptom in _symptoms) {
      if (symptom.majorComponent.isNotEmpty ||
          symptom.minorComponent.isNotEmpty) {
        final key = SymptomNormalizer.generateKey(
          symptom.majorComponent,
          symptom.minorComponent,
        );
        _usedSuggestions.add(key);
      }
    }
  }

  @override
  void dispose() {
    _notesController?.dispose();
    _drugDoseControllers.values.forEach((controllers) => controllers.dispose());
    _symptomControllers.values.forEach((controllers) => controllers.dispose());
    _appliedToolNoteControllers.values.forEach((c) => c.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 20),
        dateTimeSection(),
        const SizedBox(height: 20),
        symptomsSection(),
        const SizedBox(height: 16),
        drugDosesSection(),
        const SizedBox(height: 16),
        appliedToolsSection(),
        const SizedBox(height: 16),
        notesSection(),
        const SizedBox(height: 40),
      ],
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
          if (widget.isEditable)
            Container(
              height: 200,
              decoration: AppComponents.inputField,
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.dateAndTime,
                initialDateTime: _selectedDateTime,
                backgroundColor: AppColors.backgroundTertiary,
                onDateTimeChanged: (DateTime newDateTime) {
                  setState(() => _selectedDateTime = newDateTime);
                  widget.onDateTimeChanged?.call(newDateTime);
                },
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('EEEE, MMMM d, yyyy').format(_selectedDateTime),
                  style: AppTypography.headlineSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('h:mm a').format(_selectedDateTime),
                  style: AppTypography.bodyMediumTertiary,
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget symptomsSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: widget.isEditable
          ? AppComponents.inputField
          : AppComponents.primaryCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          symptomsHeader(),
          const SizedBox(height: 8),
          symptomsContent(),
        ],
      ),
    );
  }

  Widget symptomsHeader() {
    return EnhancedUIComponents.sectionHeader(
      title: 'Symptoms',
      trailing: widget.isEditable
          ? CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: addSymptom,
              child: const Icon(CupertinoIcons.add),
            )
          : null,
    );
  }

  Widget symptomsContent() {
    if (_symptoms.isEmpty) {
      return Text('No symptoms recorded', style: AppTypography.bodyMedium);
    }

    if (!widget.isEditable) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _symptoms.map(readOnlySymptomItem).toList(),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _symptoms.asMap().entries.map((entry) {
        final index = entry.key;
        final symptom = entry.value;
        return editableSymptomItem(
          index: index,
          symptom: symptom,
          controllers: _symptomControllers[index]!,
        );
      }).toList(),
    );
  }

  Widget readOnlySymptomItem(Symptom symptom) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  symptom.fullDescription,
                  style: AppTypography.labelLarge,
                ),
              ),
              EnhancedUIComponents.statusIndicator(
                text: '${symptom.severityLevel}/10',
                color: AppColors.primary,
              ),
            ],
          ),
          if (symptom.additionalNotes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 20),
              child: Text(
                symptom.additionalNotes,
                style: AppTypography.bodyMediumSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget drugDosesSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: widget.isEditable
          ? AppComponents.inputField
          : AppComponents.primaryCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          drugDosesHeader(),
          const SizedBox(height: 8),
          drugDosesContent(),
        ],
      ),
    );
  }

  Widget appliedToolsSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: widget.isEditable
          ? AppComponents.inputField
          : AppComponents.primaryCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          appliedToolsHeader(),
          const SizedBox(height: 8),
          appliedToolsContent(),
        ],
      ),
    );
  }

  Widget appliedToolsHeader() {
    return EnhancedUIComponents.sectionHeader(
      title: 'Applied Tools',
      trailing: widget.isEditable
          ? CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: showToolPicker,
              child: const Icon(CupertinoIcons.add),
            )
          : null,
    );
  }

  Widget appliedToolsContent() {
    if (_appliedTools.isEmpty) {
      return Text('No tools applied', style: AppTypography.bodyMedium);
    }

    if (!widget.isEditable) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _appliedTools.map(readOnlyAppliedToolItem).toList(),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _appliedTools.asMap().entries.map((entry) {
        final index = entry.key;
        final tool = entry.value;
        final controller = _appliedToolNoteControllers[index]!;
        return editableAppliedToolItem(
          index: index,
          tool: tool,
          noteController: controller,
        );
      }).toList(),
    );
  }

  Widget readOnlyAppliedToolItem(AppliedTool tool) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(tool.toolName, style: AppTypography.labelLarge),
              ),
            ],
          ),
          if (tool.note.isNotEmpty) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 20),
              child: Text(tool.note, style: AppTypography.bodyMediumSecondary),
            ),
          ],
        ],
      ),
    );
  }

  Widget editableAppliedToolItem({
    required int index,
    required AppliedTool tool,
    required TextEditingController noteController,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: AppComponents.primaryCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(tool.toolName, style: AppTypography.labelLarge),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => removeAppliedTool(index),
                child: const Icon(
                  CupertinoIcons.delete,
                  color: AppColors.destructive,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          CupertinoTextField(
            controller: noteController,
            placeholder: 'Note for this tool (optional)',
            placeholderStyle: AppTypography.inputPlaceholder,
            style: AppTypography.input,
            maxLines: 2,
            onChanged: (value) => updateAppliedToolNote(index, value),
          ),
        ],
      ),
    );
  }

  void showToolPicker() {
    final searchController = TextEditingController();
    showCupertinoModalPopup(
      context: context,
      builder: (context) {
        return Align(
          alignment: Alignment.bottomCenter,
          child: FractionallySizedBox(
            heightFactor: 0.7,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppRadius.extraLarge),
                topRight: Radius.circular(AppRadius.extraLarge),
              ),
              child: Container(
                color: AppColors.backgroundSecondary,
                child: StatefulBuilder(
                  builder: (context, setSheetState) {
                    return SafeArea(
                      top: false,
                      child: Column(
                        children: [
                          const SizedBox(height: 8),
                          Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppColors.backgroundQuinary,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.m,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Select a tool',
                                    style: AppTypography.headlineSmall,
                                  ),
                                ),
                                CupertinoButton(
                                  padding: EdgeInsets.zero,
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Icon(CupertinoIcons.xmark),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.m,
                            ),
                            child: EnhancedUIComponents.searchField(
                              controller: searchController,
                              placeholder: 'Search tools',
                              onChanged: (_) => setSheetState(() {}),
                              showSuffix: searchController.text.isNotEmpty,
                              onSuffixTap: () {
                                searchController.clear();
                                setSheetState(() {});
                              },
                            ),
                          ),
                          const SizedBox(height: AppSpacing.s),
                          Expanded(
                            child: Consumer(
                              builder: (context, ref, _) {
                                final toolsAsync = ref.watch(
                                  healthToolsNotifierProvider,
                                );
                                return toolsAsync.when(
                                  data: (tools) {
                                    final q = searchController.text
                                        .trim()
                                        .toLowerCase();
                                    final filtered = q.isEmpty
                                        ? tools
                                        : tools
                                              .where(
                                                (t) => t.name
                                                    .toLowerCase()
                                                    .contains(q),
                                              )
                                              .toList();
                                    if (filtered.isEmpty) {
                                      return EnhancedUIComponents.emptyState(
                                        title: 'No tools found',
                                        message:
                                            'Try a different search or add tools in My Tools',
                                        icon: CupertinoIcons.search,
                                      );
                                    }
                                    return ListView.separated(
                                      padding: const EdgeInsets.all(
                                        AppSpacing.m,
                                      ),
                                      itemBuilder: (context, i) {
                                        final t = filtered[i];
                                        final isAlreadySelected = _appliedTools
                                            .any((at) => at.toolId == t.id);
                                        return GestureDetector(
                                          onTap: () {
                                            if (!isAlreadySelected) {
                                              addAppliedToolFromHealthTool(t);
                                            }
                                            Navigator.of(context).pop();
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.all(14),
                                            decoration: AppComponents
                                                .primaryCardWithBorder,
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        t.name,
                                                        style: AppTypography
                                                            .labelLarge,
                                                      ),
                                                      const SizedBox(
                                                        height: AppSpacing.xs,
                                                      ),
                                                      Text(
                                                        t.description,
                                                        style: AppTypography
                                                            .bodySmallSecondary,
                                                        maxLines: 2,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(
                                                  width: AppSpacing.m,
                                                ),
                                                if (isAlreadySelected)
                                                  Text(
                                                    'Selected',
                                                    style: AppTypography
                                                        .bodySmallSystemGreySemibold,
                                                  ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                      separatorBuilder: (_, __) =>
                                          const SizedBox(height: AppSpacing.s),
                                      itemCount: filtered.length,
                                    );
                                  },
                                  loading: () =>
                                      EnhancedUIComponents.loadingIndicator(
                                        message: 'Loading tools...',
                                      ),
                                  error: (e, st) => Center(
                                    child: Text(
                                      'Error: $e',
                                      style: AppTypography.error,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void addAppliedToolFromHealthTool(HealthTool t) {
    setState(() {
      _appliedTools.add(AppliedTool(toolId: t.id, toolName: t.name, note: ''));
      _appliedToolNoteControllers[_appliedTools.length - 1] =
          TextEditingController(text: '');
    });
  }

  void removeAppliedTool(int index) {
    setState(() {
      _appliedToolNoteControllers[index]?.dispose();
      _appliedToolNoteControllers.remove(index);
      _appliedTools.removeAt(index);
      _appliedToolNoteControllers = _appliedTools.asMap().map(
        (key, value) => MapEntry(
          key,
          _appliedToolNoteControllers[key] ??
              TextEditingController(text: value.note),
        ),
      );
    });
  }

  void updateAppliedToolNote(int index, String value) {
    setState(() {
      final current = _appliedTools[index];
      _appliedTools[index] = current.copyWith(note: value);
    });
  }

  Widget drugDosesHeader() {
    return EnhancedUIComponents.sectionHeader(
      title: 'Medications',
      trailing: widget.isEditable
          ? CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: addDrugDose,
              child: const Icon(CupertinoIcons.add),
            )
          : null,
    );
  }

  Widget drugDosesContent() {
    if (_drugDoses.isEmpty) {
      return Text('No medications recorded', style: AppTypography.bodyMedium);
    }

    if (!widget.isEditable) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _drugDoses.map(readOnlyDrugDoseItem).toList(),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _drugDoses.asMap().entries.map((entry) {
        final index = entry.key;
        final dose = entry.value;
        return editableDrugDoseItem(
          index: index,
          dose: dose,
          controllers: _drugDoseControllers[index]!,
        );
      }).toList(),
    );
  }

  Widget readOnlyDrugDoseItem(DrugDose dose) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(dose.name, style: AppTypography.labelLarge)),
          Text(dose.displayDosage, style: AppTypography.bodyMediumTertiary),
        ],
      ),
    );
  }

  Widget editableDrugDoseItem({
    required int index,
    required DrugDose dose,
    required DrugDoseControllers controllers,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: AppComponents.primaryCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: CupertinoTextField(
                  controller: controllers.name,
                  placeholder: 'Medication name',
                  placeholderStyle: AppTypography.inputPlaceholder,
                  style: AppTypography.input,
                  onChanged: (value) => updateDrugDose(index, name: value),
                ),
              ),
              const SizedBox(width: 8),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => removeDrugDose(index),
                child: const Icon(
                  CupertinoIcons.delete,
                  color: AppColors.destructive,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: CupertinoTextField(
                  controller: controllers.dosage,
                  placeholder: 'Dosage',
                  placeholderStyle: AppTypography.inputPlaceholder,
                  style: AppTypography.input,
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    final dosage = double.tryParse(value) ?? 0.0;
                    updateDrugDose(index, dosage: dosage);
                  },
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 80,
                child: CupertinoTextField(
                  controller: controllers.unit,
                  placeholder: 'Unit',
                  placeholderStyle: AppTypography.inputPlaceholder,
                  style: AppTypography.input,
                  onChanged: (value) => updateDrugDose(index, unit: value),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget notesSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: widget.isEditable
          ? AppComponents.inputField
          : AppComponents.primaryCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [notesHeader(), const SizedBox(height: 8), notesContent()],
      ),
    );
  }

  Widget notesHeader() {
    return Text('Notes', style: AppTypography.labelLarge);
  }

  Widget notesContent() {
    if (widget.isEditable) {
      return CupertinoTextField(
        controller: _notesController!,
        placeholder: 'Additional Notes (optional)',
        placeholderStyle: AppTypography.inputPlaceholder,
        style: AppTypography.input,
        maxLines: 4,
        onChanged: widget.onNotesChanged,
      );
    }

    final text = _notesController?.text.isNotEmpty == true
        ? _notesController!.text
        : 'No additional notes';
    return Text(text, style: AppTypography.bodyMedium);
  }

  DateTime get currentDateTime => _selectedDateTime;
  List<Symptom> get currentSymptoms => _symptoms;
  String get currentNotes => _notesController?.text ?? '';
  List<DrugDose> get currentDrugDoses => _drugDoses;
  List<AppliedTool> get currentAppliedTools => _appliedTools;

  void addDrugDose() {
    setState(() {
      final newIndex = _drugDoses.length;
      _drugDoses.add(DrugDoseExtensions.empty);
      _drugDoseControllers[newIndex] = DrugDoseControllers(
        _drugDoses[newIndex],
      );
    });
    widget.onDrugDosesChanged?.call(_drugDoses);
  }

  void removeDrugDose(int index) {
    setState(() {
      _drugDoseControllers.values.forEach(
        (controllers) => controllers.dispose(),
      );
      _drugDoseControllers.clear();
      _drugDoses.removeAt(index);
      _drugDoseControllers = _drugDoses.asMap().map(
        (key, value) => MapEntry(key, DrugDoseControllers(value)),
      );
    });
    widget.onDrugDosesChanged?.call(_drugDoses);
  }

  void updateDrugDose(int index, {String? name, double? dosage, String? unit}) {
    setState(() {
      final currentDose = _drugDoses[index];
      _drugDoses[index] = DrugDose(
        name: name ?? currentDose.name,
        dosage: dosage ?? currentDose.dosage,
        unit: unit ?? currentDose.unit,
      );
    });
    widget.onDrugDosesChanged?.call(_drugDoses);
  }

  void addSymptom() {
    setState(() {
      final newIndex = _symptoms.length;
      _symptoms.add(SymptomExtensions.empty);
      _symptomControllers[newIndex] = SymptomControllers(_symptoms[newIndex]);
    });
  }

  void removeSymptom(int index) {
    setState(() {
      final symptom = _symptoms[index];
      if (symptom.majorComponent.isNotEmpty ||
          symptom.minorComponent.isNotEmpty) {
        final key = SymptomNormalizer.generateKey(
          symptom.majorComponent,
          symptom.minorComponent,
        );
        _usedSuggestions.remove(key);
      }

      _symptomControllers.values.forEach(
        (controllers) => controllers.dispose(),
      );
      _symptomControllers.clear();

      _symptoms.removeAt(index);

      _symptomControllers = _symptoms.asMap().map(
        (key, value) => MapEntry(key, SymptomControllers(value)),
      );
    });
  }

  void updateSymptom(
    int index, {
    int? severityLevel,
    String? majorComponent,
    String? minorComponent,
    String? additionalNotes,
  }) {
    setState(() {
      final currentSymptom = _symptoms[index];
      final oldKey = SymptomNormalizer.generateKey(
        currentSymptom.majorComponent,
        currentSymptom.minorComponent,
      );

      final newSymptom = Symptom(
        severityLevel: severityLevel ?? currentSymptom.severityLevel,
        majorComponent: majorComponent ?? currentSymptom.majorComponent,
        minorComponent: minorComponent ?? currentSymptom.minorComponent,
        additionalNotes: additionalNotes ?? currentSymptom.additionalNotes,
      );

      _symptoms[index] = newSymptom;

      if (oldKey.isNotEmpty && oldKey != '|') {
        _usedSuggestions.remove(oldKey);
      }

      if (newSymptom.majorComponent.isNotEmpty ||
          newSymptom.minorComponent.isNotEmpty) {
        final newKey = SymptomNormalizer.generateKey(
          newSymptom.majorComponent,
          newSymptom.minorComponent,
        );
        _usedSuggestions.add(newKey);
      }
    });
  }

  Widget symptomSuggestions(int index) {
    final symptom = _symptoms[index];

    if (symptom.majorComponent.isNotEmpty ||
        symptom.minorComponent.isNotEmpty) {
      return const SizedBox.shrink();
    }

    return Consumer(
      builder: (context, ref, child) {
        final suggestionsAsync = ref.watch(symptomSuggestionsProvider);

        return suggestionsAsync.when(
          data: (suggestions) {
            final availableSuggestions = suggestions.where((suggestion) {
              final suggestionKey = SymptomNormalizer.generateKey(
                suggestion.majorComponent,
                suggestion.minorComponent,
              );
              return !_usedSuggestions.contains(suggestionKey);
            }).toList();

            if (availableSuggestions.isEmpty) return const SizedBox.shrink();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recent symptoms:',
                  style: AppTypography.labelMediumSecondary,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: availableSuggestions.map((suggestion) {
                    return CupertinoButton(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      color: AppColors.backgroundSecondary,
                      borderRadius: BorderRadius.circular(16),
                      onPressed: () {
                        final newSymptom =
                            SymptomSuggestionsService.createSymptomFromSuggestion(
                              suggestion,
                            );
                        final suggestionKey = SymptomNormalizer.generateKey(
                          suggestion.majorComponent,
                          suggestion.minorComponent,
                        );
                        setState(() {
                          _symptoms[index] = newSymptom;
                          _symptomControllers[index] = SymptomControllers(
                            newSymptom,
                          );
                          _usedSuggestions.add(suggestionKey);
                        });
                      },
                      child: Text(
                        suggestion.toString(),
                        style: AppTypography.bodySmallPrimary,
                      ),
                    );
                  }).toList(),
                ),
              ],
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (error, stack) => const SizedBox.shrink(),
        );
      },
    );
  }

  Widget editableSymptomItem({
    required int index,
    required Symptom symptom,
    required SymptomControllers controllers,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: AppComponents.primaryCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.isEditable) symptomSuggestions(index),
          const SizedBox(height: 8),
          editableSymptomRow(index, controllers),
          const SizedBox(height: 8),
          editableSymptomNotes(index, controllers),
        ],
      ),
    );
  }

  Widget editableSymptomRow(int index, SymptomControllers controllers) {
    return Row(
      children: [
        Expanded(
          child: CupertinoTextField(
            controller: controllers.majorComponent,
            placeholder: 'Major component (e.g., headache)',
            placeholderStyle: AppTypography.inputPlaceholder,
            style: AppTypography.input,
            onChanged: (value) => updateSymptom(index, majorComponent: value),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: CupertinoTextField(
            controller: controllers.minorComponent,
            placeholder: 'Minor component (e.g., right temple)',
            placeholderStyle: AppTypography.inputPlaceholder,
            style: AppTypography.input,
            onChanged: (value) => updateSymptom(index, minorComponent: value),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 80,
          child: CupertinoTextField(
            controller: controllers.severity,
            placeholder: '1-10',
            placeholderStyle: AppTypography.inputPlaceholder,
            style: AppTypography.input,
            keyboardType: TextInputType.number,
            onChanged: (value) {
              final severity = int.tryParse(value);
              if (severity != null && severity >= 1 && severity <= 10) {
                updateSymptom(index, severityLevel: severity);
              }
            },
          ),
        ),
        const SizedBox(width: 8),
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => removeSymptom(index),
          child: const Icon(
            CupertinoIcons.delete,
            color: CupertinoColors.destructiveRed,
          ),
        ),
      ],
    );
  }

  Widget editableSymptomNotes(int index, SymptomControllers controllers) {
    return CupertinoTextField(
      controller: controllers.additionalNotes,
      placeholder: 'Additional notes (optional)',
      placeholderStyle: AppTypography.inputPlaceholder,
      style: AppTypography.input,
      maxLines: 2,
      onChanged: (value) => updateSymptom(index, additionalNotes: value),
    );
  }
}

class DrugDoseControllers {
  final TextEditingController name;
  final TextEditingController dosage;
  final TextEditingController unit;

  DrugDoseControllers(DrugDose dose)
    : name = TextEditingController(text: dose.name),
      dosage = TextEditingController(text: dose.dosage.toString()),
      unit = TextEditingController(text: dose.unit);

  void dispose() {
    name.dispose();
    dosage.dispose();
    unit.dispose();
  }
}

class SymptomControllers {
  final TextEditingController majorComponent;
  final TextEditingController minorComponent;
  final TextEditingController severity;
  final TextEditingController additionalNotes;

  SymptomControllers(Symptom symptom)
    : majorComponent = TextEditingController(text: symptom.majorComponent),
      minorComponent = TextEditingController(text: symptom.minorComponent),
      severity = TextEditingController(text: symptom.severityLevel.toString()),
      additionalNotes = TextEditingController(text: symptom.additionalNotes);

  void dispose() {
    majorComponent.dispose();
    minorComponent.dispose();
    severity.dispose();
    additionalNotes.dispose();
  }
}
