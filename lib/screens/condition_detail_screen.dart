import 'package:ethan_ui/ethan_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_notes/models/condition.dart';
import 'package:health_notes/models/condition_entry.dart';
import 'package:health_notes/models/health_note.dart';
import 'package:health_notes/providers/conditions_provider.dart';
import 'package:health_notes/providers/dao_providers.dart';
import 'package:health_notes/screens/condition_form.dart';
import 'package:health_notes/widgets/app_dialogs.dart';
import 'package:health_notes/widgets/condition_activity_calendar.dart';
import 'package:health_notes/widgets/condition_detail/condition_activity_list.dart';
import 'package:health_notes/widgets/condition_detail/condition_detail_header.dart';
import 'package:health_notes/widgets/condition_detail/condition_statistics_section.dart';
import 'package:health_notes/widgets/condition_entry_edit_modal.dart';
import 'package:health_notes/theme/app_theme.dart';
import 'package:health_notes/widgets/health_notes_page.dart';
import 'package:health_notes/theme/spacing.dart';
import 'package:health_notes/widgets/sync_status_widget.dart';
import 'package:intl/intl.dart';

class const ConditionDetailScreen({required final String conditionId})
    extends ConsumerStatefulWidget {
  @override
  ConsumerState<ConditionDetailScreen> createState() =>
      _ConditionDetailScreenState();
}

enum ConditionDetailView() {
  calendar,
  activity,
}

