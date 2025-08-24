import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_notes/models/drug_dose.dart';
import 'package:health_notes/providers/health_notes_provider.dart';
import 'package:health_notes/theme/app_theme.dart';

class AddNoteModal extends ConsumerStatefulWidget {
  const AddNoteModal({super.key});

  @override
  ConsumerState<AddNoteModal> createState() => _AddNoteModalState();
}

class _AddNoteModalState extends ConsumerState<AddNoteModal> {
  final _formKey = GlobalKey<FormState>();
  final _symptomsController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _selectedDateTime = DateTime.now();
  bool _isLoading = false;
  final List<DrugDose> _drugDoses = <DrugDose>[];

  @override
  void dispose() {
    _symptomsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> saveNote() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await ref
          .read(healthNotesNotifierProvider.notifier)
          .addNote(
            dateTime: _selectedDateTime,
            symptoms: _symptomsController.text,
            drugDoses: _drugDoses,
            notes: _notesController.text,
          );

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: Text('Error', style: AppTheme.titleMedium),
            content: Text('Failed to save note: $e', style: AppTheme.error),
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
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('Add Health Note', style: AppTheme.titleMedium),
        leading: CupertinoNavigationBarBackButton(
          onPressed: () => Navigator.of(context).pop(),
        ),
        trailing: _isLoading
            ? const CupertinoActivityIndicator()
            : CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: saveNote,
                child: Text('Save', style: AppTheme.buttonSecondary),
              ),
      ),
      child: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey6,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Date & Time', style: AppTheme.titleMedium),
                    const SizedBox(height: 16),
                    Container(
                      height: 200,
                      decoration: AppTheme.inputContainer,
                      child: CupertinoDatePicker(
                        mode: CupertinoDatePickerMode.dateAndTime,
                        initialDateTime: _selectedDateTime,
                        backgroundColor: CupertinoColors.systemGrey6,
                        onDateTimeChanged: (DateTime newDateTime) {
                          setState(() => _selectedDateTime = newDateTime);
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              CupertinoTextField(
                controller: _symptomsController,
                placeholder: 'Symptoms (optional)',
                placeholderStyle: AppTheme.inputPlaceholder,
                padding: const EdgeInsets.all(16),
                decoration: AppTheme.inputContainer,
                style: AppTheme.input,
                maxLines: 3,
              ),

              const SizedBox(height: 16),

              Container(
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
              ),

              const SizedBox(height: 16),

              CupertinoTextField(
                controller: _notesController,
                placeholder: 'Additional Notes (optional)',
                placeholderStyle: AppTheme.inputPlaceholder,
                padding: const EdgeInsets.all(16),
                decoration: AppTheme.inputContainer,
                style: AppTheme.input,
                maxLines: 4,
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  void addDrugDose() {
    setState(() {
      _drugDoses.add(const DrugDose(name: '', dosage: 0.0));
    });
  }

  void removeDrugDose(int index) {
    setState(() {
      _drugDoses.removeAt(index);
    });
  }

  void updateDrugDose(int index, DrugDose dose) {
    setState(() {
      _drugDoses[index] = dose;
    });
  }

  Widget buildDrugDoseItem(int index, DrugDose dose) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: AppTheme.cardContainer,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: CupertinoTextField(
                  placeholder: 'Drug name',
                  placeholderStyle: AppTheme.inputPlaceholder,
                  style: AppTheme.input,
                  onChanged: (value) {
                    updateDrugDose(index, dose.copyWith(name: value));
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
                  placeholder: 'Dosage',
                  placeholderStyle: AppTheme.inputPlaceholder,
                  style: AppTheme.input,
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    final dosage = double.tryParse(value) ?? 0.0;
                    updateDrugDose(index, dose.copyWith(dosage: dosage));
                  },
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: AppTheme.labelContainer,
                child: Text('mg', style: AppTheme.labelMedium),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
