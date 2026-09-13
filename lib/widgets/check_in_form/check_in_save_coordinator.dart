import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_notes/models/check_in.dart';
import 'package:health_notes/models/condition_entry.dart';
import 'package:health_notes/providers/check_ins_provider.dart';
import 'package:health_notes/providers/conditions_provider.dart';
import 'package:health_notes/utils/data_utils.dart';

class const CheckInSaveCoordinator({required final WidgetRef ref}) {
  Future<void> save({
    required CheckIn? existing,
    required DateTime dateTime,
    required Map<String, int> selectedMetrics,
    required List<ConditionEntryDraft> conditionDrafts,
  }) async {
    final notifier = ref.read(checkInsProvider.notifier);
    final checkInId = existing != null
        ? await _updateExisting(
            notifier,
            existing: existing,
            dateTime: dateTime,
            selectedMetrics: selectedMetrics,
          )
        : await _addNew(
            notifier,
            dateTime: dateTime,
            selectedMetrics: selectedMetrics,
          );

    await _saveConditionDrafts(
      dateTime: dateTime,
      checkInId: checkInId,
      conditionDrafts: conditionDrafts,
    );
  }

  Future<String> _updateExisting(
    CheckInsNotifier notifier, {
    required CheckIn existing,
    required DateTime dateTime,
    required Map<String, int> selectedMetrics,
  }) async {
    final entry = selectedMetrics.entries.first;
    await notifier.updateCheckIn(
      existing.copyWith(
        metricName: entry.key,
        rating: entry.value,
        dateTime: dateTime,
      ),
    );
    return existing.id;
  }

  Future<String> _addNew(
    CheckInsNotifier notifier, {
    required DateTime dateTime,
    required Map<String, int> selectedMetrics,
  }) async {
    for (final entry in selectedMetrics.entries) {
      await notifier.addCheckIn(
        CheckIn(
          id: '',
          metricName: entry.key,
          rating: entry.value,
          dateTime: dateTime,
          createdAt: DateTime.now(),
        ),
      );
    }

    final allCheckIns = await ref.read(checkInsProvider.future);
    final latestCheckIn = allCheckIns
        .where(
          (checkIn) =>
              checkIn.dateTime.isAtSameMomentAs(dateTime) ||
              checkIn.dateTime.difference(dateTime).inSeconds.abs() < 5,
        )
        .toList();
    if (latestCheckIn.isNotEmpty) {
      return latestCheckIn.first.id;
    }
    return DataUtils.uuid.v4();
  }

  Future<void> _saveConditionDrafts({
    required DateTime dateTime,
    required String checkInId,
    required List<ConditionEntryDraft> conditionDrafts,
  }) async {
    for (final draft in conditionDrafts) {
      final conditionsNotifier = ref.read(conditionsProvider.notifier);
      final entriesNotifier = ref.read(
        conditionEntriesProvider(draft.conditionId).notifier,
      );

      await entriesNotifier.addEntry(
        entryDate: dateTime,
        severity: draft.severity,
        phase: draft.phase,
        notes: draft.notes,
        linkedCheckInId: checkInId,
      );

      if (draft.markResolved) {
        await conditionsNotifier.resolveCondition(
          draft.conditionId,
          endDate: dateTime,
        );
      }
    }
  }
}
