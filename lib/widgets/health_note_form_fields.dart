import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_notes/models/drug_dose.dart';
import 'package:health_notes/models/health_note.dart';
import 'package:health_notes/models/symptom.dart';
import 'package:health_notes/models/applied_tool.dart';
import 'package:health_notes/models/health_tool.dart';
import 'package:health_notes/services/text_normalizer.dart';
import 'package:health_notes/widgets/health_note_form/applied_tools_section.dart';
import 'package:health_notes/widgets/health_note_form/date_time_section.dart';
import 'package:health_notes/widgets/health_note_form/form_controllers.dart';
import 'package:health_notes/widgets/health_note_form/general_notes_section.dart';
import 'package:health_notes/widgets/health_note_form/medications_section.dart';
import 'package:health_notes/widgets/health_note_form/symptoms_section.dart';
import 'package:health_notes/providers/medication_recommendations_provider.dart';

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
    final recommendations = ref.watch(medicationRecommendationsProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 20),
        DateTimeSection(
          isEditable: widget.isEditable,
          selectedDateTime: _selectedDateTime,
          onDateTimeChanged: (newDateTime) {
            setState(() => _selectedDateTime = newDateTime);
            widget.onDateTimeChanged?.call(newDateTime);
          },
        ),
        const SizedBox(height: 20),
        SymptomsSection(
          isEditable: widget.isEditable,
          symptoms: _symptoms,
          controllers: _symptomControllers,
          usedSuggestions: _usedSuggestions,
          onAdd: addSymptom,
          onRemove: removeSymptom,
          onUpdateFromSuggestion: updateSymptomFromSuggestion,
          onUpdate: updateSymptom,
        ),
        const SizedBox(height: 16),
        MedicationsSection(
          isEditable: widget.isEditable,
          drugDoses: _drugDoses,
          controllers: _drugDoseControllers,
          recentRecommendations: recommendations.when(
            data: (data) => data.recent,
            loading: () => [],
            error: (_, __) => [],
          ),
          commonRecommendations: recommendations.when(
            data: (data) => data.common,
            loading: () => [],
            error: (_, __) => [],
          ),
          onAdd: addDrugDose,
          onRemove: removeDrugDose,
          onUpdate: updateDrugDose,
        ),
        const SizedBox(height: 16),
        AppliedToolsSection(
          isEditable: widget.isEditable,
          appliedTools: _appliedTools,
          noteControllers: _appliedToolNoteControllers,
          onAdd: addAppliedToolFromHealthTool,
          onRemove: removeAppliedTool,
          onUpdateNote: updateAppliedToolNote,
        ),
        const SizedBox(height: 16),
        GeneralNotesSection(
          isEditable: widget.isEditable,
          notesController: _notesController,
          onNotesChanged: widget.onNotesChanged,
        ),
        const SizedBox(height: 40),
      ],
    );
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

  void updateSymptomFromSuggestion(
    int index,
    Symptom newSymptom,
    String suggestionKey,
  ) {
    setState(() {
      _symptoms[index] = newSymptom;
      _symptomControllers[index] = SymptomControllers(newSymptom);
      _usedSuggestions.add(suggestionKey);
    });
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
}
