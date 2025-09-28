import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_notes/models/health_note.dart';
import 'package:health_notes/providers/health_notes_provider.dart';
import 'package:health_notes/widgets/enhanced_ui_components.dart';
import 'package:health_notes/widgets/health_note_form_fields.dart';

class HealthNoteForm extends ConsumerStatefulWidget {
  final HealthNote? note;
  final String title;
  final String saveButtonText;
  final Function()? onCancel;
  final Function()? onSuccess;

  const HealthNoteForm({
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
  final _formFieldsKey = GlobalKey<HealthNoteFormFieldsState>();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final currentNote = widget.note != null
        ? ref
              .watch(healthNotesNotifierProvider)
              .when(
                data: (notes) => notes.firstWhere(
                  (note) => note.id == widget.note!.id,
                  orElse: () => widget.note!,
                ),
                loading: () => widget.note!,
                error: (error, stack) => widget.note!,
              )
        : widget.note;

    return CupertinoPageScaffold(
      navigationBar: EnhancedUIComponents.navigationBar(
        title: widget.title,
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
          child: HealthNoteFormFields(
            key: _formFieldsKey,
            note: currentNote,
            isEditable: true,
          ),
        ),
      ),
    );
  }

  Future<void> saveNote() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final formFieldsState = _formFieldsKey.currentState;
      if (formFieldsState == null) return;

      final updatedNote = _composeUpdatedNote(formFieldsState);

      if (widget.note != null) {
        await _persistExistingNote(updatedNote);
      } else {
        await _persistNewNote(updatedNote);
      }

      if (mounted) {
        widget.onSuccess?.call();
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => AppAlertDialogs.error(
            title: 'Error',
            content:
                'Failed to ${widget.note != null ? 'update' : 'save'} note: $e',
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

  HealthNote _composeUpdatedNote(HealthNoteFormFieldsState formFieldsState) {
    final base = widget.note;
    if (base != null) {
      return base.copyWith(
        dateTime: formFieldsState.currentDateTime,
        symptomsList: formFieldsState.currentSymptoms,
        drugDoses: formFieldsState.currentDrugDoses,
        appliedTools: formFieldsState.currentAppliedTools,
        notes: formFieldsState.currentNotes.trim(),
      );
    }

    return HealthNote(
      id: '',
      dateTime: formFieldsState.currentDateTime,
      symptomsList: formFieldsState.currentSymptoms,
      drugDoses: formFieldsState.currentDrugDoses,
      appliedTools: formFieldsState.currentAppliedTools,
      notes: formFieldsState.currentNotes.trim(),
      createdAt: DateTime.now(),
    );
  }

  Future<void> _persistExistingNote(HealthNote updatedNote) async {
    await ref
        .read(healthNotesNotifierProvider.notifier)
        .updateNote(
          id: widget.note!.id,
          dateTime: updatedNote.dateTime,
          symptomsList: updatedNote.validSymptoms,
          drugDoses: updatedNote.validDrugDoses,
          appliedTools: updatedNote.appliedTools,
          notes: updatedNote.notes,
        );
  }

  Future<void> _persistNewNote(HealthNote updatedNote) async {
    await ref
        .read(healthNotesNotifierProvider.notifier)
        .addNote(
          dateTime: updatedNote.dateTime,
          symptomsList: updatedNote.validSymptoms,
          drugDoses: updatedNote.validDrugDoses,
          appliedTools: updatedNote.appliedTools,
          notes: updatedNote.notes,
        );
  }
}
