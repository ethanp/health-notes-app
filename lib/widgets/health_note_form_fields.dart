import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_notes/models/drug_dose.dart';
import 'package:health_notes/models/health_note.dart';
import 'package:health_notes/models/symptom.dart';
import 'package:health_notes/providers/symptom_suggestions_provider.dart';
import 'package:health_notes/services/symptom_suggestions_service.dart';
import 'package:health_notes/theme/app_theme.dart';
import 'package:health_notes/widgets/enhanced_ui_components.dart';
import 'package:intl/intl.dart';

class HealthNoteFormFields extends ConsumerStatefulWidget {
  final HealthNote? note;
  final bool isEditable;
  final Function(DateTime)? onDateTimeChanged;
  final Function(String)? onSymptomsChanged;
  final Function(String)? onNotesChanged;
  final Function(List<DrugDose>)? onDrugDosesChanged;
  final VoidCallback? onAddDrugDose;
  final Function(int)? onRemoveDrugDose;
  final Function(int, {String? name, double? dosage, String? unit})?
  onUpdateDrugDose;

  const HealthNoteFormFields({
    super.key,
    this.note,
    required this.isEditable,
    this.onDateTimeChanged,
    this.onSymptomsChanged,
    this.onNotesChanged,
    this.onDrugDosesChanged,
    this.onAddDrugDose,
    this.onRemoveDrugDose,
    this.onUpdateDrugDose,
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
  Map<int, DrugDoseControllers> _drugDoseControllers = {};
  Map<int, SymptomControllers> _symptomControllers = {};

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

    if (widget.note != null) {
      final note = widget.note!;
      _notesController = TextEditingController(text: note.notes);
      _selectedDateTime = note.dateTime;
      _drugDoses = List.from(note.drugDoses);
      _symptoms = List.from(note.symptomsList);
    } else {
      _notesController = TextEditingController();
      _selectedDateTime = DateTime.now();
      _drugDoses = <DrugDose>[];
      _symptoms = <Symptom>[];
    }

    _drugDoseControllers = _drugDoses.asMap().map(
      (key, value) => MapEntry(key, DrugDoseControllers(value)),
    );
    _symptomControllers = _symptoms.asMap().map(
      (key, value) => MapEntry(key, SymptomControllers(value)),
    );
  }

  @override
  void dispose() {
    _notesController?.dispose();
    _drugDoseControllers.values.forEach((controllers) => controllers.dispose());
    _symptomControllers.values.forEach((controllers) => controllers.dispose());
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
        notesSection(),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget dateTimeSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.primaryCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Date & Time', style: AppTheme.headlineSmall),
          const SizedBox(height: 16),
          if (widget.isEditable)
            Container(
              height: 200,
              decoration: AppTheme.inputField,
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.dateAndTime,
                initialDateTime: _selectedDateTime,
                backgroundColor: AppTheme.backgroundTertiary,
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
                  style: AppTheme.headlineSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('h:mm a').format(_selectedDateTime),
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.textTertiary,
                  ),
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
          ? AppTheme.inputField
          : AppTheme.primaryCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EnhancedUIComponents.sectionHeader(
            title: 'Symptoms',
            trailing: widget.isEditable
                ? CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: addSymptom,
                    child: const Icon(CupertinoIcons.add),
                  )
                : null,
          ),
          const SizedBox(height: 8),
          if (_symptoms.isEmpty)
            Text('No symptoms recorded', style: AppTheme.bodyMedium)
          else if (!widget.isEditable)
            ..._symptoms.map(
              (symptom) => Padding(
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
                            color: AppTheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            symptom.fullDescription,
                            style: AppTheme.labelLarge,
                          ),
                        ),
                        EnhancedUIComponents.statusIndicator(
                          text: '${symptom.severityLevel}/10',
                          color: AppTheme.primary,
                        ),
                      ],
                    ),
                    if (symptom.additionalNotes.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.only(left: 20),
                        child: Text(
                          symptom.additionalNotes,
                          style: AppTheme.bodyMedium.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            )
          else if (widget.isEditable)
            ..._symptoms.asMap().entries.map((entry) {
              final index = entry.key;
              final symptom = entry.value;
              return editableSymptomItem(
                index: index,
                symptom: symptom,
                controllers: _symptomControllers[index]!,
              );
            }),
        ],
      ),
    );
  }

  Widget drugDosesSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: widget.isEditable
          ? AppTheme.inputField
          : AppTheme.primaryCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EnhancedUIComponents.sectionHeader(
            title: 'Medications',
            trailing: widget.isEditable
                ? CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: addDrugDose,
                    child: const Icon(CupertinoIcons.add),
                  )
                : null,
          ),
          const SizedBox(height: 8),
          if (_drugDoses.isEmpty)
            Text('No medications recorded', style: AppTheme.bodyMedium)
          else if (!widget.isEditable)
            ..._drugDoses.map(
              (dose) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppTheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(dose.name, style: AppTheme.labelLarge),
                    ),
                    Text(
                      dose.displayDosage,
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (widget.isEditable)
            ..._drugDoses.asMap().entries.map((entry) {
              final index = entry.key;
              final dose = entry.value;
              return editableDrugDoseItem(
                index: index,
                dose: dose,
                controllers: _drugDoseControllers[index]!,
              );
            }),
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
      decoration: AppTheme.primaryCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: CupertinoTextField(
                  controller: controllers.name,
                  placeholder: 'Medication name',
                  placeholderStyle: AppTheme.inputPlaceholder,
                  style: AppTheme.input,
                  onChanged: (value) => updateDrugDose(index, name: value),
                ),
              ),
              const SizedBox(width: 8),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => removeDrugDose(index),
                child: const Icon(
                  CupertinoIcons.delete,
                  color: AppTheme.destructive,
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
                  placeholderStyle: AppTheme.inputPlaceholder,
                  style: AppTheme.input,
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
                  placeholderStyle: AppTheme.inputPlaceholder,
                  style: AppTheme.input,
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
          ? AppTheme.inputField
          : AppTheme.primaryCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Notes', style: AppTheme.labelLarge),
          const SizedBox(height: 8),
          if (widget.isEditable)
            CupertinoTextField(
              controller: _notesController!,
              placeholder: 'Additional Notes (optional)',
              placeholderStyle: AppTheme.inputPlaceholder,
              style: AppTheme.input,
              maxLines: 4,
              onChanged: widget.onNotesChanged,
            )
          else
            Text(
              _notesController?.text.isNotEmpty == true
                  ? _notesController!.text
                  : 'No additional notes',
              style: AppTheme.bodyMedium,
            ),
        ],
      ),
    );
  }

  DateTime get currentDateTime => _selectedDateTime;
  List<Symptom> get currentSymptoms => _symptoms;
  String get currentNotes => _notesController?.text ?? '';
  List<DrugDose> get currentDrugDoses => _drugDoses;

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
      if (_drugDoseControllers.containsKey(index)) {
        _drugDoseControllers[index]!.dispose();
        _drugDoseControllers.remove(index);
      }
      _drugDoses.removeAt(index);
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
      if (_symptomControllers.containsKey(index)) {
        _symptomControllers[index]!.dispose();
        _symptomControllers.remove(index);
      }
      _symptoms.removeAt(index);
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
      _symptoms[index] = Symptom(
        severityLevel: severityLevel ?? currentSymptom.severityLevel,
        majorComponent: majorComponent ?? currentSymptom.majorComponent,
        minorComponent: minorComponent ?? currentSymptom.minorComponent,
        additionalNotes: additionalNotes ?? currentSymptom.additionalNotes,
      );
    });
  }

  Widget symptomSuggestions() {
    return Consumer(
      builder: (context, ref, child) {
        final suggestionsAsync = ref.watch(symptomSuggestionsProvider);

        return suggestionsAsync.when(
          data: (suggestions) {
            if (suggestions.isEmpty) return const SizedBox.shrink();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recent symptoms:',
                  style: AppTheme.labelMedium.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: suggestions.map((suggestion) {
                    return CupertinoButton(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      color: AppTheme.backgroundSecondary,
                      borderRadius: BorderRadius.circular(16),
                      onPressed: () {
                        final newSymptom =
                            SymptomSuggestionsService.createSymptomFromSuggestion(
                              suggestion,
                            );
                        setState(() {
                          _symptoms[0] = newSymptom;
                          _symptomControllers[0] = SymptomControllers(
                            newSymptom,
                          );
                        });
                      },
                      child: Text(
                        suggestion.toString(),
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.textPrimary,
                        ),
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
      decoration: AppTheme.primaryCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (index == 0 && widget.note == null) symptomSuggestions(),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: CupertinoTextField(
                  controller: controllers.majorComponent,
                  placeholder: 'Major component (e.g., headache)',
                  placeholderStyle: AppTheme.inputPlaceholder,
                  style: AppTheme.input,
                  onChanged: (value) =>
                      updateSymptom(index, majorComponent: value),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CupertinoTextField(
                  controller: controllers.minorComponent,
                  placeholder: 'Minor component (e.g., right temple)',
                  placeholderStyle: AppTheme.inputPlaceholder,
                  style: AppTheme.input,
                  onChanged: (value) =>
                      updateSymptom(index, minorComponent: value),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 80,
                child: CupertinoTextField(
                  controller: controllers.severity,
                  placeholder: '1-10',
                  placeholderStyle: AppTheme.inputPlaceholder,
                  style: AppTheme.input,
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
          ),
          const SizedBox(height: 8),
          CupertinoTextField(
            controller: controllers.additionalNotes,
            placeholder: 'Additional notes (optional)',
            placeholderStyle: AppTheme.inputPlaceholder,
            style: AppTheme.input,
            maxLines: 2,
            onChanged: (value) => updateSymptom(index, additionalNotes: value),
          ),
        ],
      ),
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
