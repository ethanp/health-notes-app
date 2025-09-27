import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_notes/models/drug_dose.dart';
import 'package:health_notes/models/health_note.dart';
import 'package:health_notes/models/symptom.dart';
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
  Map<int, DrugDoseControllers> _drugDoseControllers = {};
  Map<int, SymptomControllers> _symptomControllers = {};
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
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textTertiary,
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
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
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
          Text(
            dose.displayDosage,
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textTertiary),
          ),
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
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
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
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textPrimary,
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
      decoration: AppComponents.primaryCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.isEditable) symptomSuggestions(index),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: CupertinoTextField(
                  controller: controllers.majorComponent,
                  placeholder: 'Major component (e.g., headache)',
                  placeholderStyle: AppTypography.inputPlaceholder,
                  style: AppTypography.input,
                  onChanged: (value) =>
                      updateSymptom(index, majorComponent: value),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CupertinoTextField(
                  controller: controllers.minorComponent,
                  placeholder: 'Minor component (e.g., right temple)',
                  placeholderStyle: AppTypography.inputPlaceholder,
                  style: AppTypography.input,
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
          ),
          const SizedBox(height: 8),
          CupertinoTextField(
            controller: controllers.additionalNotes,
            placeholder: 'Additional notes (optional)',
            placeholderStyle: AppTypography.inputPlaceholder,
            style: AppTypography.input,
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
