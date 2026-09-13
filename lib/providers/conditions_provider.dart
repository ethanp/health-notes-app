import 'package:health_notes/app_identity.dart';
import 'package:health_notes/models/condition.dart';
import 'package:health_notes/models/condition_entry.dart';
import 'package:health_notes/models/symptom.dart';
import 'package:health_notes/providers/dao_providers.dart';
import 'package:health_notes/providers/health_notes_provider.dart';
import 'package:health_notes/utils/data_utils.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'conditions_provider.g.dart';

/// A symptom linked to a condition, with date information from the health note.
class const LinkedSymptom({
  required final DateTime date,
  required final Symptom symptom,
  required final String healthNoteId,
});

@riverpod
class ConditionsNotifier() extends _$ConditionsNotifier {
  @override
  Future<List<Condition>> build() async {
    final conditionsDao = await ref.watch(conditionsDaoProvider.future);
    return conditionsDao.getAllConditions(AppIdentity.localUserId);
  }

  Future<List<Condition>> getActiveConditions() async {
    final conditionsDao = await ref.read(conditionsDaoProvider.future);
    return conditionsDao.getActiveConditions(AppIdentity.localUserId);
  }

  Future<Condition?> getConditionById(String id) async {
    final conditionsDao = await ref.read(conditionsDaoProvider.future);
    return conditionsDao.getConditionById(id);
  }

  Future<Condition?> getActiveConditionByName(String name) async {
    final conditionsDao = await ref.read(conditionsDaoProvider.future);
    return conditionsDao.getActiveConditionByName(
      AppIdentity.localUserId,
      name,
    );
  }

  Future<Condition> addCondition({
    required String name,
    required DateTime startDate,
    int colorValue = 0xFFE57373,
    int iconCodePoint = 0xf36e,
    String notes = '',
  }) async {
    final conditionsDao = await ref.read(conditionsDaoProvider.future);
    final now = DateTime.now();
    final newCondition = Condition(
      id: DataUtils.uuid.v4(),
      userId: AppIdentity.localUserId,
      name: name,
      startDate: startDate,
      status: ConditionStatus.active,
      colorValue: colorValue,
      iconCodePoint: iconCodePoint,
      notes: notes,
      createdAt: now,
      updatedAt: now,
    );
    await conditionsDao.insertCondition(newCondition, AppIdentity.localUserId);
    ref.invalidateSelf();
    return newCondition;
  }

  Future<void> updateCondition(Condition condition) async {
    final conditionsDao = await ref.read(conditionsDaoProvider.future);
    await conditionsDao.updateCondition(condition);
    ref.invalidateSelf();
  }

  Future<void> resolveCondition(String id, {DateTime? endDate}) async {
    final conditionsDao = await ref.read(conditionsDaoProvider.future);
    await conditionsDao.resolveCondition(id, endDate ?? DateTime.now());
    ref.invalidateSelf();
  }

  Future<void> deleteCondition(String id) async {
    final entriesDao = await ref.read(conditionEntriesDaoProvider.future);
    final conditionsDao = await ref.read(conditionsDaoProvider.future);
    await entriesDao.deleteEntriesForCondition(id);
    await conditionsDao.deleteCondition(id);
    ref.invalidateSelf();
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

@riverpod
class ConditionEntriesNotifier() extends _$ConditionEntriesNotifier {
  @override
  Future<List<ConditionEntry>> build(String conditionId) async {
    final entriesDao = await ref.watch(conditionEntriesDaoProvider.future);
    return entriesDao.getEntriesForCondition(conditionId);
  }

  Future<ConditionEntry?> getEntryForDate(DateTime date) async {
    final entriesDao = await ref.read(conditionEntriesDaoProvider.future);
    return entriesDao.getEntryForDate(conditionId, date);
  }

  Future<ConditionEntry> addEntry({
    required DateTime entryDate,
    required int severity,
    required ConditionPhase phase,
    required String notes,
    required String linkedCheckInId,
  }) async {
    final entriesDao = await ref.read(conditionEntriesDaoProvider.future);
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
    await entriesDao.insertEntry(newEntry);
    ref.invalidateSelf();
    return newEntry;
  }

  Future<void> updateEntry(ConditionEntry entry) async {
    final entriesDao = await ref.read(conditionEntriesDaoProvider.future);
    await entriesDao.updateEntry(entry);
    ref.invalidateSelf();
  }

  Future<void> deleteEntry(String id) async {
    final entriesDao = await ref.read(conditionEntriesDaoProvider.future);
    await entriesDao.deleteEntry(id);
    ref.invalidateSelf();
  }
}

@riverpod
Future<List<Condition>> activeConditions(Ref ref) async {
  final conditionsDao = await ref.watch(conditionsDaoProvider.future);
  return conditionsDao.getActiveConditions(AppIdentity.localUserId);
}

@riverpod
Future<List<ConditionEntry>> conditionEntriesForCheckIn(
  Ref ref,
  String checkInId,
) async {
  final entriesDao = await ref.watch(conditionEntriesDaoProvider.future);
  return entriesDao.getEntriesForCheckIn(checkInId);
}

@riverpod
Future<List<LinkedSymptom>> symptomsForCondition(
  Ref ref,
  String conditionId,
) async {
  final healthNotes = await ref.watch(healthNotesProvider.future);
  final linkedSymptoms = <LinkedSymptom>[];
  for (final note in healthNotes) {
    for (final symptom in note.symptomsList) {
      if (symptom.conditionId == conditionId) {
        linkedSymptoms.add(
          LinkedSymptom(
            date: note.dateTime,
            symptom: symptom,
            healthNoteId: note.id,
          ),
        );
      }
    }
  }
  linkedSymptoms.sort((a, b) => b.date.compareTo(a.date));
  return linkedSymptoms;
}
