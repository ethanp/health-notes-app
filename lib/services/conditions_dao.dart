import 'package:sqflite/sqflite.dart';
import 'package:health_notes/models/condition.dart';
import 'package:health_notes/services/local_database.dart';

class ConditionsDao {
  static const String _tableName = 'conditions';

  static Future<List<Condition>> getAllConditions(String userId) async {
    final db = await LocalDatabase.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'user_id = ? AND is_deleted = 0',
      whereArgs: [userId],
      orderBy: 'start_date DESC',
    );
    return maps.map((map) => _mapToCondition(map)).toList();
  }

  static Future<List<Condition>> getActiveConditions(String userId) async {
    final db = await LocalDatabase.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'user_id = ? AND condition_status = ? AND is_deleted = 0',
      whereArgs: [userId, 'active'],
      orderBy: 'start_date DESC',
    );
    return maps.map((map) => _mapToCondition(map)).toList();
  }

  static Future<Condition?> getConditionById(String id) async {
    final db = await LocalDatabase.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'id = ? AND is_deleted = 0',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return _mapToCondition(maps.first);
  }

  static Future<Condition?> getActiveConditionByName(String userId, String name) async {
    final db = await LocalDatabase.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'user_id = ? AND name = ? AND condition_status = ? AND is_deleted = 0',
      whereArgs: [userId, name, 'active'],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return _mapToCondition(maps.first);
  }

  static Future<void> insertCondition(Condition condition, String userId) async {
    final db = await LocalDatabase.database;
    final now = DateTime.now().toIso8601String();

    await db.insert(_tableName, {
      'id': condition.id,
      'user_id': userId,
      'name': condition.name,
      'start_date': condition.startDate.toIso8601String(),
      'end_date': condition.endDate?.toIso8601String(),
      'condition_status': condition.status.name,
      'color_value': condition.colorValue,
      'icon_code_point': condition.iconCodePoint,
      'notes': condition.notes,
      'created_at': condition.createdAt.toIso8601String(),
      'updated_at': now,
      'sync_status': SyncStatus.pending.value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<void> updateCondition(Condition condition) async {
    final db = await LocalDatabase.database;
    final now = DateTime.now().toIso8601String();

    await db.update(
      _tableName,
      {
        'name': condition.name,
        'start_date': condition.startDate.toIso8601String(),
        'end_date': condition.endDate?.toIso8601String(),
        'condition_status': condition.status.name,
        'color_value': condition.colorValue,
        'icon_code_point': condition.iconCodePoint,
        'notes': condition.notes,
        'updated_at': now,
        'sync_status': SyncStatus.pending.value,
      },
      where: 'id = ?',
      whereArgs: [condition.id],
    );
  }

  static Future<void> resolveCondition(String id, DateTime endDate) async {
    final db = await LocalDatabase.database;
    final now = DateTime.now().toIso8601String();

    await db.update(
      _tableName,
      {
        'condition_status': ConditionStatus.resolved.name,
        'end_date': endDate.toIso8601String(),
        'updated_at': now,
        'sync_status': SyncStatus.pending.value,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<void> deleteCondition(String id) async {
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

  static Future<List<Map<String, dynamic>>> getPendingSyncConditions() async {
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

  static Future<void> upsertFromServer(
    Map<String, dynamic> serverData,
    String userId,
  ) async {
    final db = await LocalDatabase.database;
    final now = DateTime.now().toIso8601String();

    final existing = await getConditionById(serverData['id']);

    if (existing != null) {
      final serverUpdatedStr = serverData['updated_at'] ?? serverData['created_at'] ?? now;
      final serverUpdated = DateTime.parse(serverUpdatedStr);
      final localUpdated = existing.updatedAt;

      if (serverUpdated.isAfter(localUpdated)) {
        await db.update(
          _tableName,
          {
            'name': serverData['name'],
            'start_date': serverData['start_date'],
            'end_date': serverData['end_date'],
            'condition_status': serverData['condition_status'],
            'color_value': serverData['color_value'],
            'icon_code_point': serverData['icon_code_point'],
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
        'user_id': userId,
        'name': serverData['name'],
        'start_date': serverData['start_date'],
        'end_date': serverData['end_date'],
        'condition_status': serverData['condition_status'] ?? 'active',
        'color_value': serverData['color_value'] ?? 4293467747,
        'icon_code_point': serverData['icon_code_point'] ?? 62318,
        'notes': serverData['notes'] ?? '',
        'created_at': serverData['created_at'] ?? now,
        'updated_at': serverData['updated_at'] ?? now,
        'sync_status': SyncStatus.synced.value,
        'synced_at': now,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  static Condition _mapToCondition(Map<String, dynamic> map) {
    return Condition(
      id: map['id'],
      userId: map['user_id'],
      name: map['name'],
      startDate: DateTime.parse(map['start_date']),
      endDate: map['end_date'] != null ? DateTime.parse(map['end_date']) : null,
      status: ConditionStatus.values.firstWhere(
        (s) => s.name == map['condition_status'],
        orElse: () => ConditionStatus.active,
      ),
      colorValue: map['color_value'],
      iconCodePoint: map['icon_code_point'],
      notes: map['notes'] ?? '',
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }
}

