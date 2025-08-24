import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_notes/models/health_note.dart';
import 'package:health_notes/providers/health_notes_provider.dart';
import 'package:health_notes/theme/app_theme.dart';
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
          child: HealthNoteFormFields(
            key: _formFieldsKey,
            note: widget.note,
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

      final updatedNote =
          widget.note?.copyWith(
            dateTime: formFieldsState.currentDateTime,
            symptoms: formFieldsState.currentSymptoms.trim(),
            drugDoses: formFieldsState.currentDrugDoses,
            notes: formFieldsState.currentNotes.trim(),
          ) ??
          HealthNote(
            id: '', // Will be set by the provider
            dateTime: formFieldsState.currentDateTime,
            symptoms: formFieldsState.currentSymptoms.trim(),
            drugDoses: formFieldsState.currentDrugDoses,
            notes: formFieldsState.currentNotes.trim(),
            createdAt: DateTime.now(),
          );

      if (widget.note != null) {
        await ref
            .read(healthNotesNotifierProvider.notifier)
            .updateNote(
              id: widget.note!.id,
              dateTime: updatedNote.dateTime,
              symptoms: updatedNote.symptoms,
              drugDoses: updatedNote.validDrugDoses,
              notes: updatedNote.notes,
            );
      } else {
        await ref
            .read(healthNotesNotifierProvider.notifier)
            .addNote(
              dateTime: updatedNote.dateTime,
              symptoms: updatedNote.symptoms,
              drugDoses: updatedNote.validDrugDoses,
              notes: updatedNote.notes,
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
