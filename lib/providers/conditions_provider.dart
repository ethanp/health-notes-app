import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:health_notes/models/condition.dart';
import 'package:health_notes/models/condition_entry.dart';
import 'package:health_notes/models/symptom.dart';
import 'package:health_notes/services/conditions_dao.dart';
import 'package:health_notes/services/condition_entries_dao.dart';
import 'package:health_notes/providers/auth_provider.dart';
import 'package:health_notes/providers/health_notes_provider.dart';
import 'package:health_notes/utils/data_utils.dart';

part 'conditions_provider.g.dart';

/// A symptom linked to a condition, with date information from the health note.
class LinkedSymptom {
  final DateTime date;
  final Symptom symptom;
  final String healthNoteId;

  const LinkedSymptom({
    required this.date,
    required this.symptom,
    required this.healthNoteId,
  });
}

@riverpod
class ConditionsNotifier extends _$ConditionsNotifier {
  @override
  Future<List<Condition>> build() async {
    final user = await ref.watch(currentUserProvider.future);
    if (user == null) {
      throw Exception('User not authenticated');
    }
    return await ConditionsDao.getAllConditions(user.id);
  }

  Future<List<Condition>> getActiveConditions() async {
    final user = await ref.read(currentUserProvider.future);
    if (user == null) return [];
    return await ConditionsDao.getActiveConditions(user.id);
  }

  Future<Condition?> getConditionById(String id) async {
    return await ConditionsDao.getConditionById(id);
  }

  Future<Condition?> getActiveConditionByName(String name) async {
    final user = await ref.read(currentUserProvider.future);
    if (user == null) return null;
    return await ConditionsDao.getActiveConditionByName(user.id, name);
  }

  Future<Condition> addCondition({
    required String name,
    required DateTime startDate,
    int colorValue = 0xFFE57373,
    int iconCodePoint = 0xf36e,
    String notes = '',
  }) async {
    final user = await ref.read(currentUserProvider.future);
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final now = DateTime.now();
    final newCondition = Condition(
      id: DataUtils.uuid.v4(),
      userId: user.id,
      name: name,
      startDate: startDate,
      status: ConditionStatus.active,
      colorValue: colorValue,
      iconCodePoint: iconCodePoint,
      notes: notes,
      createdAt: now,
      updatedAt: now,
    );

    await ConditionsDao.insertCondition(newCondition, user.id);
    DataUtils.syncService.queueForSync(
      'conditions',
      newCondition.id,
      'insert',
      newCondition.toJsonForUpdate(),
    );

    ref.invalidateSelf();
    return newCondition;
  }

  Future<void> updateCondition(Condition condition) async {
    await ConditionsDao.updateCondition(condition);
    DataUtils.syncService.queueForSync(
      'conditions',
      condition.id,
      'update',
      condition.toJsonForUpdate(),
    );
    ref.invalidateSelf();
  }

  Future<void> resolveCondition(String id, {DateTime? endDate}) async {
    final resolveDate = endDate ?? DateTime.now();
    await ConditionsDao.resolveCondition(id, resolveDate);
    DataUtils.syncService.queueForSync(
      'conditions',
      id,
      'update',
      {
        'condition_status': ConditionStatus.resolved.name,
        'end_date': resolveDate.toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
    );
    ref.invalidateSelf();
  }

  Future<void> deleteCondition(String id) async {
    await ConditionEntriesDao.deleteEntriesForCondition(id);
    await ConditionsDao.deleteCondition(id);
    DataUtils.syncService.queueForSync('conditions', id, 'delete', {});
    ref.invalidateSelf();
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

@riverpod
class ConditionEntriesNotifier extends _$ConditionEntriesNotifier {
  @override
  Future<List<ConditionEntry>> build(String conditionId) async {
    return await ConditionEntriesDao.getEntriesForCondition(conditionId);
  }

  Future<ConditionEntry?> getEntryForDate(DateTime date) async {
    final conditionId = this.conditionId;
    return await ConditionEntriesDao.getEntryForDate(conditionId, date);
  }

  Future<ConditionEntry> addEntry({
    required DateTime entryDate,
    required int severity,
    required ConditionPhase phase,
    required String notes,
    required String linkedCheckInId,
  }) async {
    final now = DateTime.now();
    final newEntry = ConditionEntry(
      id: DataUtils.uuid.v4(),
      conditionId: conditionId,
      entryDate: entryDate,
      severity: severity,
      phase: phase,
      notes: notes,
      linkedCheckInId: linkedCheckInId,
      createdAt: now,
      updatedAt: now,
    );

    await ConditionEntriesDao.insertEntry(newEntry);
    DataUtils.syncService.queueForSync(
      'condition_entries',
      newEntry.id,
      'insert',
      newEntry.toJsonForUpdate(),
    );

    ref.invalidateSelf();
    return newEntry;
  }

  Future<void> updateEntry(ConditionEntry entry) async {
    await ConditionEntriesDao.updateEntry(entry);
    DataUtils.syncService.queueForSync(
      'condition_entries',
      entry.id,
      'update',
      entry.toJsonForUpdate(),
    );
    ref.invalidateSelf();
  }

  Future<void> deleteEntry(String id) async {
    await ConditionEntriesDao.deleteEntry(id);
    DataUtils.syncService.queueForSync('condition_entries', id, 'delete', {});
    ref.invalidateSelf();
  }
}

@riverpod
Future<List<Condition>> activeConditions(Ref ref) async {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) return [];
  return await ConditionsDao.getActiveConditions(user.id);
}

@riverpod
Future<List<ConditionEntry>> conditionEntriesForCheckIn(Ref ref, String checkInId) async {
  return await ConditionEntriesDao.getEntriesForCheckIn(checkInId);
}

/// Provider that returns all symptoms linked to a specific condition.
/// Symptoms are linked via conditionId in health notes.
@riverpod
Future<List<LinkedSymptom>> symptomsForCondition(Ref ref, String conditionId) async {
  final healthNotes = await ref.watch(healthNotesNotifierProvider.future);
  final linkedSymptoms = <LinkedSymptom>[];

  for (final note in healthNotes) {
    for (final symptom in note.symptomsList) {
      if (symptom.conditionId == conditionId) {
        linkedSymptoms.add(LinkedSymptom(
          date: note.dateTime,
          symptom: symptom,
          healthNoteId: note.id,
        ));
      }
    }
  }

  // Sort by date descending (most recent first)
  linkedSymptoms.sort((a, b) => b.date.compareTo(a.date));
  return linkedSymptoms;
}

