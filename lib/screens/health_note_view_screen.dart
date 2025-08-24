import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_notes/models/health_note.dart';
import 'package:health_notes/screens/health_note_form.dart';
import 'package:health_notes/providers/health_notes_provider.dart';
import 'package:health_notes/theme/app_theme.dart';
import 'package:intl/intl.dart';

class HealthNoteViewScreen extends ConsumerWidget {
  final HealthNote note;

  const HealthNoteViewScreen({required this.note});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('Health Note', style: AppTheme.titleMedium),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => navigateToEdit(context, ref),
          child: const Icon(CupertinoIcons.pencil),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildDateTimeSection(),
              const SizedBox(height: 24),
              buildSymptomsSection(),
              const SizedBox(height: 24),
              buildDrugDosesSection(),
              const SizedBox(height: 24),
              buildNotesSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildDateTimeSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Date & Time', style: AppTheme.titleSmall),
          const SizedBox(height: 8),
          Text(
            DateFormat('EEEE, MMMM d, yyyy').format(note.dateTime),
            style: AppTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            DateFormat('h:mm a').format(note.dateTime),
            style: AppTheme.bodyMedium.copyWith(
              color: CupertinoColors.systemGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSymptomsSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Symptoms', style: AppTheme.titleSmall),
          const SizedBox(height: 8),
          Text(
            note.symptoms.isNotEmpty ? note.symptoms : 'No symptoms recorded',
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
      decoration: AppTheme.cardContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Medications', style: AppTheme.titleSmall),
          const SizedBox(height: 8),
          if (note.drugDoses.isEmpty)
            Text('No medications recorded', style: AppTheme.bodyMedium)
          else
            ...note.drugDoses.map(
              (dose) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: CupertinoColors.systemBlue,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        dose.name,
                        style: AppTheme.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      '${dose.dosage} ${dose.unit}',
                      style: AppTheme.bodyMedium.copyWith(
                        color: CupertinoColors.systemGrey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget buildNotesSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Notes', style: AppTheme.titleSmall),
          const SizedBox(height: 8),
          Text(
            note.notes.isNotEmpty ? note.notes : 'No additional notes',
            style: AppTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  void navigateToEdit(BuildContext context, WidgetRef ref) async {
    await Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => HealthNoteForm(
          note: note,
          title: 'Edit Note',
          saveButtonText: 'Save',
        ),
      ),
    );
    // Refresh the data when returning from edit
    ref.read(healthNotesNotifierProvider.notifier).refreshNotes();
  }
}
