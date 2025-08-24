import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_notes/models/drug_dose.dart';
import 'package:health_notes/models/health_note.dart';
import 'package:health_notes/providers/health_notes_provider.dart';
import 'package:health_notes/theme/app_theme.dart';

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

class HealthNoteForm extends ConsumerStatefulWidget {
  final HealthNote? note;
  final String title;
  final String saveButtonText;
  final Function()? onCancel;
  final Function()? onSuccess;

  const HealthNoteForm({
    super.key,
    this.note,
    required this.title,
    required this.saveButtonText,
    this.onCancel,
    this.onSuccess,
  });

  @override
  ConsumerState<HealthNoteForm> createState() => _HealthNoteFormState();
}

class _HealthNoteFormState extends ConsumerState<HealthNoteForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _symptomsController;
  late TextEditingController _notesController;
  late DateTime _selectedDateTime;
  late List<DrugDose> _drugDoses;
  bool _isLoading = false;

  late final Map<int, DrugDoseControllers> _drugDoseControllers;

  @override
  void initState() {
    super.initState();

    if (widget.note != null) {
      // Editing existing note
      final note = widget.note!;
      _symptomsController = TextEditingController(text: note.symptoms);
      _notesController = TextEditingController(text: note.notes);
      _selectedDateTime = note.dateTime;
      _drugDoses = List.from(note.drugDoses);
    } else {
      // Creating new note
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
    _drugDoseControllers.clear();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(widget.title, style: AppTheme.titleMedium),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: widget.onCancel ?? () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _isLoading ? null : saveNote,
          child: _isLoading
              ? const CupertinoActivityIndicator()
              : Text(widget.saveButtonText),
        ),
      ),
      child: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
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
          ),
        ),
      ),
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
          Container(
            height: 200,
            decoration: AppTheme.datePickerContainer,
            child: CupertinoDatePicker(
              mode: CupertinoDatePickerMode.dateAndTime,
              initialDateTime: _selectedDateTime,
              backgroundColor: AppTheme.backgroundDepth4,
              onDateTimeChanged: (DateTime newDateTime) {
                setState(() => _selectedDateTime = newDateTime);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSymptomsSection() {
    return CupertinoTextField(
      controller: _symptomsController,
      placeholder: 'Symptoms (optional)',
      placeholderStyle: AppTheme.inputPlaceholder,
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.inputContainer,
      style: AppTheme.input,
      maxLines: 3,
    );
  }

  Widget buildDrugDosesSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.inputContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Drugs/Medications', style: AppTheme.titleMedium),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: addDrugDose,
                child: const Icon(CupertinoIcons.add),
              ),
            ],
          ),
          if (_drugDoses.isNotEmpty) ...[
            const SizedBox(height: 12),
            ..._drugDoses.asMap().entries.map((entry) {
              final index = entry.key;
              final dose = entry.value;
              return buildDrugDoseItem(index, dose);
            }),
          ],
        ],
      ),
    );
  }

  Widget buildDrugDoseItem(int index, DrugDose dose) {
    final controllers = _drugDoseControllers[index]!;

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
                  onChanged: (value) {
                    updateDrugDose(index, name: value);
                  },
                ),
              ),
              const SizedBox(width: 8),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => removeDrugDose(index),
                child: const Icon(
                  CupertinoIcons.delete,
                  color: CupertinoColors.destructiveRed,
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
                  onChanged: (value) {
                    updateDrugDose(index, unit: value);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildNotesSection() {
    return CupertinoTextField(
      controller: _notesController,
      placeholder: 'Additional Notes (optional)',
      placeholderStyle: AppTheme.inputPlaceholder,
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.inputContainer,
      style: AppTheme.input,
      maxLines: 4,
    );
  }

  void addDrugDose() {
    setState(() {
      final newIndex = _drugDoses.length;
      _drugDoses.add(const DrugDose(name: '', dosage: 0.0, unit: 'mg'));
      _drugDoseControllers[newIndex] = DrugDoseControllers(
        _drugDoses[newIndex],
      );
    });
  }

  void removeDrugDose(int index) {
    setState(() {
      // Dispose controllers for the removed drug dose
      if (_drugDoseControllers.containsKey(index)) {
        _drugDoseControllers[index]!.dispose();
        _drugDoseControllers.remove(index);
      }

      _drugDoses.removeAt(index);
    });
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
  }

  Future<void> saveNote() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (widget.note != null) {
        await ref
            .read(healthNotesNotifierProvider.notifier)
            .updateNote(
              id: widget.note!.id,
              dateTime: _selectedDateTime,
              symptoms: _symptomsController.text.trim(),
              drugDoses: _drugDoses
                  .where((dose) => dose.name.isNotEmpty)
                  .toList(),
              notes: _notesController.text.trim(),
            );
      } else {
        await ref
            .read(healthNotesNotifierProvider.notifier)
            .addNote(
              dateTime: _selectedDateTime,
              symptoms: _symptomsController.text.trim(),
              drugDoses: _drugDoses
                  .where((dose) => dose.name.isNotEmpty)
                  .toList(),
              notes: _notesController.text.trim(),
            );
      }

      if (mounted) {
        widget.onSuccess?.call();
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: Text('Error', style: AppTheme.titleMedium),
            content: Text(
              'Failed to ${widget.note != null ? 'update' : 'save'} note: $e',
              style: AppTheme.error,
            ),
            actions: [
              CupertinoDialogAction(
                child: Text('OK', style: AppTheme.buttonSecondary),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
