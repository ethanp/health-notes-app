import 'package:ethan_sync/ethan_sync.dart';
import 'package:ethan_utils/ethan_utils.dart';
import 'package:health_notes/models/condition_entry.dart';
import 'package:powersync/powersync.dart';

class ConditionEntriesDao(final PowerSyncDatabase _powerSync) {
  static const _tableName = 'condition_entries';

  Future<List<ConditionEntry>> getEntriesForCondition(
    String conditionId,
  ) async {
    final entryRows = await _powerSync.getAll(
      'SELECT * FROM $_tableName WHERE condition_id = ? AND is_deleted = 0 '
      'ORDER BY entry_date DESC',
      [conditionId],
    );
    return [for (final entryRow in entryRows) _mapToConditionEntry(entryRow)];
  }

  Future<ConditionEntry?> getEntryById(String id) async {
    final entryRow = await _powerSync.getOptional(
      'SELECT * FROM $_tableName WHERE id = ? AND is_deleted = 0',
      [id],
    );
    if (entryRow == null) return null;
    return _mapToConditionEntry(entryRow);
  }

  Future<ConditionEntry?> getEntryForDate(
    String conditionId,
    DateTime date,
  ) async {
    final datePrefix = date.startOfDay.toIso8601String().split('T')[0];
    final entryRow = await _powerSync.getOptional(
      'SELECT * FROM $_tableName WHERE condition_id = ? AND entry_date LIKE ? '
      'AND is_deleted = 0 LIMIT 1',
      [conditionId, '$datePrefix%'],
    );
    if (entryRow == null) return null;
    return _mapToConditionEntry(entryRow);
  }

  Future<List<ConditionEntry>> getEntriesForCheckIn(String checkInId) async {
    final entryRows = await _powerSync.getAll(
      'SELECT * FROM $_tableName WHERE linked_check_in_id = ? AND is_deleted = 0',
      [checkInId],
    );
    return [for (final entryRow in entryRows) _mapToConditionEntry(entryRow)];
  }

  Future<void> insertEntry(ConditionEntry entry) async {
    final now = DateTime.now().toIso8601String();
    await _powerSync.upsert(_tableName, {
      'id': entry.id,
      'condition_id': entry.conditionId,
      'entry_date': entry.entryDate.toIso8601String(),
      'severity': entry.severity,
      'phase': entry.phase.name,
      'notes': entry.notes,
      'linked_check_in_id': entry.linkedCheckInId,
      'created_at': entry.createdAt.toIso8601String(),
      'updated_at': now,
      'is_deleted': 0,
    });
  }

  Future<void> updateEntry(ConditionEntry entry) async {
    final now = DateTime.now().toIso8601String();
    await _powerSync.execute(
      'UPDATE $_tableName SET severity = ?, phase = ?, notes = ?, '
      'updated_at = ? WHERE id = ?',
      [entry.severity, entry.phase.name, entry.notes, now, entry.id],
    );
  }

  Future<void> deleteEntry(String id) async {
    final now = DateTime.now().toIso8601String();
    await _powerSync.execute(
      'UPDATE $_tableName SET is_deleted = 1, updated_at = ? WHERE id = ?',
      [now, id],
    );
  }

  Future<void> deleteEntriesForCondition(String conditionId) async {
    final now = DateTime.now().toIso8601String();
    await _powerSync.execute(
      'UPDATE $_tableName SET is_deleted = 1, updated_at = ? '
      'WHERE condition_id = ?',
      [now, conditionId],
    );
  }

  Future<void> deleteEntriesForCheckIn(String checkInId) async {
    final now = DateTime.now().toIso8601String();
    await _powerSync.execute(
      'UPDATE $_tableName SET is_deleted = 1, updated_at = ? '
      'WHERE linked_check_in_id = ?',
      [now, checkInId],
    );
  }

  static ConditionEntry _mapToConditionEntry(Map<String, dynamic> entryRow) {
    return ConditionEntry(
      id: entryRow['id'] as String,
      conditionId: entryRow['condition_id'] as String,
      entryDate: DateTime.parse(entryRow['entry_date'] as String),
      severity: entryRow['severity'] as int,
      phase: ConditionPhase.values.firstWhere(
        (phase) => phase.name == entryRow['phase'],
        orElse: () => ConditionPhase.onset,
      ),
      notes: entryRow['notes'] as String? ?? '',
      linkedCheckInId: entryRow['linked_check_in_id'] as String,
      createdAt: DateTime.parse(entryRow['created_at'] as String),
      updatedAt: DateTime.parse(entryRow['updated_at'] as String),
    );
  }
}
