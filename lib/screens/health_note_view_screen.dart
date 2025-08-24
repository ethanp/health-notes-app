import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_notes/models/health_note.dart';
import 'package:health_notes/providers/health_notes_provider.dart';
import 'package:health_notes/theme/app_theme.dart';
import 'package:health_notes/widgets/health_note_form_fields.dart';

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
      return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: Text('Edit Note', style: AppTheme.titleMedium),
          leading: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: cancelEdit,
            child: const Text('Cancel'),
          ),
          trailing: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _isLoading ? null : saveChanges,
            child: _isLoading
                ? const CupertinoActivityIndicator()
                : const Text('Save'),
          ),
        ),
        child: SafeArea(
          child: HealthNoteFormFields(
            key: _formFieldsKey,
            note: widget.note,
            isEditable: true,
          ),
        ),
      );
    }

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('Health Note', style: AppTheme.titleMedium),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: toggleEditMode,
          child: const Icon(CupertinoIcons.pencil),
        ),
      ),
      child: SafeArea(child: buildViewMode()),
    );
  }

  Widget buildViewMode() {
    // Get the latest note data from the provider
    final notesAsync = ref.watch(healthNotesNotifierProvider);

    return notesAsync.when(
      data: (notes) {
        final updatedNote = notes.firstWhere(
          (note) => note.id == widget.note.id,
          orElse: () => widget.note,
        );

        return HealthNoteFormFields(note: updatedNote, isEditable: false);
      },
      loading: () => const Center(child: CupertinoActivityIndicator()),
      error: (error, stack) => Center(
        child: Text('Error loading note: $error', style: AppTheme.error),
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
            notes: formFieldsState.currentNotes.trim(),
          );

      if (mounted) {
        setState(() {
          _isEditing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: Text('Error', style: AppTheme.titleMedium),
            content: Text('Failed to update note: $e', style: AppTheme.error),
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
