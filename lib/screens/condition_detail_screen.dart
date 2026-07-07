import 'package:ethan_utils/ethan_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_notes/models/condition.dart';
import 'package:health_notes/models/condition_entry.dart';
import 'package:health_notes/models/health_note.dart';
import 'package:health_notes/providers/conditions_provider.dart';
import 'package:health_notes/screens/condition_form.dart';
import 'package:health_notes/screens/sub_symptom_trends_screen.dart';
import 'package:health_notes/screens/symptom_trends_screen.dart';
import 'package:health_notes/services/health_notes_dao.dart';
import 'package:health_notes/theme/app_theme.dart';
import 'package:health_notes/utils/severity_utils.dart';
import 'package:health_notes/widgets/app_dialogs.dart';
import 'package:health_notes/widgets/condition_activity_calendar.dart';
import 'package:health_notes/widgets/condition_entry_edit_modal.dart';
import 'package:health_notes/widgets/app_card.dart';
import 'package:health_notes/widgets/enhanced_ui_components.dart';
import 'package:health_notes/theme/spacing.dart';
import 'package:health_notes/widgets/sync_status_widget.dart';
import 'package:intl/intl.dart';

class ConditionDetailScreen extends ConsumerStatefulWidget {
  final String conditionId;

  const ConditionDetailScreen({required this.conditionId});

  @override
  ConsumerState<ConditionDetailScreen> createState() =>
      _ConditionDetailScreenState();
}

enum ConditionDetailView { calendar, activity }

class _ConditionDetailScreenState extends ConsumerState<ConditionDetailScreen> {
  ConditionDetailView selectedView = ConditionDetailView.calendar;