class _ConditionDetailScreenState()
    extends ConsumerState<ConditionDetailScreen> {
  ConditionDetailView selectedView = ConditionDetailView.calendar;

  @override
  Widget build(BuildContext context) {
    final conditionsAsync = ref.watch(conditionsProvider);
    final entriesAsync = ref.watch(
      conditionEntriesProvider(widget.conditionId),
    );
    final linkedSymptomsAsync = ref.watch(
      symptomsForConditionProvider(widget.conditionId),
    );

    return conditionsAsync.when(
      data: (conditions) {
        final condition = conditions
            .where((c) => c.id == widget.conditionId)
            .firstOrNull;
        if (condition == null) {
          return const HealthNotesPage(
            title: 'Condition',
            body: Center(child: Text('Condition not found')),
          );
        }

        return entriesAsync.when(
          data: (entries) {
            final linkedSymptoms = linkedSymptomsAsync.value ?? [];
            return conditionDetailContent(condition, entries, linkedSymptoms);
          },
          loading: () => HealthNotesPage(
            title: condition.name,
            body: const SyncStatusWidget.loading(message: 'Loading entries...'),
          ),
          error: (error, stack) => HealthNotesPage(
            title: condition.name,
            body: SyncStatusWidget.error(
              errorMessage: 'Error: $error',
              onRetry: () =>
                  ref.invalidate(conditionEntriesProvider(widget.conditionId)),
            ),
          ),
        );
      },
      loading: () => const HealthNotesPage(
        title: 'Loading...',
        body: SyncStatusWidget.loading(message: 'Loading condition...'),
      ),
      error: (error, stack) => HealthNotesPage(
        title: 'Error',
        body: Center(child: Text('Error: $error', style: EText.error)),
      ),
    );
  }

  Widget conditionDetailContent(
    Condition condition,
    List<ConditionEntry> entries,
    List<LinkedSymptom> linkedSymptoms,
  ) {
    return HealthNotesPage(
      title: condition.name,
      actions: [
        IconButton(
          tooltip: 'More',
          onPressed: () => showActionsMenu(condition),
          icon: const Icon(Icons.more_vert),
        ),
      ],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.m).withOverlaidTabBar(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ConditionDetailHeader(condition: condition),
            VSpace.l,
            ConditionStatisticsSection(
              condition: condition,
              entries: entries,
              linkedSymptoms: linkedSymptoms,
            ),
            VSpace.l,
            viewSelector(),
            VSpace.l,
            ...selectedViewContent(condition, entries, linkedSymptoms),
          ],
        ),
      ),
    );
  }

  Widget viewSelector() {
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<ConditionDetailView>(
        segments: const [
          ButtonSegment(
            value: ConditionDetailView.calendar,
            label: Text('Calendar'),
          ),
          ButtonSegment(
            value: ConditionDetailView.activity,
            label: Text('Activity'),
          ),
        ],
        selected: {selectedView},
        onSelectionChanged: (selection) {
          setState(() => selectedView = selection.first);
        },
      ),
    );
  }

  List<Widget> selectedViewContent(
    Condition condition,
    List<ConditionEntry> entries,
    List<LinkedSymptom> linkedSymptoms,
  ) {
    if (selectedView == ConditionDetailView.calendar) {
      return [
        ConditionActivityCalendar(
          condition: condition,
          entries: entries,
          linkedSymptoms: linkedSymptoms,
          onEntrySelected: (entry) => showEntryEditModal(entry),
          onSymptomTap: (date, symptoms) =>
              _showSymptomDateDialog(date, symptoms),
        ),
      ];
    }
    return [
      ConditionActivityList(
        entries: entries,
        linkedSymptoms: linkedSymptoms,
        onEntrySelected: showEntryEditModal,
      ),
    ];
  }

  void showActionsMenu(Condition condition) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Edit Condition'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (routeContext) => ConditionForm(
                      condition: condition,
                      title: 'Edit Condition',
                      saveButtonText: 'Save',
                    ),
                  ),
                );
              },
            ),
            if (condition.isActive)
              ListTile(
                title: const Text('Mark as Resolved'),
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  await ref
                      .read(conditionsProvider.notifier)
                      .resolveCondition(widget.conditionId);
                },
              ),
            ListTile(
              title: Text(
                'Delete Condition',
                style: TextStyle(color: EColors.danger),
              ),
              onTap: () async {
                Navigator.of(sheetContext).pop();
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: const Text('Delete Condition'),
                    content: const Text(
                      'Are you sure you want to delete this condition and all its entries? This cannot be undone.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(true),
                        child: Text(
                          'Delete',
                          style: TextStyle(color: EColors.danger),
                        ),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) {
                  await ref
                      .read(conditionsProvider.notifier)
                      .deleteCondition(widget.conditionId);
                  if (mounted) {
                    Navigator.of(context).pop();
                  }
                }
              },
            ),
            ListTile(
              title: const Text('Cancel'),
              onTap: () => Navigator.of(sheetContext).pop(),
            ),
          ],
        ),
      ),
    );
  }

  void showEntryEditModal(ConditionEntry entry) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => ConditionEntryEditModal(
        entry: entry,
        onSave: (updatedEntry) async {
          await ref
              .read(conditionEntriesProvider(widget.conditionId).notifier)
              .updateEntry(updatedEntry);
          if (sheetContext.mounted) {
            Navigator.of(sheetContext).pop();
          }
        },
      ),
    );
  }

  Future<void> _showSymptomDateDialog(
    DateTime date,
    List<LinkedSymptom> symptoms,
  ) async {
    if (symptoms.isEmpty) return;

    final uniqueNoteIds = symptoms.map((ls) => ls.healthNoteId).toSet();
    final notesDao = await ref.read(healthNotesDaoProvider.future);
    final notes = <HealthNote>[];
    for (final noteId in uniqueNoteIds) {
      final note = await notesDao.getNoteById(noteId);
      if (note != null) notes.add(note);
    }
    notes.sort((a, b) => a.dateTime.compareTo(b.dateTime));

    if (!mounted || notes.isEmpty) return;

    showNoteDateDialog(
      context: context,
      date: date,
      notes: notes,
      summary: Text(
        '${symptoms.length} symptom${symptoms.length == 1 ? '' : 's'} across ${notes.length} note${notes.length == 1 ? '' : 's'}',
      ),
      noteLabelBuilder: (note) {
        final noteSymptomCount = symptoms
            .where((ls) => ls.healthNoteId == note.id)
            .length;
        return Text(
          '${DateFormat('h:mm a').format(note.dateTime)}  ·  $noteSymptomCount symptom${noteSymptomCount == 1 ? '' : 's'}',
        );
      },
    );
  }
}
