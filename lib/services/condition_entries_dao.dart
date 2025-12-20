import 'package:sqflite/sqflite.dart';
import 'package:health_notes/models/condition_entry.dart';
import 'package:health_notes/services/local_database.dart';

class ConditionEntriesDao {
  static const String _tableName = 'condition_entries';

  static Future<List<ConditionEntry>> getEntriesForCondition(String conditionId) async {
    final db = await LocalDatabase.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'condition_id = ? AND is_deleted = 0',
      whereArgs: [conditionId],
      orderBy: 'entry_date DESC',
    );
    return maps.map((map) => _mapToConditionEntry(map)).toList();
  }

  static Future<ConditionEntry?> getEntryById(String id) async {
    final db = await LocalDatabase.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'id = ? AND is_deleted = 0',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return _mapToConditionEntry(maps.first);
  }

  static Future<ConditionEntry?> getEntryForDate(String conditionId, DateTime date) async {
    final db = await LocalDatabase.database;
    final dateStr = DateTime(date.year, date.month, date.day).toIso8601String().split('T')[0];
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'condition_id = ? AND entry_date LIKE ? AND is_deleted = 0',
      whereArgs: [conditionId, '$dateStr%'],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return _mapToConditionEntry(maps.first);
  }

  static Future<List<ConditionEntry>> getEntriesForCheckIn(String checkInId) async {
    final db = await LocalDatabase.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'linked_check_in_id = ? AND is_deleted = 0',
      whereArgs: [checkInId],
    );
    return maps.map((map) => _mapToConditionEntry(map)).toList();
  }

  static Future<void> insertEntry(ConditionEntry entry) async {
    final db = await LocalDatabase.database;
    final now = DateTime.now().toIso8601String();

    await db.insert(_tableName, {
      'id': entry.id,
      'condition_id': entry.conditionId,
      'entry_date': entry.entryDate.toIso8601String(),
      'severity': entry.severity,
      'phase': entry.phase.name,
      'notes': entry.notes,
      'linked_check_in_id': entry.linkedCheckInId,
      'created_at': entry.createdAt.toIso8601String(),
      'updated_at': now,
      'sync_status': SyncStatus.pending.value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<void> updateEntry(ConditionEntry entry) async {
    final db = await LocalDatabase.database;
    final now = DateTime.now().toIso8601String();

    await db.update(
      _tableName,
      {
        'severity': entry.severity,
        'phase': entry.phase.name,
        'notes': entry.notes,
        'updated_at': now,
        'sync_status': SyncStatus.pending.value,
      },
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  static Future<void> deleteEntry(String id) async {
    final db = await LocalDatabase.database;
    final now = DateTime.now().toIso8601String();

    await db.update(
      _tableName,
      {
        'is_deleted': 1,
        'updated_at': now,
        'sync_status': SyncStatus.pending.value,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<void> deleteEntriesForCondition(String conditionId) async {
    final db = await LocalDatabase.database;
    final now = DateTime.now().toIso8601String();

    await db.update(
      _tableName,
      {
        'is_deleted': 1,
        'updated_at': now,
        'sync_status': SyncStatus.pending.value,
      },
      where: 'condition_id = ?',
      whereArgs: [conditionId],
    );
  }

  static Future<void> deleteEntriesForCheckIn(String checkInId) async {
    final db = await LocalDatabase.database;
    final now = DateTime.now().toIso8601String();

    await db.update(
      _tableName,
      {
        'is_deleted': 1,
        'updated_at': now,
        'sync_status': SyncStatus.pending.value,
      },
      where: 'linked_check_in_id = ?',
      whereArgs: [checkInId],
    );
  }

  static Future<List<Map<String, dynamic>>> getPendingSyncEntries() async {
    final db = await LocalDatabase.database;
    return await db.query(
      _tableName,
      where: 'sync_status IN (?, ?)',
      whereArgs: [SyncStatus.pending.value, SyncStatus.failed.value],
    );
  }

  static Future<void> markAsSynced(String id) async {
    final db = await LocalDatabase.database;
    final now = DateTime.now().toIso8601String();

    await db.update(
      _tableName,
      {'sync_status': SyncStatus.synced.value, 'synced_at': now},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<void> upsertFromServer(Map<String, dynamic> serverData) async {
    final db = await LocalDatabase.database;
    final now = DateTime.now().toIso8601String();

    final existing = await getEntryById(serverData['id']);

    if (existing != null) {
      final serverUpdatedStr = serverData['updated_at'] ?? serverData['created_at'] ?? now;
      final serverUpdated = DateTime.parse(serverUpdatedStr);
      final localUpdated = existing.updatedAt;

      if (serverUpdated.isAfter(localUpdated)) {
        await db.update(
          _tableName,
          {
            'severity': serverData['severity'],
            'phase': serverData['phase'],
            'notes': serverData['notes'] ?? '',
            'updated_at': serverData['updated_at'] ?? now,
            'sync_status': SyncStatus.synced.value,
            'synced_at': now,
          },
          where: 'id = ?',
          whereArgs: [serverData['id']],
        );
      }
    } else {
      await db.insert(_tableName, {
        'id': serverData['id'],
        'condition_id': serverData['condition_id'],
        'entry_date': serverData['entry_date'],
        'severity': serverData['severity'],
        'phase': serverData['phase'] ?? 'onset',
        'notes': serverData['notes'] ?? '',
        'linked_check_in_id': serverData['linked_check_in_id'],
        'created_at': serverData['created_at'] ?? now,
        'updated_at': serverData['updated_at'] ?? now,
        'sync_status': SyncStatus.synced.value,
        'synced_at': now,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  static ConditionEntry _mapToConditionEntry(Map<String, dynamic> map) {
    return ConditionEntry(
      id: map['id'],
      conditionId: map['condition_id'],
      entryDate: DateTime.parse(map['entry_date']),
      severity: map['severity'],
      phase: ConditionPhase.values.firstWhere(
        (p) => p.name == map['phase'],
        orElse: () => ConditionPhase.onset,
      ),
      notes: map['notes'] ?? '',
      linkedCheckInId: map['linked_check_in_id'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }
}