  @override
  Widget build(BuildContext context) {
    final conditionsAsync = ref.watch(conditionsNotifierProvider);
    final entriesAsync = ref.watch(
      conditionEntriesNotifierProvider(widget.conditionId),
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
          return CupertinoPageScaffold(
            navigationBar: EnhancedUIComponents.navigationBar(
              title: 'Condition',
            ),
            child: const Center(child: Text('Condition not found')),
          );
        }

        return entriesAsync.when(
          data: (entries) {
            final linkedSymptoms = linkedSymptomsAsync.valueOrNull ?? [];
            return conditionDetailContent(
              condition,
              entries,
              linkedSymptoms,
            );
          },
          loading: () => CupertinoPageScaffold(
            navigationBar: EnhancedUIComponents.navigationBar(
              title: condition.name,
            ),
            child: const SyncStatusWidget.loading(
              message: 'Loading entries...',
            ),
          ),
          error: (error, stack) => CupertinoPageScaffold(
            navigationBar: EnhancedUIComponents.navigationBar(
              title: condition.name,
            ),
            child: SyncStatusWidget.error(
              errorMessage: 'Error: $error',
              onRetry: () => ref.invalidate(
                conditionEntriesNotifierProvider(widget.conditionId),
              ),
            ),
          ),
        );
      },
      loading: () => CupertinoPageScaffold(
        navigationBar: EnhancedUIComponents.navigationBar(title: 'Loading...'),
        child: const SyncStatusWidget.loading(message: 'Loading condition...'),
      ),
      error: (error, stack) => CupertinoPageScaffold(
        navigationBar: EnhancedUIComponents.navigationBar(title: 'Error'),
        child: Center(child: Text('Error: $error', style: AppText.error)),
      ),
    );
  }

  Widget conditionDetailContent(
    Condition condition,
    List<ConditionEntry> entries,
    List<LinkedSymptom> linkedSymptoms,
  ) {
    return CupertinoPageScaffold(
      navigationBar: EnhancedUIComponents.navigationBar(
        title: condition.name,
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => showActionsMenu(condition),
          child: const Icon(CupertinoIcons.ellipsis_vertical),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.m),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              conditionHeader(condition),
              VSpace.l,
              statisticsSection(condition, entries, linkedSymptoms),
              VSpace.l,
              viewSelector(),
              VSpace.l,
              ...selectedViewContent(condition, entries, linkedSymptoms),
            ],
          ),
        ),
      ),
    );
  }

  Widget viewSelector() {
    return SizedBox(
      width: double.infinity,
      child: CupertinoSlidingSegmentedControl<ConditionDetailView>(
        groupValue: selectedView,
        onValueChanged: (view) {
          if (view == null) return;
          setState(() => selectedView = view);
        },
        children: const {
          ConditionDetailView.calendar: Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: Text('Calendar'),
          ),
          ConditionDetailView.activity: Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: Text('Activity'),
          ),
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
          onEntryTap: (entry) => showEntryEditModal(entry),
          onSymptomTap: (date, symptoms) =>
              _showSymptomDateDialog(date, symptoms),
        ),
      ];
    }
    return activitySections(entries, linkedSymptoms);
  }

  List<Widget> activitySections(
    List<ConditionEntry> entries,
    List<LinkedSymptom> linkedSymptoms,
  ) {
    return [
      EnhancedUIComponents.sectionHeader(title: 'Daily Entries'),
      VSpace.s,
      entriesList(entries, linkedSymptoms),
      if (linkedSymptoms.isNotEmpty) ...[
        VSpace.l,
        EnhancedUIComponents.sectionHeader(title: 'Linked Symptoms'),
        VSpace.s,
        linkedSymptomsBreakdown(linkedSymptoms),
      ],
    ];
  }

  Widget conditionHeader(Condition condition) {
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: AppComponents.tintedSolidDecoration(
              condition.color,
              radius: 28,
              borderWidth: 2,
            ),
            child: Icon(condition.icon, size: 28, color: condition.color),
          ),
          HSpace.m,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(condition.name, style: AppText.headline.small),
                VSpace.xs,
                Text(
                  formatDateRange(condition),
                  style: AppText.body.small.tertiary,
                ),
              ],
            ),
          ),
          statusBadge(condition),
        ],
      ),
    );
  }

  Widget statusBadge(Condition condition) {
    final color = condition.isActive
        ? CupertinoColors.systemOrange
        : CupertinoColors.systemGreen;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.s),
      decoration: AppComponents.tintedSolidDecoration(
        color,
        radius: AppRadius.large,
      ),
      child: Text(
        condition.status.displayName,
        style: AppText.label.medium.copyWith(color: color),
      ),
    );
  }

  Widget statisticsSection(
    Condition condition,
    List<ConditionEntry> entries,
    List<LinkedSymptom> linkedSymptoms,
  ) {
    final avgSeverity = entries.isEmpty
        ? 0.0
        : entries.map((e) => e.severity).reduce((a, b) => a + b) /
              entries.length;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Statistics', style: AppText.label.large.primary),
          VSpace.m,
          Row(
            children: [
              Expanded(
                child: statCard(
                  'Duration',
                  '${condition.durationDays}',
                  'days',
                ),
              ),
              HSpace.m,
              Expanded(
                child: statCard('Entries', '${entries.length}', 'logged'),
              ),
            ],
          ),
          VSpace.m,
          Row(
            children: [
              Expanded(
                child: statCard(
                  'Avg Severity',
                  avgSeverity.toStringAsFixed(1),
                  '/10',
                ),
              ),
              HSpace.m,
              Expanded(
                child: statCard(
                  'Symptoms',
                  '${linkedSymptoms.length}',
                  'linked',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget statCard(String label, String value, String unit) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.backgroundTertiary,
        borderRadius: BorderRadius.circular(AppRadius.small),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppText.caption),
          VSpace.xs,
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: AppText.headline.medium),
              HSpace.xs,
              Text(unit, style: AppText.caption),
            ],
          ),
        ],
      ),
    );
  }

  Widget entriesList(
    List<ConditionEntry> entries,
    List<LinkedSymptom> linkedSymptoms,
  ) {
    if (entries.isEmpty) {
      final emptyMessage = linkedSymptoms.isNotEmpty
          ? 'No check-in entries yet'
          : 'No entries yet. Add entries via check-ins.';
      return AppCard(
        child: Center(
          child: Text(
            emptyMessage,
            style: AppText.body.medium.systemGrey,
          ),
        ),
      );
    }

    final sortedEntries = [...entries]
      ..sort((a, b) => b.entryDate.compareTo(a.entryDate));

    return Column(
      children: sortedEntries
          .map((entry) => entryCard(entry))
          .toList(),
    );
  }

  Widget entryCard(ConditionEntry entry) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () => showEntryEditModal(entry),
        child: AppCard(
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('EEE, MMM d').format(entry.entryDate),
                    style: AppText.label.medium,
                  ),
                  VSpace.xs,
                  Row(
                    children: [
                      phaseBadge(entry.phase),
                      if (entry.notes.isNotEmpty) ...[
                        HSpace.s,
                        Icon(
                          CupertinoIcons.text_bubble,
                          size: 14,
                          color: AppColors.textQuaternary,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              const Spacer(),
              severityIndicator(entry.severity),
              HSpace.s,
              Icon(
                CupertinoIcons.chevron_right,
                size: 14,
                color: AppColors.textQuaternary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget phaseBadge(ConditionPhase phase) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: AppComponents.tintedSolidDecoration(
        phase.color,
        radius: AppRadius.small,
      ),
      child: Text(
        phase.displayName,
        style: AppText.caption.copyWith(color: phase.color),
      ),
    );
  }

  Widget severityIndicator(int severity) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: SeverityUtils.discreteCupertinoColor(severity),
        borderRadius: BorderRadius.circular(AppRadius.medium),
      ),
      child: Text('$severity', style: AppText.label.medium.white),
    );
  }

  String formatDateRange(Condition condition) {
    final startStr = DateFormat('MMM d, y').format(condition.startDate);
    if (condition.endDate != null) {
      final endStr = DateFormat('MMM d, y').format(condition.endDate!);
      return '$startStr - $endStr';
    }
    return 'Started $startStr';
  }

  void showActionsMenu(Condition condition) {
    showCupertinoModalPopup(
      context: context,
      builder: (sheetContext) => CupertinoActionSheet(
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(sheetContext).pop();
              Navigator.of(context).push(
                CupertinoPageRoute(
                  builder: (routeContext) => ConditionForm(
                    condition: condition,
                    title: 'Edit Condition',
                    saveButtonText: 'Save',
                  ),
                ),
              );
            },
            child: const Text('Edit Condition'),
          ),
          if (condition.isActive)
            CupertinoActionSheetAction(
              onPressed: () async {
                Navigator.of(sheetContext).pop();
                await ref
                    .read(conditionsNotifierProvider.notifier)
                    .resolveCondition(widget.conditionId);
              },
              child: const Text('Mark as Resolved'),
            ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.of(sheetContext).pop();
              final confirmed = await showCupertinoDialog<bool>(
                context: context,
                builder: (dialogContext) => CupertinoAlertDialog(
                  title: const Text('Delete Condition'),
                  content: const Text(
                    'Are you sure you want to delete this condition and all its entries? This cannot be undone.',
                  ),
                  actions: [
                    CupertinoDialogAction(
                      child: const Text('Cancel'),
                      onPressed: () => Navigator.of(dialogContext).pop(false),
                    ),
                    CupertinoDialogAction(
                      isDestructiveAction: true,
                      child: const Text('Delete'),
                      onPressed: () => Navigator.of(dialogContext).pop(true),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                await ref
                    .read(conditionsNotifierProvider.notifier)
                    .deleteCondition(widget.conditionId);
                if (mounted) {
                  Navigator.of(context).pop();
                }
              }
            },
            child: const Text('Delete Condition'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(sheetContext).pop(),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  void showEntryEditModal(ConditionEntry entry) {
    showCupertinoModalPopup(
      context: context,
      builder: (sheetContext) => ConditionEntryEditModal(
        entry: entry,
        onSave: (updatedEntry) async {
          await ref
              .read(conditionEntriesNotifierProvider(widget.conditionId).notifier)
              .updateEntry(updatedEntry);
          if (sheetContext.mounted) {
            Navigator.of(sheetContext).pop();
          }
        },
      ),
    );
  }

  Widget linkedSymptomsBreakdown(List<LinkedSymptom> linkedSymptoms) {
    final byDescription = <String, List<LinkedSymptom>>{};
    for (final linkedSymptom in linkedSymptoms) {
      final key = linkedSymptom.symptom.fullDescription;
      byDescription.putIfAbsent(key, () => []).add(linkedSymptom);
    }

    final sortedKeys = byDescription.keys.toList()
      ..sort((a, b) =>
          byDescription[b]!.length.compareTo(byDescription[a]!.length));

    return Column(
      children: sortedKeys.map((description) {
        final occurrences = byDescription[description]!;
        final avgSeverity =
            occurrences.map((ls) => ls.symptom.severityLevel).reduce(
                  (a, b) => a + b,
                ) /
            occurrences.length;
        final avgColor = SeverityUtils.colorForSeverity(avgSeverity.round());

        return GestureDetector(
          onTap: () {
            final symptom = occurrences.first.symptom;
            if (symptom.majorComponent.isEmpty) return;
            if (symptom.minorComponent.isNotEmpty) {
              context.push(
                SubSymptomTrendsScreen(
                  majorComponent: symptom.majorComponent,
                  minorComponent: symptom.minorComponent,
                ),
              );
              return;
            }
            context.push(
              SymptomTrendsScreen(symptomName: symptom.majorComponent),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.s),
            decoration: BoxDecoration(
              color: AppColors.backgroundTertiary,
              borderRadius: BorderRadius.circular(AppRadius.small),
              border: Border(
                left: BorderSide(color: avgColor, width: 3),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(description, style: AppText.body.medium),
                ),
                HSpace.s,
                Text(
                  '${occurrences.length}×',
                  style: AppText.body.small.secondary,
                ),
                HSpace.s,
                EnhancedUIComponents.statusIndicator(
                  text: 'avg ${avgSeverity.toStringAsFixed(1)}',
                  color: avgColor,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _showSymptomDateDialog(
    DateTime date,
    List<LinkedSymptom> symptoms,
  ) async {
    if (symptoms.isEmpty) return;

    final uniqueNoteIds = symptoms.map((ls) => ls.healthNoteId).toSet();
    final notes = <HealthNote>[];
    for (final noteId in uniqueNoteIds) {
      final note = await HealthNotesDao.getNoteById(noteId);
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
        final noteSymptomCount =
            symptoms.where((ls) => ls.healthNoteId == note.id).length;
        return Text(
          '${DateFormat('h:mm a').format(note.dateTime)}  ·  $noteSymptomCount symptom${noteSymptomCount == 1 ? '' : 's'}',
        );
      },
    );
  }
}
