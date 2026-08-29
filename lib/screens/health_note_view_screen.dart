import 'package:ethan_ui/ethan_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_notes/models/health_note.dart';
import 'package:health_notes/providers/health_notes_provider.dart';
import 'package:health_notes/widgets/app_dialogs.dart';
import 'package:health_notes/widgets/health_note_form_fields.dart';
import 'package:health_notes/widgets/health_notes_page.dart';
import 'package:health_notes/widgets/sync_status_widget.dart';

class HealthNoteViewScreen extends ConsumerStatefulWidget {
  final HealthNote note;

  const HealthNoteViewScreen({required this.note});

  @override
  ConsumerState<HealthNoteViewScreen> createState() =>
      _HealthNoteViewScreenState();
}

class _HealthNoteViewScreenState extends ConsumerState<HealthNoteViewScreen> {
  bool _isEditing = false;
  bool _isLoading = false;
  final _formFieldsKey = GlobalKey<HealthNoteFormFieldsState>();

  @override
  Widget build(BuildContext context) {
    if (_isEditing) {
      return HealthNotesPage(
        title: 'Edit Note',
        leading: TextButton(
          onPressed: cancelEdit,
          child: const Text('Cancel'),
        ),
        actions: [
          if (_isLoading)
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            TextButton(onPressed: saveChanges, child: const Text('Save')),
        ],
        body: HealthNoteFormFields(
          key: _formFieldsKey,
          note: widget.note,
          isEditable: true,
        ),
      );
    }

    return HealthNotesPage(
      title: 'Health Note',
      actions: [
        IconButton(
          tooltip: 'Edit',
          onPressed: toggleEditMode,
          icon: const Icon(Icons.edit_outlined),
        ),
      ],
      body: viewMode(),
    );
  }

  Widget viewMode() {
    final notesAsync = ref.watch(healthNotesNotifierProvider);

    return notesAsync.when(
      data: (notes) {
        final updatedNote = notes.firstWhere(
          (note) => note.id == widget.note.id,
          orElse: () => widget.note,
        );

        return HealthNoteFormFields(note: updatedNote, isEditable: false);
      },
      loading: () =>
          const SyncStatusWidget.loading(message: 'Loading note data...'),
      error: (error, stack) => Center(
        child: Text('Error loading note: $error', style: EText.error),
      ),
    );
  }

  void toggleEditMode() {
    setState(() {
      _isEditing = true;
    });
  }

  void cancelEdit() {
    setState(() {
      _isEditing = false;
    });
  }

  Future<void> saveChanges() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final formFieldsState = _formFieldsKey.currentState;
      if (formFieldsState == null) return;

      await ref
          .read(healthNotesNotifierProvider.notifier)
          .updateNote(
            id: widget.note.id,
            dateTime: formFieldsState.currentDateTime,
            symptomsList: formFieldsState.currentSymptoms,
            drugDoses: formFieldsState.currentDrugDoses,
            appliedTools: formFieldsState.currentAppliedTools,
            notes: formFieldsState.currentNotes.trim(),
          );

      if (mounted) {
        setState(() {
          _isEditing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AppAlertDialogs.error(
            title: 'Error',
            content: 'Failed to update note: $e',
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
