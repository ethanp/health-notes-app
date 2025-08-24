import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_notes/models/drug_dose.dart';
import 'package:health_notes/models/health_note.dart';
import 'package:health_notes/theme/app_theme.dart';
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
  late TextEditingController _symptomsController;
  late TextEditingController _notesController;
  late DateTime _selectedDateTime;
  late List<DrugDose> _drugDoses;
  late Map<int, DrugDoseControllers> _drugDoseControllers;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    if (widget.note != null) {
      final note = widget.note!;
      _symptomsController = TextEditingController(text: note.symptoms);
      _notesController = TextEditingController(text: note.notes);
      _selectedDateTime = note.dateTime;
      _drugDoses = List.from(note.drugDoses);
    } else {
      _symptomsController = TextEditingController();
      _notesController = TextEditingController();
      _selectedDateTime = DateTime.now();
      _drugDoses = <DrugDose>[];
    }

    _drugDoseControllers = _drugDoses.asMap().map(
      (key, value) => MapEntry(key, DrugDoseControllers(value)),
    );
  }

  @override
  void dispose() {
    _symptomsController.dispose();
    _notesController.dispose();
    _drugDoseControllers.values.forEach((controllers) => controllers.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 20),
        buildDateTimeSection(),
        const SizedBox(height: 20),
        buildSymptomsSection(),
        const SizedBox(height: 16),
        buildDrugDosesSection(),
        const SizedBox(height: 16),
        buildNotesSection(),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget buildDateTimeSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Date & Time', style: AppTheme.titleMedium),
          const SizedBox(height: 16),
          if (widget.isEditable)
            Container(
              height: 200,
              decoration: AppTheme.datePickerContainer,
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.dateAndTime,
                initialDateTime: _selectedDateTime,
                backgroundColor: AppTheme.backgroundDepth4,
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
                  style: AppTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('h:mm a').format(_selectedDateTime),
                  style: AppTheme.bodyMediumSecondary,
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget buildSymptomsSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: widget.isEditable
          ? AppTheme.inputContainer
          : AppTheme.cardContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Symptoms', style: AppTheme.titleSmall),
          const SizedBox(height: 8),
          if (widget.isEditable)
            CupertinoTextField(
              controller: _symptomsController,
              placeholder: 'Symptoms (optional)',
              placeholderStyle: AppTheme.inputPlaceholder,
              style: AppTheme.input,
              maxLines: 3,
              onChanged: widget.onSymptomsChanged,
            )
          else
            Text(
              _symptomsController.text.isNotEmpty
                  ? _symptomsController.text
                  : 'No symptoms recorded',
              style: AppTheme.bodyMedium,
            ),
        ],
      ),
    );
  }

  Widget buildDrugDosesSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: widget.isEditable
          ? AppTheme.inputContainer
          : AppTheme.cardContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Medications', style: AppTheme.titleSmall),
              if (widget.isEditable)
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: addDrugDose,
                  child: const Icon(CupertinoIcons.add),
                ),
            ],
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
                      child: Text(dose.name, style: AppTheme.bodyMediumBold),
                    ),
                    Text(
                      dose.displayDosage,
                      style: AppTheme.bodyMediumSecondary,
                    ),
                  ],
                ),
              ),
            )
          else if (widget.isEditable)
            ..._drugDoses.asMap().entries.map((entry) {
              final index = entry.key;
              final dose = entry.value;
              return buildEditableDrugDoseItem(
                index: index,
                dose: dose,
                controllers: _drugDoseControllers[index]!,
              );
            }),
        ],
      ),
    );
  }

  Widget buildEditableDrugDoseItem({
    required int index,
    required DrugDose dose,
    required DrugDoseControllers controllers,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: AppTheme.cardContainer,
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

  Widget buildNotesSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: widget.isEditable
          ? AppTheme.inputContainer
          : AppTheme.cardContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Notes', style: AppTheme.titleSmall),
          const SizedBox(height: 8),
          if (widget.isEditable)
            CupertinoTextField(
              controller: _notesController,
              placeholder: 'Additional Notes (optional)',
              placeholderStyle: AppTheme.inputPlaceholder,
              style: AppTheme.input,
              maxLines: 4,
              onChanged: widget.onNotesChanged,
            )
          else
            Text(
              _notesController.text.isNotEmpty
                  ? _notesController.text
                  : 'No additional notes',
              style: AppTheme.bodyMedium,
            ),
        ],
      ),
    );
  }

  // Getters for accessing current values
  DateTime get currentDateTime => _selectedDateTime;
  String get currentSymptoms => _symptomsController.text;
  String get currentNotes => _notesController.text;
  List<DrugDose> get currentDrugDoses => _drugDoses;

  // Methods for managing drug doses
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
